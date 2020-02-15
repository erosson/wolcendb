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
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skills" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "desc" ]
                    , th [] [ text "lore" ]
                    ]
                ]
            , tbody []
                (dm.skills
                    |> List.map
                        (\s ->
                            tr []
                                [ td [ title s.uiName ]
                                    [ a [ Route.href <| Route.Skill s.uid ] [ Datamine.lang dm s.uiName |> Maybe.withDefault "???" |> text ] ]
                                , td [ title <| s.uiName ++ "_desc" ]
                                    (View.Desc.desc dm (s.uiName ++ "_desc") |> Maybe.withDefault [ text "???" ])
                                , td [ title <| Maybe.withDefault "" s.lore ]
                                    (View.Desc.mdesc dm s.lore |> Maybe.withDefault [ text "???" ])
                                ]
                        )
                )
            ]
        ]
    ]
