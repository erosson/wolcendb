module Main exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Datamine.NormalItem as NormalItem exposing (NormalItem)
import Datamine.UniqueItem as UniqueItem exposing (UniqueItem)
import Dict exposing (Dict)
import ElmTextSearch
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Decode as D
import Lang exposing (Lang)
import Maybe.Extra
import Page.Affixes
import Page.Ailments
import Page.BuildRevisions
import Page.Changelog
import Page.City
import Page.Gems
import Page.Home
import Page.Langs
import Page.NormalItem
import Page.NormalItems
import Page.Offline
import Page.Passives
import Page.Privacy
import Page.Reagents
import Page.Search
import Page.Skill
import Page.SkillVariant
import Page.Skills
import Page.Source
import Page.Table
import Page.UniqueItem
import Page.UniqueItems
import Ports
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Search exposing (SearchScore)
import Set exposing (Set)
import Task
import Url exposing (Url)
import Util
import View.Affix
import View.Loading
import View.Nav



---- MODEL ----


type alias Model =
    { nav : Maybe Nav.Key
    , buildRevisions : List String
    , datamine : RemoteData String Datamine
    , lang : RemoteData String Lang
    , defaultLang : RemoteData String Lang
    , langs : List String
    , searchIndex : RemoteData String Search.Index
    , changelog : String
    , route : Maybe Route

    -- TODO: these really belong in a per-page model
    , expandedAffixClasses : Set String
    , globalSearch : String
    , globalSearchResults : Result String (List SearchScore)
    , filterItemLevel : Int
    , filterGemFamilies : Set String
    , filterKeywords : Set String
    , filterGentypes : Set String
    , cityPlayerLevel : Int
    , progress : Dict String ( Int, Int )
    }


type alias Flags f =
    { f
        | changelog : String
        , buildRevisions : List String
        , langs : List String
        , datamine : Maybe D.Value
        , searchIndex : Maybe D.Value
    }


init : Flags {} -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    init_ flags (Route.parse url) (Just nav)
        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Ports.ssr View.Loading.ssrRootId ])


init_ : Flags f -> Maybe Route -> Maybe Nav.Key -> ( Model, Cmd Msg )
init_ flags route nav =
    let
        defaultLang =
            flags.datamine |> maybeDecode (D.decodeValue Lang.decoder >> Result.mapError D.errorToString)
    in
    { nav = nav
    , buildRevisions = flags.buildRevisions
    , langs = flags.langs
    , datamine = flags.datamine |> maybeDecode Datamine.decode
    , lang = defaultLang
    , defaultLang = defaultLang
    , searchIndex = flags.searchIndex |> maybeDecode Search.decodeIndex
    , changelog = flags.changelog
    , route = Nothing
    , expandedAffixClasses = Set.empty
    , globalSearch = ""
    , globalSearchResults = Ok []
    , filterItemLevel = 0
    , filterGemFamilies = Set.empty
    , filterKeywords = Set.empty
    , filterGentypes = Set.empty
    , cityPlayerLevel = 0
    , progress = Dict.empty
    }
        |> routeTo route


initSSRRender : Flags { url : String } -> ( Model, Cmd Msg )
initSSRRender flags =
    init_ flags (flags.url |> Url.fromString |> Maybe.andThen Route.parse) Nothing


initSSRPages : Flags {} -> ( Model, Cmd Msg )
initSSRPages flags =
    let
        ( model, cmd ) =
            init_ flags ("/" |> Url.fromString |> Maybe.andThen Route.parse) Nothing

        routes : List Route
        routes =
            case model.datamine of
                RemoteData.Success dm ->
                    [ dm.loot |> List.map (NormalItem.name >> Route.NormalItem)
                    , dm.uniqueLoot |> List.map (UniqueItem.name >> Route.UniqueItem)
                    , dm.skills |> List.map (.uid >> Route.Skill)
                    , dm.skills |> List.concatMap .variants |> List.map (.uid >> Route.SkillVariant)
                    ]
                        |> List.concat

                _ ->
                    []
    in
    ( model
    , Cmd.batch
        [ cmd
        , routes
            |> List.map (Route.toUrl >> .path)
            |> Ports.ssrCliPages
        ]
    )


maybeDecode : (D.Value -> Result String a) -> Maybe D.Value -> RemoteData String a
maybeDecode decoder mjson =
    case mjson |> Maybe.map decoder of
        Nothing ->
            RemoteData.NotAsked

        Just (Err err) ->
            RemoteData.Failure err

        Just (Ok ok) ->
            RemoteData.Success ok


routeTo : Maybe Route -> Model -> ( Model, Cmd Msg )
routeTo mroute model0 =
    case mroute of
        Just (Route.Redirect route) ->
            ( model0, Route.replaceUrl model0.nav route )

        Just (Route.WithOptions opts route) ->
            let
                ( model1, cmd1 ) =
                    routeTo (Just route) model0

                opts0 =
                    Route.toMOptions model0.route

                opts1 =
                    Route.toMOptions mroute
            in
            ( { model1 | route = mroute }, [ cmd1 ] )
                |> (\( m, cmd ) ->
                        if opts0.lang == opts1.lang then
                            ( m, cmd )

                        else
                            case opts1.lang of
                                Nothing ->
                                    ( { m | lang = m.defaultLang }, cmd )

                                Just lang ->
                                    ( { m | lang = RemoteData.Loading }
                                    , Ports.langRequest { lang = lang, revision = opts1.revision } :: cmd
                                    )
                   )
                |> (\( m, cmd ) ->
                        if opts0.revision == opts1.revision then
                            ( m, cmd )

                        else
                            ( { m | datamine = RemoteData.Loading }
                            , Ports.revisionRequest opts1.revision :: cmd
                            )
                   )
                |> Tuple.mapSecond Cmd.batch

        _ ->
            case model0.datamine of
                RemoteData.Success dm ->
                    let
                        model =
                            { model0 | route = mroute }
                    in
                    case mroute of
                        Just (Route.Search q) ->
                            ( Page.Search.init q dm model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    -- caller must retry when loaded
                    ( { model0 | route = mroute }, Cmd.none )



---- UPDATE ----


type Msg
    = Noop
    | LoadAssets Ports.LoadAssets
    | LoadAssetsProgress Ports.LoadAssetsProgress
    | LoadAssetsFailure Ports.LoadAssetsFailure
    | OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest
    | NormalItemMsg Page.NormalItem.Msg
    | PageAffixesMsg Page.Affixes.Msg
    | ViewAffixMsg View.Affix.ItemMsg
    | SearchMsg Page.Search.Msg
    | CityMsg Page.City.Msg
    | AilmentsMsg Page.Ailments.Msg
    | NavMsg View.Nav.Msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.loadAssets LoadAssets
        , Ports.loadAssetsProgress LoadAssetsProgress
        , Ports.loadAssetsFailure LoadAssetsFailure
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- loadassets stuff always runs, regardless of datamine state
    case msg of
        LoadAssets res ->
            let
                opts =
                    Route.toMOptions model.route

                name =
                    res.name ++ Maybe.Extra.unwrap "" ((++) "/") res.revision
            in
            (if opts.revision == res.revision then
                case res.name of
                    "datamine" ->
                        let
                            defaultLang =
                                D.decodeValue Lang.decoder res.json
                                    |> Result.mapError D.errorToString
                                    |> RemoteData.fromResult
                        in
                        { model
                            | datamine = Datamine.decode res.json |> RemoteData.fromResult
                            , defaultLang = defaultLang
                            , lang =
                                case model.lang of
                                    RemoteData.Success _ ->
                                        model.lang

                                    RemoteData.Failure _ ->
                                        model.lang

                                    _ ->
                                        defaultLang
                        }

                    "searchIndex" ->
                        { model | searchIndex = Search.decodeIndex res.json |> RemoteData.fromResult }

                    _ ->
                        if String.startsWith "lang/" res.name then
                            case D.decodeValue Lang.decoder res.json of
                                Ok lang ->
                                    { model | lang = RemoteData.Success lang }

                                Err err ->
                                    model

                        else
                            model

             else
                model
            )
                -- |> (\m -> {m|progress=model.progress |> Dict.remove name)
                |> routeTo model.route

        LoadAssetsProgress res ->
            let
                opts =
                    Route.toMOptions model.route

                name =
                    res.name ++ Maybe.Extra.unwrap "" ((++) "/") res.revision
            in
            ( { model | progress = model.progress |> Dict.insert name ( res.progress, res.size ) }, Cmd.none )

        LoadAssetsFailure err ->
            let
                opts =
                    Route.toMOptions model.route

                name =
                    err.name ++ Maybe.Extra.unwrap "" ((++) "/") err.revision
            in
            ( if opts.revision == err.revision then
                case err.name of
                    "datamine" ->
                        { model | datamine = remoteDataOr model.datamine <| RemoteData.Failure <| "Couldn't fetch datamine. Something is very wrong.\n\n" ++ err.err }

                    "searchIndex" ->
                        { model | searchIndex = remoteDataOr model.searchIndex <| RemoteData.Failure <| "Couldn't fetch searchIndex. Something is very wrong.\n\n" ++ err.err }

                    _ ->
                        case opts.lang of
                            Just lang ->
                                if err.name == "lang/" ++ lang ++ "_xml" then
                                    { model | lang = RemoteData.Failure <| "Couldn't fetch lang/" ++ lang ++ ". Something is very wrong.\n\n" ++ err.err }

                                else
                                    model

                            Nothing ->
                                model

              else
                model
            , Cmd.none
            )

        _ ->
            -- most msgs require datamine to be productive
            case model.datamine of
                RemoteData.Success dm ->
                    updateOk msg dm model

                _ ->
                    ( model, Cmd.none )


remoteDataOr : RemoteData e a -> RemoteData e a -> RemoteData e a
remoteDataOr a b =
    case a of
        RemoteData.Success _ ->
            a

        _ ->
            b


updateOk : Msg -> Datamine -> Model -> ( Model, Cmd Msg )
updateOk msg dm model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        LoadAssets res ->
            ( model, Cmd.none )

        LoadAssetsProgress res ->
            ( model, Cmd.none )

        LoadAssetsFailure res ->
            ( model, Cmd.none )

        OnUrlChange url ->
            let
                route =
                    Route.parse url
            in
            routeTo route model
                |> Tuple.mapSecond
                    (\cmd ->
                        Cmd.batch
                            [ cmd
                            , case route of
                                Just (Route.Redirect _) ->
                                    Cmd.none

                                _ ->
                                    Ports.urlChange { route = Route.toAnalytics route, path = url.path, query = url.query }
                            ]
                    )

        OnUrlRequest (Browser.Internal url) ->
            ( model
            , Cmd.batch
                [ case model.nav of
                    Nothing ->
                        Cmd.none

                    Just nav ->
                        url |> Url.toString |> Nav.pushUrl nav
                , Task.perform (always Noop) (Browser.Dom.setViewport 0 0)
                ]
            )

        OnUrlRequest (Browser.External url) ->
            ( model, Nav.load url )

        NormalItemMsg msg_ ->
            ( Page.NormalItem.update msg_ dm model, Cmd.none )

        PageAffixesMsg msg_ ->
            ( Page.Affixes.update msg_ dm model, Cmd.none )

        ViewAffixMsg msg_ ->
            ( View.Affix.update msg_ model, Cmd.none )

        SearchMsg msg_ ->
            Page.Search.update msg_ dm model
                |> Tuple.mapSecond (Cmd.map SearchMsg)

        CityMsg msg_ ->
            ( Page.City.update msg_ model, Cmd.none )

        AilmentsMsg msg_ ->
            ( Page.Ailments.update msg_ dm model, Cmd.none )

        NavMsg msg_ ->
            View.Nav.update msg_ dm model
                |> Tuple.mapSecond (Cmd.map NavMsg)



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model
    , body = viewBody { ssr = False } model model.route
    }


viewTitle : Model -> String
viewTitle model =
    case model.route of
        Nothing ->
            "WolcenDB"

        Just route ->
            case ( route, model.lang, model.datamine ) of
                ( Route.Redirect _, _, _ ) ->
                    "WolcenDB"

                ( Route.WithOptions _ next, _, _ ) ->
                    viewTitle { model | route = Just next }

                ( Route.Home, _, _ ) ->
                    "WolcenDB: a Wolcen item, skill, and magic affix database"

                ( Route.NormalItems tier kws okws, _, _ ) ->
                    "WolcenDB: normal item list"
                        ++ Maybe.Extra.unwrap "" (String.fromInt >> (++) ": Tier ") tier
                        ++ Maybe.Extra.unwrap "" ((++) ": ") kws

                ( Route.NormalItem name, RemoteData.Success lang, RemoteData.Success dm ) ->
                    "WolcenDB: normal item: " ++ Page.NormalItem.viewTitle lang dm name

                ( Route.NormalItem name, _, _ ) ->
                    "WolcenDB: normal item"

                ( Route.UniqueItems kws, _, _ ) ->
                    "WolcenDB: unique item list" ++ Maybe.Extra.unwrap "" ((++) ": ") kws

                ( Route.UniqueItem name, RemoteData.Success lang, RemoteData.Success dm ) ->
                    "WolcenDB: unique item: " ++ Page.UniqueItem.viewTitle lang dm name

                ( Route.UniqueItem name, _, _ ) ->
                    "WolcenDB: unique item"

                ( Route.Skills, _, _ ) ->
                    "WolcenDB: skill list"

                ( Route.Skill name, RemoteData.Success lang, RemoteData.Success dm ) ->
                    "WolcenDB: skill: " ++ Page.Skill.viewTitle lang dm name

                ( Route.Skill name, _, _ ) ->
                    "WolcenDB: skill"

                ( Route.SkillVariant id, RemoteData.Success lang, RemoteData.Success dm ) ->
                    "WolcenDB: skill-variant: " ++ Page.SkillVariant.viewTitle lang dm id

                ( Route.SkillVariant _, _, _ ) ->
                    "WolcenDB: skill-variant"

                ( Route.Affixes, _, _ ) ->
                    "WolcenDB: magic affixes and modifiers"

                ( Route.Gems, _, _ ) ->
                    "WolcenDB: gems"

                ( Route.Passives, _, _ ) ->
                    "WolcenDB: passive skill tree nodes"

                ( Route.Reagents, _, _ ) ->
                    "WolcenDB: crafting reagents"

                ( Route.City _, _, _ ) ->
                    "WolcenDB: endgame city rewards"

                ( Route.Ailments, _, _ ) ->
                    "WolcenDB: ailments"

                ( Route.Source _ _, _, _ ) ->
                    "WolcenDB: view xml source file"

                ( Route.Offline _ _, _, _ ) ->
                    "WolcenDB: view offline save file code (you dirty cheater, you)"

                ( Route.Search _, _, _ ) ->
                    "WolcenDB: search"

                ( Route.Table _, _, _ ) ->
                    "WolcenDB: raw tabular data"

                ( Route.BuildRevisions, _, _ ) ->
                    "WolcenDB: build revisions"

                ( Route.Langs, _, _ ) ->
                    "WolcenDB: languages"

                ( Route.Changelog, _, _ ) ->
                    "WolcenDB: changelog"

                ( Route.Privacy, _, _ ) ->
                    "WolcenDB: privacy"


viewBody : { ssr : Bool } -> Model -> Maybe Route -> List (Html Msg)
viewBody { ssr } model mroute =
    View.Loading.view { navbar = True }
        model
        (RemoteData.map2 Tuple.pair model.lang model.datamine)
        (\( lang, dm ) ->
            let
                content =
                    case mroute of
                        Nothing ->
                            viewNotFound

                        Just route ->
                            case route of
                                Route.Redirect _ ->
                                    -- should never be here, we should've performed the redirect in update/init
                                    viewNotFound

                                Route.WithOptions _ next ->
                                    viewBody { ssr = True } model (Just next)

                                Route.Home ->
                                    Page.Home.view dm

                                Route.NormalItems tier kws okws ->
                                    Page.NormalItems.view lang dm tier kws okws

                                Route.NormalItem name ->
                                    Page.NormalItem.view lang dm model name
                                        |> Maybe.map (List.map (H.map NormalItemMsg))
                                        |> Maybe.withDefault viewNotFound

                                Route.UniqueItems tags ->
                                    Page.UniqueItems.view lang dm tags

                                Route.UniqueItem name ->
                                    Page.UniqueItem.view lang dm name
                                        |> Maybe.withDefault viewNotFound

                                Route.Skills ->
                                    Page.Skills.view lang dm

                                Route.Skill s ->
                                    Page.Skill.view lang dm s
                                        |> Maybe.withDefault viewNotFound

                                Route.SkillVariant v ->
                                    Page.SkillVariant.view lang dm v
                                        |> Maybe.withDefault viewNotFound

                                Route.Affixes ->
                                    Page.Affixes.view lang dm model
                                        |> List.map (H.map PageAffixesMsg)

                                Route.Gems ->
                                    Page.Gems.view lang dm

                                Route.Passives ->
                                    Page.Passives.view lang dm

                                Route.Reagents ->
                                    Page.Reagents.view lang dm

                                Route.City name ->
                                    Page.City.view lang dm model name
                                        |> Maybe.withDefault viewNotFound
                                        |> List.map (H.map CityMsg)

                                Route.Ailments ->
                                    Page.Ailments.view dm model
                                        |> List.map (H.map AilmentsMsg)

                                Route.Source type_ id ->
                                    Page.Source.view lang dm type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Offline type_ id ->
                                    Page.Offline.view lang dm type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Search query ->
                                    Page.Search.view lang dm model
                                        |> List.map (H.map SearchMsg)

                                Route.Table t ->
                                    Page.Table.view lang dm t
                                        |> Maybe.withDefault viewNotFound

                                Route.BuildRevisions ->
                                    Page.BuildRevisions.view dm model

                                Route.Langs ->
                                    Page.Langs.view model

                                Route.Changelog ->
                                    Page.Changelog.view model

                                Route.Privacy ->
                                    Page.Privacy.view
            in
            -- no navbar for statically rendered pages, it's added by the loading page
            if ssr then
                content

            else
                [ Route.base <| Route.toMOptions model.route
                , div [ class "container" ]
                    ((View.Nav.view model |> H.map NavMsg)
                        :: content
                    )
                ]
        )


viewNotFound =
    [ code [] [ text "404 not found" ], div [] [ a [ Route.href Route.Home ] [ text "Back to safety" ] ] ]



---- PROGRAM ----


main : Program (Flags {}) Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
