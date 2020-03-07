module Page.Langs exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import Route exposing (Route)


view : { m | langs : List String } -> List (Html msg)
view m =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Langs ] [ text "Select Language" ]
        ]
    , p [] [ text "Translate all text exported from Wolcen, like skill/item names and affix text. Website text is not translated (yet), sorry." ]
    , p [] [ text "Beware: this feature is new to WolcenDB and still only ", code [] [ text "beta" ], text " quality. Expect bugs." ]
    , div [ class "list-group" ]
        (m.langs
            |> List.reverse
            |> List.map
                (String.toLower
                    >> String.replace "datamine/lang/" ""
                    >> String.replace "_xml.json" ""
                    >> String.replace "chineses" "chinese"
                )
            |> List.reverse
            |> List.map
                (\r ->
                    a
                        [ class "list-group-item list-group-item-action"
                        , target "_blank"
                        , href <| "/?lang=" ++ r
                        ]
                        [ text r ]
                )
        )
    ]
