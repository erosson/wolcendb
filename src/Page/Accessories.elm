module Page.Accessories exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra


view : Datamine -> List (Html msg)
view dm =
    [ h1 [] [ text "Armors" ]
    , table []
        [ thead []
            [ tr []
                [ th [] [ text "name" ]
                , th [] [ text "id" ]
                , th [] [ text "keywords" ]
                ]
            ]
        , tbody []
            (dm.loot.accessories
                |> List.map
                    (\w ->
                        tr []
                            [ td []
                                [ Dict.get (String.replace "@" "" w.uiName) dm.en
                                    |> Maybe.withDefault "???"
                                    |> text
                                ]
                            , td [] [ text w.name ]
                            , td [] [ text <| String.join ", " w.keywords ]
                            ]
                    )
            )
        ]
    ]
