module Page.Skill exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Desc
import View.Nav
import View.Skill


view : Datamine -> String -> Maybe (List (Html msg))
view dm uid =
    dm.skills
        |> List.filter (\s -> s.uid == uid)
        |> List.head
        |> Maybe.map
            (\skill ->
                let
                    ast =
                        dm.skillASTs
                            |> List.filter (\a -> String.toLower a.name == String.toLower skill.uid)
                            |> List.head

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
                        Datamine.lang dm skill.uiName |> Maybe.withDefault "???"
                in
                [ div [ class "container" ]
                    [ View.Nav.view
                    , ol [ class "breadcrumb" ]
                        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                        , a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skills" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Skill skill.uid ] [ text label ]
                        ]
                    , img [ class "skill", View.Skill.img skill ] []
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
                                            [ td [ title v.uiName ]
                                                [ Datamine.lang dm v.uiName |> Maybe.withDefault "???" |> text ]
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
            )
