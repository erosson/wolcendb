module Datamine.Affix exposing
    ( Affix
    , Affixes
    , Datamine
    , MagicAffix
    , MagicEffect
    , NonmagicAffix
    , Rarity
    , decoder
    , formatEffect
    , getMagicIds
    , getNonmagicIds
    )

import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Affixes =
    { magic : List MagicAffix
    , nonmagic : List NonmagicAffix
    }


type alias MagicAffix =
    { source : Source
    , affixId : String
    , class : Maybe String
    , type_ : String
    , tier : Int
    , effects : List MagicEffect
    , drop : DropParams
    }


type alias DropParams =
    { frequency : Int
    , craftOnly : Bool
    , sarisel : Bool
    , itemLevel : Util.Range Int
    , mandatoryKeywords : List String
    , optionalKeywords : List String
    , rarity : Rarity
    }


type alias Rarity =
    { magic : Bool
    , rare : Bool
    , set : Bool
    , legendary : Bool
    }


{-| Implicit or unique affixes are much simplier
-}
type alias NonmagicAffix =
    { source : Source
    , affixId : String
    , effects : List MagicEffect
    }


type alias Affix a =
    { a
        | source : Source
        , affixId : String
        , effects : List MagicEffect
    }


type alias MagicEffect =
    { effectId : String
    , stats : List ( String, Util.Range Float )
    }


formatEffect : Lang.Datamine d -> MagicEffect -> Maybe String
formatEffect dm effect =
    let
        stats =
            -- TODO: sometimes stats are out of order, but I haven't been able to find a pattern. JSON decoding seems fine.
            if effect.effectId == "default_attacks_chain" then
                effect.stats |> List.reverse

            else
                effect.stats

        key =
            Dict.get effect.effectId formatEffectOverrides
                |> Maybe.withDefault ("@ui_eim_" ++ effect.effectId)
    in
    Lang.get dm key
        |> Maybe.map
            (\template ->
                stats
                    |> List.indexedMap Tuple.pair
                    |> List.foldl Util.formatEffectStat template
            )


{-| These deviate from the usual effect naming pattern. No idea how they work in-game.

Discovered via scanning <http://localhost:3000/table/unique-loot.html> for "???"

TODO check in a unit test, or with the type system

-}
formatEffectOverrides : Dict String String
formatEffectOverrides =
    Dict.fromList
        [ ( "cast_deathmark_on_hit", "@ui_eim_deathmark_on_hit" )
        , ( "umbracosts_percent_elemental", "@ui_eim_umbracost_percent_elemental" )
        , ( "criticaldamage_on_bleeding", "@ui_eim_criticaldamage_on_bleeding_pts" )
        , ( "convert_physical_to_frost", "@ui_eim_convert_physcial_to_frost" )
        ]


type alias Datamine d =
    Lang.Datamine
        { d
            | nonmagicAffixesById : Dict String NonmagicAffix
            , magicAffixesById : Dict String MagicAffix
        }


getNonmagicIds : Datamine d -> List String -> List NonmagicAffix
getNonmagicIds dm =
    List.filterMap (\id -> Dict.get id dm.nonmagicAffixesById)


getMagicIds : Datamine d -> List String -> List MagicAffix
getMagicIds dm =
    List.filterMap (\id -> Dict.get id dm.magicAffixesById)


decoder : D.Decoder Affixes
decoder =
    D.map2 Affixes
        (Util.filteredJsons
            (\f ->
                String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesArmors" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesWeapons" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesAccessories" f
            )
            |> D.map (List.map (\( filename, json ) -> D.decodeValue (magicAffixesDecoder filename) json))
            |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
            |> Util.resultDecoder
            |> D.map List.concat
        )
        (Util.filteredJsons
            (\f ->
                String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesImplicit" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesUniques" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesGems" f
            )
            |> D.map (List.map (\( filename, json ) -> D.decodeValue (nonmagicAffixesDecoder filename) json))
            |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
            |> Util.resultDecoder
            |> D.map List.concat
        )


nonmagicAffixesDecoder : String -> D.Decoder (List NonmagicAffix)
nonmagicAffixesDecoder file =
    D.succeed NonmagicAffix
        |> P.custom (Source.decoder file "Affix")
        |> P.requiredAt [ "$", "AffixId" ] D.string
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


magicAffixesDecoder : String -> D.Decoder (List MagicAffix)
magicAffixesDecoder file =
    D.succeed MagicAffix
        |> P.custom (Source.decoder file "Affix")
        |> P.requiredAt [ "$", "AffixId" ] D.string
        -- |> P.requiredAt [ "$", "Class" ] D.string
        |> P.optionalAt [ "$", "Class" ] (D.string |> D.map Just) Nothing
        |> P.requiredAt [ "$", "AffixType" ] D.string
        -- |> P.optionalAt [ "$", "Tier" ] (intString |> D.map Just) Nothing
        |> P.requiredAt [ "$", "Tier" ] Util.intString
        -- |> P.optionalAt [ "$", "AffixType" ] (D.string |> D.map Just) Nothing
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> P.custom (dropParamsDecoder |> Util.single |> D.at [ "DropParams" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


dropParamsDecoder : D.Decoder DropParams
dropParamsDecoder =
    D.succeed DropParams
        |> P.requiredAt [ "$", "Frequency" ] Util.intString
        |> P.optionalAt [ "$", "CraftOnly" ] Util.boolString False
        |> P.optionalAt [ "$", "Sarisel" ] Util.boolString False
        |> P.custom
            (D.map2 Util.Range
                (D.at [ "ItemLevel", "0", "$", "LevelMin" ] Util.intString)
                (D.at [ "ItemLevel", "0", "$", "LevelMax" ] Util.intString)
            )
        |> P.optionalAt [ "Keywords", "0", "$", "MandatoryKeywords" ] Util.csStrings []
        |> P.optionalAt [ "Keywords", "0", "$", "OptionalKeywords" ] Util.csStrings []
        |> P.requiredAt [ "ItemRarity", "0" ] rarityDecoder


rarityDecoder : D.Decoder Rarity
rarityDecoder =
    D.succeed Rarity
        |> P.optionalAt [ "$", "Magic" ] Util.boolString False
        |> P.optionalAt [ "$", "Rare" ] Util.boolString False
        |> P.optionalAt [ "$", "Set" ] Util.boolString False
        |> P.optionalAt [ "$", "Legendary" ] Util.boolString False


magicEffectDecoder : D.Decoder MagicEffect
magicEffectDecoder =
    D.succeed MagicEffect
        |> P.requiredAt [ "$", "EffectId" ] D.string
        |> P.custom magicEffectStatsDecoder


magicEffectStatsDecoder : D.Decoder (List ( String, Util.Range Float ))
magicEffectStatsDecoder =
    D.map2 Tuple.pair
        (D.at [ "LoRoll", "0", "$" ] (D.keyValuePairs Util.floatString))
        (D.at [ "HiRoll", "0", "$" ] (D.keyValuePairs Util.floatString))
        |> D.map
            (\( mins, maxs ) ->
                let
                    maxd =
                        Dict.fromList maxs
                in
                if List.map Tuple.first maxs /= List.map Tuple.first mins then
                    Err <| "magicEffectStats have different lo/hi keys: " ++ String.join "," (List.map Tuple.first mins)

                else
                    mins
                        |> List.map
                            (\( key, min ) ->
                                Dict.get key maxd
                                    |> Maybe.map (\max -> ( key, { min = min, max = max } ))
                                    |> Result.fromMaybe ("magicEffectStats missing max key: " ++ key)
                            )
                        |> Result.Extra.combine
            )
        |> Util.resultDecoder
