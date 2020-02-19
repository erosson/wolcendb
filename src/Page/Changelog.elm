module Page.Changelog exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import View.Nav


view : { m | datamine : Datamine, changelog : String } -> List (Html msg)
view m =
    [ div [ class "container" ]
        [ View.Nav.view
        , small []
            [ p []
                [ text "WolcenDB based on Wolcen build revision "
                , code [] [ text m.datamine.revision.buildRevision ]
                , text ", created at "
                , code [] [ text m.datamine.revision.date ]
                ]
            ]
        , m.changelog
            |> String.split "---"
            |> List.drop 1
            |> String.join "---"
            |> Markdown.toHtml []
        ]
    ]
