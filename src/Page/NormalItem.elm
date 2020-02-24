module Page.NormalItem exposing (Msg, update, view)

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


view : Model m -> String -> Maybe (List (Html Msg))
view model name =
    Dict.get (String.toLower name) model.datamine.lootByName
        |> Maybe.map (viewMain model)


viewMain : Model m -> NormalItem -> List (Html Msg)
viewMain m nitem =
    let
        dm =
            m.datamine

        label =
            NormalItem.label dm nitem |> Maybe.withDefault "???" |> text
    in
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.NormalItems Nothing ] [ text "Normal Items" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.NormalItem <| NormalItem.name nitem ] [ label ]
        ]
    , div [ class "card" ]
        [ div [ class "card-header" ] [ label ]
        , div [ class "card-body" ]
            [ span [ class "item float-right" ]
                [ img [ View.Item.imgNormal dm nitem ] []
                , div [] [ text "[", a [ Route.href <| Route.Source "normal-loot" <| NormalItem.name nitem ] [ text "Source" ], text "]" ]
                ]
            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt <| NormalItem.levelPrereq nitem ]
            , ul [ class "list-group affixes" ] (nitem |> NormalItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , ul [ class "list-group affixes" ] (NormalItem.implicitEffects dm nitem |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " <| NormalItem.keywords nitem ]
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
    , NormalItem.possibleAffixes dm nitem
        |> List.filter (\aff -> m.filterItemLevel <= 0 || (m.filterItemLevel >= aff.drop.itemLevel.min && m.filterItemLevel <= aff.drop.itemLevel.max))
        |> List.filter (GemFamily.filterAffix dm m.filterGemFamilies)
        |> View.Affix.viewItem dm m.expandedAffixClasses
        |> div []
        |> H.map ItemMsg
    ]
