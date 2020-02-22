module Page.Table exposing (view)

import Datamine exposing (Datamine)
import Datamine.Passive as Passive exposing (Passive)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)


view : Datamine -> String -> Maybe (List (Html msg))
view dm tableId =
    case tableId |> String.toLower |> String.split "." of
        [ dataId, viewId ] ->
            Maybe.map2 (\viewer data -> viewer data)
                (viewFromString viewId)
                (dataFromString dm dataId)

        _ ->
            Nothing


type alias Data =
    { cols : List String, rows : List Row }


type alias Row =
    List Cell


type Cell
    = StringCell String
    | LinesCell (List String)
    | RouteCell Route String
    | IntCell Int
    | FloatCell Float
    | BoolCell Bool
    | EmptyCell


maybeCell : (a -> Cell) -> Maybe a -> Cell
maybeCell =
    Maybe.Extra.unwrap EmptyCell



-- DATAS


dataFromString : Datamine -> String -> Maybe Data
dataFromString dm dataId =
    case dataId of
        "passive" ->
            passiveData dm |> Just

        _ ->
            Nothing


passiveData : Datamine -> Data
passiveData dm =
    { cols =
        [ "name"
        , "uiName"
        , "hudLoreDesc"
        , "gameplayDesc"
        , "rarity"
        , "category"
        , "label"
        , "desc"
        , "lore"
        , "effects"
        ]
    , rows =
        dm.passiveTreeEntries
            |> List.map
                (\( entry, passive, tree ) ->
                    [ StringCell passive.name
                    , StringCell passive.uiName
                    , maybeCell StringCell passive.hudLoreDesc
                    , maybeCell StringCell passive.gameplayDesc
                    , IntCell entry.rarity
                    , StringCell entry.category
                    , maybeCell StringCell <| Passive.label dm passive
                    , maybeCell StringCell <| Passive.desc dm passive
                    , maybeCell StringCell <| Passive.lore dm passive
                    , LinesCell <| Passive.effects dm passive
                    ]
                )
    }



-- VIEWS


viewFromString : String -> Maybe (Data -> List (Html msg))
viewFromString format =
    case format of
        "html" ->
            Just viewHtml

        _ ->
            Nothing


viewHtml : Data -> List (Html msg)
viewHtml d =
    [ table [ class "table" ]
        [ thead [] [ tr [] (d.cols |> List.map (\col -> th [ class "sticky" ] [ text col ])) ]
        , tbody []
            (List.map
                (List.map
                    (\cell ->
                        case cell of
                            StringCell s ->
                                [ text s ]

                            LinesCell ls ->
                                ls |> List.map (\l -> div [] [ text l ])

                            RouteCell r s ->
                                [ a [ Route.href r ] [ text s ] ]

                            IntCell i ->
                                [ text <| String.fromInt i ]

                            FloatCell f ->
                                [ text <| String.fromFloat f ]

                            BoolCell b ->
                                if b then
                                    [ text "TRUE" ]

                                else
                                    []

                            EmptyCell ->
                                []
                    )
                    >> List.map (td [])
                    >> tr []
                )
                d.rows
            )
        ]
    ]
