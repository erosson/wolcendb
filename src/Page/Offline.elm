module Page.Offline exposing (view)

-- import Html.Events as E exposing (..)

import Datamine exposing (Datamine)
import Datamine.Affix as Affix exposing (Affix, MagicEffect)
import Datamine.NormalItem as NormalItem
import Datamine.UniqueItem as UniqueItem
import Datamine.Util as Util
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Json.Encode as E
import Lang exposing (Lang)
import Maybe.Extra
import Route exposing (Route)
import Url exposing (Url)


view : Lang -> Datamine -> String -> String -> Maybe (List (Html msg))
view lang dm type_ id =
    getOffline lang dm type_ id
        |> Maybe.map
            (\( label, sources, breadcrumb ) ->
                [ ol [ class "breadcrumb" ]
                    (a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ] :: breadcrumb)
                , h4 [] [ text label, text ": ", code [] [ text id ] ]
                , p [] [ text "The code below can be used to cheat/modify your saved games in offline mode. (Online-mode saves cannot be modified.)" ]
                , p [] [ text "Make a backup copy of your saved game file before attempting this." ]
                , p [] [ text "Usage: " ]
                , ol []
                    [ li [] [ text "Close Wolcen" ]
                    , li []
                        [ text "Find your saved game file. Usually it's in "
                        , code [] [ text "C:\\Users\\<YOUR_USERNAME_HERE>\\Saved Games\\wolcen\\savegames\\characters" ]
                        , text " and ends with "
                        , code [] [ text ".json" ]
                        ]
                    , li []
                        [ text "Make a backup copy of your saved game file ("
                        , code [] [ text "ctrl-c, ctrl-v" ]
                        , text "). "
                        , ul []
                            [ li [] [ text "Seriously, don't skip making the backup copy. If these steps break your saved game, the WolcenDB developer cannot and will not help you." ]
                            ]
                        ]
                    , li [] [ text "Copy (", code [] [ text "ctrl-c" ], text ") all of the code below." ]
                    , li []
                        [ text "Open your saved game file in Notepad. Find ("
                        , code [] [ text "ctrl-f" ]
                        , text ") the "
                        , code [] [ text "\"InventoryGrid\"" ]
                        , text " section. Paste ("
                        , code [] [ text "ctrl-v" ]
                        , text ") the code below "
                        , b []
                            [ text "immediately after the first "
                            , code [] [ text "[" ]
                            ]
                        , text "."
                        ]
                    , li []
                        [ text "Change "
                        , code [] [ text "InventoryX, InventoryY" ]
                        , text " to empty coordinates in your inventory. Alternately, make sure the top-left of your inventory is empty before doing all this."
                        ]
                    , li [] [ text "Open Wolcen. Enjoy your ill-gotten gains." ]
                    ]
                , ul [ class "list-group" ] <| List.map (viewOffline >> li [ class "list-group-item" ]) sources
                ]
            )


getOffline : Lang -> Datamine -> String -> String -> Maybe ( String, List E.Value, List (Html msg) )
getOffline lang dm type_ id =
    case type_ of
        "unique-loot" ->
            Dict.get (String.toLower id) dm.uniqueLootByName
                |> Maybe.map
                    (\uitem ->
                        let
                            label =
                                UniqueItem.label lang uitem |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ E.object
                                [ ( "InventoryX", E.int 0 )
                                , ( "InventoryY", E.int 0 )
                                , ( "Rarity", E.int 6 )
                                , ( "Quality", E.int 1 )
                                , ( "Type"
                                    -- wolcen ignores the item if Type isn't correct
                                  , case uitem of
                                        UniqueItem.UWeapon _ ->
                                            E.int 3

                                        UniqueItem.UShield _ ->
                                            E.int 3

                                        UniqueItem.UArmor _ ->
                                            E.int 2

                                        UniqueItem.UAccessory _ ->
                                            E.int 2
                                  )

                                -- Wolcen helpfully fills in ItemType for me if I omit it
                                -- , ( "ItemType",  )
                                , ( "Value", E.string <| String.fromInt 1 )
                                , ( "Level", E.int 1 )
                                , (case uitem of
                                    UniqueItem.UWeapon w ->
                                        ( "Weapon"
                                        , [ Just ( "Name", E.string w.name )
                                          , w.damage |> Maybe.map (.min >> E.int >> Tuple.pair "DamageMin")
                                          , w.damage |> Maybe.map (.max >> E.int >> Tuple.pair "DamageMax")
                                          , w.resourceGain |> Maybe.map (.max >> E.int >> Tuple.pair "ResourceGeneration")
                                          ]
                                        )

                                    UniqueItem.UShield w ->
                                        ( "Weapon"
                                        , [ Just ( "Name", E.string w.name )
                                          , w.shieldResistance |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "ShieldResistance")
                                          , w.shieldBlockChance |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "ShieldBlockChance")
                                          , w.shieldBlockEfficiency |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "ShieldBlockEfficiency")
                                          ]
                                        )

                                    UniqueItem.UArmor w ->
                                        ( "Armor"
                                        , [ Just ( "Name", E.string w.name )
                                          , w.healthBonus |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "Health")
                                          , w.forceShield |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "Armor")
                                          , w.allResistance |> Maybe.andThen (.max >> maybeIf ((/=) 0)) |> Maybe.map (E.int >> Tuple.pair "Resistance")
                                          ]
                                        )

                                    UniqueItem.UAccessory w ->
                                        ( "Armor"
                                        , [ Just ( "Name", E.string w.name )
                                          ]
                                        )
                                  )
                                    |> Tuple.mapSecond (List.filterMap identity >> E.object)
                                , ( "MagicEffects"
                                  , E.object
                                        [ ( "Default", UniqueItem.implicitAffixes uitem |> Affix.getNonmagicIds dm |> encodeAffixes )
                                        , ( "RolledAffixes", UniqueItem.defaultAffixes uitem |> Affix.getNonmagicIds dm |> encodeAffixes )
                                        ]
                                  )
                                ]
                          ]
                        , [ a [ class "breadcrumb-item active", Route.href <| Route.UniqueItems Nothing ] [ text "Unique Loot" ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItem id ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Offline" ]
                          ]
                        )
                    )

        _ ->
            Nothing


encodeAffixes : List (Affix a) -> E.Value
encodeAffixes =
    List.concatMap encodeAffix >> E.list identity


encodeAffix : Affix a -> List E.Value
encodeAffix aff =
    aff.effects |> List.map (encodeEffect aff)


encodeEffect : Affix a -> MagicEffect -> E.Value
encodeEffect affix effect =
    E.object
        [ ( "EffectId", E.string effect.effectId )
        , ( "EffectName", E.string affix.affixId )

        -- TODO what is this
        , ( "MaxStack", E.int 1 )

        -- TODO what is this
        , ( "bDefault", E.int 1 )
        , ( "Parameters", E.list encodeEffectStats effect.stats )
        ]


encodeEffectStats : ( String, Util.Range Float ) -> E.Value
encodeEffectStats ( stat, range ) =
    E.object
        [ ( "semantic", E.string stat )

        -- max rolls for all affixes is fine
        , ( "value", E.float range.max )
        ]


maybeIf : (a -> Bool) -> a -> Maybe a
maybeIf pred val =
    if pred val then
        Just val

    else
        Nothing


viewOffline : E.Value -> List (Html msg)
viewOffline json =
    [ textarea
        [ class "form-control"
        , readonly True
        , style "height" "30em"
        ]
        [ text <| E.encode 8 json ++ ",\n" ]
    ]
