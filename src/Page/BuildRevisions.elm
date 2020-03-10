module Page.BuildRevisions exposing (view)

import Datamine exposing (Datamine)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)


view : Datamine -> { m | route : Maybe Route, buildRevisions : List String } -> List (Html msg)
view dm m =
    let
        options : Route.Options
        options =
            Route.toMOptions m.route
    in
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.BuildRevisions ] [ text "Build Revisions" ]
        ]
    , p [] [ text "View WolcenDB with data exported from older Wolcen build revisions." ]
    , div [ class "list-group" ]
        (m.buildRevisions
            |> List.reverse
            |> List.map
                (\r ->
                    a
                        [ class "list-group-item list-group-item-action"
                        , classList [ ( "active", Just r == options.revision ) ]
                        , Route.hrefOptions { options | revision = Just r } Route.Home
                        ]
                        [ text r ]
                )
            |> (::)
                (a
                    [ class "list-group-item list-group-item-action"
                    , classList [ ( "active", Nothing == options.revision ) ]
                    , Route.hrefOptions { options | revision = Nothing } Route.Home
                    ]
                    [ i [] [ text "Latest revision" ] ]
                )
        )
    ]
