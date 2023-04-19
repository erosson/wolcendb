module Datamine.UniqueItem exposing
    ( UItem
    , UniqueItem(..)
    , baseEffects
    , decoder
    , defaultAffixes
    , defaultEffects
    , img
    , implicitAffixes
    , implicitEffects
    , isNonmax
    , keywords
    , label
    , levelPrereq
    , lore
    , name
    , nonmaxName
    , source
    )

import Datamine.Affix as Affix exposing (Affixes, MagicAffix)
import Datamine.Cosmetic as Cosmetic
import Datamine.NormalItem as NormalItem exposing (Item)
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Lang exposing (Lang)
import Result.Extra
import Set exposing (Set)


type UniqueItem
    = UWeapon UniqueWeapon
    | UShield UniqueShield
    | UArmor UniqueArmor
    | UAccessory UniqueAccessory


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
    , damage : Maybe (Util.Range Int)
    , resourceGain : Maybe (Util.Range Int)
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
    , shieldResistance : Maybe (Util.Range Int)
    , shieldBlockChance : Maybe (Util.Range Int)
    , shieldBlockEfficiency : Maybe (Util.Range Int)
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
    , healthBonus : Maybe (Util.Range Int)
    , forceShield : Maybe (Util.Range Int)
    , allResistance : Maybe (Util.Range Int)
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


type alias Datamine d =
    { d
        | cosmeticWeaponDescriptors : Dict String Cosmetic.CCosmeticWeaponDescriptor
        , cosmeticTransferTemplates : Dict String Cosmetic.CCosmeticTransferTemplate
    }


img : Datamine d -> UniqueItem -> Maybe String
img dm uitem =
    Maybe.map String.toLower <|
        case uitem of
            UAccessory item ->
                Util.imghost ++ "/armors/" ++ item.hudPicture |> Just

            UArmor item ->
                Dict.get (Maybe.withDefault "" item.attachmentName |> String.toLower) dm.cosmeticTransferTemplates
                    |> Maybe.map (\t -> Util.imghost ++ "/armors/" ++ t.hudPicture)

            _ ->
                Dict.get (name uitem |> String.toLower) dm.cosmeticWeaponDescriptors
                    |> Maybe.map (\t -> Util.imghost ++ "/weapons/" ++ t.hudPicture)


{-| High-level uniques are named after the original, with "\_max" at the end
-}
nonmaxName : UniqueItem -> String
nonmaxName =
    name >> String.replace "_max" "" >> String.replace "_ultimate" ""


isNonmax : UniqueItem -> Bool
isNonmax uitem =
    name uitem == nonmaxName uitem


label : Lang -> UniqueItem -> Maybe String
label lang =
    uiName >> Lang.get lang


uiName : UniqueItem -> String
uiName nitem =
    case nitem of
        UWeapon i ->
            i.uiName

        UShield i ->
            i.uiName

        UArmor i ->
            i.uiName

        UAccessory i ->
            i.uiName


keywords : UniqueItem -> List String
keywords uitem =
    case uitem of
        UWeapon i ->
            i.keywords

        UShield i ->
            i.keywords

        UArmor i ->
            i.keywords

        UAccessory i ->
            i.keywords


source : UniqueItem -> Source
source uitem =
    case uitem of
        UWeapon i ->
            i.source

        UShield i ->
            i.source

        UArmor i ->
            i.source

        UAccessory i ->
            i.source


lore : Lang -> UniqueItem -> Maybe String
lore lang n =
    Lang.mget lang <|
        case n of
            UWeapon i ->
                i.lore

            UShield i ->
                i.lore

            UArmor i ->
                i.lore

            UAccessory i ->
                i.lore


implicitAffixes : UniqueItem -> List String
implicitAffixes uitem =
    case uitem of
        UWeapon i ->
            i.implicitAffixes

        UShield i ->
            i.implicitAffixes

        UArmor i ->
            i.implicitAffixes

        UAccessory i ->
            i.implicitAffixes


implicitEffects : Lang -> Affix.Datamine d -> UniqueItem -> List String
implicitEffects lang dm =
    implicitAffixes
        >> Affix.getNonmagicIds dm
        >> List.concatMap .effects
        -- >> List.filterMap (Affix.formatEffect dm)
        >> List.map (Affix.formatEffect lang >> Maybe.withDefault "???")


defaultAffixes : UniqueItem -> List String
defaultAffixes uitem =
    case uitem of
        UWeapon i ->
            i.defaultAffixes

        UShield i ->
            i.defaultAffixes

        UArmor i ->
            i.defaultAffixes

        UAccessory i ->
            i.defaultAffixes


defaultEffects : Lang -> Affix.Datamine d -> UniqueItem -> List String
defaultEffects lang dm =
    defaultAffixes
        >> Affix.getNonmagicIds dm
        >> List.concatMap .effects
        -- >> List.filterMap (Affix.formatEffect dm)
        >> List.map (Affix.formatEffect lang >> Maybe.withDefault "???")


baseEffects : Affix.Datamine d -> UniqueItem -> List String
baseEffects dm uitem =
    case uitem of
        UWeapon w ->
            [ w.damage |> Maybe.andThen formatStat |> Maybe.map (\s -> "Damage: " ++ s)
            , w.resourceGain |> Maybe.andThen formatStat |> Maybe.map (\s -> "Resource: " ++ s)
            ]
                |> List.filterMap identity

        UShield w ->
            [ w.shieldResistance |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ " All Resistance")
            , w.shieldBlockChance |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ "% Block Chance")
            , w.shieldBlockEfficiency |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ "% Block Efficiency")
            ]
                |> List.filterMap identity

        UArmor a ->
            [ a.healthBonus |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ " Health")
            , a.forceShield |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ " Force Shield")
            , a.allResistance |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ " All Resistance")
            ]
                |> List.filterMap identity

        _ ->
            []


formatStat : Util.Range Int -> Maybe String
formatStat r =
    if r.min == r.max then
        if r.min == 0 then
            Nothing

        else
            Just <| String.fromInt r.min

    else
        Just <| String.fromInt r.min ++ "-" ++ String.fromInt r.max


name : UniqueItem -> String
name n =
    case n of
        UWeapon i ->
            i.name

        UShield i ->
            i.name

        UArmor i ->
            i.name

        UAccessory i ->
            i.name


levelPrereq : UniqueItem -> Maybe Int
levelPrereq n =
    case n of
        UWeapon i ->
            i.levelPrereq

        UShield i ->
            i.levelPrereq

        UArmor i ->
            i.levelPrereq

        UAccessory i ->
            i.levelPrereq


decoder : D.Decoder (List UniqueItem)
decoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeapons.json"
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeaponsMax.json"
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeaponsMaxMax.json"

        -- older versions of wolcen don't have ultimate-tier unique weapons
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueWeaponsUltimate.json" |> D.maybe |> D.map (Maybe.withDefault [])
        , uniqueWeaponsDecoder "Game/Umbra/Loot/Weapons/UniqueShields.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/Armors_uniques.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniqueArmorsMax.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniqueArmorsMaxMax.json"
        , uniqueArmorsDecoder "Game/Umbra/Loot/Armors/UniquesAccessories.json"
        ]


uniqueWeaponsDecoder : String -> D.Decoder (List UniqueItem)
uniqueWeaponsDecoder file =
    D.at [ "$", "Keywords" ] Util.csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\kws ->
                if Set.member "shield" kws then
                    D.succeed UniqueShield
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "ShieldResistanceMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "ShieldResistanceMax" ] Util.intString)
                            )
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "ShieldBlockChanceMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "ShieldBlockChanceMax" ] Util.intString)
                            )
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "ShieldBlockEfficiencyMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "ShieldBlockEfficiencyMax" ] Util.intString)
                            )
                        |> D.map UShield

                else
                    D.succeed UniqueWeapon
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "LowDamage_Max" ] Util.intString)
                                (D.maybe <| D.at [ "$", "HighDamage_Max" ] Util.intString)
                            )
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "ResourceGain_Min" ] Util.intString)
                                (D.maybe <| D.at [ "$", "ResourceGain_Max" ] Util.intString)
                            )
                        |> D.map UWeapon
            )
        |> D.list
        |> D.field "Item"
        |> Util.single
        |> D.at [ file, "MetaData", "Weapons" ]


uniqueArmorsDecoder : String -> D.Decoder (List UniqueItem)
uniqueArmorsDecoder file =
    D.at [ "$", "Keywords" ] Util.csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\kws ->
                if Set.member "accessory" kws then
                    D.succeed UniqueAccessory
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map UAccessory

                else
                    D.succeed UniqueArmor
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> P.optionalAt [ "$", "AttachmentName" ] (D.string |> D.map Just) Nothing
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "HealthBonusMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "HealthBonusMax" ] Util.intString)
                            )
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "ForceShieldMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "ForceShieldMax" ] Util.intString)
                            )
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "AllResistanceMin" ] Util.intString)
                                (D.maybe <| D.at [ "$", "AllResistanceMax" ] Util.intString)
                            )
                        |> D.map UArmor
            )
        |> D.list
        |> D.field "Item"
        |> Util.single
        |> D.at [ file, "MetaData", "Armors" ]


uniqueLootDecoder =
    NormalItem.commonLootDecoder
        >> P.optionalAt [ "$", "DefaultAffixes" ] Util.csStrings []
        >> P.optionalAt [ "$", "Lore" ] (D.string |> D.map Just) Nothing
