module Page.UniqueAccessories exposing (view)

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
            , a [ class "breadcrumb-item active", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
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
                (dm.loot.uniqueAccessories
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
