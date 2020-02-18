module Datamine exposing
    ( Affix
    , Datamine
    , Flag
    , Item
    , MagicAffix
    , MagicEffect
    , NonmagicAffix
    , NormalItem(..)
    , Range
    , Rarity
    , UItem
    , UniqueItem(..)
    , decode
    , itemAffixes
    , lang
    , magicAffixes
    , mlang
    , nonmagicAffixes
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
import Set exposing (Set)


type alias Flag =
    D.Value


type alias Datamine =
    { loot : List NormalItem
    , uniqueLoot : List UniqueItem
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : Affixes
    , cosmeticTransferTemplates : Dict String CCosmeticTransferTemplate
    , cosmeticWeaponDescriptors : Dict String CCosmeticWeaponDescriptor
    , en : Dict String String
    , lootByName : Dict String NormalItem
    , uniqueLootByName : Dict String UniqueItem
    , skillsByUid : Dict String Skill
    , skillASTsByName : Dict String SkillAST
    }


type alias RawDatamine =
    { loot : List NormalItem
    , uniqueLoot : List UniqueItem
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : Affixes
    , cosmeticTransferTemplates : Dict String CCosmeticTransferTemplate
    , cosmeticWeaponDescriptors : Dict String CCosmeticWeaponDescriptor
    , en : Dict String String
    }


index : RawDatamine -> Datamine
index raw =
    { loot = raw.loot
    , uniqueLoot = raw.uniqueLoot
    , skills = raw.skills
    , skillASTs = raw.skillASTs
    , affixes = raw.affixes
    , cosmeticTransferTemplates = raw.cosmeticTransferTemplates
    , cosmeticWeaponDescriptors = raw.cosmeticWeaponDescriptors
    , en = raw.en
    , lootByName = raw.loot |> Dict.Extra.fromListBy (nitemName >> String.toLower)
    , uniqueLootByName = raw.uniqueLoot |> Dict.Extra.fromListBy (uitemName >> String.toLower)
    , skillsByUid = raw.skills |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , skillASTsByName = raw.skillASTs |> Dict.Extra.fromListBy (.name >> String.toLower)
    }


type alias Affixes =
    { magic : List MagicAffix
    , nonmagic : List NonmagicAffix
    }


type NormalItem
    = NWeapon Weapon
    | NShield Shield
    | NArmor Armor
    | NAccessory Accessory


type UniqueItem
    = UWeapon UniqueWeapon
    | UShield UniqueShield
    | UArmor UniqueArmor
    | UAccessory UniqueAccessory


type alias Weapon =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , damage : Range (Maybe Int)
    }


type alias Shield =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    }


type alias Armor =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , attachmentName : String
    }


type alias Accessory =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , hudPicture : String
    }


type alias Item i =
    { i
        | name : String
        , uiName : String
        , levelPrereq : Maybe Int
        , keywords : List String
        , implicitAffixes : List String
    }


type alias UItem i =
    Item
        { i
            | defaultAffixes : List String
            , lore : Maybe String
        }


type alias UniqueWeapon =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , damage : Range (Maybe Int)
    }


type alias UniqueShield =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    }


type alias UniqueArmor =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , attachmentName : Maybe String
    }


type alias UniqueAccessory =
    { name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , hudPicture : String
    }


{-| where weapon icons come from
-}
type alias CCosmeticWeaponDescriptor =
    { name : String
    , hudPicture : String
    }


{-| where armor icons come from
-}
type alias CCosmeticTransferTemplate =
    { name : String
    , hudPicture : String
    }


type alias Range a =
    { min : a, max : a }


type alias Skill =
    { uid : String
    , uiName : String
    , hudPicture : String
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


type alias MagicAffix =
    { affixId : String
    , filename : String
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
    , itemLevel : Range Int
    , optionalKeywords : List String
    , mandatoryKeywords : List String
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
    { affixId : String
    , filename : String
    , effects : List MagicEffect
    }


type alias Affix a =
    { a
        | affixId : String
        , filename : String
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


nitemName : NormalItem -> String
nitemName n =
    case n of
        NWeapon i ->
            i.name

        NShield i ->
            i.name

        NArmor i ->
            i.name

        NAccessory i ->
            i.name


uitemName : UniqueItem -> String
uitemName n =
    case n of
        UWeapon i ->
            i.name

        UShield i ->
            i.name

        UArmor i ->
            i.name

        UAccessory i ->
            i.name


{-| Get all random magic affixes that this item can spawn.

Includes craftable and sarisel affixes.

I have no authoritative source for how this works. Below I've implemented my own theory -
seems to yield decent results, and I'm not aware of any counterexamples:

  - All of an affix's optional keywords must be present on an item. (Great name for this one, yes?)

  - If an affix has any mandatory keywords, at least one of them must be present on an item

  - Item level, like poe and diablo, depends on the monster level that drops the item.
    (Confirmed this by viewing my save file during offline play.) This is what
    an affix's level bounds are applied. Not done in this function.

  - At most one affix spawns for affixes with the same class, like poe modgroups.

  - TODO: what are Sarisel affixes?
      - I've assumed they're limited to a boss I haven't seen yet, and not part of the natural drop pool. They have much higher weights than other mods.

-}
itemAffixes : Datamine -> Item i -> List MagicAffix
itemAffixes dm item =
    let
        itemKeywords : Set String
        itemKeywords =
            Set.fromList item.keywords

        isItemKeyword : String -> Bool
        isItemKeyword k =
            Set.member k itemKeywords
    in
    dm.affixes.magic
        |> List.filter
            (\affix ->
                List.all isItemKeyword affix.drop.optionalKeywords
                    && (List.any isItemKeyword affix.drop.mandatoryKeywords
                            || (affix.drop.mandatoryKeywords == [])
                       )
            )



--- DECODING


decode : Flag -> Result String Datamine
decode =
    D.decodeValue jsonDecoder
        >> Result.mapError D.errorToString


nonmagicAffixes : Datamine -> List String -> List NonmagicAffix
nonmagicAffixes dm =
    List.filterMap (\id -> dm.affixes.nonmagic |> List.filter (\a -> a.affixId == id) |> List.head)


magicAffixes : Datamine -> List String -> List MagicAffix
magicAffixes dm =
    List.filterMap (\id -> dm.affixes.magic |> List.filter (\a -> a.affixId == id) |> List.head)


jsonDecoder : D.Decoder Datamine
jsonDecoder =
    D.succeed RawDatamine
        |> P.custom normalItemsDecoder
        |> P.custom uniqueItemsDecoder
        |> P.custom skillsDecoder
        |> P.custom skillASTsDecoder
        |> P.custom rootAffixesDecoder
        |> P.custom cosmeticTransferTemplateDecoder
        |> P.custom cosmeticWeaponDescriptorDecoder
        |> P.custom rootLangDecoder
        |> D.map index


normalItemsDecoder : D.Decoder (List NormalItem)
normalItemsDecoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ D.field "Game/Umbra/Loot/Weapons/Weapons.json" normalWeaponsDecoder
        , D.field "Game/Umbra/Loot/Weapons/Shields.json" normalWeaponsDecoder
        , D.field "Game/Umbra/Loot/Armors/Armors.json" normalArmorsDecoder
        , D.field "Game/Umbra/Loot/Armors/Accessories.json" normalArmorsDecoder
        ]


normalWeaponsDecoder : D.Decoder (List NormalItem)
normalWeaponsDecoder =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "shield" keywords then
                    D.succeed Shield
                        |> commonLootDecoder
                        |> D.map NShield

                else
                    D.succeed Weapon
                        |> commonLootDecoder
                        |> P.custom
                            (D.succeed Range
                                |> P.optionalAt [ "$", "LowDamage_Max" ] (intString |> D.map Just) Nothing
                                |> P.optionalAt [ "$", "HighDamage_Max" ] (intString |> D.map Just) Nothing
                            )
                        |> D.map NWeapon
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


normalArmorsDecoder : D.Decoder (List NormalItem)
normalArmorsDecoder =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "accessory" keywords then
                    D.succeed Accessory
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map NAccessory

                else
                    D.succeed Armor
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "AttachmentName" ] D.string
                        |> D.map NArmor
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


uniqueItemsDecoder : D.Decoder (List UniqueItem)
uniqueItemsDecoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ D.field "Game/Umbra/Loot/Weapons/UniqueWeapons.json" uniqueWeaponsDecoder
        , D.field "Game/Umbra/Loot/Weapons/UniqueWeaponsMax.json" uniqueWeaponsDecoder
        , D.field "Game/Umbra/Loot/Weapons/UniqueWeaponsMaxMax.json" uniqueWeaponsDecoder
        , D.field "Game/Umbra/Loot/Weapons/UniqueShields.json" uniqueWeaponsDecoder
        , D.field "Game/Umbra/Loot/Armors/Armors_uniques.json" uniqueArmorsDecoder
        , D.field "Game/Umbra/Loot/Armors/UniqueArmorsMax.json" uniqueArmorsDecoder
        , D.field "Game/Umbra/Loot/Armors/UniqueArmorsMaxMax.json" uniqueArmorsDecoder
        , D.field "Game/Umbra/Loot/Armors/UniquesAccessories.json" uniqueArmorsDecoder
        ]


uniqueWeaponsDecoder : D.Decoder (List UniqueItem)
uniqueWeaponsDecoder =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "shield" keywords then
                    D.succeed UniqueShield
                        |> uniqueLootDecoder
                        |> D.map UShield

                else
                    D.succeed UniqueWeapon
                        |> uniqueLootDecoder
                        |> P.custom
                            (D.succeed Range
                                |> P.optionalAt [ "$", "LowDamage_Max" ] (intString |> D.map Just) Nothing
                                |> P.optionalAt [ "$", "HighDamage_Max" ] (intString |> D.map Just) Nothing
                            )
                        |> D.map UWeapon
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Weapons" ]


uniqueArmorsDecoder : D.Decoder (List UniqueItem)
uniqueArmorsDecoder =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "accessory" keywords then
                    D.succeed UniqueAccessory
                        |> uniqueLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map UAccessory

                else
                    D.succeed UniqueArmor
                        |> uniqueLootDecoder
                        |> P.optionalAt [ "$", "AttachmentName" ] (D.string |> D.map Just) Nothing
                        |> D.map UArmor
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ "MetaData", "Armors" ]


cosmeticTransferTemplateDecoder : D.Decoder (Dict String CCosmeticTransferTemplate)
cosmeticTransferTemplateDecoder =
    D.map2 CCosmeticTransferTemplate
        (D.at [ "$", "name" ] D.string)
        (D.at [ "$", "hud_picture" ] D.string)
        |> D.maybe
        |> D.list
        |> D.map (List.filterMap identity)
        |> D.at
            [ "Game/Umbra/SkinParams/TransferTemplate/TransferTemplateBank.json"
            , "CCosmeticTransferTemplateBank"
            , "CCosmeticTransferTemplate"
            ]
        |> D.map (Dict.Extra.fromListBy (.name >> String.toLower))


cosmeticWeaponDescriptorDecoder : D.Decoder (Dict String CCosmeticWeaponDescriptor)
cosmeticWeaponDescriptorDecoder =
    D.map2 CCosmeticWeaponDescriptor
        (D.at [ "$", "name" ] D.string)
        (D.at [ "$", "hud_picture" ] D.string)
        |> D.list
        |> D.at
            [ "Game/Umbra/SkinParams/WeaponSkins/CosmeticWeaponDescriptorBankGameplay.json"
            , "CCosmeticWeaponDescriptorBank"
            , "CCosmeticWeaponDescriptor"
            ]
        |> D.map (Dict.Extra.fromListBy (.name >> String.toLower))


rootAffixesDecoder : D.Decoder Affixes
rootAffixesDecoder =
    D.map2 Affixes
        (filteredJsons
            (\f ->
                String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesArmors" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesWeapons" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesAccessories" f
            )
            |> D.map (List.map (\( filename, json ) -> D.decodeValue (magicAffixesDecoder filename) json))
            |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
            |> resultDecoder
            |> D.map List.concat
        )
        (filteredJsons
            (\f ->
                String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesImplicit" f
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesUniques" f
            )
            |> D.map (List.map (\( filename, json ) -> D.decodeValue (nonmagicAffixesDecoder filename) json))
            |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
            |> resultDecoder
            |> D.map List.concat
        )


filteredJsons : (String -> Bool) -> D.Decoder (List ( String, D.Value ))
filteredJsons pred =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> pred))


nonmagicAffixesDecoder : String -> D.Decoder (List NonmagicAffix)
nonmagicAffixesDecoder filename =
    D.succeed NonmagicAffix
        |> P.requiredAt [ "$", "AffixId" ] D.string
        |> P.custom (D.succeed filename)
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


magicAffixesDecoder : String -> D.Decoder (List MagicAffix)
magicAffixesDecoder filename =
    D.succeed MagicAffix
        |> P.requiredAt [ "$", "AffixId" ] D.string
        |> P.custom (D.succeed filename)
        -- |> P.requiredAt [ "$", "Class" ] D.string
        |> P.optionalAt [ "$", "Class" ] (D.string |> D.map Just) Nothing
        |> P.requiredAt [ "$", "AffixType" ] D.string
        -- |> P.optionalAt [ "$", "Tier" ] (intString |> D.map Just) Nothing
        |> P.requiredAt [ "$", "Tier" ] intString
        -- |> P.optionalAt [ "$", "AffixType" ] (D.string |> D.map Just) Nothing
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> P.custom (dropParamsDecoder |> single |> D.at [ "DropParams" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


dropParamsDecoder : D.Decoder DropParams
dropParamsDecoder =
    D.succeed DropParams
        |> P.requiredAt [ "$", "Frequency" ] intString
        |> P.optionalAt [ "$", "CraftOnly" ] boolString False
        |> P.optionalAt [ "$", "Sarisel" ] boolString False
        |> P.custom
            (D.map2 Range
                (D.at [ "ItemLevel", "0", "$", "LevelMin" ] intString)
                (D.at [ "ItemLevel", "0", "$", "LevelMax" ] intString)
            )
        |> P.optionalAt [ "Keywords", "0", "$", "MandatoryKeywords" ] csStrings []
        |> P.optionalAt [ "Keywords", "0", "$", "OptionalKeywords" ] csStrings []
        |> P.requiredAt [ "ItemRarity", "0" ] rarityDecoder


rarityDecoder : D.Decoder Rarity
rarityDecoder =
    D.succeed Rarity
        |> P.optionalAt [ "$", "Magic" ] boolString False
        |> P.optionalAt [ "$", "Rare" ] boolString False
        |> P.optionalAt [ "$", "Set" ] boolString False
        |> P.optionalAt [ "$", "Legendary" ] boolString False


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
    filteredJsons (String.contains "/Skills/Trees/ActiveSkills/")
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
    filteredJsons (\s -> String.contains "/Skills/NewSkills/Player/" s && not (List.any (\c -> String.contains c s) ignoredSkills))
        |> D.map (List.map (Tuple.second >> D.decodeValue skillDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder


type alias SkillDecoder =
    { uid : String
    , uiName : Maybe String
    , hudPicture : Maybe String
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
        |> P.optionalAt [ "HUD", "0", "$", "HUDPicture" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Lore" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Keywords" ] (csStrings |> D.map Just) Nothing
        |> D.list
        |> D.at [ "MetaData", "Skill" ]
        |> D.andThen
            (\els ->
                case els of
                    s :: vs ->
                        case ( s.uiName, s.hudPicture ) of
                            ( Just uiName, Just hudPicture ) ->
                                D.succeed
                                    { uid = s.uid
                                    , uiName = uiName
                                    , lore = s.lore
                                    , hudPicture = hudPicture
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

                            ( Nothing, _ ) ->
                                D.fail <| "no skill.uiname for skill: " ++ s.uid

                            ( _, Nothing ) ->
                                D.fail <| "no skill.hudPicture for skill: " ++ s.uid

                    [] ->
                        D.fail "skill has no instances"
            )


rootLangDecoder : D.Decoder (Dict String String)
rootLangDecoder =
    filteredJsons (String.contains "localization/text_ui_")
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


commonLootDecoder =
    P.requiredAt [ "$", "Name" ] D.string
        >> P.requiredAt [ "$", "UIName" ] D.string
        >> P.optionalAt [ "$", "LevelPrereq" ] (intString |> D.map Just) Nothing
        >> P.requiredAt [ "$", "Keywords" ] csStrings
        >> P.optionalAt [ "$", "ImplicitAffixes" ] csStrings []


uniqueLootDecoder =
    commonLootDecoder
        >> P.optionalAt [ "$", "DefaultAffixes" ] csStrings []
        >> P.optionalAt [ "$", "Lore" ] (D.string |> D.map Just) Nothing


{-| Decode a comma-separated list of strings

data's a bit sloppy, sometimes has empty strings - remove them

-}
csStrings : D.Decoder (List String)
csStrings =
    D.string
        |> D.map
            (String.split ","
                >> List.map String.trim
                >> List.filter ((/=) "")
            )


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


boolString : D.Decoder Bool
boolString =
    D.string |> D.andThen (\s -> s /= "0" && s /= "" |> D.succeed)


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
