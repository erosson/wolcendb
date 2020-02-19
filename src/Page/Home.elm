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
                [ p []
                    [ text "Datamined loot and skill information for the action RPG "
                    , a [ target "_blank", href "https://wolcengame.com/" ] [ text "Wolcen: Lords of Mayhem" ]
                    , text "."
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-sm" ]
                [ div [ class "card" ]
                    [ div [ class "card-header" ] [ text "Player" ]
                    , ul [ class "list-group list-group-flush" ]
                        [ li [ class "list-group-item" ] [ a [ Route.href Route.Skills ] [ text "Skills" ] ]
                        ]
                    ]
                ]
            , div [ class "col-sm" ]
                [ div [ class "card" ]
                    [ div [ class "card-header" ] [ text "Loot" ]
                    , ul [ class "list-group list-group-flush" ]
                        [ li [ class "list-group-item" ] [ a [ Route.href Route.Weapons ] [ text "Weapons" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Shields ] [ text "Shields" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Armors ] [ text "Armors" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Accessories ] [ text "Accessories" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Affixes ] [ text "Affixes" ] ]
                        , li [ class "list-group-item" ] [ a [ Route.href Route.Gems ] [ text "Gems" ] ]
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
        , div [ class "row" ]
            [ div [ class "col-sm" ]
                [ ul [ class "nav nav-horizontal" ]
                    [ li [ class "nav-item" ]
                        [ a
                            [ class "nav-link"
                            , target "_blank"
                            , href "https://gitlab.com/erosson/wolcendb"
                            ]
                            [ text "WolcenDB is open-source" ]
                        ]
                    , li [ class "nav-item" ]
                        [ a
                            [ class "nav-link"
                            , Route.href Route.Changelog
                            ]
                            [ text "WolcenDB changelog" ]
                        ]
                    , li [ class "nav-item" ]
                        [ a
                            [ class "nav-link"
                            , Route.href Route.Privacy
                            ]
                            [ text "Privacy" ]
                        ]
                    ]
                , small []
                    [ p []
                        [ text "This site is fan-made and not affiliated with "
                        , a [ target "_blank", href "https://wolcengame.com/" ] [ text "Wolcen Studios" ]
                        , text "."
                        ]
                    ]
                ]
            ]
        ]
    ]
