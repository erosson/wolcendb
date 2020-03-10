module View.Nav exposing (Msg, update, view, viewNoSearchbar)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Search exposing (Index, SearchResult)
import View.Search


type Msg
    = SearchInput String
    | SearchSubmit


type alias Model m =
    View.Search.Model { m | langs : List String }


view : Model m -> Html Msg
view m =
    viewMain (viewSearchbar m)


viewNoSearchbar : Html msg
viewNoSearchbar =
    viewMain (span [] [])


viewMain : Html msg -> Html msg
viewMain searchbar =
    -- https://getbootstrap.com/docs/4.4/components/navbar/
    div [ class "navbar navbar-expand-sm navbar-light bg-light" ]
        [ a [ class "navbar-brand", Route.href Route.Home ] [ text "WolcenDB" ]
        , button
            [ type_ "button"
            , class "navbar-toggler"
            , attribute "data-toggle" "collapse"
            , attribute "data-target" "navbarLinks"
            ]
            [ span [ class "navbar-toggler-icon" ] [] ]
        , div [ id "navbarLinks", class "collapse navbar-collapse" ]
            -- "mr-auto" maximizes the margin, effectively right-aligning the search bar
            [ ul [ class "navbar-nav mr-auto" ] []
            , searchbar
            ]
        ]


viewSearchbar : Model m -> Html Msg
viewSearchbar m =
    H.form [ class "form-inline", onSubmit SearchSubmit ]
        [ div [ class "input-group" ]
            [ input
                [ class "form-control"
                , type_ "search"
                , placeholder "Search"
                , value m.globalSearch
                , onInput SearchInput
                ]
                []
            , div [ class "input-group-append" ] [ button [ class "btn btn-outline-primary", type_ "submit" ] [ span [ class "fas fa-search" ] [] ] ]
            ]
        ]


update : Msg -> Datamine -> Model m -> ( Model m, Cmd Msg )
update msg dm model =
    case msg of
        SearchInput q ->
            ( model |> View.Search.search q dm, Cmd.none )

        SearchSubmit ->
            ( model, Just model.globalSearch |> Route.Search |> Route.pushUrl model.nav )
