module Datamine.Lang exposing (Datamine, decoder, get, mget)

import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Datamine d =
    { d | en : Dict String String }


get : Datamine d -> String -> Maybe String
get dm key =
    Dict.get (String.toLower key) dm.en


mget : Datamine d -> Maybe String -> Maybe String
mget dm =
    Maybe.andThen (get dm)


decoder : D.Decoder (Dict String String)
decoder =
    Util.filteredJsons (String.contains "localization/text_ui_")
        |> D.map (List.map (Tuple.second >> D.decodeValue langDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map
            (List.concat
                >> List.map (Tuple.mapFirst (\k -> "@" ++ String.toLower k))
                >> Dict.fromList
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
