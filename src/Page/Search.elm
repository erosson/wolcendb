module Page.Search exposing (Msg, update, view)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)
import Search exposing (Index)
import View.Nav


type Msg
    = SearchInput String


type alias Model m =
    { m | datamine : Datamine, searchIndex : Index, nav : Nav.Key }


view : Model m -> Maybe String -> List (Html Msg)
view m mquery =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href <| Route.Search mquery ] [ text "Search" ]
            ]
        , H.form [] [ input [ class "form-control", onInput SearchInput, value <| Maybe.withDefault "" mquery ] [] ]
        , case mquery of
            Nothing ->
                div [] []

            Just query ->
                case Search.search query m.searchIndex of
                    Err err ->
                        code [] [ text err ]

                    Ok ( _, [] ) ->
                        code [] [ text "No search results" ]

                    Ok results ->
                        -- TODO update search index
                        results
                            |> Tuple.second
                            |> List.map Tuple.first
                            |> List.filterMap (toResult m.datamine)
                            |> List.map (viewResult >> li [ class "list-group-item" ])
                            |> ul [ class "list-group" ]
        ]
    ]


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        SearchInput q ->
            ( model, Route.replaceUrl model.nav <| Route.Search <| Just q )


viewResult : ( Route, String ) -> List (Html msg)
viewResult ( route, title ) =
    [ a [ Route.href route ] [ text title ] ]


toResult : Datamine -> String -> Maybe ( Route, String )
toResult dm docId =
    case String.split "/" docId of
        [ "gem", id ] ->
            Dict.get (String.toLower id) dm.gemsByName |> Maybe.map (\gem -> ( Route.Gems, Datamine.lang dm gem.uiName |> Maybe.withDefault "???" ))

        _ ->
            Nothing
