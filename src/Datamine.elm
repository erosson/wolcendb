module Datamine exposing (Datamine, Flag, decode)

import Dict exposing (Dict)
import Json.Decode as Json
import Xml.Decode as D


type alias Flag =
    Json.Value


type alias Datamine =
    { weapons : List Weapon
    , en : Dict String String
    }


type alias Weapon =
    { name : String
    , uiName : String
    , damage : Range (Maybe Int)
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
        (Json.field "Weapons" <| jsonXmlDecoder weaponsDecoder)
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



--D.map2 Tuple.pair
--    (D.succeed "key")
--    (D.succeed "val")
--    |> D.list
--    |> D.path [ "ExcelWorkbook", "Worksheet", "Row" ]


weaponsDecoder : D.Decoder (List Weapon)
weaponsDecoder =
    D.map4 Weapon
        (D.stringAttr "Name")
        (D.stringAttr "UIName")
        (D.map2 Range
            (D.maybe <| D.intAttr "LowDamage_Max")
            (D.maybe <| D.intAttr "HighDamage_Max")
        )
        (D.stringAttr "Keywords" |> D.map (String.split ","))
        |> D.list
        |> D.path [ "Weapons", "Item" ]
