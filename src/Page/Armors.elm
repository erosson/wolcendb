module Page.Armors exposing (view)

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
            , a [ class "breadcrumb-item active", Route.href Route.Armors ] [ text "Armors" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "level" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (dm.loot.armors
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ a [ Route.href <| Route.Armor w.name ]
                                        [ Datamine.lang dm w.uiName |> Maybe.withDefault "???" |> text ]
                                    ]
                                , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt w.levelPrereq ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        ]
    ]
