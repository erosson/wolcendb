module Page.Changelog exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown


view : Datamine -> { m | changelog : String } -> List (Html msg)
view dm m =
    [ small []
        [ p []
            [ text "WolcenDB based on Wolcen build revision "
            , code [] [ text dm.revision.buildRevision ]
            , text ", created at "
            , code [] [ text dm.revision.date ]
            ]
        ]
    , m.changelog
        |> String.split "---"
        |> List.drop 1
        |> String.join "---"
        |> Markdown.toHtml []
    ]
