module View.Skill exposing (img)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


img : { item | hudPicture : String } -> H.Attribute msg
img s =
    src <| "/static/datamine/Game/Libs/UI/u_resources/" ++ s.hudPicture
