module Page.Search exposing (Msg, init, update, view)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Datamine.Gem as Gem exposing (Gem)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)
import Search exposing (Index, SearchResult)


type Msg
    = SearchInput String
    | SearchSubmit


type alias Model m =
    { m
        | datamine : Datamine
        , nav : Nav.Key
        , searchIndex : Index
        , globalSearch : String
        , globalSearchResults : Result String (List SearchResult)
    }


view : Model m -> List (Html Msg)
view m =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.Search <| Just m.globalSearch ] [ text "Search" ]
        ]
    , H.form [ onSubmit SearchSubmit ]
        [ input
            [ class "form-control"
            , type_ "search"
            , placeholder "Search"
            , value m.globalSearch
            , onInput SearchInput
            ]
            []
        ]
    , case m.globalSearchResults of
        Err err ->
            code [] [ text err ]

        Ok [] ->
            code [] [ text "No search results" ]

        Ok results ->
            results
                |> List.take 25
                |> List.map (viewResult >> li [ class "list-group-item" ])
                |> ul [ class "list-group" ]
    ]


init : Maybe String -> Model m -> Model m
init q model =
    search (q |> Maybe.withDefault "") model


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        SearchInput q ->
            ( model |> search q, Cmd.none )

        SearchSubmit ->
            ( model, Just model.globalSearch |> Route.Search |> Route.pushUrl model.nav )


search : String -> Model m -> Model m
search q model =
    case Search.search model.datamine q model.searchIndex of
        Err err ->
            { model | globalSearch = q, globalSearchResults = Err err }

        Ok ( index, res ) ->
            { model | globalSearch = q, globalSearchResults = Ok res, searchIndex = index }


viewResult : SearchResult -> List (Html msg)
viewResult { category, route, label } =
    List.map text category
        ++ [ a [ Route.href route ] [ text label ] ]
        |> List.intersperse (text " / ")
