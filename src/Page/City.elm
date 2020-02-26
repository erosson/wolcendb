module Page.City exposing (Msg, update, view)

import Datamine exposing (Datamine)
import Datamine.City as City
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Item


type Msg
    = InputPlayerLevel String


type alias Model m =
    { m | cityPlayerLevel : Int }


update : Msg -> Model m -> Model m
update msg model =
    case msg of
        InputPlayerLevel str ->
            if str == "" then
                { model | cityPlayerLevel = 0 }

            else
                case String.toInt str of
                    Nothing ->
                        model

                    Just n ->
                        { model | cityPlayerLevel = clamp 0 90 n }


view : Datamine -> Model m -> String -> Maybe (List (Html Msg))
view dm model name =
    Dict.get name dm.cityBuildingsByName
        |> Maybe.map (viewMain dm model)


viewMain : Datamine -> Model m -> City.Building -> List (Html Msg)
viewMain dm model building =
    let
        label =
            City.label dm building |> Maybe.withDefault "???"
    in
    [ ul [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active" ] [ text "City Rewards" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.City building.name ] [ text label ]
        ]
    , H.form []
        [ div [ class "form-group row" ]
            [ H.label [ class "col-sm-3" ] [ text "Player level" ]
            , div [ class "col-sm-9" ]
                [ input
                    [ class "form-control"
                    , type_ "number"
                    , A.min "0"
                    , A.max "90"
                    , value <|
                        if model.cityPlayerLevel == 0 then
                            ""

                        else
                            String.fromInt model.cityPlayerLevel
                    , onInput InputPlayerLevel
                    ]
                    []
                ]
            ]
        ]
    , ul [ class "list-group" ]
        (City.rolledProjects dm building
            -- |> List.filter (\r -> List.length r.project.rewards > 1)
            |> List.map
                (\r ->
                    li [ class "list-group-item card p-0" ]
                        [ div [ class "card-header" ]
                            [ span [ class "float-right" ] [ text "[", a [ Route.href <| Route.Source "city-project" r.project.name ] [ text "Source" ], text "]" ]
                            , span [ style "clear" "right" ] []
                            , div [ title r.project.uiName, style "white-space" "nowrap" ]
                                [ City.label dm r.project |> Maybe.withDefault "???" |> text
                                ]
                            ]
                        , div [ class "mx-2" ] [ City.projectOutcomes dm r.project |> Maybe.withDefault "???" |> text ]
                        , ul [ class "card-body" ] (viewRewards dm model <| City.projectRewards dm r.project)
                        ]
                )
        )
    ]


viewRewards : Datamine -> Model m -> List { weight : Int, reward : City.Reward } -> List (Html msg)
viewRewards dm model rolls =
    let
        totalWeight =
            rolls |> List.map .weight |> List.sum
    in
    rolls
        |> List.map
            (\roll ->
                li [ class "list-group-item card p-0" ]
                    [ div [ class "card-header p-1" ]
                        [ span [ title roll.reward.name ] [ text <| Maybe.withDefault "???" <| City.label dm roll.reward ]

                        -- , span [ class "badge float-right" ] [ text "[", a [ Route.href <| Route.Source "city-reward" roll.reward.name ] [ text "Source" ], text "]" ]
                        , viewWeight totalWeight roll
                        ]
                    , div [ class "card-body p-1" ]
                        (case City.rewardFormat { playerLevel = model.cityPlayerLevel } roll.reward of
                            [] ->
                                [ text "No rewards" ]

                            rewardLines ->
                                rewardLines |> List.map (\s -> div [] [ text s ])
                        )
                    ]
            )


viewWeight : Int -> { weight : Int, reward : City.Reward } -> Html msg
viewWeight totalWeight roll =
    if totalWeight == 0 || roll.weight == 0 then
        span [] []

    else
        span [ class "badge float-right", title <| String.fromInt roll.weight ++ "/" ++ String.fromInt totalWeight ]
            [ text <| percent <| toFloat roll.weight / toFloat totalWeight ]


percent : Float -> String
percent p =
    (p * 100 |> String.fromFloat |> String.left 5) ++ "%"
