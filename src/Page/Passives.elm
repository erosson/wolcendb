module Page.Passives exposing (view)

import Datamine exposing (Datamine, Socket(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Item
import View.Nav


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
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
                                    [ div [] [ b [] [ Datamine.lang dm passive.uiName |> Maybe.withDefault "???" |> text ] ]
                                    , div [ class <| "passive-" ++ entry.category ]
                                        [ Datamine.lang dm tree.uiName |> Maybe.withDefault "Unknown" |> text
                                        , text <|
                                            case entry.rarity of
                                                2 ->
                                                    " Notable"

                                                3 ->
                                                    " Keystone"

                                                _ ->
                                                    ""
                                        ]
                                    , div [] [ text "[", a [ Route.href <| Route.Source "passive" passive.name ] [ text "Source" ], text "]" ]
                                    ]
                                , td []
                                    [ p [] <| (View.Desc.mdesc dm passive.gameplayDesc |> Maybe.withDefault [ text "" ])
                                    , ul [ class "list-group affixes" ] <|
                                        (passive.effects
                                            |> List.filterMap (View.Affix.formatPassiveEffect dm)
                                            |> List.map (\s -> li [ class "list-group-item" ] [ text s ])
                                        )
                                    , p [] <| (View.Desc.mdesc dm passive.hudLoreDesc |> Maybe.withDefault [ text "" ])
                                    ]
                                ]
                        )
                )
            ]
        ]
    ]
