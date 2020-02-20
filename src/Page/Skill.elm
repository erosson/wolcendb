module Page.Skill exposing (view)

import Datamine exposing (Datamine)
import Datamine.Skill as Skill exposing (Skill)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode
import Maybe.Extra
import Route exposing (Route)
import View.Desc
import View.Nav
import View.Skill


view : Datamine -> String -> Maybe (List (Html msg))
view dm uid =
    Dict.get (String.toLower uid) dm.skillsByUid
        |> Maybe.map
            (\skill ->
                let
                    ast =
                        Dict.get uid dm.skillASTsByName

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
                [ div [ class "container" ]
                    [ View.Nav.view
                    , ol [ class "breadcrumb" ]
                        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                        , a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skills" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Skill skill.uid ] [ text label ]
                        ]
                    , div [ class "card" ]
                        [ div [ class "card-header" ] [ text label ]
                        , div [ class "card-body" ]
                            [ span [ class "float-right" ]
                                [ img [ class "skill", View.Skill.img skill ] []
                                , div [] [ text "[", a [ Route.href <| Route.Source "skill" uid ] [ text "Source" ], text "]" ]
                                ]
                            , p [] <| (View.Desc.desc dm (skill.uiName ++ "_desc") |> Maybe.withDefault [ text "???" ])
                            , p [] <| (View.Desc.mdesc dm skill.lore |> Maybe.withDefault [ text "???" ])
                            , table [ class "table" ]
                                [ thead []
                                    [ tr []
                                        [ th [] [ text "name" ]
                                        , th [] [ text "desc" ]
                                        , th [] [ text "level" ]
                                        , th [] [ text "cost" ]
                                        , th [] [ text "lore" ]
                                        ]
                                    ]
                                , tbody []
                                    (vas
                                        |> List.map
                                            (\( va, v ) ->
                                                tr []
                                                    [ td []
                                                        [ span [ title v.uiName ] [ Skill.label dm v |> Maybe.withDefault "???" |> text ]
                                                        , div [] [ text "[", a [ Route.href <| Route.Source "skill-variant" v.uid ] [ text "Source" ], text "]" ]
                                                        ]
                                                    , td [ title <| v.uiName ++ "_desc" ]
                                                        (View.Desc.desc dm (v.uiName ++ "_desc") |> Maybe.withDefault [ text "???" ])
                                                    , td [] [ text <| String.fromInt va.level ]
                                                    , td [] [ text <| String.fromInt va.cost ]
                                                    , td [ title <| Maybe.withDefault "" v.lore ]
                                                        (View.Desc.mdesc dm v.lore |> Maybe.withDefault [ text "" ])
                                                    ]
                                            )
                                    )
                                ]
                            ]
                        ]
                    ]
                ]
            )
