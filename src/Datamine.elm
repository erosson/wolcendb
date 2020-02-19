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
    , Socket(..)
    , Source
    , SourceNode
    , SourceNodeChildren(..)
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
    , gems : List Gem
    , en : Dict String String
    , lootByName : Dict String NormalItem
    , uniqueLootByName : Dict String UniqueItem
    , skillsByUid : Dict String Skill
    , skillASTsByName : Dict String SkillAST
    , skillVariantsByUid : Dict String SkillVariant
    , skillASTVariantsByUid : Dict String SkillASTVariant
    , gemsByName : Dict String Gem
    , nonmagicAffixesById : Dict String NonmagicAffix
    , magicAffixesById : Dict String MagicAffix
    }


type alias RawDatamine =
    { loot : List NormalItem
    , uniqueLoot : List UniqueItem
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : Affixes
    , cosmeticTransferTemplates : Dict String CCosmeticTransferTemplate
    , cosmeticWeaponDescriptors : Dict String CCosmeticWeaponDescriptor
    , gems : List Gem
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
    , gems = raw.gems
    , en = raw.en
    , lootByName = raw.loot |> Dict.Extra.fromListBy (nitemName >> String.toLower)
    , uniqueLootByName = raw.uniqueLoot |> Dict.Extra.fromListBy (uitemName >> String.toLower)
    , skillsByUid = raw.skills |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , skillASTsByName = raw.skillASTs |> Dict.Extra.fromListBy (.name >> String.toLower)
    , skillVariantsByUid = raw.skills |> List.concatMap .variants |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , skillASTVariantsByUid = raw.skillASTs |> List.concatMap .variants |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , gemsByName = raw.gems |> Dict.Extra.fromListBy (.name >> String.toLower)
    , nonmagicAffixesById = raw.affixes.nonmagic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
    , magicAffixesById = raw.affixes.magic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
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


type alias Source =
    { file : String, node : SourceNode }


type alias SourceNode =
    { attrs : List ( String, String )
    , children : SourceNodeChildren
    , tag : String
    }


type SourceNodeChildren
    = SourceNodeChildren (List SourceNode)


type alias Weapon =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , damage : Range (Maybe Int)
    }


type alias Shield =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    }


type alias Armor =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , attachmentName : String
    }


type alias Accessory =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , hudPicture : String
    }


type alias Item i =
    { i
        | source : Source
        , name : String
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
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , damage : Range (Maybe Int)
    }


type alias UniqueShield =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    }


type alias UniqueArmor =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , defaultAffixes : List String
    , lore : Maybe String
    , attachmentName : Maybe String
    }


type alias UniqueAccessory =
    { source : Source
    , name : String
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
    { source : Source
    , uid : String
    , uiName : String
    , hudPicture : String
    , lore : Maybe String
    , keywords : List String
    , variants : List SkillVariant
    }


type alias SkillVariant =
    { source : Source
    , uid : String
    , uiName : String
    , lore : Maybe String
    }


type alias SkillAST =
    { source : Source
    , name : String
    , variants : List SkillASTVariant
    }


type alias SkillASTVariant =
    { source : Source
    , uid : String
    , level : Int
    , cost : Int
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
    , stats : List ( String, Range Float )
    }


type alias Gem =
    { source : Source
    , name : String
    , uiName : String
    , hudPicture : String
    , levelPrereq : Int
    , gemTier : Int
    , dropLevel : Range Int
    , keywords : List String
    , effects : List ( Socket, String )
    }


type Socket
    = Offensive Int
    | Defensive Int
    | Support Int


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
    List.filterMap (\id -> Dict.get id dm.nonmagicAffixesById)


magicAffixes : Datamine -> List String -> List MagicAffix
magicAffixes dm =
    List.filterMap (\id -> Dict.get id dm.magicAffixesById)


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
        |> P.custom gemsDecoder
        |> P.custom rootLangDecoder
        |> D.map index


gemsDecoder : D.Decoder (List Gem)
gemsDecoder =
    let
        file =
            "Game/Umbra/Loot/Gems/gems.json"
    in
    D.succeed Gem
        |> P.custom (sourceDecoder file "Gem")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "HUDPicture" ] D.string
        |> P.requiredAt [ "$", "LevelPrereq" ] intString
        |> P.requiredAt [ "$", "GemTier" ] intString
        |> P.custom
            (D.succeed Range
                |> P.requiredAt [ "$", "MinDropLevel" ] intString
                |> P.requiredAt [ "$", "MaxDropLevel" ] intString
            )
        |> P.requiredAt [ "$", "Keywords" ] csStrings
        |> P.requiredAt [ "SupportedMagicEffects" ] gemEffectsDecoder
        |> D.list
        |> D.at [ file, "Gems", "Gem" ]


gemEffectsDecoder : D.Decoder (List ( Socket, String ))
gemEffectsDecoder =
    D.keyValuePairs (D.at [ "$", "Id" ] D.string |> single)
        -- |> D.andThen single_
        |> D.map
            (List.map
                (\( key, id ) ->
                    case key |> String.split "_" of
                        [ type_, index_ ] ->
                            case ( type_, String.toInt index_ ) of
                                ( "Offensive", Just i ) ->
                                    Ok ( Offensive i, id )

                                ( "Defensive", Just i ) ->
                                    Ok ( Defensive i, id )

                                ( "Support", Just i ) ->
                                    Ok ( Support i, id )

                                _ ->
                                    Err <| "unknown gem-effect key: " ++ key

                        _ ->
                            Err <| "unknown gem-effect key: " ++ key
                )
                >> Result.Extra.combine
            )
        |> resultDecoder
        |> single



-- |> D.list


normalItemsDecoder : D.Decoder (List NormalItem)
normalItemsDecoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ normalWeaponsDecoder "Game/Umbra/Loot/Weapons/Weapons.json"
        , normalWeaponsDecoder "Game/Umbra/Loot/Weapons/Shields.json"
        , normalArmorsDecoder "Game/Umbra/Loot/Armors/Armors.json"
        , normalArmorsDecoder "Game/Umbra/Loot/Armors/Accessories.json"
        ]


normalWeaponsDecoder : String -> D.Decoder (List NormalItem)
normalWeaponsDecoder file =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "shield" keywords then
                    D.succeed Shield
                        |> P.custom (sourceDecoder file "Item")
                        |> commonLootDecoder
                        |> D.map NShield

                else
                    D.succeed Weapon
                        |> P.custom (sourceDecoder file "Item")
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
        |> D.at [ file, "MetaData", "Weapons" ]


normalArmorsDecoder : String -> D.Decoder (List NormalItem)
normalArmorsDecoder file =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "accessory" keywords then
                    D.succeed Accessory
                        |> P.custom (sourceDecoder file "Item")
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map NAccessory

                else
                    D.succeed Armor
                        |> P.custom (sourceDecoder file "Item")
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "AttachmentName" ] D.string
                        |> D.map NArmor
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ file, "MetaData", "Armors" ]


uniqueItemsDecoder : D.Decoder (List UniqueItem)
uniqueItemsDecoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeapons.json"
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeaponsMax.json"
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeaponsMaxMax.json"
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueShields.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/Armors_uniques.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniqueArmorsMax.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniqueArmorsMaxMax.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniquesAccessories.json"
        ]


uniqueWeaponsDecoder : String -> D.Decoder (List UniqueItem)
uniqueWeaponsDecoder file =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "shield" keywords then
                    D.succeed UniqueShield
                        |> P.custom (sourceDecoder file "Item")
                        |> uniqueLootDecoder
                        |> D.map UShield

                else
                    D.succeed UniqueWeapon
                        |> P.custom (sourceDecoder file "Item")
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
        |> D.at [ file, "MetaData", "Weapons" ]


uniqueArmorsDecoder : String -> D.Decoder (List UniqueItem)
uniqueArmorsDecoder file =
    D.at [ "$", "Keywords" ] csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\keywords ->
                if Set.member "accessory" keywords then
                    D.succeed UniqueAccessory
                        |> P.custom (sourceDecoder file "Item")
                        |> uniqueLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map UAccessory

                else
                    D.succeed UniqueArmor
                        |> P.custom (sourceDecoder file "Item")
                        |> uniqueLootDecoder
                        |> P.optionalAt [ "$", "AttachmentName" ] (D.string |> D.map Just) Nothing
                        |> D.map UArmor
            )
        |> D.list
        |> D.field "Item"
        |> single
        |> D.at [ file, "MetaData", "Armors" ]


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
                    || String.contains "/Loot/MagicEffects/Affixes/Armors_Weapons/AffixesGems" f
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
nonmagicAffixesDecoder file =
    D.succeed NonmagicAffix
        |> P.custom (sourceDecoder file "Affix")
        |> P.requiredAt [ "$", "AffixId" ] D.string
        |> P.custom (magicEffectDecoder |> D.list |> D.at [ "MagicEffect" ])
        |> D.list
        |> D.at [ "MetaData", "Affix" ]


magicAffixesDecoder : String -> D.Decoder (List MagicAffix)
magicAffixesDecoder file =
    D.succeed MagicAffix
        |> P.custom (sourceDecoder file "Affix")
        |> P.requiredAt [ "$", "AffixId" ] D.string
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
        |> D.map (List.map (\( f, d ) -> D.decodeValue (skillASTDecoder f) d))
        -- |> D.map (List.filterMap Result.toMaybe)
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder


skillASTDecoder : String -> D.Decoder SkillAST
skillASTDecoder file =
    D.succeed SkillAST
        |> P.custom (sourceDecoder file "AST")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.custom
            (D.succeed SkillASTVariant
                |> P.custom (sourceDecoder file "SkillVariant")
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
        |> D.map (List.map (\( f, d ) -> D.decodeValue (skillDecoder f) d))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> resultDecoder


type alias SkillDecoder =
    { source : Source
    , uid : String
    , uiName : Maybe String
    , hudPicture : Maybe String
    , lore : Maybe String
    , keywords : Maybe (List String)
    }


skillDecoder : String -> D.Decoder Skill
skillDecoder file =
    -- The first skill entry is the skill itself; all following entries are its variants (d3 "runes").
    -- The XML decoding is a bit awkward because lists must be homogeneous. Decode them as an
    -- intermediate structure, SkillDecoder, and transform them to Skills/SkillVariants later.
    D.succeed SkillDecoder
        |> P.custom (sourceDecoder file "Skill")
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
                                    { source = s.source
                                    , uid = s.uid
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
                                                            { source = v.source
                                                            , uid = v.uid
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


sourceDecoder : String -> String -> D.Decoder Source
sourceDecoder file tag =
    D.map (Source file)
        (sourceNodeDecoder |> D.map (\n -> n tag))


{-| Intermediate data structure for decoding source nodes, as used in `/source/xxx` urls

Game files are originally in xml.
We convert that to json, and `Datamine` parses the json - Elm's much faster at parsing json than xml.
We convert the json back to xml-ish nodes for presentation.

Seems needlessly complex - but Elm xml parsing really was slow, and source excerpts are a pretty cool feature!

-}
type
    DecodingSourceNode
    -- Child nodes; most keys. Tag names are the json key, added afterward
    = DecodingSourceNode (List (String -> SourceNode))
      -- Attributes, the "$"
    | DecodingAttrs (List ( String, String ))
      -- a single <TAG /> has json {... TAG: [""] ...}, and decodes to this. Not sure what's going on here.
    | DecodingEmptyNode String


sourceNodeDecoder : D.Decoder (String -> SourceNode)
sourceNodeDecoder =
    D.map2 SourceNode
        (D.keyValuePairs D.string |> D.field "$" |> D.maybe |> D.map (Maybe.withDefault []))
        (D.keyValuePairs
            (D.lazy
                (\_ ->
                    D.oneOf
                        [ D.list sourceNodeDecoder |> D.map DecodingSourceNode
                        , single D.string |> D.map DecodingEmptyNode

                        -- this should only run once, for the "$" key - attributes
                        , D.keyValuePairs D.string |> D.map DecodingAttrs
                        ]
                )
            )
            |> D.map
                (List.filter (\( k, v ) -> k /= "$")
                    >> List.map
                        (\( k, mv ) ->
                            case mv of
                                DecodingSourceNode nodes ->
                                    nodes |> List.map (\n -> n k) |> Ok

                                DecodingEmptyNode "" ->
                                    Ok []

                                _ ->
                                    Err "decodeSourceNode fail"
                        )
                    >> Result.Extra.combine
                    >> Result.map (List.concat >> SourceNodeChildren)
                )
            |> resultDecoder
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
