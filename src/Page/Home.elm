module Page.Home exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)


view : List (Html msg)
view =
    [ h1 [] [ text "WolcenDB" ]
    , ul []
        [ li [] [ a [ Route.href Route.Weapons ] [ text "Weapons" ], text "; ", a [ Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ] ]
        , li [] [ a [ Route.href Route.Shields ] [ text "Shields" ], text "; ", a [ Route.href Route.UniqueShields ] [ text "Unique Shields" ] ]
        , li [] [ a [ Route.href Route.Armors ] [ text "Armors" ], text "; ", a [ Route.href Route.UniqueArmors ] [ text "Unique Armors" ] ]
        , li [] [ a [ Route.href Route.Accessories ] [ text "Accessories" ], text "; ", a [ Route.href Route.UniqueAccessories ] [ text "Unique Accessories" ] ]
        ]
    ]
