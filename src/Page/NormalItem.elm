module Page.NormalItem exposing (Msg, update, viewAccessory, viewArmor, viewShield, viewWeapon)

import Datamine exposing (Datamine)
import Datamine.GemFamily as GemFamily exposing (GemFamily)
import Datamine.NormalItem as NormalItem exposing (Item, NormalItem(..))
import Datamine.Util exposing (Range)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)
import Util
import View.Affix
import View.Desc
import View.Item


type alias Model m =
    { m
        | datamine : Datamine
        , expandedAffixClasses : Set String
        , filterItemLevel : Int
        , filterGemFamilies : Set String
    }


type Msg
    = ItemMsg View.Affix.ItemMsg
    | InputItemLevel String
    | InputGemFamily String


update : Msg -> Model m -> Model m
update msg model =
    case msg of
        ItemMsg msg_ ->
            View.Affix.update msg_ model

        InputItemLevel s ->
            case String.toInt s of
                Nothing ->
                    model

                Just i ->
                    { model | filterItemLevel = i }

        InputGemFamily name ->
            { model | filterGemFamilies = model.filterGemFamilies |> Util.toggleSet name }


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
                        [ a [ class "breadcrumb-item active", Route.href Route.Weapons ] [ text "Normal Weapons" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Weapon item.name ] [ label ]
                        ]

                    NShield item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Shields ] [ text "Normal Shields" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Shield item.name ] [ label ]
                        ]

                    NArmor item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Armors ] [ text "Normal Armors" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Armor item.name ] [ label ]
                        ]

                    NAccessory item ->
                        [ a [ class "breadcrumb-item active", Route.href Route.Accessories ] [ text "Normal Accessories" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Accessory item.name ] [ label ]
                        ]
               )


viewMain : Model m -> NormalItem -> Item i -> List (Html Msg)
viewMain m nitem item =
    let
        dm =
            m.datamine

        label =
            NormalItem.label dm nitem |> Maybe.withDefault "???" |> text
    in
    [ viewBreadcrumb dm nitem label
    , div [ class "card" ]
        [ div [ class "card-header" ] [ label ]
        , div [ class "card-body" ]
            [ span [ class "item float-right" ]
                [ img [ View.Item.imgNormal dm nitem ] []
                , div [] [ text "[", a [ Route.href <| Route.Source "normal-loot" item.name ] [ text "Source" ], text "]" ]
                ]
            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
            , ul [ class "list-group affixes" ] (nitem |> NormalItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , ul [ class "list-group affixes" ] (NormalItem.implicitEffects dm nitem |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " item.keywords ]
            ]
        ]
    , H.form []
        [ div [ class "form-group form-row" ]
            [ H.label
                [ class "col-sm-3"
                , style "text-align" "right"
                , for "affix-filter-itemlevel"
                ]
                [ text "Show only affixes for item level " ]
            , input
                [ id "affix-filter-itemlevel"
                , type_ "number"
                , class "col-sm-2 form-control"
                , A.min "0"
                , A.max "200"
                , value <|
                    if m.filterItemLevel == 0 then
                        ""

                    else
                        String.fromInt m.filterItemLevel
                , onInput InputItemLevel
                ]
                []
            , div [ class "col", classList [ ( "invisible", m.filterItemLevel == 0 ) ] ]
                [ text ", or "
                , button
                    [ type_ "button"
                    , class "btn btn-outline-dark"
                    , onClick <| InputItemLevel "0"
                    ]
                    [ text "Show affixes for all item levels" ]
                ]
            ]
        , div [ class "form-group form-row" ]
            [ div
                [ class "col-sm-3"
                , style "text-align" "right"
                ]
                [ text "Show only affixes of gem families " ]
            , div [ class "col" ]
                (dm.gemFamilies
                    |> List.map
                        (\fam ->
                            let
                                id =
                                    "affix-filter-" ++ fam.gemFamilyId
                            in
                            div [ class "form-check form-check-inline" ]
                                [ input
                                    [ class "form-check-input"
                                    , A.id id
                                    , type_ "checkbox"
                                    , onCheck <| always <| InputGemFamily fam.gemFamilyId
                                    ]
                                    []
                                , H.label [ class "form-check-label", for id ]
                                    [ img [ class "gem-icon", src <| GemFamily.img dm fam ] []
                                    ]
                                ]
                        )
                )
            ]
        ]
    , NormalItem.possibleAffixes dm item
        |> List.filter (\aff -> m.filterItemLevel <= 0 || (m.filterItemLevel >= aff.drop.itemLevel.min && m.filterItemLevel <= aff.drop.itemLevel.max))
        |> List.filter (GemFamily.filterAffix dm m.filterGemFamilies)
        |> View.Affix.viewItem dm m.expandedAffixClasses
        |> div []
        |> H.map ItemMsg
    ]
