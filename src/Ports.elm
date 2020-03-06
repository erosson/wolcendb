port module Ports exposing (..)

{-| -}

import Json.Decode as D


type alias LoadAssets =
    { searchIndex : D.Value, datamine : D.Value }


{-| JS should replace this element-id with SSR content, if any
-}
port ssr : String -> Cmd msg


{-| Load searchindex and datamine asynchronously
-}
port loadAssets : (LoadAssets -> msg) -> Sub msg


type alias LoadAssetsProgress =
    { label : String, progress : Int, size : Int }


port loadAssetsProgress : (LoadAssetsProgress -> msg) -> Sub msg


port loadAssetsFailure : (String -> msg) -> Sub msg


{-| Tell analytics when the url changes
-}
port urlChange : { route : String, path : String, query : Maybe String } -> Cmd msg


{-| Send the server-side renderer a list of pages to prerender
-}
port ssrCliPages : List String -> Cmd msg


{-| Receive a render request for one page from the server-side renderer
-}
port ssrCliRender : (String -> msg) -> Sub msg
