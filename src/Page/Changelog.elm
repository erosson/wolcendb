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
            [ text "Contact the developer: "
            , a [ href "https://keybase.io/erosson", target "_blank" ] [ text "Keybase chat" ]
            , text ", "
            , a [ href "https://gitlab.com/erosson/wolcendb/issues/new", target "_blank" ] [ text "GitLab issue" ]
            , text ", or "
            , a [ href "https://www.reddit.com/message/compose/?to=kawaritai&subject=WolcenDB", target "_blank" ] [ text "Reddit" ]
            , text "."
            ]
        ]
    , small []
        [ p []
            [ text "Wolcen build revision "
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
