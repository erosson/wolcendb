module View.Nav exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)


view : Html msg
view =
    -- https://getbootstrap.com/docs/4.4/components/navbar/
    div [ class "navbar navbar-expand-sm navbar-light bg-light" ]
        [ a [ class "navbar-brand", href "/" ] [ text "WolcenDB" ]
        , button
            [ type_ "button"
            , class "navbar-toggler"
            , attribute "data-toggle" "collapse"
            , attribute "data-target" "navbarLinks"
            ]
            [ span [ class "navbar-toggler-icon" ] [] ]
        , div [ id "navbarLinks", class "collapse navbar-collapse" ]
            [ ul [ class "navbar-nav" ]
                []

            -- [ li [ class "nav-item" ] [ a [ class "nav-link", href "/#TODO" ] [ text "Simulator" ] ]
            ]
        ]
