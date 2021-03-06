module Page.NormalItems exposing (view)

import Datamine exposing (Datamine)
import Datamine.NormalItem as NormalItem exposing (Item, NormalItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import List.Extra
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)


view : Lang -> Datamine -> Maybe Int -> Maybe String -> Maybe String -> List (Html msg)
view lang dm mtier kwStr okwStr =
    let
        kwList =
            kwStr |> Maybe.withDefault "" |> String.toLower |> String.split "," |> List.map String.trim |> List.filter ((/=) "")

        okwList =
            okwStr |> Maybe.withDefault "" |> String.toLower |> String.split "," |> List.map String.trim |> List.filter ((/=) "")

        isItemKeyword itemKws kw =
            Set.member kw itemKws

        tier_ =
            mtier |> tier |> tierTag

        allTiers =
            not <| Set.member tier_ tierTags

        loot =
            dm.loot
                |> List.filter
                    (NormalItem.keywords
                        >> List.map String.toLower
                        >> Set.fromList
                        >> (\itemKws ->
                                List.all (isItemKeyword itemKws) kwList
                                    && (List.isEmpty okwList || List.any (isItemKeyword itemKws) okwList)
                                    && (allTiers || Set.member tier_ itemKws)
                           )
                    )
    in
    viewMain lang dm mtier kwList okwList loot


tier : Maybe Int -> Int
tier =
    Maybe.withDefault 16


tierTag : Int -> String
tierTag i =
    "tier_" ++ String.fromInt i


visibleTiers : List Int
visibleTiers =
    List.range 1 16


tiers : List Int
tiers =
    List.range 1 18


tierTags : Set String
tierTags =
    tiers |> List.map tierTag |> Set.fromList


viewMain : Lang -> Datamine -> Maybe Int -> List String -> List String -> List NormalItem -> List (Html msg)
viewMain lang dm mtier keywords okws items =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.normalItems mtier keywords okws ] [ text "Loot" ]
        ]
    , div [] <| viewKeywordGroups mtier keywords okws weaponKeywordGroups
    , div [] <| viewKeywordGroups mtier keywords okws armorKeywordGroups
    , div [] <| viewKeywordGroups mtier keywords okws otherKeywordGroups
    , div [ class "card" ]
        [ div [ class "card-header p-2" ] [ text "Tier" ]
        , div [ class "card-body p-0" ]
            ((visibleTiers
                |> List.map
                    (\t ->
                        a
                            [ class "btn"
                            , classList [ ( "btn-outline-primary", t == tier mtier ) ]
                            , Route.href <| Route.normalItems (Just t) keywords okws
                            ]
                            [ text <| "T" ++ String.fromInt t ]
                    )
             )
                -- an all-tiers list is okay, just not as the default!
                ++ [ a
                        [ class "btn"
                        , classList [ ( "btn-outline-primary", 0 == tier mtier ) ]
                        , Route.href <| Route.normalItems (Just 0) keywords okws
                        ]
                        [ text "All" ]
                   ]
            )
        ]
    , ul [ class "list-group" ]
        (items
            |> List.map
                (\nitem ->
                    li [ class "list-group-item" ]
                        [ div [ class "row" ]
                            [ div [ class "col-sm-2" ]
                                [ a [ Route.href <| Route.NormalItem <| NormalItem.name nitem ]
                                    [ img [ class "item-list-img", src <| Maybe.withDefault "" <| NormalItem.img dm nitem ] []
                                    ]
                                ]
                            , div [ class "col-sm-10" ]
                                [ a [ Route.href <| Route.NormalItem <| NormalItem.name nitem ] [ NormalItem.label lang nitem |> Maybe.withDefault "???" |> text ]
                                , nitem |> NormalItem.levelPrereq |> Maybe.Extra.unwrap (p [] []) (\lvl -> p [] [ text <| "Level: " ++ String.fromInt lvl ])
                                , nitem |> NormalItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]) |> ul [ class "list-group affixes" ]
                                , nitem |> NormalItem.implicitEffects lang dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]) |> ul [ class "list-group affixes" ]
                                , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " <| NormalItem.keywords nitem ]
                                ]
                            ]
                        ]
                )
        )
    ]


type alias KeywordGroup =
    ( ( List String, String ), List ( List String, String ) )


weaponKeywordGroups : List KeywordGroup
weaponKeywordGroups =
    [ ( ( [ "1h", "melee" ], "One-handed melee" )
      , [ ( [ "1h", "melee", "axe" ], "Axe" )
        , ( [ "1h", "melee", "mace" ], "Mace" )
        , ( [ "1h", "melee", "sword" ], "Sword" )
        , ( [ "1h", "melee", "dagger" ], "Dagger" )
        , ( [ "shield" ], "Shield" )
        ]
      )
    , ( ( [ "2h", "melee" ], "Two-handed melee" )
      , [ ( [ "2h", "melee", "axe" ], "Axe" )
        , ( [ "2h", "melee", "mace" ], "Mace" )
        , ( [ "2h", "melee", "sword" ], "Sword" )
        ]
      )
    , ( ( [ "magic" ], "Magic weapons" )
      , [ ( [ "1h", "magic" ], "Catalyst" )
        , ( [ "2h", "magic" ], "Staff" )
        ]
      )
    , ( ( [ "ranged" ], "Ranged weapons" )
      , [ ( [ "1h", "ranged" ], "Pistol" )
        , ( [ "2h", "ranged" ], "Bow" )
        ]
      )
    ]


armorKeywordGroups : List ( ( List String, String ), List ( List String, String ) )
armorKeywordGroups =
    [ ( ( [ "armor", "heavy" ], "Heavy Armor" )
      , [ ( [ "armor", "heavy", "chest" ], "Chest" )
        , ( [ "armor", "heavy", "head" ], "Head" )
        , ( [ "armor", "heavy", "legs" ], "Legs" )
        , ( [ "armor", "heavy", "feet" ], "Feet" )
        , ( [ "armor", "heavy", "shoulder" ], "Shoulder" )
        , ( [ "armor", "heavy", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "armor", "warrior" ], "Brawler Armor" )
      , [ ( [ "armor", "warrior", "chest" ], "Chest" )
        , ( [ "armor", "warrior", "head" ], "Head" )
        , ( [ "armor", "warrior", "legs" ], "Legs" )
        , ( [ "armor", "warrior", "feet" ], "Feet" )
        , ( [ "armor", "warrior", "shoulder" ], "Shoulder" )
        , ( [ "armor", "warrior", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "armor", "rogue" ], "Rogue Armor" )
      , [ ( [ "armor", "rogue", "chest" ], "Chest" )
        , ( [ "armor", "rogue", "head" ], "Head" )
        , ( [ "armor", "rogue", "legs" ], "Legs" )
        , ( [ "armor", "rogue", "feet" ], "Feet" )
        , ( [ "armor", "rogue", "shoulder" ], "Shoulder" )
        , ( [ "armor", "rogue", "hand" ], "Hand" )
        ]
      )
    , ( ( [ "armor", "mage" ], "Mage Armor" )
      , [ ( [ "armor", "mage", "chest" ], "Chest" )
        , ( [ "armor", "mage", "head" ], "Head" )
        , ( [ "armor", "mage", "legs" ], "Legs" )
        , ( [ "armor", "mage", "feet" ], "Feet" )
        , ( [ "armor", "mage", "shoulder" ], "Shoulder" )
        , ( [ "armor", "mage", "hand" ], "Hand" )
        ]
      )
    ]


otherKeywordGroups : List ( ( List String, String ), List ( List String, String ) )
otherKeywordGroups =
    [ ( ( [ "armor" ], "All Armor" )
      , [ ( [ "armor", "chest" ], "Chest" )
        , ( [ "armor", "head" ], "Head" )
        , ( [ "armor", "legs" ], "Legs" )
        , ( [ "armor", "feet" ], "Feet" )
        , ( [ "armor", "shoulder" ], "Shoulder" )
        , ( [ "armor", "hand" ], "Hand" )
        , ( [ "armor", "shield" ], "Shield" )
        , ( [ "trinket" ], "Catalyst" )
        ]
      )
    , ( ( [ "accessory" ], "Accessories" )
      , [ ( [ "accessory", "ring" ], "Ring" )
        , ( [ "accessory", "amulet" ], "Amulet" )
        , ( [ "accessory", "belt" ], "Belt" )
        ]
      )
    ]


viewKeywordGroups : Maybe Int -> List String -> List String -> List KeywordGroup -> List (Html msg)
viewKeywordGroups mtier activeKws okws =
    List.map
        (\( ( mainKws, mainlabel ), entries ) ->
            div [ class "card d-inline-flex", style "max-width" "15em" ]
                [ div [ class "card-header p-2" ]
                    [ a
                        [ Route.href <| Route.normalItems mtier mainKws okws
                        , classList [ ( "btn btn-link btn-outline-primary m-0", mainKws == activeKws ) ]
                        ]
                        [ text mainlabel ]
                    ]
                , div [ class "card-body p-0" ]
                    (entries
                        |> List.map
                            (\( kws, label ) ->
                                a
                                    [ class "btn btn-link"
                                    , Route.href <| Route.normalItems mtier kws okws
                                    , classList [ ( "btn-outline-primary", kws == activeKws ) ]
                                    ]
                                    [ text label ]
                            )
                    )
                ]
        )
