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
import Route exposing (Route)
import Search exposing (SearchResult)
import Set exposing (Set)
import Task
import Url exposing (Url)
import View.Affix
import View.Nav



---- MODEL ----


type alias Model =
    Result String OkModel


type alias OkModel =
    { nav : Nav.Key
    , datamine : Datamine
    , searchIndex : ElmTextSearch.Index Search.Doc
    , changelog : String
    , route : Maybe Route

    -- TODO: these really belong in a per-page model
    , expandedAffixClasses : Set String
    , globalSearch : String
    , globalSearchResults : Result String (List SearchResult)
    , filterItemLevel : Int
    , filterGemFamilies : Set String
    , filterKeywords : Set String
    }


type alias Flags =
    { datamine : Datamine.Flag
    , changelog : String
    , searchIndex : D.Value
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    case Datamine.decode flags.datamine of
        Err err ->
            ( Err err, Cmd.none )

        Ok datamine ->
            case Search.decodeIndex flags.searchIndex of
                Err err ->
                    ( Err err, Cmd.none )

                Ok searchIndex ->
                    { nav = nav
                    , datamine = datamine
                    , searchIndex = searchIndex
                    , changelog = flags.changelog
                    , route = Nothing
                    , expandedAffixClasses = Set.empty
                    , globalSearch = ""
                    , globalSearchResults = Ok []
                    , filterItemLevel = 0
                    , filterGemFamilies = Set.empty
                    , filterKeywords = Set.empty
                    }
                        |> routeTo (Route.parse url)
                        |> Tuple.mapFirst Ok


routeTo : Maybe Route -> OkModel -> ( OkModel, Cmd Msg )
routeTo mroute model0 =
    let
        model =
            { model0 | route = mroute }
    in
    case mroute of
        Just (Route.Search q) ->
            ( Page.Search.init q model, Cmd.none )

        Just (Route.Redirect route) ->
            ( model0, Route.replaceUrl model.nav route )

        _ ->
            ( model, Cmd.none )



---- UPDATE ----


type Msg
    = OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest
    | Noop
    | NormalItemMsg Page.NormalItem.Msg
    | PageAffixesMsg Page.Affixes.Msg
    | ViewAffixMsg View.Affix.ItemMsg
    | SearchMsg Page.Search.Msg
    | NavMsg View.Nav.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg mmodel =
    case mmodel of
        Err err ->
            ( mmodel, Cmd.none )

        Ok model ->
            updateOk msg model
                |> Tuple.mapFirst Ok


updateOk : Msg -> OkModel -> ( OkModel, Cmd Msg )
updateOk msg model =
    case msg of
        Noop ->
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
            ( Page.NormalItem.update msg_ model, Cmd.none )

        PageAffixesMsg msg_ ->
            ( Page.Affixes.update msg_ model, Cmd.none )

        ViewAffixMsg msg_ ->
            ( View.Affix.update msg_ model, Cmd.none )

        SearchMsg msg_ ->
            Page.Search.update msg_ model
                |> Tuple.mapSecond (Cmd.map SearchMsg)

        NavMsg msg_ ->
            View.Nav.update msg_ model
                |> Tuple.mapSecond (Cmd.map NavMsg)



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "WolcenDB", body = viewBody model }


viewBody : Model -> List (Html Msg)
viewBody mmodel =
    case mmodel of
        Err err ->
            [ code [] [ text <| String.right 10000 err ] ]

        Ok model ->
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
                                    Page.NormalItems.view model.datamine tags

                                Route.NormalItem name ->
                                    Page.NormalItem.view model name
                                        |> Maybe.map (List.map (H.map NormalItemMsg))
                                        |> Maybe.withDefault viewNotFound

                                Route.UniqueItems tags ->
                                    Page.UniqueItems.view model.datamine tags

                                Route.UniqueItem name ->
                                    Page.UniqueItem.view model.datamine name
                                        |> Maybe.withDefault viewNotFound

                                Route.Skills ->
                                    Page.Skills.view model.datamine

                                Route.Skill s ->
                                    Page.Skill.view model.datamine s
                                        |> Maybe.withDefault viewNotFound

                                Route.Affixes ->
                                    Page.Affixes.view model
                                        |> List.map (H.map PageAffixesMsg)

                                Route.Gems ->
                                    Page.Gems.view model.datamine

                                Route.Passives ->
                                    Page.Passives.view model.datamine

                                Route.Reagents ->
                                    Page.Reagents.view model.datamine

                                Route.Source type_ id ->
                                    Page.Source.view model.datamine type_ id
                                        |> Maybe.withDefault viewNotFound

                                Route.Search query ->
                                    Page.Search.view model
                                        |> List.map (H.map SearchMsg)

                                Route.Table t ->
                                    Page.Table.view model.datamine t
                                        |> Maybe.withDefault viewNotFound

                                Route.Changelog ->
                                    Page.Changelog.view model

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
        , subscriptions = always Sub.none
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
