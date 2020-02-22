module Page.UniqueItem exposing (viewAccessory, viewArmor, viewShield, viewWeapon)

import Datamine exposing (Datamine)
import Datamine.UniqueItem as UniqueItem exposing (UItem, UniqueItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Item


viewWeapon : Datamine -> String -> Maybe (List (Html msg))
viewWeapon dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    UWeapon i ->
                        Just <| viewMain dm item i

                    _ ->
                        Nothing
            )


viewShield : Datamine -> String -> Maybe (List (Html msg))
viewShield dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    UShield i ->
                        Just <| viewMain dm item i

                    _ ->
                        Nothing
            )


viewArmor : Datamine -> String -> Maybe (List (Html msg))
viewArmor dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    UArmor i ->
                        Just <| viewMain dm item i

                    _ ->
                        Nothing
            )


viewAccessory : Datamine -> String -> Maybe (List (Html msg))
viewAccessory dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    UAccessory i ->
                        Just <| viewMain dm item i

                    _ ->
                        Nothing
            )


viewBreadcrumb : Datamine -> UniqueItem -> Html msg -> Html msg
viewBreadcrumb dm uitem label =
    ol [ class "breadcrumb" ] <|
        a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            :: (case uitem of
                    UWeapon item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueWeapon item.name ] [ label ]
                        ]

                    UShield item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.UniqueShields ] [ text "Unique Shields" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueShield item.name ] [ label ]
                        ]

                    UArmor item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.UniqueArmors ] [ text "Unique Armors" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueArmor item.name ] [ label ]
                        ]

                    UAccessory item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.UniqueAccessories ] [ text "Unique Accessories" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueAccessory item.name ] [ label ]
                        ]
               )


viewMain : Datamine -> UniqueItem -> UItem i -> List (Html msg)
viewMain dm uitem item =
    let
        label =
            UniqueItem.label dm uitem |> Maybe.withDefault "???" |> text
    in
    [ viewBreadcrumb dm uitem label
    , div [ class "card" ]
        [ div [ class "card-header" ] [ label ]
        , div [ class "card-body" ]
            [ span [ class "item float-right" ]
                [ img [ View.Item.imgUnique dm uitem ] []
                , div [] [ text "[", a [ Route.href <| Route.Source "unique-loot" item.name ] [ text "Source" ], text "]" ]
                ]
            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
            , ul [ class "list-group affixes" ] (uitem |> UniqueItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.implicitAffixes
            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.defaultAffixes
            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " item.keywords ]
            , p [] <| (View.Desc.mdesc dm item.lore |> Maybe.withDefault [ text "???" ])
            ]
        ]
    ]
