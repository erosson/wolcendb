module Datamine.UniqueItem exposing
    ( UItem
    , UniqueItem(..)
    , decoder
    , defaultAffixes
    , defaultEffects
    , implicitAffixes
    , implicitEffects
    , keywords
    , label
    , lore
    , name
    , source
    )

import Datamine.Affix as Affix exposing (Affixes, MagicAffix)
import Datamine.Lang as Lang
import Datamine.NormalItem as NormalItem exposing (Item)
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
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
    , damage : Util.Range (Maybe Int)
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


label : Lang.Datamine d -> UniqueItem -> Maybe String
label dm =
    uiName >> Lang.get dm


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


lore : Lang.Datamine d -> UniqueItem -> Maybe String
lore dm n =
    Lang.mget dm <|
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


implicitEffects : Affix.Datamine d -> UniqueItem -> List String
implicitEffects dm =
    implicitAffixes
        >> Affix.getNonmagicIds dm
        >> List.concatMap .effects
        >> List.filterMap (Affix.formatEffect dm)


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


defaultEffects : Affix.Datamine d -> UniqueItem -> List String
defaultEffects dm =
    defaultAffixes
        >> Affix.getNonmagicIds dm
        >> List.concatMap .effects
        >> List.filterMap (Affix.formatEffect dm)


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


decoder : D.Decoder (List UniqueItem)
decoder =
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
    D.at [ "$", "Keywords" ] Util.csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\kws ->
                if Set.member "shield" kws then
                    D.succeed UniqueShield
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> D.map UShield

                else
                    D.succeed UniqueWeapon
                        |> P.custom (Source.decoder file "Item")
                        |> uniqueLootDecoder
                        |> P.custom
                            (D.succeed Util.Range
                                |> P.optionalAt [ "$", "LowDamage_Max" ] (Util.intString |> D.map Just) Nothing
                                |> P.optionalAt [ "$", "HighDamage_Max" ] (Util.intString |> D.map Just) Nothing
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
