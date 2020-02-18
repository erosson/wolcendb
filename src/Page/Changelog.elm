module Page.Changelog exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import View.Nav


view : { m | changelog : String } -> List (Html msg)
view m =
    [ div [ class "container" ]
        [ View.Nav.view
        , m.changelog
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml []
        ]
    ]
