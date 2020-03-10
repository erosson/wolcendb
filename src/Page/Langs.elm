module Page.Langs exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Markdown
import Route exposing (Route)


view : { m | route : Maybe Route, langs : List String } -> List (Html msg)
view m =
    let
        options : Route.Options
        options =
            Route.toMOptions m.route
    in
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
                    >> String.replace "_xml.pak" ""
                    >> String.replace "chineses" "chinese"
                )
            |> List.reverse
            |> List.map
                (\r ->
                    a
                        [ class "list-group-item list-group-item-action"
                        , classList [ ( "active", Just r == options.lang ) ]
                        , Route.hrefOptions { options | lang = Just r } Route.Home
                        ]
                        [ text r ]
                )
            |> (::)
                (a
                    [ class "list-group-item list-group-item-action"
                    , classList [ ( "active", Nothing == options.lang ) ]
                    , Route.hrefOptions { options | lang = Nothing } Route.Home
                    ]
                    [ i [] [ text "Default language" ] ]
                )
        )
    ]
