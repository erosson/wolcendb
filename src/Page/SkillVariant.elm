module Page.SkillVariant exposing (view, viewSkillEffects, viewTitle)

import Datamine exposing (Datamine)
import Datamine.Skill as Skill exposing (Skill, SkillAST, SkillASTVariant, SkillVariant)
import Datamine.Util
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode
import Lang exposing (Lang)
import List.Extra
import Maybe.Extra
import Route exposing (Route)
import Util
import View.Desc


viewTitle : Lang -> Datamine -> String -> String
viewTitle lang dm id =
    Dict.get (String.toLower id) dm.skillVariantsByUid
        |> Maybe.andThen (\( v, s ) -> Maybe.map2 Tuple.pair (Skill.label lang v) (Skill.label lang s))
        |> Maybe.map (\( v, s ) -> s ++ ": " ++ v)
        |> Maybe.withDefault ""


view : Lang -> Datamine -> String -> Maybe (List (Html msg))
view lang dm uid =
    Dict.get (String.toLower uid) dm.skillVariantsByUid
        |> Maybe.map
            (\( variant, skill ) ->
                let
                    ast : Maybe SkillAST
                    ast =
                        Dict.get skill.uid dm.skillASTsByName

                    vast : Maybe SkillASTVariant
                    vast =
                        ast
                            |> Maybe.Extra.unwrap [] .variants
                            |> List.Extra.find (\va -> va.uid == variant.uid)

                    slabel : String
                    slabel =
                        Skill.label lang skill |> Maybe.withDefault "???"

                    vlabel : String
                    vlabel =
                        Skill.label lang variant |> Maybe.withDefault "???"

                    index : Maybe Int
                    index =
                        skill.variants
                            |> List.indexedMap Tuple.pair
                            |> List.Extra.find (\( i, v ) -> v.uid == variant.uid)
                            |> Maybe.map Tuple.first
                in
                [ ol [ class "breadcrumb" ]
                    [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                    , a [ class "breadcrumb-item active", Route.href <| Route.Skills <| Skill.apocForm skill ] [ text "Skills" ]
                    , a [ class "breadcrumb-item active", Route.href <| Route.Skill skill.uid ] [ text slabel ]
                    , a [ class "breadcrumb-item active", Route.href <| Route.SkillVariant variant.uid ] [ text vlabel ]
                    ]
                , div [ class "card" ]
                    [ div [ class "card-header" ] [ text slabel, text ": ", text vlabel ]
                    , div [ class "card-body" ]
                        [ div [ class "media" ]
                            [ div [ class "media-body" ]
                                [ span [ class "float-left" ]
                                    [ img [ class "skill-variant", src <| Skill.img variant ] [] ]
                                , div [] [ text "Variant #", index |> Maybe.Extra.unwrap "???" String.fromInt |> text ]
                                , div [] [ text "Level: ", vast |> Maybe.Extra.unwrap "???" (.level >> String.fromInt) |> text ]
                                , div [] [ text "Cost: ", vast |> Maybe.Extra.unwrap "???" (.cost >> String.fromInt) |> text ]
                                , br [] []
                                , div [ title <| variant.uiName ++ "_desc" ]
                                    (Skill.desc lang variant |> View.Desc.mformat |> Maybe.withDefault [ text "???" ])
                                , div [ title <| Maybe.withDefault "" variant.lore ]
                                    (Skill.lore lang variant |> View.Desc.mformat |> Maybe.withDefault [])
                                , div [ class "card" ] (viewSkillEffects <| Skill.effects variant)
                                ]
                            , div []
                                [ img [ class "skill", src <| Skill.img skill ] []
                                , div [] [ text "[", a [ Route.href <| Route.Source "skill-variant" uid ] [ text "Source" ], text "]" ]
                                ]
                            ]
                        ]
                    ]
                ]
            )


viewSkillEffects : List ( String, Float ) -> List (Html msg)
viewSkillEffects =
    List.map
        (\( name, val ) ->
            div [ class "row" ]
                [ div [ class "col-8 text-monospace", style "text-align" "right" ] [ text name ]
                , div [ class "col-4 text-monospace" ] [ text <| Util.formatFloat 5 val ]
                ]
        )
