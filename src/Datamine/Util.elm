module Datamine.Util exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P
import Util


type alias Range a =
    { min : a, max : a }


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


nonemptyString : D.Decoder (Maybe String)
nonemptyString =
    D.string
        |> D.map
            (\s ->
                if s == "" then
                    Nothing

                else
                    Just s
            )


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


filteredJsons : (String -> Bool) -> D.Decoder (List ( String, D.Value ))
filteredJsons pred =
    D.keyValuePairs D.value
        |> D.map (List.filter (Tuple.first >> pred))


formatEffectStat : ( Int, ( String, Range Float ) ) -> String -> String
formatEffectStat ( index, ( name, stat ) ) =
    let
        val =
            --(if stat.min > 0 && stat.max > 0 then
            --    "+"
            --
            -- else
            --    ""
            --)
            -- ++
            if stat.min == stat.max then
                Util.formatFloat 5 stat.min

            else
                "(" ++ Util.formatFloat 5 stat.min ++ "-" ++ Util.formatFloat 5 stat.max ++ ")"

        suffix =
            if String.contains "percent" (String.toLower name) then
                "%"

            else
                ""
    in
    String.replace ("%" ++ String.fromInt (index + 1)) <| val ++ suffix


imghost : String
imghost =
    String.toLower "https://img-wolcendb.erosson.org/Game/Libs/UI/u_resources"
