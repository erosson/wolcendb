module Page.UniqueItems exposing (view)

import Datamine exposing (Datamine)
import Datamine.UniqueItem as UniqueItem exposing (UItem, UniqueItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import List.Extra
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)
import View.Affix
import View.Desc


view : Lang -> Datamine -> Maybe String -> List (Html msg)
view lang dm tagStr =
    let
        tagList =
            tagStr |> Maybe.withDefault "" |> String.toLower |> String.split ","

        tagSet =
            Set.fromList tagList

        loot =
            dm.uniqueLoot
                |> List.filter UniqueItem.isNonmax
                |> List.filter (UniqueItem.keywords >> List.map String.toLower >> Set.fromList >> Set.diff tagSet >> Set.isEmpty)
    in
    viewMain lang dm tagList loot


viewMain : Lang -> Datamine -> List String -> List UniqueItem -> List (Html msg)
viewMain lang dm keywords items =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItems <| Just <| String.join "," keywords ] [ text "Unique Loot" ]
        ]
    , div [] <| viewKeywordGroups keywords weaponKeywordGroups
    , div [] <| viewKeywordGroups keywords armorKeywordGroups
    , div [] <| viewKeywordGroups keywords otherKeywordGroups
    , ul [ class "list-group" ]
        (items
            |> List.map
                (\mainitem ->
                    let
                        group : List UniqueItem
                        group =
                            case Dict.get (String.toLower <| UniqueItem.name mainitem) dm.uniqueLootByNonmaxName of
                                Nothing ->
                                    [ mainitem ]

                                Just [] ->
                                    [ mainitem ]

                                Just g ->
                                    g
                    in
                    li [ class "list-group-item" ]
                        [ div [ class "row" ]
                            (div [ class "col-sm-3" ]
                                [ a [ Route.href <| Route.UniqueItem <| UniqueItem.name mainitem ]
                                    [ img [ class "unique-list-img", src <| Maybe.withDefault "" <| UniqueItem.img dm mainitem ] []
                                    ]
                                ]
                                :: (group
                                        |> List.map
                                            (\uitem ->
                                                div [ class "col-sm-3" ]
                                                    [ a [ Route.href <| Route.UniqueItem <| UniqueItem.name uitem ] [ UniqueItem.label lang uitem |> Maybe.withDefault "???" |> text ]
                                                    , uitem |> UniqueItem.levelPrereq |> Maybe.Extra.unwrap (p [] []) (\lvl -> p [] [ text <| "Level: " ++ String.fromInt lvl ])
                                                    , uitem |> UniqueItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]) |> ul [ class "list-group affixes" ]
                                                    , uitem |> UniqueItem.implicitEffects lang dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]) |> ul [ class "list-group affixes" ]
                                                    , uitem |> UniqueItem.defaultEffects lang dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]) |> ul [ class "list-group affixes" ]
                                                    , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " <| UniqueItem.keywords uitem ]
                                                    ]
                                            )
                                   )
                            )
                        ]
                )
        )
    ]


type alias KeywordGroup =
    ( ( List String, String ), List ( List String, String ) )


weaponKeywordGroups : List KeywordGroup
weaponKeywordGroups =
    [ ( ( [ "unique", "1h", "melee" ], "One-handed melee" )
      , [ ( [ "unique", "1h", "melee", "axe" ], "Axe" )
        , ( [ "unique", "1h", "melee", "mace" ], "Mace" )
        , ( [ "unique", "1h", "melee", "sword" ], "Sword" )
        , ( [ "unique", "1h", "melee", "dagger" ], "Dagger" )
        , ( [ "unique", "shield" ], "Shield" )
        ]
      )
    , ( ( [ "unique", "2h", "melee" ], "Two-handed melee" )
      , [ ( [ "unique", "2h", "melee", "axe" ], "Axe" )
        , ( [ "unique", "2h", "melee", "mace" ], "Mace" )
        , ( [ "unique", "2h", "melee", "sword" ], "Sword" )
        ]
      )
    , ( ( [ "unique", "magic" ], "Magic weapons" )
      , [ ( [ "unique", "1h", "magic" ], "Catalyst" )
        , ( [ "unique", "2h", "magic" ], "Staff" )
        ]
      )
    , ( ( [ "ranged" ], "Ranged weapons" )
      , [ ( [ "unique", "1h", "ranged" ], "Pistol" )
        , ( [ "unique", "2h", "ranged" ], "Bow" )
        ]
      )
    ]


armorKeywordGroups : List ( ( List String, String ), List ( List String, String ) )
armorKeywordGroups =
    [ ( ( [ "unique", "armor", "heavy" ], "Heavy Armor" )
      , [ ( [ "unique", "armor", "heavy", "chest" ], "Chest" )
        , ( [ "unique", "armor", "heavy", "head" ], "Head" )
        , ( [ "unique", "armor", "heavy", "legs" ], "Legs" )
        , ( [ "unique", "armor", "heavy", "feet" ], "Feet" )
        , ( [ "unique", "armor", "heavy", "shoulder" ], "Shoulder" )
        , ( [ "unique", "armor", "heavy", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "unique", "armor", "warrior" ], "Brawler Armor" )
      , [ ( [ "unique", "armor", "warrior", "chest" ], "Chest" )
        , ( [ "unique", "armor", "warrior", "head" ], "Head" )
        , ( [ "unique", "armor", "warrior", "legs" ], "Legs" )
        , ( [ "unique", "armor", "warrior", "feet" ], "Feet" )
        , ( [ "unique", "armor", "warrior", "shoulder" ], "Shoulder" )
        , ( [ "unique", "armor", "warrior", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "unique", "armor", "rogue" ], "Rogue Armor" )
      , [ ( [ "unique", "armor", "rogue", "chest" ], "Chest" )
        , ( [ "unique", "armor", "rogue", "head" ], "Head" )
        , ( [ "unique", "armor", "rogue", "legs" ], "Legs" )
        , ( [ "unique", "armor", "rogue", "feet" ], "Feet" )
        , ( [ "unique", "armor", "rogue", "shoulder" ], "Shoulder" )
        , ( [ "unique", "armor", "rogue", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "unique", "armor", "mage" ], "Mage Armor" )
      , [ ( [ "unique", "armor", "mage", "chest" ], "Chest" )
        , ( [ "unique", "armor", "mage", "head" ], "Head" )
        , ( [ "unique", "armor", "mage", "legs" ], "Legs" )
        , ( [ "unique", "armor", "mage", "feet" ], "Feet" )
        , ( [ "unique", "armor", "mage", "shoulder" ], "Shoulder" )
        , ( [ "unique", "armor", "mage", "hand" ], "Hand" )
        ]
      )
    ]


otherKeywordGroups : List ( ( List String, String ), List ( List String, String ) )
otherKeywordGroups =
    [ ( ( [ "unique", "armor" ], "All Armor" )
      , [ ( [ "unique", "armor", "chest" ], "Chest" )
        , ( [ "unique", "armor", "head" ], "Head" )
        , ( [ "unique", "armor", "legs" ], "Legs" )
        , ( [ "unique", "armor", "feet" ], "Feet" )
        , ( [ "unique", "armor", "shoulder" ], "Shoulder" )
        , ( [ "unique", "armor", "hand" ], "Hand" )
        , ( [ "unique", "armor", "shield" ], "Shield" )
        , ( [ "unique", "trinket" ], "Catalyst" )
        ]
      )
    , ( ( [ "unique", "accessory" ], "Accessories" )
      , [ ( [ "unique", "accessory", "ring" ], "Ring" )
        , ( [ "unique", "accessory", "amulet" ], "Amulet" )
        , ( [ "unique", "accessory", "belt" ], "Belt" )
        ]
      )
    ]


viewKeywordGroups : List String -> List KeywordGroup -> List (Html msg)
viewKeywordGroups activeKw =
    List.map
        (\( ( mainkw, mainlabel ), entries ) ->
            div [ class "card d-inline-flex", style "max-width" "15em" ]
                [ div [ class "card-header p-2" ]
                    [ a
                        [ Route.href <| Route.UniqueItems <| Just <| String.join "," mainkw
                        , classList [ ( "btn btn-link btn-outline-primary m-0", mainkw == activeKw ) ]
                        ]
                        [ text mainlabel ]
                    ]
                , div [ class "card-body p-0" ]
                    (entries
                        |> List.map
                            (\( kw, label ) ->
                                a
                                    [ class "btn btn-link"
                                    , Route.href <| Route.UniqueItems <| Just <| String.join "," kw
                                    , classList [ ( "btn-outline-primary", kw == activeKw ) ]
                                    ]
                                    [ text label ]
                            )
                    )
                ]
        )
