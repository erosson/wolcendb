module Page.Weapons exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra


view : Datamine -> List (Html msg)
view dm =
    [ h1 [] [ text "Weapons" ]
    , table []
        [ thead []
            [ tr []
                [ th [] [ text "name" ]
                , th [] [ text "id" ]
                , th [] [ text "damage" ]
                , th [] [ text "keywords" ]
                ]
            ]
        , tbody []
            (dm.loot.weapons
                |> List.take 100
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
                            ]
                    )
            )
        ]
    ]
