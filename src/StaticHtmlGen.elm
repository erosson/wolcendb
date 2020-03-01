module StaticHtmlGen exposing (main)

import Browser
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Main


main =
    Browser.element
        { view = Main.viewBody >> div [ id "root" ]
        , init = Main.initStatic
        , update = Main.update
        , subscriptions = always Sub.none
        }
