module View.AffixFilterForm exposing (Model, Msg, isVisible, update, viewGemForm, viewKeywordForm, viewLevelForm)

import Datamine exposing (Datamine)
import Datamine.Affix as Affix exposing (MagicAffix)
import Datamine.GemFamily as GemFamily exposing (GemFamily)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import List.Extra
import Set exposing (Set)
import Util
import View.Affix


type alias Model m =
    { m
        | expandedAffixClasses : Set String
        , filterItemLevel : Int
        , filterGemFamilies : Set String
        , filterKeywords : Set String
        , filterGentypes : Set String
        , filterXpack : Set String
    }


type Msg
    = InputItemLevel String
    | InputGemFamily String
    | InputKeywordFilter String
    | InputGentypeFilter String
    | InputXpackFilter String


isVisible : Datamine -> Model m -> MagicAffix -> Bool
isVisible dm model aff =
    (model.filterItemLevel <= 0 || (model.filterItemLevel >= aff.drop.itemLevel.min && model.filterItemLevel <= aff.drop.itemLevel.max))
        && GemFamily.filterAffix dm model.filterGemFamilies aff
        -- slave affixes - bloodtrail negative affixes/red text - are never visible on their own.
        -- && not (aff.drop.hunt && (aff.drop.frequency == 0 || aff.type_ == "slave"))
        && not (aff.drop.hunt && String.startsWith "slave" (Maybe.withDefault "" aff.class))


update : Msg -> Datamine -> Model m -> Model m
update msg dm model =
    case msg of
        InputItemLevel s ->
            if s == "" then
                { model | filterItemLevel = 0 }

            else
                case String.toInt s of
                    Nothing ->
                        model

                    Just i ->
                        { model | filterItemLevel = clamp 0 200 i }

        InputGemFamily name ->
            { model | filterGemFamilies = model.filterGemFamilies |> Util.toggleSet name }

        InputKeywordFilter kw ->
            { model | filterKeywords = model.filterKeywords |> Util.toggleSet kw }

        InputGentypeFilter kw ->
            { model | filterGentypes = model.filterGentypes |> Util.toggleSet kw }

        InputXpackFilter kw ->
            { model | filterXpack = model.filterXpack |> Util.toggleSet kw }


viewLevelForm : Model m -> Html Msg
viewLevelForm model =
    H.form []
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
                    if model.filterItemLevel == 0 then
                        ""

                    else
                        String.fromInt model.filterItemLevel
                , onInput InputItemLevel
                ]
                []
            , div [ class "col", classList [ ( "invisible", model.filterItemLevel == 0 ) ] ]
                [ text ", or "
                , button
                    [ type_ "button"
                    , class "btn btn-outline-dark"
                    , onClick <| InputItemLevel "0"
                    ]
                    [ text "Show affixes for all item levels" ]
                ]
            ]
        ]


viewGemForm : Datamine -> Model m -> Html Msg
viewGemForm dm model =
    H.form []
        [ div [ class "form-group form-row" ]
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
                                    "affix-filter-gem-" ++ fam.gemFamilyId
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


viewKeywordForm : Datamine -> Model m -> Html Msg
viewKeywordForm dm model =
    H.form []
        [ div [ class "form-group form-row" ]
            [ div
                [ class "col-sm-3"
                , style "text-align" "right"
                ]
                [ text "Show only affixes with keyword" ]
            , div [ class "col" ]
                [ div []
                    (dm.magicAffixesKeywords
                        |> List.map
                            (\kw ->
                                let
                                    id =
                                        "affix-filter-keyword-" ++ kw
                                in
                                div [ class "form-check form-check-inline" ]
                                    [ input
                                        [ class "form-check-input"
                                        , A.id id
                                        , type_ "checkbox"
                                        , onCheck <| always <| InputKeywordFilter kw
                                        ]
                                        []
                                    , H.label [ class "form-check-label badge", for id ] [ text kw ]
                                    ]
                            )
                    )
                , div []
                    -- (List.map .type_ dm.affixes.magic
                    -- |> List.Extra.unique
                    -- same thing, but faster
                    (([ "prefix", "suffix" ]
                        |> List.map
                            (\kw ->
                                let
                                    id =
                                        "affix-filter-gentype-" ++ kw
                                in
                                div [ class "form-check form-check-inline" ]
                                    [ input
                                        [ class "form-check-input"
                                        , A.id id
                                        , type_ "checkbox"
                                        , onCheck <| always <| InputGentypeFilter kw
                                        ]
                                        []
                                    , H.label [ class "form-check-label badge", for id ] [ text kw ]
                                    ]
                            )
                     )
                        ++ ([ "sarisel", "hunt" ]
                                |> List.map
                                    (\kw ->
                                        let
                                            id =
                                                "affix-filter-xpack-" ++ kw
                                        in
                                        div [ class "form-check form-check-inline" ]
                                            [ input
                                                [ class "form-check-input"
                                                , A.id id
                                                , type_ "checkbox"
                                                , onCheck <| always <| InputXpackFilter kw
                                                ]
                                                []
                                            , H.label [ class "form-check-label badge", for id ] [ text kw ]
                                            ]
                                    )
                           )
                    )
                ]
            ]
        ]
