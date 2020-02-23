module Util exposing (..)

import Set exposing (Set)


toggleSet : comparable -> Set comparable -> Set comparable
toggleSet k ks =
    if Set.member k ks then
        Set.remove k ks

    else
        Set.insert k ks
