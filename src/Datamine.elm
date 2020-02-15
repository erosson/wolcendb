module Datamine exposing
    ( Affix
    , Datamine
    , Flag
    , MagicEffect
    , affixes
    , decode
    , lang
    , mlang
    )

import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as Json
import Result.Extra
import Xml.Decode as D


type alias Flag =
    Json.Value


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
    }


lang : Datamine -> String -> Maybe String
lang dm key =
    Dict.get (String.toLower key) dm.en


mlang : Datamine -> Maybe String -> Maybe String
mlang dm =
    Maybe.andThen (lang dm)


decode : Flag -> Result String Datamine
decode =
    Json.decodeValue jsonDecoder
        >> Result.mapError Json.errorToString


affixes : Datamine -> List String -> List Affix
affixes dm =
    List.filterMap (\id -> dm.affixes |> List.filter (\a -> a.affixId == id) |> List.head)


jsonDecoder : Json.Decoder Datamine
jsonDecoder =
    Json.map5 Datamine
        (Json.map8 Loot
            (Json.field "Game/Umbra/Loot/Weapons/Weapons.xml" <| jsonXmlDecoder weaponsDecoder)
            (Json.field "Game/Umbra/Loot/Weapons/Shields.xml" <| jsonXmlDecoder shieldsDecoder)
            (Json.field "Game/Umbra/Loot/Armors/Armors.xml" <| jsonXmlDecoder armorsDecoder)
            (Json.field "Game/Umbra/Loot/Armors/Accessories.xml" <| jsonXmlDecoder accessoriesDecoder)
            (Json.field "Game/Umbra/Loot/Weapons/UniqueWeapons.xml" <| jsonXmlDecoder uniqueWeaponsDecoder)
            (Json.field "Game/Umbra/Loot/Weapons/UniqueShields.xml" <| jsonXmlDecoder uniqueShieldsDecoder)
            (Json.field "Game/Umbra/Loot/Armors/Armors_uniques.xml" <| jsonXmlDecoder uniqueArmorsDecoder)
            (Json.field "Game/Umbra/Loot/Armors/UniquesAccessories.xml" <| jsonXmlDecoder uniqueAccessoriesDecoder)
        )
        skillsDecoder
        skillASTsDecoder
        rootAffixesDecoder
        rootLangDecoder


rootAffixesDecoder : Json.Decoder (List Affix)
rootAffixesDecoder =
    Json.keyValuePairs Json.value
        |> Json.map (List.filter (Tuple.first >> String.contains "/Loot/MagicEffects/Affixes/"))
        |> Json.map (List.map (Tuple.second >> Json.decodeValue (jsonXmlDecoder affixesDecoder)))
        |> Json.map (Result.Extra.combine >> Result.mapError Json.errorToString)
        |> resultDecoder
        |> Json.map List.concat


affixesDecoder : D.Decoder (List Affix)
affixesDecoder =
    D.map2 Affix
        (D.stringAttr "AffixId")
        (D.map MagicEffect
            (D.stringAttr "EffectId")
            |> D.list
            |> D.path [ "MagicEffect" ]
        )
        |> D.list
        |> D.path [ "Affix" ]


skillASTsDecoder : Json.Decoder (List SkillAST)
skillASTsDecoder =
    Json.keyValuePairs Json.value
        |> Json.map (List.filter (Tuple.first >> String.contains "/Skills/Trees/ActiveSkills/"))
        |> Json.map (List.map (Tuple.second >> Json.decodeValue (jsonXmlDecoder skillASTDecoder)))
        -- |> Json.map (List.filterMap Result.toMaybe)
        |> Json.map (Result.Extra.combine >> Result.mapError Json.errorToString)
        |> resultDecoder


skillASTDecoder : D.Decoder SkillAST
skillASTDecoder =
    D.map2 SkillAST
        (D.stringAttr "Name")
        (D.map3 SkillASTVariant
            (D.stringAttr "UID")
            (D.intAttr "Level")
            (D.intAttr "Cost")
            |> D.list
            |> D.path [ "SkillVariant" ]
        )
        |> D.single
        |> D.path [ "AST" ]


skillsDecoder : Json.Decoder (List Skill)
skillsDecoder =
    Json.keyValuePairs Json.value
        |> Json.map (List.filter (Tuple.first >> String.contains "/Skills/NewSkills/Player/"))
        |> Json.map (List.map (Tuple.second >> Json.decodeValue (jsonXmlDecoder skillDecoder)))
        -- |> Json.map Result.Extra.combine
        |> Json.map (List.filterMap Result.toMaybe)



--|> Json.andThen
--    (\r ->
--        case r of
--            Err err ->
--                Json.fail <| Json.errorToString err
--
--            Ok ok ->
--                Json.succeed ok
--    )


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
    D.map4 SkillDecoder
        (D.stringAttr "UID")
        (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "UIName")
        (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "Lore")
        (D.maybe <| D.map (String.split ",") <| D.stringAttr "Keywords")
        -- |> D.maybe
        |> D.list
        |> D.path [ "Skill" ]
        -- |> D.map (List.filterMap identity)
        |> D.andThen
            (\els ->
                case els of
                    s :: vs ->
                        case s.uiName of
                            Nothing ->
                                D.fail "no skill.uiname"

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


rootLangDecoder : Json.Decoder (Dict String String)
rootLangDecoder =
    Json.keyValuePairs Json.value
        |> Json.map (List.filter (Tuple.first >> String.contains "localization/text_ui_"))
        |> Json.map (List.map (Tuple.second >> Json.decodeValue langDecoder))
        |> Json.map (Result.Extra.combine >> Result.mapError Json.errorToString)
        |> resultDecoder
        |> Json.map
            (List.concat
                >> List.map (Tuple.mapFirst (\k -> "@" ++ String.toLower k))
                >> Dict.fromList
            )


jsonXmlDecoder : D.Decoder a -> Json.Decoder a
jsonXmlDecoder decoder =
    Json.string |> Json.map (D.decodeString decoder) |> resultDecoder


resultDecoder : Json.Decoder (Result String a) -> Json.Decoder a
resultDecoder =
    Json.andThen
        (\r ->
            case r of
                Err err ->
                    Json.fail err

                Ok val ->
                    Json.succeed val
        )


langDecoder : Json.Decoder (List ( String, String ))
langDecoder =
    Json.map2 Tuple.pair
        (Json.field "KEY" Json.string)
        (Json.field "ORIGINAL TEXT" Json.string)
        |> Json.maybe
        |> Json.list
        |> Json.map (List.filterMap identity)
        |> Json.field "Sheet1"


weaponsDecoder : D.Decoder (List Weapon)
weaponsDecoder =
    D.succeed Weapon
        |> commonLootDecoder
        |> D.andMap
            (D.map2 Range
                (D.maybe <| D.intAttr "LowDamage_Max")
                (D.maybe <| D.intAttr "HighDamage_Max")
            )
        |> D.list
        |> D.path [ "Weapons", "Item" ]


shieldsDecoder : D.Decoder (List Shield)
shieldsDecoder =
    D.succeed Shield
        |> commonLootDecoder
        |> D.list
        |> D.path [ "Weapons", "Item" ]


armorsDecoder : D.Decoder (List Armor)
armorsDecoder =
    D.succeed Armor
        |> commonLootDecoder
        |> D.list
        |> D.path [ "Armors", "Item" ]


accessoriesDecoder : D.Decoder (List Accessory)
accessoriesDecoder =
    D.succeed Accessory
        |> commonLootDecoder
        |> D.list
        |> D.path [ "Armors", "Item" ]


uniqueWeaponsDecoder : D.Decoder (List UniqueWeapon)
uniqueWeaponsDecoder =
    D.succeed UniqueWeapon
        |> uniqueLootDecoder
        |> D.andMap
            (D.map2 Range
                (D.maybe <| D.intAttr "LowDamage_Max")
                (D.maybe <| D.intAttr "HighDamage_Max")
            )
        |> D.list
        |> D.path [ "Weapons", "Item" ]


uniqueShieldsDecoder : D.Decoder (List UniqueShield)
uniqueShieldsDecoder =
    D.succeed UniqueShield
        |> uniqueLootDecoder
        |> D.list
        |> D.path [ "Weapons", "Item" ]


uniqueArmorsDecoder : D.Decoder (List UniqueArmor)
uniqueArmorsDecoder =
    D.succeed UniqueArmor
        |> uniqueLootDecoder
        |> D.list
        |> D.path [ "Armors", "Item" ]


uniqueAccessoriesDecoder : D.Decoder (List UniqueAccessory)
uniqueAccessoriesDecoder =
    D.succeed UniqueAccessory
        |> uniqueLootDecoder
        |> D.list
        |> D.path [ "Armors", "Item" ]


commonLootDecoder =
    D.andMap (D.stringAttr "Name")
        >> D.andMap (D.stringAttr "UIName")
        >> D.andMap (D.stringAttr "Keywords" |> D.map (String.split ","))
        >> D.andMap (D.stringAttr "ImplicitAffixes" |> D.maybe |> D.map (Maybe.withDefault "" >> String.split ","))


uniqueLootDecoder =
    commonLootDecoder
        >> D.andMap (D.stringAttr "DefaultAffixes" |> D.maybe |> D.map (Maybe.withDefault "" >> String.split ","))
        >> D.andMap (D.maybe <| D.stringAttr "Lore")
