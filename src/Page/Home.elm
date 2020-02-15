module Page.Home exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Nav


view : List (Html msg)
view =
    [ div [ class "container" ]
        [ View.Nav.view
        , div [ class "row" ]
            [ div [ class "col-sm" ]
                [ div [ class "card" ]
                    [ div [ class "card-header" ] [ text "Loot" ]
                    , ul [ class "list-group list-group-flush" ]
                        [ li [ class "list-group-item" ] [ a [ Route.href Route.Weapons ] [ text "Weapons" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Shields ] [ text "Shields" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Armors ] [ text "Armors" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Accessories ] [ text "Accessories" ] ]
                        ]
                    ]
                ]
            , div [ class "col-sm" ]
                [ div [ class "card" ]
                    [ div [ class "card-header" ] [ text "Uniques" ]
                    , ul [ class "list-group list-group-flush" ]
                        [ li [ class "list-group-item" ] [ a [ Route.href Route.UniqueWeapons ] [ text "Weapons" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.UniqueShields ] [ text "Shields" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.UniqueArmors ] [ text "Armors" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.UniqueAccessories ] [ text "Accessories" ] ]
                        ]
                    ]
                ]
            ]
        ]
    ]
