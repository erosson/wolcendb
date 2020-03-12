module Page.Skills exposing (view)

import Datamine exposing (Datamine)
import Datamine.Skill as Skill exposing (Skill)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import Maybe.Extra
import Route exposing (Route)
import Util
import View.Desc


view : Lang -> Datamine -> Maybe String -> Maybe (List (Html msg))
view lang dm mapoc =
    let
        apoc =
            mapoc |> Maybe.withDefault Skill.apocFormNone
    in
    case dm.skillsByApocForm |> Dict.get apoc of
        Nothing ->
            if List.member apoc Skill.apocForms then
                [ ol [ class "breadcrumb" ]
                    [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                    , a [ class "breadcrumb-item active", Route.href <| Route.Skills mapoc ] [ text "Skills" ]
                    ]
                , p [] [ code [] [ text "Error: no skills found for this apocalypse form." ] ]
                , p [] [ text "It looks like this is a valid apocalypse form, though. Are you looking at an old version of Wolcen? We didn't datamine apocalypse form skills until after v1.0.9.0; sorry!" ]
                ]
                    |> Just

            else
                Nothing

        Just skills ->
            [ ol [ class "breadcrumb" ]
                [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                , a [ class "breadcrumb-item active", Route.href <| Route.Skills mapoc ] [ text "Skills" ]
                ]
            , p [] [ text "Apocalypse form: ", text <| Util.titleCase apoc ]
            , table [ class "table" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "icon" ]
                        , th [] [ text "name" ]
                        , th [] [ text "desc" ]

                        -- , th [] [ text "lore" ]
                        ]
                    ]
                , tbody []
                    (skills
                        |> List.map
                            (\s ->
                                tr []
                                    [ td []
                                        [ a [ Route.href <| Route.Skill s.uid ]
                                            [ img [ class "skill-icon", src <| Skill.img s ] []
                                            ]
                                        ]
                                    , td [ title s.uiName ]
                                        [ a [ Route.href <| Route.Skill s.uid ]
                                            [ Skill.label lang s |> Maybe.withDefault "???" |> text
                                            ]
                                        ]
                                    , td [ title <| s.uiName ++ "_desc" ]
                                        (Skill.desc lang s |> View.Desc.mformat |> Maybe.withDefault [ text "???" ])

                                    -- , td [ title <| Maybe.withDefault "" s.lore ]
                                    -- (View.Desc.mdesc dm s.lore |> Maybe.withDefault [ text "???" ])
                                    ]
                            )
                    )
                ]
            ]
                |> Just
