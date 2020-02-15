module Page.UniqueArmors exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Desc
import View.Nav


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "container" ]
        [ View.Nav.view
        , div [ class "navbar navbar-expand-sm navbar-light bg-light" ]
            [ a [ class "navbar-brand", Route.href Route.UniqueArmors ] [ text "Unique Armors" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "keywords" ]
                    , th [] [ text "lore" ]
                    ]
                ]
            , tbody []
                (dm.loot.uniqueArmors
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Datamine.lang dm w.uiName |> Maybe.withDefault "???" |> text ]
                                , td [] [ text w.name ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                , td []
                                    (View.Desc.mdesc dm w.lore |> Maybe.withDefault [ text "???" ])
                                ]
                        )
                )
            ]
        ]
    ]
