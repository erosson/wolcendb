module Page.Skill exposing (view, viewTitle)

import Datamine exposing (Datamine)
import Datamine.Skill as Skill exposing (Skill, SkillAST, SkillASTVariant, SkillVariant)
import Datamine.Util
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode
import Maybe.Extra
import Page.SkillVariant exposing (viewSkillEffects)
import Route exposing (Route)
import Util
import View.Desc


viewTitle : Datamine -> String -> String
viewTitle dm name =
    Dict.get (String.toLower name) dm.skillsByUid
        |> Maybe.andThen (Skill.label dm)
        |> Maybe.withDefault ""


view : Datamine -> String -> Maybe (List (Html msg))
view dm uid =
    Dict.get (String.toLower uid) dm.skillsByUid
        |> Maybe.map
            (\skill ->
                let
                    ast : Maybe SkillAST
                    ast =
                        Dict.get uid dm.skillASTsByName

                    vas : List ( SkillASTVariant, SkillVariant )
                    vas =
                        ast
                            |> Maybe.Extra.unwrap [] .variants
                            |> List.filterMap
                                (\va ->
                                    skill.variants
                                        |> List.filter (\v -> String.toLower va.uid == String.toLower v.uid)
                                        |> List.head
                                        |> Maybe.map (Tuple.pair va)
                                )

                    label : String
                    label =
                        Skill.label dm skill |> Maybe.withDefault "???"
                in
                [ ol [ class "breadcrumb" ]
                    [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                    , a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skills" ]
                    , a [ class "breadcrumb-item active", Route.href <| Route.Skill skill.uid ] [ text label ]
                    ]
                , div [ class "card" ]
                    [ div [ class "card-header" ] [ text label ]
                    , div [ class "card-body" ]
                        [ div [ class "media" ]
                            [ div [ class "media-body" ]
                                [ Skill.desc dm skill |> View.Desc.mformat |> Maybe.withDefault [ text "???" ] |> p []
                                , Skill.lore dm skill |> View.Desc.mformat |> Maybe.withDefault [] |> p []
                                , div [] (viewSkillEffects <| Skill.effects skill)
                                ]
                            , div []
                                [ img [ class "skill", src <| Skill.img skill ] []
                                , div [] [ text "[", a [ Route.href <| Route.Source "skill" uid ] [ text "Source" ], text "]" ]
                                ]
                            ]
                        , table [ class "table" ]
                            [ thead []
                                [ tr []
                                    [ th [] [ text "" ]
                                    , th [] [ text "" ]
                                    , th [] [ text "name" ]
                                    , th [] [ text "level" ]
                                    , th [] [ text "cost" ]
                                    , th [] [ text "desc" ]
                                    ]
                                ]
                            , tbody []
                                (vas
                                    |> List.indexedMap
                                        (\i ( va, v ) ->
                                            tr []
                                                [ td [] [ text <| String.fromInt <| i + 1 ]
                                                , td [] [ img [ class "skill-variant", src <| Skill.img v ] [] ]
                                                , td []
                                                    [ a [ title v.uiName, Route.href <| Route.SkillVariant v.uid ] [ Skill.label dm v |> Maybe.withDefault "???" |> text ]
                                                    ]
                                                , td [] [ text <| String.fromInt va.level ]
                                                , td [] [ text <| String.fromInt va.cost ]
                                                , td []
                                                    [ div [ title <| v.uiName ++ "_desc" ]
                                                        (Skill.desc dm v |> View.Desc.mformat |> Maybe.withDefault [ text "???" ])
                                                    , div [ class "card" ] (viewSkillEffects <| Skill.effects v)

                                                    -- , div [ title <| Maybe.withDefault "" v.lore ]
                                                    -- (Skill.lore dm v |> View.Desc.mformat |> Maybe.withDefault [])
                                                    ]
                                                ]
                                        )
                                )
                            ]
                        , table [ class "table" ]
                            [ thead []
                                [ tr []
                                    [ th [] [ text "level" ]
                                    , th [] [ text "effect" ]
                                    , th [] [ text "xp" ]
                                    ]
                                ]
                            , tbody []
                                (ast
                                    |> Maybe.Extra.unwrap [] Skill.modTotals
                                    |> List.map
                                        (\mod ->
                                            tr []
                                                [ td [] [ text <| String.fromInt mod.level ]
                                                , td [ title mod.uiDesc ] [ Skill.modDesc dm mod |> Maybe.withDefault "???" |> text ]
                                                , td [] [ text <| String.fromInt mod.xp ]
                                                ]
                                        )
                                )
                            ]
                        ]
                    ]
                ]
            )
