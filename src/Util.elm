module Util exposing (..)

import Set exposing (Set)


toggleSet : comparable -> Set comparable -> Set comparable
toggleSet k ks =
    if Set.member k ks then
        Set.remove k ks

    else
        Set.insert k ks


percent : Float -> String
percent p =
    (p * 100 |> String.fromFloat |> String.left 5) ++ "%"


formatFloat : Int -> Float -> String
formatFloat digits f =
    let
        s =
            String.fromFloat f
    in
    case String.split "." s of
        [ head, tail ] ->
            -- try to trim sigfigs a bit
            if String.length head >= digits then
                head

            else
                String.left (digits + 1) s

        [ _ ] ->
            -- no decimal, no problem
            s

        _ ->
            -- TODO french decimals? 1.234.567,89 vs 1,234,567.89
            s
