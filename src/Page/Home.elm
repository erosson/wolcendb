module Page.Home exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "row" ]
        [ div [ class "col-sm" ]
            [ p []
                [ text "Loot, skill, city, and magic affix lists for the action RPG "
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
                    , li [ class "list-group-item" ] [ a [ Route.href Route.Passives ] [ text "Passives" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href Route.Ailments ] [ text "Ailments" ] ]
                    ]
                ]
            , div [ class "card" ]
                [ div [ class "card-header" ] [ text "City" ]
                , ul [ class "list-group list-group-flush" ]
                    [ li [ class "list-group-item" ] [ a [ Route.href <| Route.City "building_seekers_garrison" ] [ text "Seekers" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.City "building_trade_assembly" ] [ text "Trade Assembly" ] ]
                    ]
                ]
            ]
        , div [ class "col-sm" ]
            [ div [ class "card" ]
                [ div [ class "card-header" ] [ text "Loot" ]
                , ul [ class "list-group list-group-flush" ]
                    [ li [ class "list-group-item" ] [ a [ Route.href Route.Affixes ] [ text "Magic Affixes" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.NormalItems Nothing <| Just "weapon" ] [ text "Weapons" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.NormalItems Nothing <| Just "shield" ] [ text "Shields" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.NormalItems Nothing <| Just "armor" ] [ text "Armors" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.NormalItems Nothing <| Just "accessory" ] [ text "Accessories" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href Route.Gems ] [ text "Gems" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href Route.Reagents ] [ text "Reagents" ] ]
                    ]
                ]
            ]
        , div [ class "col-sm" ]
            [ div [ class "card" ]
                [ div [ class "card-header" ] [ text "Uniques" ]
                , ul [ class "list-group list-group-flush" ]
                    [ li [ class "list-group-item" ] [ a [ Route.href <| Route.UniqueItems <| Just "weapon" ] [ text "Weapons" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.UniqueItems <| Just "shield" ] [ text "Shields" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.UniqueItems <| Just "armor" ] [ text "Armors" ] ]
                    , li [ class "list-group-item" ] [ a [ Route.href <| Route.UniqueItems <| Just "accessory" ] [ text "Accessories" ] ]
                    ]
                ]
            ]
        ]
    , div [ class "row" ]
        [ div [ class "col-sm" ]
            -- [ ul [ class "nav nav-horizontal" ]
            [ ul [ class "nav flex-column" ]
                [ li [ class "nav-item" ]
                    [ a
                        [ class "nav-link"
                        , Route.href Route.Langs
                        ]
                        [ text "Choose Language ", span [ class "badge" ] [ text "(BETA)" ] ]
                    ]
                , li [ class "nav-item" ]
                    [ a
                        [ class "nav-link"
                        , Route.href Route.Changelog
                        ]
                        [ text "Changelog" ]
                    ]
                , li [ class "nav-item" ]
                    [ a
                        [ class "nav-link"
                        , target "_blank"
                        , href "https://www.reddit.com/r/wolcendb"
                        ]
                        [ text "Reddit: /r/wolcendb" ]
                    ]
                , li [ class "nav-item" ]
                    [ a
                        [ class "nav-link"
                        , target "_blank"
                        , href "https://gitlab.com/erosson/wolcendb"
                        ]
                        [ text "Source code" ]
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
                    [ text "Wolcen build revision "
                    , code [] [ text dm.revision.buildRevision ]
                    , text ", created at "
                    , code [] [ text dm.revision.date ]
                    , text ". See data for "
                    , a [ Route.href Route.BuildRevisions ] [ text "other Wolcen versions" ]
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
