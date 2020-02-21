module Datamine.NormalItem exposing
    ( Item
    , NormalItem(..)
    , commonLootDecoder
    , decoder
    , implicitAffixes
    , implicitEffects
    , keywords
    , label
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
    , damage : Util.Range (Maybe Int)
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


type alias Datamine d =
    Lang.Datamine { d | affixes : Affixes }


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
possibleAffixes : Datamine d -> Item i -> List MagicAffix
possibleAffixes dm item =
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
                        |> D.map NShield

                else
                    D.succeed Weapon
                        |> P.custom (Source.decoder file "Item")
                        |> commonLootDecoder
                        |> P.custom
                            (D.succeed Util.Range
                                |> P.optionalAt [ "$", "LowDamage_Max" ] (Util.intString |> D.map Just) Nothing
                                |> P.optionalAt [ "$", "HighDamage_Max" ] (Util.intString |> D.map Just) Nothing
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
