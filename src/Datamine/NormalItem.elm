module Datamine.NormalItem exposing
    ( Item
    , NormalItem(..)
    , baseEffects
    , commonLootDecoder
    , decoder
    , implicitAffixes
    , implicitEffects
    , keywords
    , label
    , levelPrereq
    , name
    , possibleAffixes
    , source
    )

import Datamine.Affix as Affix exposing (Affixes, MagicAffix)
import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra
import Set exposing (Set)


type NormalItem
    = NWeapon Weapon
    | NShield Shield
    | NArmor Armor
    | NAccessory Accessory


type alias Weapon =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , damage : Maybe (Util.Range Int)
    }


type alias Shield =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , shieldResistance : Maybe (Util.Range Int)
    , shieldBlockChance : Maybe (Util.Range Int)
    , shieldBlockEfficiency : Maybe (Util.Range Int)
    }


type alias Armor =
    { source : Source
    , name : String
    , uiName : String
    , levelPrereq : Maybe Int
    , keywords : List String
    , implicitAffixes : List String
    , attachmentName : String
    , healthBonus : Maybe (Util.Range Int)
    , forceShield : Maybe (Util.Range Int)
    , allResistance : Maybe (Util.Range Int)
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


label : Lang.Datamine d -> NormalItem -> Maybe String
label dm =
    uiName >> Lang.get dm


uiName : NormalItem -> String
uiName nitem =
    case nitem of
        NWeapon i ->
            i.uiName

        NShield i ->
            i.uiName

        NArmor i ->
            i.uiName

        NAccessory i ->
            i.uiName


keywords : NormalItem -> List String
keywords nitem =
    case nitem of
        NWeapon i ->
            i.keywords

        NShield i ->
            i.keywords

        NArmor i ->
            i.keywords

        NAccessory i ->
            i.keywords


source : NormalItem -> Source
source nitem =
    case nitem of
        NWeapon i ->
            i.source

        NShield i ->
            i.source

        NArmor i ->
            i.source

        NAccessory i ->
            i.source


implicitAffixes : NormalItem -> List String
implicitAffixes nitem =
    case nitem of
        NWeapon i ->
            i.implicitAffixes

        NShield i ->
            i.implicitAffixes

        NArmor i ->
            i.implicitAffixes

        NAccessory i ->
            i.implicitAffixes


implicitEffects : Affix.Datamine d -> NormalItem -> List String
implicitEffects dm =
    implicitAffixes
        >> Affix.getNonmagicIds dm
        >> List.concatMap .effects
        >> List.filterMap (Affix.formatEffect dm)


baseEffects : Affix.Datamine d -> NormalItem -> List String
baseEffects dm nitem =
    case nitem of
        NWeapon w ->
            [ w.damage |> Maybe.andThen formatStat |> Maybe.map (\s -> "Damage: " ++ s)
            ]
                |> List.filterMap identity

        NShield w ->
            [ w.shieldResistance |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ " All Resistance")
            , w.shieldBlockChance |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ "% Block Chance")
            , w.shieldBlockEfficiency |> Maybe.andThen formatStat |> Maybe.map (\s -> s ++ "% Block Efficiency")
            ]
                |> List.filterMap identity

        NArmor a ->
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


name : NormalItem -> String
name n =
    case n of
        NWeapon i ->
            i.name

        NShield i ->
            i.name

        NArmor i ->
            i.name

        NAccessory i ->
            i.name


levelPrereq : NormalItem -> Maybe Int
levelPrereq n =
    case n of
        NWeapon i ->
            i.levelPrereq

        NShield i ->
            i.levelPrereq

        NArmor i ->
            i.levelPrereq

        NAccessory i ->
            i.levelPrereq


type alias Datamine d =
    Lang.Datamine { d | affixes : Affixes }


{-| Get all random magic affixes that this item can spawn.

Includes craftable and Sarisel affixes. These aren't part of the usual drop pool;
the caller's responsible for filtering them out.

I have no authoritative source for how this works. Below I've implemented my own theory -
seems to yield decent results, and I'm not aware of any counterexamples:

  - All of an affix's mandatory keywords must be present on an item.

  - If an affix has any optional keywords, at least one of them must be present on an item

  - Item level, like poe and diablo, depends on the monster level that drops the item.
    (Confirmed this by viewing my save file during offline play.) This is what
    an affix's level bounds are applied. Not done in this function.

  - At most one affix spawns for affixes with the same class, like poe modgroups.

-}
possibleAffixes : Datamine d -> NormalItem -> List MagicAffix
possibleAffixes dm item =
    let
        itemKeywords : Set String
        itemKeywords =
            Set.fromList <| keywords item

        isItemKeyword : String -> Bool
        isItemKeyword k =
            Set.member k itemKeywords
    in
    dm.affixes.magic
        |> List.filter
            (\affix ->
                List.all isItemKeyword affix.drop.mandatoryKeywords
                    && (List.any isItemKeyword affix.drop.optionalKeywords
                            || (affix.drop.optionalKeywords == [])
                       )
            )


decoder : D.Decoder (List NormalItem)
decoder =
    List.foldl (\di -> D.map (++) >> P.custom di)
        (D.succeed [])
        [ normalWeaponsDecoder "Game/Umbra/Loot/Weapons/Weapons.json"
        , normalWeaponsDecoder "Game/Umbra/Loot/Weapons/Shields.json"
        , normalArmorsDecoder "Game/Umbra/Loot/Armors/Armors.json"
        , normalArmorsDecoder "Game/Umbra/Loot/Armors/Accessories.json"
        ]


normalWeaponsDecoder : String -> D.Decoder (List NormalItem)
normalWeaponsDecoder file =
    D.at [ "$", "Keywords" ] Util.csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\kws ->
                if Set.member "shield" kws then
                    D.succeed Shield
                        |> P.custom (Source.decoder file "Item")
                        |> commonLootDecoder
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
                        |> D.map NShield

                else
                    D.succeed Weapon
                        |> P.custom (Source.decoder file "Item")
                        |> commonLootDecoder
                        |> P.custom
                            (D.map2 (Maybe.map2 Util.Range)
                                (D.maybe <| D.at [ "$", "LowDamage_Max" ] Util.intString)
                                (D.maybe <| D.at [ "$", "HighDamage_Max" ] Util.intString)
                            )
                        |> D.map NWeapon
            )
        |> D.list
        |> D.field "Item"
        |> Util.single
        |> D.at [ file, "MetaData", "Weapons" ]


normalArmorsDecoder : String -> D.Decoder (List NormalItem)
normalArmorsDecoder file =
    D.at [ "$", "Keywords" ] Util.csStrings
        |> D.map Set.fromList
        |> D.andThen
            (\kws ->
                if Set.member "accessory" kws then
                    D.succeed Accessory
                        |> P.custom (Source.decoder file "Item")
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "HUDPicture" ] D.string
                        |> D.map NAccessory

                else
                    D.succeed Armor
                        |> P.custom (Source.decoder file "Item")
                        |> commonLootDecoder
                        |> P.requiredAt [ "$", "AttachmentName" ] D.string
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
                        |> D.map NArmor
            )
        |> D.list
        |> D.field "Item"
        |> Util.single
        |> D.at [ file, "MetaData", "Armors" ]


commonLootDecoder =
    P.requiredAt [ "$", "Name" ] D.string
        >> P.requiredAt [ "$", "UIName" ] D.string
        >> P.optionalAt [ "$", "LevelPrereq" ] (Util.intString |> D.map Just) Nothing
        >> P.requiredAt [ "$", "Keywords" ] Util.csStrings
        >> P.optionalAt [ "$", "ImplicitAffixes" ] Util.csStrings []
