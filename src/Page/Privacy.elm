module Page.Privacy exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


view : List (Html msg)
view =
    [ p [] [ text "WolcenDB privacy policy" ]
    , p []
        [ text "We use "
        , a [ href "https://analytics.google.com" ] [ text "Google Analytics" ]
        , text " to see which pages on WolcenDB are most popular. If this bothers you, feel free to "
        , a [ href "https://tools.google.com/dlpage/gaoptout" ] [ text "opt-out of Google Analytics" ]
        , text "."
        ]
    , p [] [ text "Otherwise, we don't use your data at all" ]
    , p [] [ text "Like, we don't even have logins here" ]
    ]
