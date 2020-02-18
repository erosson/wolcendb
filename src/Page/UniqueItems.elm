module Page.UniqueItems exposing (viewAccessories, viewArmors, viewShields, viewWeapons)

import Datamine exposing (Datamine, UItem, UniqueItem(..))
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


viewWeapons : Datamine -> List (Html msg)
viewWeapons dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "damage" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UWeapon i ->
                            Just ( uitem, i )

                        _ ->
                            Nothing
                )
        )


viewShields : Datamine -> List (Html msg)
viewShields dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.UniqueShields ] [ text "Unique Shields" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UShield i ->
                            Just ( uitem, i )

                        _ ->
                            Nothing
                )
        )


viewArmors : Datamine -> List (Html msg)
viewArmors dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.UniqueArmors ] [ text "Unique Armors" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UArmor i ->
                            Just ( uitem, i )

                        _ ->
                            Nothing
                )
        )


viewAccessories : Datamine -> List (Html msg)
viewAccessories dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.UniqueAccessories ] [ text "Unique Accessories" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UAccessory i ->
                            Just ( uitem, i )

                        _ ->
                            Nothing
                )
        )


itemRoute : UniqueItem -> Route
itemRoute uitem =
    case uitem of
        UWeapon i ->
            Route.UniqueWeapon i.name

        UArmor i ->
            Route.UniqueArmor i.name

        UShield i ->
            Route.UniqueShield i.name

        UAccessory i ->
            Route.UniqueAccessory i.name


viewMain : Datamine -> { breadcrumb : List (Html msg), headers : List (Html msg) } -> List ( UniqueItem, UItem i ) -> List (Html msg)
viewMain dm { breadcrumb, headers } items =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ] breadcrumb
        , table [ class "table" ]
            [ thead [] [ tr [] headers ]
            , tbody []
                (items
                    |> List.filter (\( _, item ) -> Datamine.lang dm item.uiName |> Maybe.Extra.isJust)
                    |> List.map
                        (\( uitem, item ) ->
                            tr []
                                ([ td []
                                    [ a [ Route.href <| itemRoute uitem ]
                                        [ img [ class "item-icon", View.Item.imgUnique dm uitem ] []
                                        , Datamine.lang dm item.uiName |> Maybe.withDefault "???" |> text
                                        ]
                                    ]
                                 , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                                 ]
                                    ++ (case uitem of
                                            UWeapon w ->
                                                [ td []
                                                    [ Maybe.Extra.unwrap "?" String.fromInt w.damage.min
                                                        ++ "-"
                                                        ++ Maybe.Extra.unwrap "?" String.fromInt w.damage.max
                                                        |> text
                                                    ]
                                                ]

                                            _ ->
                                                []
                                       )
                                    ++ [ td [] [ text <| String.join ", " item.keywords ]
                                       ]
                                )
                        )
                )
            ]
        ]
    ]
