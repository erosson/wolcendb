module Page.Skills exposing (view)

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
            [ a [ class "navbar-brand", Route.href Route.Skills ] [ text "Skills" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "desc" ]
                    , th [] [ text "lore" ]
                    ]
                ]
            , tbody []
                (dm.skills
                    |> List.map
                        (\s ->
                            tr []
                                [ td [ title <| Maybe.withDefault "" s.uiName ]
                                    [ Datamine.mlang dm s.uiName |> Maybe.withDefault "???" |> text ]
                                , td [] [ text s.uid ]
                                , td [ title <| Maybe.withDefault "" <| Maybe.map (\n -> n ++ "_desc") s.uiName ]
                                    (View.Desc.mdesc dm (Maybe.map (\n -> n ++ "_desc") s.uiName) |> Maybe.withDefault [ text "???" ])
                                , td [ title <| Maybe.withDefault "" s.lore ]
                                    (View.Desc.mdesc dm s.lore |> Maybe.withDefault [ text "???" ])
                                ]
                        )
                )
            ]
        ]
    ]
