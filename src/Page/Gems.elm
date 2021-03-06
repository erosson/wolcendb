module Page.Gems exposing (view)

import Datamine exposing (Datamine)
import Datamine.Affix as Affix
import Datamine.Gem as Gem exposing (Socket(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import Maybe.Extra
import Route exposing (Route)
import View.Affix


view : Lang -> Datamine -> List (Html msg)
view lang dm =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Gems ] [ text "Gems" ]
        ]
    , table [ class "table" ]
        --[ thead []
        --    [ tr []
        --        [ th [] [ text "name" ]
        --        , th [] [ text "affixes" ]
        --        ]
        --    ]
        [ tbody []
            (dm.gems
                |> List.map
                    (\gem ->
                        tr []
                            [ td [ title gem.uiName ]
                                [ div [] [ img [ class "skill-icon", src <| Gem.img gem ] [] ]
                                , Gem.label lang gem |> Maybe.withDefault "???" |> text
                                , div [] [ text "[", a [ Route.href <| Route.Source "gem" gem.name ] [ text "Source" ], text "]" ]
                                ]
                            , td []
                                [ ul [ class "list-group affixes nowrap" ]
                                    (Gem.effects lang dm gem |> List.map (\s -> li [ class "list-group-item", style "display" "inline" ] [ text s ]))
                                ]
                            ]
                    )
            )
        ]
    ]
