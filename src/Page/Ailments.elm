module Page.Ailments exposing (Msg, update, view)

import Datamine exposing (Datamine)
import Datamine.Ailment as Ailment exposing (Ailment)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Desc


type Msg
    = InputPlayerLevel String


type alias Model m =
    { m | cityPlayerLevel : Int }


update : Msg -> Datamine -> Model m -> Model m
update msg dm model =
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


view : Datamine -> Model m -> List (Html Msg)
view dm model =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Ailments ] [ text "Ailments" ]
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
    , div []
        (dm.ailments
            |> List.map
                (\ail ->
                    div [ class "card" ]
                        [ div [ class "card-header" ]
                            [ span [ class "float-right" ] [ text "[", a [ Route.href <| Route.Source "ailment" ail.name ] [ text "Source" ], text "]" ]
                            , span [ style "clear" "right" ] []
                            , text ail.name
                            ]
                        , table [ class "card-body" ]
                            [ thead []
                                (th [] [ text "level" ]
                                    :: (case ail.params of
                                            [] ->
                                                []

                                            p :: _ ->
                                                p.values |> List.map (\( k, _ ) -> th [] [ text k ])
                                       )
                                )
                            , tbody []
                                (ail.params
                                    |> List.filter (\p -> model.cityPlayerLevel == 0 || model.cityPlayerLevel == p.level)
                                    |> List.map
                                        (\p ->
                                            tr []
                                                (td [] [ text <| String.fromInt p.level ]
                                                    :: (p.values
                                                            |> List.map
                                                                (\( _, v ) ->
                                                                    td [] [ text <| String.fromFloat v ]
                                                                )
                                                       )
                                                )
                                        )
                                )
                            ]
                        ]
                )
        )
    ]
