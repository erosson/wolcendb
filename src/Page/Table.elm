module Page.Table exposing (view)

import Datamine exposing (Datamine)
import Datamine.City as City
import Datamine.Passive as Passive exposing (Passive)
import Datamine.Reagent as Reagent exposing (Reagent)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Route exposing (Route)
import Url exposing (Url)
import View.Desc


view : Datamine -> String -> Maybe (List (Html msg))
view dm tableId =
    case tableId |> String.toLower |> String.split "." of
        dataId :: viewIds ->
            let
                viewId =
                    String.join "." viewIds
            in
            Maybe.map2
                (\viewer data ->
                    viewBreadcrumb tableId
                        :: viewPageNav ( dataId, viewId )
                        :: viewer (Route.Table tableId) data
                )
                (viewFromString viewId)
                (dataFromString dm dataId)

        _ ->
            Nothing


viewBreadcrumb : String -> Html msg
viewBreadcrumb tableId =
    ul [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.Table tableId ] [ text <| String.toLower tableId ]
        ]


viewPageNav : ( String, String ) -> Html msg
viewPageNav ( dataId, viewId ) =
    div []
        [ div [ class "dropdown" ]
            [ button
                [ type_ "button"
                , class "btn btn-outline-dark dropdown-toggle"
                , attribute "data-toggle" "dropdown"
                ]
                [ text <| "Dataset: " ++ dataId ]
            , div [ class "dropdown-menu" ]
                (datas
                    |> List.map Tuple.first
                    |> List.map
                        (\nextId ->
                            let
                                id =
                                    nextId ++ "." ++ viewId
                            in
                            a
                                [ class "dropdown-item"
                                , classList [ ( "active", nextId == dataId ) ]
                                , Route.href <| Route.Table id
                                ]
                                [ text nextId ]
                        )
                )
            ]
        , div [ class "dropdown" ]
            [ button
                [ type_ "button"
                , class "btn btn-outline-dark dropdown-toggle"
                , attribute "data-toggle" "dropdown"
                ]
                [ text <| "Format: " ++ viewId ]
            , div [ class "dropdown-menu" ]
                (views
                    |> List.map Tuple.first
                    |> List.map
                        (\nextId ->
                            let
                                id =
                                    dataId ++ "." ++ nextId
                            in
                            a
                                [ class "dropdown-item"
                                , classList [ ( "active", nextId == viewId ) ]
                                , Route.href <| Route.Table id
                                ]
                                [ text nextId ]
                        )
                )
            ]
        ]


type alias Data =
    { cols : List String, rows : List Row }


type alias Row =
    List Cell


type Cell
    = StringCell String
    | LinesCell (List String)
    | DescCell String
    | ImgCell String
    | RouteCell Route String
    | IntCell Int
    | FloatCell Float
    | BoolCell Bool
    | EmptyCell


maybeCell : (a -> Cell) -> Maybe a -> Cell
maybeCell =
    Maybe.Extra.unwrap EmptyCell



-- DATAS


datas : List ( String, Datamine -> Data )
datas =
    [ ( "passive", dataPassive )
    , ( "reagent", dataReagent )
    , ( "city-project", dataCityProject )
    ]


dataByKey =
    Dict.fromList datas


dataFromString : Datamine -> String -> Maybe Data
dataFromString dm s =
    Dict.get (String.toLower s) dataByKey
        |> Maybe.map (\fn -> fn dm)


dataPassive : Datamine -> Data
dataPassive dm =
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
                    , maybeCell DescCell <| Passive.desc dm passive
                    , maybeCell DescCell <| Passive.lore dm passive
                    , LinesCell <| Passive.effects dm passive
                    ]
                )
    }


dataReagent : Datamine -> Data
dataReagent dm =
    { cols =
        [ "name"
        , "uiName"
        , "gameplayDesc"
        , "hudLoreDesc"
        , "hudPicture"
        , "reagentType"
        , "label"
        , "desc"
        , "lore"
        , "img"
        ]
    , rows =
        dm.reagents
            |> List.map
                (\reagent ->
                    [ StringCell reagent.name
                    , StringCell reagent.uiName
                    , StringCell reagent.gameplayDesc
                    , StringCell reagent.lore
                    , StringCell reagent.hudPicture
                    , StringCell reagent.reagentType
                    , maybeCell StringCell <| Reagent.label dm reagent
                    , maybeCell DescCell <| Reagent.desc dm reagent
                    , maybeCell DescCell <| Reagent.lore dm reagent
                    , ImgCell <| Reagent.img reagent
                    ]
                )
    }


dataCityProject : Datamine -> Data
dataCityProject dm =
    { cols =
        [ "name"
        , "uiName"
        , "label"
        , "uiLore"
        , "lore"
        ]
    , rows =
        dm.cityProjects
            |> List.map
                (\proj ->
                    [ StringCell proj.name
                    , StringCell proj.uiName
                    , maybeCell StringCell <| City.label dm proj
                    , StringCell proj.uiLore
                    , maybeCell DescCell <| City.lore dm proj
                    ]
                )
    }



-- VIEWS


views : List ( String, Route -> Data -> List (Html msg) )
views =
    [ ( "html", always viewHtml )
    , ( "tsv", viewTsv )
    , ( "csv", viewCsv )
    , ( "json", viewJsonObjects 2 )
    , ( "min.json", viewJsonObjects 0 )
    , ( "table.json", viewJsonTable 2 )
    , ( "table.min.json", viewJsonTable 0 )
    ]


viewByKey =
    Dict.fromList views


viewFromString : String -> Maybe (Route -> Data -> List (Html msg))
viewFromString s =
    Dict.get (String.toLower s) viewByKey


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
                                [ ul [] (ls |> List.map (\l -> li [] [ text l ])) ]

                            DescCell s ->
                                [ div [ style "min-width" "20em" ] (View.Desc.format s) ]

                            ImgCell s ->
                                [ img [ src s ] [] ]

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


viewTextarea : String -> List (Html msg)
viewTextarea s =
    [ textarea [ class "form-control", rows 20, cols 100, readonly True ]
        [ text s ]
    ]


viewTsv : Route -> Data -> List (Html msg)
viewTsv route =
    formatTsv route >> viewTextarea


formatTsv : Route -> Data -> String
formatTsv route =
    toStringCells route
        >> List.map (List.map formatTsvString >> String.join "\t")
        >> String.join "\n"


{-| <https://en.wikipedia.org/wiki/Tab-separated_values#Conventions_for_lossless_conversion_to_TSV>
-}
formatTsvString : String -> String
formatTsvString =
    String.replace "\\" "\\\\"
        >> String.replace "\t" "\\t"
        >> String.replace "\n" "\\n"
        -- elm-format is replacing \r here. ¯\_(ツ)_/¯
        >> String.replace "\u{000D}" "\\r"


viewCsv : Route -> Data -> List (Html msg)
viewCsv route =
    formatCsv route >> viewTextarea


formatCsv : Route -> Data -> String
formatCsv route =
    toStringCells route
        >> List.map (List.map formatCsvString >> String.join ",")
        >> String.join "\n"


{-| <https://en.wikipedia.org/wiki/Comma-separated_values#Basic_rules>
-}
formatCsvString : String -> String
formatCsvString raw =
    if String.contains "," raw || String.contains "\"" raw then
        "\"" ++ String.replace "\"" "\"\"" raw ++ "\""

    else
        raw


toStringCells : Route -> Data -> List (List String)
toStringCells route data =
    (data.cols ++ [ route |> Route.toUrl |> Url.toString ]) :: List.map (List.map toStringCell) data.rows


toStringCell : Cell -> String
toStringCell cell =
    case cell of
        StringCell s ->
            s

        LinesCell ls ->
            String.join "\n" ls

        DescCell s ->
            s

        ImgCell s ->
            s

        RouteCell r s ->
            s

        IntCell i ->
            String.fromInt i

        FloatCell f ->
            String.fromFloat f

        BoolCell b ->
            if b then
                "TRUE"

            else
                "FALSE"

        EmptyCell ->
            ""


viewJsonTable : Int -> Route -> Data -> List (Html msg)
viewJsonTable indent route =
    formatJsonTable indent route >> viewTextarea


formatJsonTable : Int -> Route -> Data -> String
formatJsonTable indent route data =
    E.object
        [ ( "source", route |> Route.toUrl |> Url.toString |> E.string )
        , ( "cols", E.list E.string data.cols )
        , ( "rows", E.list (E.list toJsonCell) data.rows )
        ]
        |> E.encode indent


viewJsonObjects : Int -> Route -> Data -> List (Html msg)
viewJsonObjects indent route =
    formatJsonObjects indent route >> viewTextarea


formatJsonObjects : Int -> Route -> Data -> String
formatJsonObjects indent route data =
    E.object
        [ ( "source", route |> Route.toUrl |> Url.toString |> E.string )
        , ( "data"
          , data.rows
                |> E.list
                    (List.map toJsonCell
                        >> List.map2 Tuple.pair data.cols
                        >> E.object
                    )
          )
        ]
        |> E.encode indent


toJsonCell : Cell -> E.Value
toJsonCell cell =
    case cell of
        StringCell s ->
            E.string s

        LinesCell ls ->
            E.list E.string ls

        DescCell s ->
            E.string s

        ImgCell s ->
            E.string s

        RouteCell r s ->
            E.string s

        IntCell i ->
            E.int i

        FloatCell f ->
            E.float f

        BoolCell b ->
            E.bool b

        EmptyCell ->
            E.null
