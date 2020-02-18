module Page.NormalItem exposing (viewAccessory, viewArmor, viewShield, viewWeapon)

import Datamine exposing (Datamine, Item, NormalItem(..))
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
import View.Nav


type alias Model m =
    { m | datamine : Datamine, expandedAffixClasses : Set String }


type alias Msg =
    View.Affix.ItemMsg


viewWeapon : Model m -> String -> Maybe (List (Html Msg))
viewWeapon model name =
    Dict.get (String.toLower name) model.datamine.lootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    NWeapon i ->
                        Just <| viewMain model item i

                    _ ->
                        Nothing
            )


viewShield : Model m -> String -> Maybe (List (Html Msg))
viewShield model name =
    Dict.get (String.toLower name) model.datamine.lootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    NShield i ->
                        Just <| viewMain model item i

                    _ ->
                        Nothing
            )


viewArmor : Model m -> String -> Maybe (List (Html Msg))
viewArmor model name =
    Dict.get (String.toLower name) model.datamine.lootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    NArmor i ->
                        Just <| viewMain model item i

                    _ ->
                        Nothing
            )


viewAccessory : Model m -> String -> Maybe (List (Html Msg))
viewAccessory model name =
    Dict.get (String.toLower name) model.datamine.lootByName
        |> Maybe.andThen
            (\item ->
                case item of
                    NAccessory i ->
                        Just <| viewMain model item i

                    _ ->
                        Nothing
            )


viewBreadcrumb : Datamine -> NormalItem -> Html msg -> Html msg
viewBreadcrumb dm nitem label =
    ol [ class "breadcrumb" ] <|
        a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            :: (case nitem of
                    NWeapon item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Weapons ] [ text "Unique Weapons" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Weapon item.name ] [ label ]
                        ]

                    NShield item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Shields ] [ text "Unique Shields" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Shield item.name ] [ label ]
                        ]

                    NArmor item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Armors ] [ text "Unique Armors" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Armor item.name ] [ label ]
                        ]

                    NAccessory item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Accessories ] [ text "Unique Accessories" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Accessory item.name ] [ label ]
                        ]
               )


viewMain : Model m -> NormalItem -> Item i -> List (Html Msg)
viewMain m nitem item =
    let
        dm =
            m.datamine

        label =
            Datamine.lang dm item.uiName |> Maybe.withDefault "???" |> text
    in
    [ div [ class "container" ]
        [ View.Nav.view
        , viewBreadcrumb dm nitem label
        , div [ class "card" ]
            [ div [ class "card-header" ] [ label ]
            , div [ class "card-body" ]
                [ span [ class "item float-right" ] [ img [ View.Item.imgNormal dm nitem ] [] ]
                , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                , div [] <|
                    case nitem of
                        NWeapon w ->
                            [ p []
                                [ text "Damage: "
                                , Maybe.Extra.unwrap "?" String.fromInt w.damage.min
                                    ++ "-"
                                    ++ Maybe.Extra.unwrap "?" String.fromInt w.damage.max
                                    |> text
                                ]
                            ]

                        _ ->
                            []
                , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.implicitAffixes
                , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                ]
            ]
        , div [] <| View.Affix.viewItem dm m.expandedAffixClasses <| Datamine.itemAffixes dm item
        ]
    ]
