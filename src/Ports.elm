port module Ports exposing (..)

{-| -}

import Json.Decode as D


type alias LoadAssets =
    { searchIndex : D.Value, datamine : D.Value }


{-| Load searchindex and datamine asynchronously
-}
port loadAssets : (LoadAssets -> msg) -> Sub msg


{-| Tell analytics when the url changes
-}
port urlChange : { route : String, path : String, query : Maybe String } -> Cmd msg
