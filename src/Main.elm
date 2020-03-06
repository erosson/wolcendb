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
import Maybe.Extra
import Page.Affixes
import Page.Ailments
import Page.Changelog
import Page.City
import Page.Gems
import Page.Home
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
import Search exposing (SearchResult)
import Set exposing (Set)
import Task
import Url exposing (Url)
import Util
import View.Affix
import View.Nav



---- MODEL ----


type alias Model =
    { nav : Maybe Nav.Key
    , datamine : RemoteData String Datamine
    , searchIndex : RemoteData String Search.Index
    , changelog : String
    , route : Maybe Route

    -- TODO: these really belong in a per-page model
    , expandedAffixClasses : Set String
    , globalSearch : String
    , globalSearchResults : Result String (List SearchResult)
    , filterItemLevel : Int
    , filterGemFamilies : Set String
    , filterKeywords : Set String
    , filterGentypes : Set String
    , cityPlayerLevel : Int
    , progress : Dict String ( Int, Int )
    }


type alias ReadyModel =
    { datamine : Datamine, searchIndex : Search.Index }


type alias Flags f =
    { f
        | changelog : String
        , datamine : Maybe D.Value
        , searchIndex : Maybe D.Value
    }


init : Flags {} -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    init_ flags (Route.parse url) (Just nav)
        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Ports.ssr ssrRootId ])


ssrRootId : String
ssrRootId =
    "ssr-root"


init_ : Flags f -> Maybe Route -> Maybe Nav.Key -> ( Model, Cmd Msg )
init_ flags route nav =
    { nav = nav
    , datamine = flags.datamine |> maybeDecode Datamine.decode
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


readyModel : Model -> RemoteData String ReadyModel
readyModel model =
    RemoteData.map2 ReadyModel model.datamine model.searchIndex


routeTo : Maybe Route -> Model -> ( Model, Cmd Msg )
routeTo mroute model0 =
    case readyModel model0 of
        RemoteData.Success ok ->
            let
                model =
                    { model0 | route = mroute }
            in
            case mroute of
                Just (Route.Search q) ->
                    ( Page.Search.init q ok model, Cmd.none )

                Just (Route.Redirect route) ->
                    ( model0, Route.replaceUrl model.nav route )

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
    | LoadAssetsFailure String
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
    case readyModel model of
        RemoteData.Success ready ->
            updateOk msg ready model

        _ ->
            case msg of
                LoadAssets res ->
                    { model
                        | datamine = Datamine.decode res.datamine |> RemoteData.fromResult
                        , searchIndex = Search.decodeIndex res.searchIndex |> RemoteData.fromResult
                    }
                        |> routeTo model.route

                LoadAssetsProgress res ->
                    ( { model | progress = model.progress |> Dict.insert res.label ( res.progress, res.size ) }, Cmd.none )

                LoadAssetsFailure err ->
                    ( { model | datamine = RemoteData.Failure <| "Couldn't fetch Wolcen data. Something is very wrong.\n\n" ++ err }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


updateOk : Msg -> ReadyModel -> Model -> ( Model, Cmd Msg )
updateOk msg ok model =
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
            ( Page.NormalItem.update msg_ ok.datamine model, Cmd.none )

        PageAffixesMsg msg_ ->
            ( Page.Affixes.update msg_ ok.datamine model, Cmd.none )

        ViewAffixMsg msg_ ->
            ( View.Affix.update msg_ model, Cmd.none )

        SearchMsg msg_ ->
            Page.Search.update msg_ ok model
                |> Tuple.mapSecond (Cmd.map SearchMsg)

        CityMsg msg_ ->
            ( Page.City.update msg_ model, Cmd.none )

        AilmentsMsg msg_ ->
            ( Page.Ailments.update msg_ ok.datamine model, Cmd.none )

        NavMsg msg_ ->
            View.Nav.update msg_ ok model
                |> Tuple.mapSecond (Cmd.map NavMsg)



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model, body = viewBody { ssr = False } model }


viewTitle : Model -> String
viewTitle model =
    case model.route of
        Nothing ->
            "WolcenDB"

        Just route ->
            case ( route, readyModel model ) of
                ( Route.Redirect _, _ ) ->
                    "WolcenDB"

                ( Route.Home, _ ) ->
                    "WolcenDB: a Wolcen item, skill, and magic affix database"

                ( Route.NormalItems tier kws, _ ) ->
                    "WolcenDB: normal item list"
                        ++ Maybe.Extra.unwrap "" (String.fromInt >> (++) ": Tier ") tier
                        ++ Maybe.Extra.unwrap "" ((++) ": ") kws

                ( Route.NormalItem name, RemoteData.Success ok ) ->
                    "WolcenDB: normal item: " ++ Page.NormalItem.viewTitle ok.datamine name

                ( Route.NormalItem name, _ ) ->
                    "WolcenDB: normal item"

                ( Route.UniqueItems kws, _ ) ->
                    "WolcenDB: unique item list" ++ Maybe.Extra.unwrap "" ((++) ": ") kws

                ( Route.UniqueItem name, RemoteData.Success ok ) ->
                    "WolcenDB: unique item: " ++ Page.UniqueItem.viewTitle ok.datamine name

                ( Route.UniqueItem name, _ ) ->
                    "WolcenDB: unique item"

                ( Route.Skills, _ ) ->
                    "WolcenDB: skill list"

                ( Route.Skill name, RemoteData.Success ok ) ->
                    "WolcenDB: skill: " ++ Page.Skill.viewTitle ok.datamine name

                ( Route.Skill name, _ ) ->
                    "WolcenDB: skill"

                ( Route.SkillVariant id, RemoteData.Success ok ) ->
                    "WolcenDB: skill-variant: " ++ Page.SkillVariant.viewTitle ok.datamine id

                ( Route.SkillVariant _, _ ) ->
                    "WolcenDB: skill-variant"

                ( Route.Affixes, _ ) ->
                    "WolcenDB: magic affixes and modifiers"

                ( Route.Gems, _ ) ->
                    "WolcenDB: gems"

                ( Route.Passives, _ ) ->
                    "WolcenDB: passive skill tree nodes"

                ( Route.Reagents, _ ) ->
                    "WolcenDB: crafting reagents"

                ( Route.City _, _ ) ->
                    "WolcenDB: endgame city rewards"

                ( Route.Ailments, _ ) ->
                    "WolcenDB: ailments"

                ( Route.Source _ _, _ ) ->
                    "WolcenDB: view xml source file"

                ( Route.Offline _ _, _ ) ->
                    "WolcenDB: view offline save file code (you dirty cheater, you)"

                ( Route.Search _, _ ) ->
                    "WolcenDB: search"

                ( Route.Table _, _ ) ->
                    "WolcenDB: raw tabular data"

                ( Route.Changelog, _ ) ->
                    "WolcenDB: changelog"

                ( Route.Privacy, _ ) ->
                    "WolcenDB: privacy"


viewLoading model =
    [ div [ class "container" ]
        [ View.Nav.viewNoSearchbar
        , div [ class "alert alert-info loading-alert" ]
            [ div [ class "fas fa-spinner fa-spin" ] []
            , text " Loading..."
            , div []
                (model.progress
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map
                        (\( key, ( val, max ) ) ->
                            let
                                pct =
                                    Util.percent <| clamp 0 1 <| toFloat val / toFloat max
                            in
                            div [ class "loading progress" ]
                                [ div
                                    [ class "progress-bar bg-info"
                                    , style "width" pct
                                    , style "text-align" "left"
                                    ]
                                    [ text <| key ++ ": " ++ String.fromInt val ++ "/" ++ String.fromInt max ++ " - " ++ pct ]
                                ]
                        )
                )
            , div [ style "font-size" "60%" ] [ text "Thanks for waiting!" ]
            ]
        , div []
            [ div []
                [ div []
                    [ div []
                        [ div []
                            [ div []
                                [ div []
                                    [ div []
                                        [ div [ id ssrRootId ]
                                            [-- `Ports:ssr` replaces this with SSR'ed content while loading.
                                             -- Nested divs force Elm's dom-diffing to remove, not modify, this element when loading's done.
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]


viewErr err =
    [ div [ class "container" ]
        [ View.Nav.viewNoSearchbar
        , pre [ class "alert alert-danger" ]
            [ text <| String.right 100000 err ]
        ]
    ]


viewBody : { ssr : Bool } -> Model -> List (Html Msg)
viewBody { ssr } model =
    case readyModel model of
        RemoteData.Failure err ->
            viewErr err

        RemoteData.NotAsked ->
            viewLoading model

        RemoteData.Loading ->
            viewLoading model

        RemoteData.Success ok ->
            let
                content =
                    case model.route of
                        Nothing ->
                            viewNotFound

                        Just route ->
                            case route of
                                Route.Redirect _ ->
                                    -- should never be here, we should've performed the redirect in update/init
                                    viewNotFound

                                Route.Home ->
                                    Page.Home.view ok.datamine

                                Route.NormalItems tier tags ->
                                    Page.NormalItems.view ok.datamine tier tags

                                Route.NormalItem name ->
                                    Page.NormalItem.view ok.datamine model name
                                        |> Maybe.map (List.map (H.map NormalItemMsg))
                                        |> Maybe.withDefault viewNotFound

                                Route.UniqueItems tags ->
                                    Page.UniqueItems.view ok.datamine tags

                                Route.UniqueItem name ->
                                    Page.UniqueItem.view ok.datamine name
                                        |> Maybe.withDefault viewNotFound

                                Route.Skills ->
                                    Page.Skills.view ok.datamine

                                Route.Skill s ->
                                    Page.Skill.view ok.datamine s
                                        |> Maybe.withDefault viewNotFound

                                Route.SkillVariant v ->
                                    Page.SkillVariant.view ok.datamine v
                                        |> Maybe.withDefault viewNotFound

                                Route.Affixes ->
                                    Page.Affixes.view ok.datamine model
                                        |> List.map (H.map PageAffixesMsg)

                                Route.Gems ->
                                    Page.Gems.view ok.datamine

                                Route.Passives ->
                                    Page.Passives.view ok.datamine

                                Route.Reagents ->
                                    Page.Reagents.view ok.datamine

                                Route.City name ->
                                    Page.City.view ok.datamine model name
                                        |> Maybe.withDefault viewNotFound
                                        |> List.map (H.map CityMsg)

                                Route.Ailments ->
                                    Page.Ailments.view ok.datamine model
                                        |> List.map (H.map AilmentsMsg)

                                Route.Source type_ id ->
                                    Page.Source.view ok.datamine type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Offline type_ id ->
                                    Page.Offline.view ok.datamine type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Search query ->
                                    Page.Search.view model
                                        |> List.map (H.map SearchMsg)

                                Route.Table t ->
                                    Page.Table.view ok.datamine t
                                        |> Maybe.withDefault viewNotFound

                                Route.Changelog ->
                                    Page.Changelog.view model

                                Route.Privacy ->
                                    Page.Privacy.view
            in
            -- no navbar for statically rendered pages, it's added by the loading page
            if ssr then
                content

            else
                [ div [ class "container" ]
                    ((View.Nav.view model |> H.map NavMsg)
                        :: content
                    )
                ]


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
