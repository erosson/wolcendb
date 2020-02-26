module Main exposing (..)

import Browser
import Browser.Dom
import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import ElmTextSearch
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Decode as D
import Maybe.Extra
import Page.Affixes
import Page.Changelog
import Page.City
import Page.Gems
import Page.Home
import Page.NormalItem
import Page.NormalItems
import Page.Passives
import Page.Privacy
import Page.Reagents
import Page.Search
import Page.Skill
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
import View.Affix
import View.Nav



---- MODEL ----


type alias Model =
    { nav : Nav.Key
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
    , cityPlayerLevel : Int
    }


type alias ReadyModel =
    { datamine : Datamine, searchIndex : Search.Index }


type alias Flags =
    { changelog : String

    -- , datamine : Datamine.Flag
    -- , searchIndex : D.Value
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    { nav = nav
    , datamine = RemoteData.NotAsked
    , searchIndex = RemoteData.NotAsked
    , changelog = flags.changelog
    , route = Nothing
    , expandedAffixClasses = Set.empty
    , globalSearch = ""
    , globalSearchResults = Ok []
    , filterItemLevel = 0
    , filterGemFamilies = Set.empty
    , filterKeywords = Set.empty
    , cityPlayerLevel = 0
    }
        |> routeTo (Route.parse url)


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
    | OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest
    | NormalItemMsg Page.NormalItem.Msg
    | PageAffixesMsg Page.Affixes.Msg
    | ViewAffixMsg View.Affix.ItemMsg
    | SearchMsg Page.Search.Msg
    | CityMsg Page.City.Msg
    | NavMsg View.Nav.Msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.loadAssets LoadAssets
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

                _ ->
                    ( model, Cmd.none )


updateOk : Msg -> ReadyModel -> Model -> ( Model, Cmd Msg )
updateOk msg ok model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        LoadAssets res ->
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
                [ url |> Url.toString |> Nav.pushUrl model.nav
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

        NavMsg msg_ ->
            View.Nav.update msg_ ok model
                |> Tuple.mapSecond (Cmd.map NavMsg)



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = viewTitle model, body = viewBody model }


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

                ( Route.NormalItems kws, _ ) ->
                    "WolcenDB: normal item list" ++ Maybe.Extra.unwrap "" ((++) ": ") kws

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

                ( Route.Source _ _, _ ) ->
                    "WolcenDB: view xml source file"

                ( Route.Search _, _ ) ->
                    "WolcenDB: search"

                ( Route.Table _, _ ) ->
                    "WolcenDB: raw tabular data"

                ( Route.Changelog, _ ) ->
                    "WolcenDB: changelog"

                ( Route.Privacy, _ ) ->
                    "WolcenDB: privacy"


viewLoading =
    [ div [ style "width" "100%", style "text-align" "center", style "font-size" "200%" ]
        [ code []
            [ div [ class "fas fa-spinner fa-spin" ] []
            , div [] [ text "Loading WolcenDB..." ]
            , div [ style "font-size" "50%" ] [ text "Thanks for waiting!" ]
            ]
        ]
    ]


viewErr err =
    [ code [] [ text <| String.right 10000 err ] ]


viewBody : Model -> List (Html Msg)
viewBody model =
    case readyModel model of
        RemoteData.Failure err ->
            viewErr err

        RemoteData.NotAsked ->
            viewLoading

        RemoteData.Loading ->
            viewLoading

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
                                    Page.Home.view

                                Route.NormalItems tags ->
                                    Page.NormalItems.view ok.datamine tags

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

                                Route.Source type_ id ->
                                    Page.Source.view ok.datamine type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Search query ->
                                    Page.Search.view model
                                        |> List.map (H.map SearchMsg)

                                Route.Table t ->
                                    Page.Table.view ok.datamine t
                                        |> Maybe.withDefault viewNotFound

                                Route.Changelog ->
                                    Page.Changelog.view ok.datamine model

                                Route.Privacy ->
                                    Page.Privacy.view
            in
            [ div [ class "container" ]
                ((View.Nav.view model |> H.map NavMsg)
                    :: content
                )
            ]


viewNotFound =
    [ code [] [ text "404 not found" ], div [] [ a [ Route.href Route.Home ] [ text "Back to safety" ] ] ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
