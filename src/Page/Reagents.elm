module Page.Reagents exposing (view)

import Datamine exposing (Datamine)
import Datamine.Reagent as Reagent exposing (Reagent)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import Maybe.Extra
import Route exposing (Route)
import View.Desc


view : Lang -> Datamine -> List (Html msg)
view lang dm =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Reagents ] [ text "Reagents" ]
        ]
    , table [ class "table" ]
        [ tbody []
            (dm.reagents
                |> List.map
                    (\reagent ->
                        tr []
                            [ td []
                                [ div [] [ img [ class "skill-icon", src <| Reagent.img reagent ] [] ]
                                , span [ title reagent.uiName ] [ Reagent.label lang reagent |> Maybe.withDefault "???" |> text ]
                                , div [] [ text "[", a [ Route.href <| Route.Source "reagent" reagent.name ] [ text "Source" ], text "]" ]
                                ]
                            , td [] (Reagent.desc lang reagent |> View.Desc.mformat |> Maybe.withDefault [])
                            , td [] (Reagent.lore lang reagent |> View.Desc.mformat |> Maybe.withDefault [])
                            ]
                    )
            )
        ]
    ]
