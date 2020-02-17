module Page.Weapons exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Nav


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Weapons ] [ text "Weapons" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "level" ]
                    , th [] [ text "damage" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (dm.loot.weapons
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ a [ Route.href <| Route.Weapon w.name ]
                                        [ Datamine.lang dm w.uiName |> Maybe.withDefault "???" |> text ]
                                    ]
                                , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt w.levelPrereq ]
                                , td []
                                    [ Maybe.Extra.unwrap "?" String.fromInt w.damage.min
                                        ++ "-"
                                        ++ Maybe.Extra.unwrap "?" String.fromInt w.damage.max
                                        |> text
                                    ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        ]
    ]
