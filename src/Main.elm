module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Url exposing (Url)



---- MODEL ----


type alias Model =
    Result String OkModel


type alias OkModel =
    { nav : Nav.Key
    , datamine : Datamine
    }


type alias Flags =
    { datamine : Datamine.Flag
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    case Datamine.decode flags.datamine of
        Err err ->
            ( Err err, Cmd.none )

        Ok datamine ->
            ( Ok
                { nav = nav
                , datamine = datamine
                }
            , Cmd.none
            )



---- UPDATE ----


type Msg
    = OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "WolcenDB", body = viewBody model }


viewBody : Model -> List (Html Msg)
viewBody mmodel =
    case mmodel of
        Err err ->
            [ code [] [ text err ] ]

        Ok model ->
            viewOk model


viewOk : OkModel -> List (Html Msg)
viewOk model =
    [ div []
        [ h1 [] [ text "hello from wolcendb" ]
        , h1 [] [ text "Weapons" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "damage" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (model.datamine.loot.weapons
                    |> List.take 100
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Dict.get (String.replace "@" "" w.uiName) model.datamine.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                , td [] [ text w.name ]
                                , td []
                                    [ Maybe.Extra.unwrap "?" String.fromInt w.damage.min
                                        ++ "-"
                                        ++ Maybe.Extra.unwrap "?" String.fromInt w.damage.max
                                        |> text
                                    ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        , h1 [] [ text "Shields" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (model.datamine.loot.shields
                    |> List.take 100
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Dict.get (String.replace "@" "" w.uiName) model.datamine.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                , td [] [ text w.name ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        , h1 [] [ text "Armors" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (model.datamine.loot.armors
                    |> List.take 100
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Dict.get (String.replace "@" "" w.uiName) model.datamine.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                , td [] [ text w.name ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        , h1 [] [ text "Accessories" ]
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "keywords" ]
                    ]
                ]
            , tbody []
                (model.datamine.loot.accessories
                    |> List.take 100
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Dict.get (String.replace "@" "" w.uiName) model.datamine.en
                                        |> Maybe.withDefault "???"
                                        |> text
                                    ]
                                , td [] [ text w.name ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                ]
                        )
                )
            ]
        ]
    ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
