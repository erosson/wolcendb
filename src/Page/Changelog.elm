module Page.Changelog exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import Route exposing (Route)


view : { m | changelog : String } -> List (Html msg)
view m =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Changelog ] [ text "Changelog" ]
        ]
    , small []
        [ p []
            [ text "Contact the developer: "
            , a [ href "https://keybase.io/erosson", target "_blank" ] [ text "Keybase chat" ]
            , text ", "
            , a [ href "https://github.com/erosson/wolcendb/issues/new", target "_blank" ] [ text "Github issue" ]
            , text ", or "
            , a [ href "https://www.reddit.com/message/compose/?to=kawaritai&subject=WolcenDB", target "_blank" ] [ text "Reddit" ]
            , text "."
            ]
        ]
    , m.changelog
        |> String.split "---"
        |> List.drop 1
        |> String.join "---"
        |> Markdown.toHtml []
    ]
