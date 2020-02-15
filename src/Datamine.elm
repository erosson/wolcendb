module Datamine exposing (Datamine, Flag, decode)

import Dict exposing (Dict)
import Json.Decode as Json
import Xml.Decode as D


type alias Flag =
    Json.Value


type alias Datamine =
    { loot : Loot
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


decode : Flag -> Result String Datamine
decode =
    Json.decodeValue jsonDecoder
        >> Result.mapError Json.errorToString


jsonDecoder : Json.Decoder Datamine
jsonDecoder =
    Json.map2 Datamine
        (Json.map8 Loot
            (Json.field "Weapons" <| jsonXmlDecoder weaponsDecoder)
            (Json.field "Shields" <| jsonXmlDecoder shieldsDecoder)
            (Json.field "Armors" <| jsonXmlDecoder armorsDecoder)
            (Json.field "Accessories" <| jsonXmlDecoder accessoriesDecoder)
            (Json.field "UniqueWeapons" <| jsonXmlDecoder uniqueWeaponsDecoder)
            (Json.field "UniqueShields" <| jsonXmlDecoder uniqueShieldsDecoder)
            (Json.field "UniqueArmors" <| jsonXmlDecoder uniqueArmorsDecoder)
            (Json.field "UniqueAccessories" <| jsonXmlDecoder uniqueAccessoriesDecoder)
        )
        (Json.field "en" rootLangDecoder)


rootLangDecoder : Json.Decoder (Dict String String)
rootLangDecoder =
    Json.map Dict.fromList
        -- (Json.field "Loot" <| jsonXmlDecoder langDecoder)
        (Json.field "Loot" langDecoder)


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
