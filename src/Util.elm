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
