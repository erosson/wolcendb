module Page.NormalItem exposing (Msg, update, view, viewTitle)

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
import View.AffixFilterForm
import View.Desc


type alias Model m =
    View.AffixFilterForm.Model m


type Msg
    = ItemMsg View.Affix.ItemMsg
    | FormMsg View.AffixFilterForm.Msg


update : Msg -> Datamine -> Model m -> Model m
update msg dm model =
    case msg of
        ItemMsg msg_ ->
            View.Affix.update msg_ model

        FormMsg msg_ ->
            View.AffixFilterForm.update msg_ dm model


viewTitle : Datamine -> String -> String
viewTitle dm name =
    Dict.get (String.toLower name) dm.lootByName
        |> Maybe.andThen (NormalItem.label dm)
        |> Maybe.withDefault ""


view : Datamine -> Model m -> String -> Maybe (List (Html Msg))
view dm model name =
    Dict.get (String.toLower name) dm.lootByName
        |> Maybe.map (viewMain dm model)


viewMain : Datamine -> Model m -> NormalItem -> List (Html Msg)
viewMain dm m nitem =
    let
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
                [ img [ src <| Maybe.withDefault "" <| NormalItem.img dm nitem ] []
                , div [] [ text "[", a [ Route.href <| Route.Source "normal-loot" <| NormalItem.name nitem ] [ text "Source" ], text "]" ]
                ]
            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt <| NormalItem.levelPrereq nitem ]
            , ul [ class "list-group affixes" ] (nitem |> NormalItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , ul [ class "list-group affixes" ] (NormalItem.implicitEffects dm nitem |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " <| NormalItem.keywords nitem ]
            ]
        ]
    , View.AffixFilterForm.viewLevelForm m |> H.map FormMsg
    , View.AffixFilterForm.viewGemForm dm m |> H.map FormMsg
    , NormalItem.possibleAffixes dm nitem
        |> List.filter (View.AffixFilterForm.isVisible dm m)
        |> View.Affix.viewItem dm m.expandedAffixClasses
        |> div []
        |> H.map ItemMsg
    ]
