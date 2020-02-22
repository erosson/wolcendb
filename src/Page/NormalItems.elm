module Page.NormalItems exposing (viewAccessories, viewArmors, viewShields, viewWeapons)

import Datamine exposing (Datamine)
import Datamine.NormalItem as NormalItem exposing (Item, NormalItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Item


viewWeapons : Datamine -> List (Html msg)
viewWeapons dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Weapons ] [ text "Weapons" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.loot
            |> List.filterMap
                (\nitem ->
                    case nitem of
                        NWeapon i ->
                            Just ( nitem, i )

                        _ ->
                            Nothing
                )
        )


viewShields : Datamine -> List (Html msg)
viewShields dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Shields ] [ text "Shields" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.loot
            |> List.filterMap
                (\nitem ->
                    case nitem of
                        NShield i ->
                            Just ( nitem, i )

                        _ ->
                            Nothing
                )
        )


viewArmors : Datamine -> List (Html msg)
viewArmors dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Armors ] [ text "Armors" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.loot
            |> List.filterMap
                (\nitem ->
                    case nitem of
                        NArmor i ->
                            Just ( nitem, i )

                        _ ->
                            Nothing
                )
        )


viewAccessories : Datamine -> List (Html msg)
viewAccessories dm =
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Accessories ] [ text "Accessories" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.loot
            |> List.filterMap
                (\nitem ->
                    case nitem of
                        NAccessory i ->
                            Just ( nitem, i )

                        _ ->
                            Nothing
                )
        )


itemRoute : NormalItem -> Route
itemRoute nitem =
    case nitem of
        NWeapon i ->
            Route.Weapon i.name

        NArmor i ->
            Route.Armor i.name

        NShield i ->
            Route.Shield i.name

        NAccessory i ->
            Route.Accessory i.name


viewMain : Datamine -> { breadcrumb : List (Html msg), headers : List (Html msg) } -> List ( NormalItem, Item i ) -> List (Html msg)
viewMain dm { breadcrumb, headers } items =
    [ ol [ class "breadcrumb" ] breadcrumb
    , table [ class "table" ]
        [ thead [] [ tr [] headers ]
        , tbody []
            (items
                |> List.map
                    (\( nitem, item ) ->
                        tr []
                            [ td []
                                [ a [ Route.href <| itemRoute nitem ]
                                    [ img [ class "item-icon", View.Item.imgNormal dm nitem ] []
                                    , NormalItem.label dm nitem |> Maybe.withDefault "???" |> text
                                    ]
                                ]
                            , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                            , td [] (nitem |> NormalItem.baseEffects dm |> List.map (\s -> div [] [ text s ]))
                            , td [] [ text <| String.join ", " item.keywords ]
                            ]
                    )
            )
        ]
    ]
