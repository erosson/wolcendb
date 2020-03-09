module Page.Search exposing (Msg, init, update, view)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Datamine.Gem as Gem exposing (Gem)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Search exposing (Index, SearchResult)
import View.Loading
import View.Search


type Msg
    = SearchInput String
    | SearchSubmit


type alias Model m =
    View.Search.Model m


view : Lang -> Datamine -> Model m -> List (Html Msg)
view lang dm m =
    View.Loading.view { navbar = False }
        m
        m.searchIndex
        (\searchIndex ->
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
            , case m.globalSearchResults |> Result.map (Search.toResults lang dm) of
                Err err ->
                    code [] [ text err ]

                Ok [] ->
                    code [] [ text "No search results" ]

                Ok results ->
                    results
                        |> List.map (viewResult >> li [ class "list-group-item" ])
                        |> ul [ class "list-group" ]
            ]
        )


init : Maybe String -> Datamine -> Model m -> Model m
init q dm model =
    View.Search.search (q |> Maybe.withDefault "") dm model


update : Msg -> Datamine -> Model m -> ( Model m, Cmd Msg )
update msg dm model =
    case msg of
        SearchInput q ->
            ( model |> View.Search.search q dm, Cmd.none )

        SearchSubmit ->
            ( model, Just model.globalSearch |> Route.Search |> Route.pushUrl model.nav )


viewResult : SearchResult -> List (Html msg)
viewResult { category, route, label } =
    List.map text category
        ++ [ a [ Route.href route ] [ text label ] ]
        |> List.intersperse (text " / ")
