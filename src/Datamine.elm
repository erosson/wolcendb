module Datamine exposing
    ( Affix
    , Datamine
    , Flag
    , MagicEffect
    , Range
    , affixes
    , decode
    , lang
    , mlang
    )

{-| Import JSON files from the `datamine` directory.

These are passed in as Elm flags.

We used to decode the xml directly in Elm using the `ymtszw/elm-xml-decode` package.
Converting to JSON and parsing that instead is a little awkward, but it runs much
faster in development (webpack imports - not sure why!) and the JSON decoder has
some features we need (ex. `Json.Decode.keyValuePairs`).

-}

import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Flag =
    D.Value


type alias Datamine =
    { loot : Loot
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : List Affix
    , en : Dict String String
    }


type alias Loot =
    { weapons : List Weapon
    , shields : List Shield
    , armors : List Armor
    , accessories : List Accessory
    , uniqueWeapons : List UniqueWeapon
    , uniqueShields : List UniqueShield
    , uniqueArmors : List UniqueArmor
    , uniqueAccessories : List UniqueAccessory
    }


type alias Weapon =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    , damage : Range (Maybe Int)
    }


type alias Shield =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    }


type alias Armor =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    }


type alias Accessory =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    }


type alias UniqueWeapon =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , damage : Range (Maybe Int)
    }


type alias UniqueShield =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    }


type alias UniqueArmor =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    }


type alias UniqueAccessory =
    { name : String
    , uiName : String
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    }


type alias Range a =
    { min : a, max : a }


type alias Skill =
    { uid : String
    , uiName : String
    , lore : Maybe String
    , keywords : List String
    , variants : List SkillVariant
    }


type alias SkillVariant =
    { uid : String
    , uiName : String
    , lore : Maybe String
    }


type alias SkillAST =
    { name : String
    , variants : List SkillASTVariant
    }


type alias SkillASTVariant =
    { uid : String
    , level : Int
    , cost : Int
    }


type alias Affix =
    { affixId : String
    , effects : List MagicEffect
    }


type alias MagicEffect =
    { effectId : String
    , stats : List ( String, Range Float )
    }


lang : Datamine -> String -> Maybe String
lang dm key =
    Dict.get (String.toLower key) dm.en


mlang : Datamine -> Maybe String -> Maybe String
mlang dm =
    Maybe.andThen (lang dm)


decode : Flag -> Result String Datamine
decode =
    D.decodeValue jsonDecoder
        >> Result.mapError D.errorToString


affixes : Datamine -> List String -> List Affix
affixes dm =
    List.filterMap (\id -> dm.affixes |> List.filter (\a -> a.affixId == id) |> List.head)


jsonDecoder : D.Decoder Datamine
jsonDecoder =
    D.map5 Datamine
        (D.map8 Loot
            (D.field "Game/Umbra/Loot/Weapons/Weapons.json" weaponsDecoder)
            (D.field "Game/Umbra/Loot/Weapons/Shields.json" shieldsDecoder)
            (D.field "Game/Umbra/Loot/Armors/Armors.json" armorsDecoder)
            (D.field "Game/Umbra/Loot/Armors/Accessories.json" accessoriesDecoder)
            (D.field "Game/Umbra/Loot/Weapons/UniqueWeapons.json" uniqueWeaponsDecoder)
            (D.field "Game/Umbra/Loot/Weapons/UniqueShields.json" uniqueShieldsDecoder)
            (D.field "Game/Umbra/Loot/Armors/Armors_uniques.json" uniqueArmorsDecoder)
            (D.field "Game/Umbra/Loot/Armors/UniquesAccessories.json" uniqueAccessoriesDecoder)
        )
        skillsDecoder
        skillASTsDecoder
        rootAffixesDecoder
        rootLangDecoder


rootAffixesDecoder : D.Decoder (List Affix)
rootAffixesDecoder =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> String.contains "/Loot/MagicEffects/Affixes/"))
        |> D.map (List.map (Tuple.second >> D.decodeValue affixesDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder
        |> D.map List.concat


affixesDecoder : D.Decoder (List Affix)
affixesDecoder =
    D.succeed Affix
        |> P.requiredAt [ "$", "AffixId" ] D.string
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


magicEffectDecoder : D.Decoder MagicEffect
magicEffectDecoder =
    D.succeed MagicEffect
        |> P.requiredAt [ "$", "EffectId" ] D.string
        |> P.custom magicEffectStatsDecoder


magicEffectStatsDecoder : D.Decoder (List ( String, Range Float ))
magicEffectStatsDecoder =
    D.map2 Tuple.pair
        (D.at [ "LoRoll", "0", "$" ] (D.keyValuePairs floatString))
        (D.at [ "HiRoll", "0", "$" ] (D.keyValuePairs floatString))
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
        |> resultDecoder


skillASTsDecoder : D.Decoder (List SkillAST)
skillASTsDecoder =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> String.contains "/Skills/Trees/ActiveSkills/"))
        |> D.map (List.map (Tuple.second >> D.decodeValue skillASTDecoder))
        -- |> D.map (List.filterMap Result.toMaybe)
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder


skillASTDecoder : D.Decoder SkillAST
skillASTDecoder =
    D.succeed SkillAST
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.custom
            (D.succeed SkillASTVariant
                |> P.requiredAt [ "$", "UID" ] D.string
                |> P.requiredAt [ "$", "Level" ] intString
                |> P.requiredAt [ "$", "Cost" ] intString
                |> D.list
                |> D.at [ "SkillVariant" ]
            )
        |> single
        |> D.at [ "MetaData", "AST" ]


ignoredSkills =
    [ "ActiveDodge"
    , "AutoDash"
    , "DeathMark_Explosion"
    , "FrostLance_Explosion"
    , "FrostNova_Zone_Shadow"
    , "FrostNova_Zone"
    , "UsePotion"
    ]


skillsDecoder : D.Decoder (List Skill)
skillsDecoder =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> String.contains "/Skills/NewSkills/Player/"))
        |> D.map (List.filter (Tuple.first >> (\s -> List.any (\c -> String.contains c s) ignoredSkills) >> not))
        |> D.map (List.map (Tuple.second >> D.decodeValue skillDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder


type alias SkillDecoder =
    { uid : String
    , uiName : Maybe String
    , lore : Maybe String
    , keywords : Maybe (List String)
    }


skillDecoder : D.Decoder Skill
skillDecoder =
    -- The first skill entry is the skill itself; all following entries are its variants (d3 "runes").
    -- The XML decoding is a bit awkward because lists must be homogeneous. Decode them as an
    -- intermediate structure, SkillDecoder, and transform them to Skills/SkillVariants later.
    D.succeed SkillDecoder
        |> P.requiredAt [ "$", "UID" ] D.string
        |> P.optionalAt [ "HUD", "0", "$", "UIName" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Lore" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Keywords" ] (D.string |> D.map (String.split "," >> Just)) Nothing
        |> D.list
        |> D.at [ "MetaData", "Skill" ]
        |> D.andThen
            (\els ->
                case els of
                    s :: vs ->
                        case s.uiName of
                            Nothing ->
                                D.fail <| "no skill.uiname for skill: " ++ s.uid

                            Just uiName ->
                                D.succeed
                                    { uid = s.uid
                                    , uiName = uiName
                                    , lore = s.lore
                                    , keywords = s.keywords |> Maybe.withDefault []
                                    , variants =
                                        vs
                                            |> List.filterMap
                                                (\v ->
                                                    Maybe.map
                                                        (\vUiName ->
                                                            { uid = v.uid
                                                            , uiName = vUiName
                                                            , lore = v.lore
                                                            }
                                                        )
                                                        v.uiName
                                                )
                                    }

                    [] ->
                        D.fail "skill has no instances"
            )


rootLangDecoder : D.Decoder (Dict String String)
rootLangDecoder =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> String.contains "localization/text_ui_"))
        |> D.map (List.map (Tuple.second >> D.decodeValue langDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder
        |> D.map
            (List.concat
                >> List.map (Tuple.mapFirst (\k -> "@" ++ String.toLower k))
                >> Dict.fromList
            )


resultDecoder : D.Decoder (Result String a) -> D.Decoder a
resultDecoder =
    D.andThen
        (\r ->
            case r of
                Err err ->
                    D.fail err

                Ok val ->
                    D.succeed val
        )


langDecoder : D.Decoder (List ( String, String ))
langDecoder =
    D.map2 Tuple.pair
        (D.field "KEY" D.string)
        (D.field "ORIGINAL TEXT" D.string)
        |> D.maybe
        |> D.list
        |> D.map (List.filterMap identity)
        |> D.field "Sheet1"


weaponsDecoder : D.Decoder (List Weapon)
weaponsDecoder =
    D.succeed Weapon
        |> commonLootDecoder
        |> P.custom
            (D.succeed Range
                |> P.optionalAt [ "$", "LowDamage_Max" ] (intString |> D.map Just) Nothing
                |> P.optionalAt [ "$", "HighDamage_Max" ] (intString |> D.map Just) Nothing
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


shieldsDecoder : D.Decoder (List Shield)
shieldsDecoder =
    D.succeed Shield
        |> commonLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


armorsDecoder : D.Decoder (List Armor)
armorsDecoder =
    D.succeed Armor
        |> commonLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


accessoriesDecoder : D.Decoder (List Accessory)
accessoriesDecoder =
    D.succeed Accessory
        |> commonLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


uniqueWeaponsDecoder : D.Decoder (List UniqueWeapon)
uniqueWeaponsDecoder =
    D.succeed UniqueWeapon
        |> uniqueLootDecoder
        |> P.custom
            (D.succeed Range
                |> P.optionalAt [ "$", "LowDamage_Max" ] (intString |> D.map Just) Nothing
                |> P.optionalAt [ "$", "HighDamage_Max" ] (intString |> D.map Just) Nothing
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


uniqueShieldsDecoder : D.Decoder (List UniqueShield)
uniqueShieldsDecoder =
    D.succeed UniqueShield
        |> uniqueLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


uniqueArmorsDecoder : D.Decoder (List UniqueArmor)
uniqueArmorsDecoder =
    D.succeed UniqueArmor
        |> uniqueLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


uniqueAccessoriesDecoder : D.Decoder (List UniqueAccessory)
uniqueAccessoriesDecoder =
    D.succeed UniqueAccessory
        |> uniqueLootDecoder
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


commonLootDecoder =
    P.requiredAt [ "$", "Name" ] D.string
        >> P.requiredAt [ "$", "UIName" ] D.string
        >> P.requiredAt [ "$", "Keywords" ] (D.string |> D.map (String.split ","))
        >> P.optionalAt [ "$", "ImplicitAffixes" ] (D.string |> D.map (String.split ",")) []


uniqueLootDecoder =
    commonLootDecoder
        >> P.optionalAt [ "$", "DefaultAffixes" ] (D.string |> D.map (String.split ",")) []
        >> P.optionalAt [ "$", "Lore" ] (D.string |> D.map Just) Nothing


{-| Decode a JSON string as an Elm int.

Our XML-to-JSON converter leaves everything as strings in the JSON, so
D.Decode.int doesn't work. Same with other non-string decoders.

-}
intString : D.Decoder Int
intString =
    D.string
        |> D.andThen
            (\s ->
                case String.toInt s of
                    Nothing ->
                        D.fail <| "expected an int, got: " ++ s

                    Just i ->
                        D.succeed i
            )


floatString : D.Decoder Float
floatString =
    D.string
        |> D.andThen
            (\s ->
                case String.toFloat s of
                    Nothing ->
                        D.fail <| "expected a float, got: " ++ s

                    Just i ->
                        D.succeed i
            )


{-| Decode a list with exactly one item.

A side effect of our xml-to-json conversion is that our data has many scattered single-item lists.
This unwraps them cleanly.

-}
single : D.Decoder a -> D.Decoder a
single =
    D.list >> D.andThen single_


single_ : List a -> D.Decoder a
single_ vals =
    case vals of
        [ val ] ->
            D.succeed val

        _ ->
            D.fail <| "`single` expected 1 item, got " ++ String.fromInt (List.length vals)
