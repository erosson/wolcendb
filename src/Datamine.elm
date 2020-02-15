module Datamine exposing (Datamine, Flag, decode, lang, mlang)

import Dict exposing (Dict)
import Json.Decode as Json
import Result.Extra
import Xml.Decode as D


type alias Flag =
    Json.Value


type alias Datamine =
    { loot : Loot
    , skills : List Skill
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
    , damage : Range (Maybe Int)
    }


type alias Shield =
    { name : String
    , uiName : String
    , keywords : List String
    }


type alias Armor =
    { name : String
    , uiName : String
    , keywords : List String
    }


type alias Accessory =
    { name : String
    , uiName : String
    , keywords : List String
    }


type alias UniqueWeapon =
    { name : String
    , uiName : String
    , lore : Maybe String
    , keywords : List String
    , damage : Range (Maybe Int)
    }


type alias UniqueShield =
    { name : String
    , uiName : String
    , lore : Maybe String
    , keywords : List String
    }


type alias UniqueArmor =
    { name : String
    , uiName : String
    , lore : Maybe String
    , keywords : List String
    }


type alias UniqueAccessory =
    { name : String
    , uiName : String
    , lore : Maybe String
    , keywords : List String
    }


type alias Range a =
    { min : a, max : a }


type alias Skill =
    { uid : String
    , uiName : Maybe String
    , lore : Maybe String

    -- , keywords : List String
    , variants : List SkillVariant
    }


type alias SkillVariant =
    { uid : String
    , uiName : Maybe String
    , lore : Maybe String
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


jsonDecoder : Json.Decoder Datamine
jsonDecoder =
    Json.map3 Datamine
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
        rootLangDecoder


skillsDecoder : Json.Decoder (List Skill)
skillsDecoder =
    Json.keyValuePairs Json.value
        |> Json.map (List.filter (Tuple.first >> String.contains "/Skills/NewSkills/Player/"))
        |> Json.map (List.map (Tuple.second >> Json.decodeValue (jsonXmlDecoder skillDecoder)))
        |> Json.map Result.Extra.combine
        |> Json.andThen
            (\r ->
                case r of
                    Err err ->
                        Json.fail <| Json.errorToString err

                    Ok ok ->
                        Json.succeed ok
            )


type SkillDecoder
    = SkillXml (List SkillVariant -> Skill)
    | SkillVariantXml SkillVariant


skillDecoder : D.Decoder Skill
skillDecoder =
    D.oneOf
        [ D.map3 Skill
            -- (D.path [ "WeaponRequirements" ] <| D.single <| D.stringAttr "Requirements")
            (D.stringAttr "UID")
            (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "UIName")
            (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "Lore")
            -- (D.stringAttr "Keywords" |> D.map (String.split ","))
            |> D.map SkillXml
        , D.map3 SkillVariant
            (D.stringAttr "UID")
            (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "UIName")
            (D.maybe <| D.path [ "HUD" ] <| D.single <| D.stringAttr "Lore")
            |> D.map SkillVariantXml
        ]
        -- |> D.maybe
        |> D.list
        |> D.path [ "Skill" ]
        -- |> D.map (List.filterMap identity)
        |> D.andThen
            (\els ->
                case els of
                    (SkillXml s) :: tail ->
                        let
                            variants : List SkillVariant
                            variants =
                                els
                                    |> List.filterMap
                                        (\el ->
                                            case el of
                                                SkillVariantXml v ->
                                                    Just v

                                                _ ->
                                                    Nothing
                                        )
                        in
                        D.succeed <| s variants

                    _ ->
                        D.fail "first <skill> unparsable as a skill"
             -- _ ->
             -- D.fail "multiple skills"
            )


rootLangDecoder : Json.Decoder (Dict String String)
rootLangDecoder =
    Json.map2
        (\a b ->
            [ a, b ]
                |> List.concat
                |> List.map (Tuple.mapFirst (\k -> "@" ++ String.toLower k))
                |> Dict.fromList
        )
        (Json.field "localization/text_ui_Loot.xml" langDecoder)
        (Json.field "localization/text_ui_Activeskills.xml" langDecoder)


jsonXmlDecoder : D.Decoder a -> Json.Decoder a
jsonXmlDecoder decoder =
    Json.string
        |> Json.andThen
            (\s ->
                case D.decodeString decoder s of
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
    D.map4 Weapon
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        (D.map2 Range
            (D.maybe <| D.intAttr "LowDamage_Max")
            (D.maybe <| D.intAttr "HighDamage_Max")
        )
        |> D.list
        |> D.path [ "Weapons", "Item" ]


shieldsDecoder : D.Decoder (List Shield)
shieldsDecoder =
    D.map3 Shield
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Weapons", "Item" ]


armorsDecoder : D.Decoder (List Armor)
armorsDecoder =
    D.map3 Armor
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Armors", "Item" ]


accessoriesDecoder : D.Decoder (List Accessory)
accessoriesDecoder =
    D.map3 Accessory
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Armors", "Item" ]


uniqueWeaponsDecoder : D.Decoder (List UniqueWeapon)
uniqueWeaponsDecoder =
    D.map5 UniqueWeapon
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.maybe <| D.stringAttr "Lore")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        (D.map2 Range
            (D.maybe <| D.intAttr "LowDamage_Max")
            (D.maybe <| D.intAttr "HighDamage_Max")
        )
        |> D.list
        |> D.path [ "Weapons", "Item" ]


uniqueShieldsDecoder : D.Decoder (List UniqueShield)
uniqueShieldsDecoder =
    D.map4 UniqueShield
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.maybe <| D.stringAttr "Lore")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Weapons", "Item" ]


uniqueArmorsDecoder : D.Decoder (List UniqueArmor)
uniqueArmorsDecoder =
    D.map4 UniqueArmor
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.maybe <| D.stringAttr "Lore")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Armors", "Item" ]


uniqueAccessoriesDecoder : D.Decoder (List UniqueAccessory)
uniqueAccessoriesDecoder =
    D.map4 UniqueAccessory
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.maybe <| D.stringAttr "Lore")
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Armors", "Item" ]
