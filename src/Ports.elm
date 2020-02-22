port module Ports exposing (urlChange)

{-| -}


{-| Tell analytics when the url changes
-}
port urlChange : { route : String, path : String, query : Maybe String } -> Cmd msg
