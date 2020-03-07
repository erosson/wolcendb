module View.Loading exposing (ssrRootId, view, viewErr)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import RemoteData exposing (RemoteData)
import Util
import View.Nav


ssrRootId : String
ssrRootId =
    "ssr-root"


type alias Model m =
    { m | progress : Dict String ( Int, Int ) }


view : { navbar : Bool } -> Model m -> RemoteData String a -> (a -> List (Html msg)) -> List (Html msg)
view args model rd next =
    case rd of
        RemoteData.Failure err ->
            viewErr err

        RemoteData.NotAsked ->
            viewLoading args model

        RemoteData.Loading ->
            viewLoading args model

        RemoteData.Success val ->
            next val


viewLoading : { navbar : Bool } -> Model m -> List (Html msg)
viewLoading args model =
    let
        alert =
            div [ class "alert alert-info loading-alert" ]
                [ div [ class "fas fa-spinner fa-spin" ] []
                , text " Loading..."
                , div []
                    (model.progress
                        |> Dict.toList
                        |> List.sortBy Tuple.first
                        |> List.map
                            (\( key, ( val, max ) ) ->
                                let
                                    pct =
                                        Util.percent <| clamp 0 1 <| toFloat val / toFloat max
                                in
                                div [ class "loading progress" ]
                                    [ div
                                        [ class "progress-bar bg-info"
                                        , style "width" pct
                                        , style "text-align" "left"
                                        ]
                                        [ text <| key ++ ": " ++ String.fromInt val ++ "/" ++ String.fromInt max ++ " - " ++ pct ]
                                    ]
                            )
                    )
                , div [ style "font-size" "60%" ] [ text "Thanks for waiting!" ]
                ]
    in
    if args.navbar then
        [ div [ class "container" ]
            [ View.Nav.viewNoSearchbar
            , div []
                [ div []
                    [ div []
                        [ div []
                            [ div []
                                [ div []
                                    [ div []
                                        [ div []
                                            [ div [ id ssrRootId ]
                                                [-- `Ports:ssr` replaces this with SSR'ed content while loading.
                                                 -- Nested divs force Elm's dom-diffing to remove, not modify, this element when loading's done.
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "container fixed-top", style "top" "3.5em" ] [ alert ]
        ]

    else
        [ alert ]


viewErr err =
    [ div [ class "container" ]
        [ View.Nav.viewNoSearchbar
        , pre [ class "alert alert-danger" ]
            [ text <| String.right 100000 err ]
        ]
    ]
