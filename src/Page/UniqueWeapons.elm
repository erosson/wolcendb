module Page.UniqueWeapons exposing (view)

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
        , div [ class "navbar navbar-expand-sm navbar-light bg-light" ]
            [ a [ class "navbar-brand", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "damage" ]
                    , th [] [ text "keywords" ]
                    , th [] [ text "lore" ]
                    ]
                ]
            , tbody []
                (dm.loot.uniqueWeapons
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Dict.get (String.replace "@" "" w.uiName) dm.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                , td [] [ text w.name ]
                                , td []
                                    [ Maybe.Extra.unwrap "?" String.fromInt w.damage.min
                                        ++ "-"
                                        ++ Maybe.Extra.unwrap "?" String.fromInt w.damage.max
                                        |> text
                                    ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                , td []
                                    [ Dict.get (String.replace "@" "" (Maybe.withDefault "" w.lore)) dm.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                ]
                        )
                )
            ]
        ]
    ]
