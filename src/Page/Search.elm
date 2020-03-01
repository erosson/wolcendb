module Page.Search exposing (Msg, init, update, view)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Datamine.Gem as Gem exposing (Gem)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Search exposing (Index, SearchResult)


type Msg
    = SearchInput String
    | SearchSubmit


type alias ReadyModel m =
    { m
        | datamine : Datamine
        , searchIndex : Index
    }


type alias Model m =
    { m
        | nav : Maybe Nav.Key
        , globalSearch : String
        , globalSearchResults : Result String (List SearchResult)
        , searchIndex : RemoteData String Index
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
                |> List.map (viewResult >> li [ class "list-group-item" ])
                |> ul [ class "list-group" ]
    ]


init : Maybe String -> ReadyModel r -> Model m -> Model m
init q ok model =
    search (q |> Maybe.withDefault "") ok model


update : Msg -> ReadyModel r -> Model m -> ( Model m, Cmd Msg )
update msg ok model =
    case msg of
        SearchInput q ->
            ( model |> search q ok, Cmd.none )

        SearchSubmit ->
            ( model, Just model.globalSearch |> Route.Search |> Route.pushUrl model.nav )


search : String -> ReadyModel r -> Model m -> Model m
search q ok model =
    case Search.search ok.datamine q ok.searchIndex of
        Err err ->
            { model | globalSearch = q, globalSearchResults = Err err }

        Ok ( index, res ) ->
            { model | globalSearch = q, globalSearchResults = Ok res, searchIndex = RemoteData.Success index }


viewResult : SearchResult -> List (Html msg)
viewResult { category, route, label } =
    List.map text category
        ++ [ a [ Route.href route ] [ text label ] ]
        |> List.intersperse (text " / ")
