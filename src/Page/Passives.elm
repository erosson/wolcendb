module Page.Passives exposing (view)

import Datamine exposing (Datamine)
import Datamine.Passive as Passive
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc


view : Datamine -> List (Html msg)
view dm =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Passives ] [ text "Passives" ]
        ]
    , table [ class "table" ]
        [ tbody []
            (dm.passiveTreeEntries
                |> List.sortBy (\( entry, passive, tree ) -> ( tree.name, -entry.rarity ))
                |> List.map
                    (\( entry, passive, tree ) ->
                        tr []
                            [ td [ title passive.uiName, style "white-space" "nowrap" ]
                                -- [ div [] [ img [ class "skill-icon", View.Item.imgGem gem ] [] ]
                                [ div [] [ b [] [ Passive.label dm passive |> Maybe.withDefault "???" |> text ] ]
                                , div [ class <| "passive-" ++ entry.category ]
                                    [ text <| Passive.nodeTypeLabel dm entry tree ]
                                , div [] [ text "[", a [ Route.href <| Route.Source "passive" passive.name ] [ text "Source" ], text "]" ]
                                ]
                            , td []
                                [ p [] <| (View.Desc.mdesc dm passive.gameplayDesc |> Maybe.withDefault [ text "" ])
                                , ul [ class "list-group affixes" ] (Passive.effects dm passive |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
                                , p [] <| (View.Desc.mdesc dm passive.hudLoreDesc |> Maybe.withDefault [ text "" ])
                                ]
                            ]
                    )
            )
        ]
    ]
