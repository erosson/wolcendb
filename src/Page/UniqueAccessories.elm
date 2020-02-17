module Page.UniqueAccessories exposing (view)

import Datamine exposing (Datamine)
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
            , a [ class "breadcrumb-item active", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "level" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (dm.loot.uniqueAccessories
                    |> List.filter (\w -> Datamine.lang dm w.uiName |> Maybe.Extra.isJust)
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ a [ Route.href <| Route.UniqueAccessory w.name ]
                                        [ img [ class "item-icon", View.Item.imgAccessory w ] []
                                        , Datamine.lang dm w.uiName |> Maybe.withDefault "???" |> text
                                        ]
                                    ]
                                , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt w.levelPrereq ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        ]
    ]
