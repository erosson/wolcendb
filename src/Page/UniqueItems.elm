module Page.UniqueItems exposing (viewAccessories, viewArmors, viewShields, viewTags, viewWeapons)

import Datamine exposing (Datamine)
import Datamine.UniqueItem as UniqueItem exposing (UItem, UniqueItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)
import View.Affix
import View.Desc
import View.Item


viewTags : Datamine -> Maybe String -> List (Html msg)
viewTags dm tagStr =
    let
        tagSet =
            tagStr |> Maybe.withDefault "" |> String.split "," |> Set.fromList
    in
    viewMain dm
        { breadcrumb =
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItems tagStr ] [ text "Unique Loot" ]
            ]
        , headers =
            [ th [] [ text "name" ]
            , th [] [ text "level" ]
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot |> List.filter (UniqueItem.keywords >> Set.fromList >> Set.diff tagSet >> Set.isEmpty))


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
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UWeapon i ->
                            Just uitem

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
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UShield i ->
                            Just uitem

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
            , th [] [ text "properties" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UArmor i ->
                            Just uitem

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
            , th [] [ text "" ]
            , th [] [ text "keywords" ]
            ]
        }
        (dm.uniqueLoot
            |> List.filterMap
                (\uitem ->
                    case uitem of
                        UAccessory i ->
                            Just uitem

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


viewMain : Datamine -> { breadcrumb : List (Html msg), headers : List (Html msg) } -> List UniqueItem -> List (Html msg)
viewMain dm { breadcrumb, headers } items =
    [ ol [ class "breadcrumb" ] breadcrumb
    , table [ class "table" ]
        [ thead [] [ tr [] headers ]
        , tbody []
            (items
                |> List.filter (\uitem -> UniqueItem.label dm uitem |> Maybe.Extra.isJust)
                |> List.map
                    (\uitem ->
                        tr []
                            [ td []
                                [ a [ Route.href <| itemRoute uitem ]
                                    [ img [ class "item-icon", View.Item.imgUnique dm uitem ] []
                                    , UniqueItem.label dm uitem |> Maybe.withDefault "???" |> text
                                    ]
                                ]
                            , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt <| UniqueItem.levelPrereq uitem ]
                            , td [] (uitem |> UniqueItem.baseEffects dm |> List.map (\s -> div [] [ text s ]))
                            , td [] [ text <| String.join ", " <| UniqueItem.keywords uitem ]
                            ]
                    )
            )
        ]
    ]
