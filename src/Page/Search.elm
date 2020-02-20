module Page.Search exposing (Msg, init, update, view)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Datamine.Gem as Gem exposing (Gem)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)
import Search exposing (Index)
import View.Nav


type Msg
    = SearchInput String
    | SearchSubmit


type alias Model m =
    { m
        | datamine : Datamine
        , searchIndex : Index
        , nav : Nav.Key
        , globalSearch : String
        , globalSearchResults : Result String (List ( String, Float ))
    }


view : Model m -> List (Html Msg)
view m =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href <| Route.Search <| Just m.globalSearch ] [ text "Search" ]
            ]
        , H.form [ onSubmit SearchSubmit ] [ input [ class "form-control", onInput SearchInput, value m.globalSearch ] [] ]
        , case m.globalSearchResults of
            Err err ->
                code [] [ text err ]

            Ok [] ->
                code [] [ text "No search results" ]

            Ok results ->
                -- TODO update search index
                results
                    |> List.take 25
                    |> List.map Tuple.first
                    |> List.filterMap (toResult m.datamine)
                    |> List.map (viewResult >> li [ class "list-group-item" ])
                    |> ul [ class "list-group" ]
        ]
    ]


init : Maybe String -> Model m -> Model m
init q model =
    { model | globalSearch = q |> Maybe.withDefault "" }


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        SearchInput q ->
            ( model |> search q, Cmd.none )

        SearchSubmit ->
            ( model, Just model.globalSearch |> Route.Search |> Route.pushUrl model.nav )


search : String -> Model m -> Model m
search q model =
    case Search.search q model.searchIndex of
        Err err ->
            { model | globalSearch = q, globalSearchResults = Err err }

        Ok ( index, res ) ->
            { model | globalSearch = q, globalSearchResults = Ok res, searchIndex = index }


viewResult : ( Route, String ) -> List (Html msg)
viewResult ( route, title ) =
    [ a [ Route.href route ] [ text title ] ]


toResult : Datamine -> String -> Maybe ( Route, String )
toResult dm docId =
    case String.split "/" docId of
        [ "gem", id ] ->
            Dict.get (String.toLower id) dm.gemsByName |> Maybe.map (\gem -> ( Route.Gems, Gem.label dm gem |> Maybe.withDefault "???" ))

        _ ->
            Nothing
