module Lang exposing (Lang, decoder, get, mget)

import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type Lang
    = Lang (Dict String String)


get : Lang -> String -> Maybe String
get (Lang d) key =
    Dict.get (String.toLower key) d


mget : Lang -> Maybe String -> Maybe String
mget lang =
    Maybe.andThen (get lang)


decoder : D.Decoder Lang
decoder =
    Util.filteredJsons (String.contains "text_ui_")
        |> D.map (List.map (Tuple.second >> D.decodeValue langDecoder))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map
            (List.concat
                >> List.map (Tuple.mapFirst (\k -> "@" ++ String.toLower k))
                >> Dict.fromList
                >> Lang
            )


langDecoder : D.Decoder (List ( String, String ))
langDecoder =
    D.map2 Tuple.pair
        -- TODO: the js xml->json transform should make these fields more consistent
        (D.oneOf
            [ D.field "KEY" D.string

            -- czech
            , D.field "Key" D.string
            ]
        )
        (D.oneOf
            -- most languages
            [ D.field "TRANSLATED TEXT" D.string

            -- czech
            , D.field "Translated text" D.string

            -- french
            , D.field "ORIGINAL TEXT_1" D.string

            -- english
            , D.field "ORIGINAL TEXT" D.string
            ]
        )
        |> D.maybe
        |> D.list
        |> D.map (List.filterMap identity)
        |> D.field "Sheet1"
