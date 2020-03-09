module Page.Table exposing (view)

import Array exposing (Array)
import Datamine exposing (Datamine)
import Datamine.City as City
import Datamine.GemFamily as GemFamily exposing (GemFamily)
import Datamine.NormalItem as NormalItem exposing (NormalItem(..))
import Datamine.Passive as Passive exposing (Passive)
import Datamine.Reagent as Reagent exposing (Reagent)
import Datamine.Skill as Skill exposing (Skill)
import Datamine.UniqueItem as UniqueItem exposing (UniqueItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Json.Decode as D
import Json.Encode as E
import Lang exposing (Lang)
import Maybe.Extra
import Route exposing (Route)
import Url exposing (Url)
import View.Desc


view : Lang -> Datamine -> String -> Maybe (List (Html msg))
view lang dm tableId =
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
                (dataFromString lang dm dataId)

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
    | SourceCell String String
    | IntCell Int
    | FloatCell Float
    | BoolCell Bool
    | EmptyCell


maybeCell : (a -> Cell) -> Maybe a -> Cell
maybeCell =
    Maybe.Extra.unwrap EmptyCell



-- DATAS


datas : List ( String, Lang -> Datamine -> Data )
datas =
    [ ( "normal-loot", dataNormalItem )
    , ( "unique-loot", dataUniqueItem )
    , ( "passive", dataPassive )
    , ( "reagent", dataReagent )
    , ( "gem-family", dataGemFamily )
    , ( "city-project", dataCityProject )
    , ( "city-project-scaling", always dataCityProjectScaling )
    , ( "city-reward", dataCityReward )
    , ( "city-building", dataCityBuilding )
    , ( "city-category", always dataCityCategory )
    , ( "city-level", always dataCityLevel )
    , ( "skill-effect-popularity", always dataSkillEffectPopularity )
    ]


dataByKey =
    Dict.fromList datas


dataFromString : Lang -> Datamine -> String -> Maybe Data
dataFromString lang dm s =
    Dict.get (String.toLower s) dataByKey
        |> Maybe.map (\fn -> fn lang dm)


dataNormalItem : Lang -> Datamine -> Data
dataNormalItem lang dm =
    { cols =
        [ "name"
        , "label"
        , "baseEffects"
        , "implicitEffects"
        ]
    , rows =
        dm.loot
            |> List.map
                (\nitem ->
                    [ StringCell <| NormalItem.name nitem
                    , maybeCell StringCell <| NormalItem.label lang nitem
                    , LinesCell <| NormalItem.baseEffects dm nitem
                    , LinesCell <| NormalItem.implicitEffects lang dm nitem
                    ]
                )
    }


dataUniqueItem : Lang -> Datamine -> Data
dataUniqueItem lang dm =
    { cols =
        [ "name"
        , "label"
        , "lore"
        , "baseEffects"
        , "implicitEffects"
        , "defaultEffects"
        ]
    , rows =
        dm.uniqueLoot
            |> List.map
                (\uitem ->
                    [ StringCell <| UniqueItem.name uitem
                    , maybeCell StringCell <| UniqueItem.label lang uitem
                    , maybeCell DescCell <| UniqueItem.lore lang uitem
                    , LinesCell <| UniqueItem.baseEffects dm uitem
                    , LinesCell <| UniqueItem.implicitEffects lang dm uitem
                    , LinesCell <| UniqueItem.defaultEffects lang dm uitem
                    ]
                )
    }


dataPassive : Lang -> Datamine -> Data
dataPassive lang dm =
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
                    , maybeCell StringCell <| Passive.label lang passive
                    , maybeCell DescCell <| Passive.desc lang passive
                    , maybeCell DescCell <| Passive.lore lang passive
                    , LinesCell <| Passive.effects lang passive
                    ]
                )
    }


dataReagent : Lang -> Datamine -> Data
dataReagent lang dm =
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
                    , maybeCell StringCell <| Reagent.label lang reagent
                    , maybeCell DescCell <| Reagent.desc lang reagent
                    , maybeCell DescCell <| Reagent.lore lang reagent
                    , ImgCell <| Reagent.img reagent
                    ]
                )
    }


dataGemFamily : Lang -> Datamine -> Data
dataGemFamily lang dm =
    { cols =
        [ "gemFamilyId"
        , "relatedGems"
        , "craftRelatedAffixes"
        , "label"
        , "img"
        ]
    , rows =
        dm.gemFamilies
            |> List.map
                (\fam ->
                    [ StringCell fam.gemFamilyId
                    , LinesCell <| List.map .gemId fam.relatedGems
                    , LinesCell fam.craftRelatedAffixes
                    , StringCell <| GemFamily.label lang dm fam
                    , ImgCell <| GemFamily.img dm fam
                    ]
                )
    }


dataCityProject : Lang -> Datamine -> Data
dataCityProject lang dm =
    { cols =
        [ "name"
        , "source"
        , "uiName"
        , "label"
        , "uiLore"
        , "lore"
        , "outcomes"
        ]
    , rows =
        dm.cityProjects
            |> List.map
                (\proj ->
                    [ StringCell proj.name
                    , SourceCell "city-project" proj.name
                    , StringCell proj.uiName
                    , maybeCell StringCell <| City.label lang proj
                    , StringCell proj.uiLore
                    , maybeCell DescCell <| City.lore lang proj
                    , LinesCell <| List.map (String.fromInt << .weight) proj.rewards
                    , LinesCell <| List.map .rewardName proj.rewards
                    , LinesCell <| List.map (Maybe.withDefault "???" << City.label lang << .reward) <| City.projectRewards dm proj
                    , maybeCell StringCell <| City.projectOutcomes lang proj
                    ]
                )
    }


dataCityProjectScaling : Datamine -> Data
dataCityProjectScaling dm =
    { cols =
        [ "name"
        , "factor"
        ]
    , rows =
        dm.cityProjectScaling
            |> List.map
                (\scale ->
                    [ StringCell scale.name
                    , LinesCell <| List.map String.fromInt <| Array.toList scale.factor
                    ]
                )
    }


dataCityReward : Lang -> Datamine -> Data
dataCityReward lang dm =
    { cols =
        [ "name"
        , "uiTitle"
        , "uiLore"
        , "label"
        , "lore"
        ]
    , rows =
        dm.cityRewards
            |> List.map
                (\reward ->
                    [ StringCell reward.name
                    , SourceCell "city-reward" reward.name
                    , StringCell reward.uiName
                    , StringCell reward.uiLore
                    , maybeCell DescCell <| City.label lang reward
                    , maybeCell DescCell <| City.lore lang reward
                    , LinesCell <| City.rewardToString reward
                    ]
                )
    }


dataCityBuilding : Lang -> Datamine -> Data
dataCityBuilding lang dm =
    { cols =
        [ "name"
        , "uiTitle"
        , "uiLore"
        , "project.name"
        , "rolledProject.name"
        , "label"
        , "lore"
        , "project.label"
        , "rolledProject.label"
        ]
    , rows =
        dm.cityBuildings
            |> List.map
                (\building ->
                    [ StringCell building.name
                    , StringCell building.uiName
                    , StringCell building.uiLore
                    , LinesCell <| building.projects
                    , LinesCell <| List.map .projectName building.rolledProjects
                    , maybeCell DescCell <| City.label lang building
                    , maybeCell DescCell <| City.lore lang building
                    , LinesCell <| List.map (Maybe.withDefault "???" << City.label lang) <| City.projects dm building
                    , LinesCell <| List.map (Maybe.withDefault "???" << City.label lang << .project) <| City.rolledProjects dm building
                    ]
                )
    }


dataCityCategory : Datamine -> Data
dataCityCategory dm =
    { cols =
        [ "name"
        , "uiTitle"
        , "order"
        ]
    , rows =
        dm.cityCategories
            |> List.map
                (\cat ->
                    [ StringCell cat.name
                    , StringCell cat.uiName
                    , IntCell cat.order
                    ]
                )
    }


dataCityLevel : Datamine -> Data
dataCityLevel dm =
    { cols =
        [ "level"
        , "productionThreshold"
        ]
    , rows =
        dm.cityLevels
            |> List.map
                (\level ->
                    [ IntCell level.level
                    , IntCell level.pptThreshold
                    ]
                )
    }


dataSkillEffectPopularity : Datamine -> Data
dataSkillEffectPopularity dm =
    { cols =
        [ "effect"
        , "count"
        ]
    , rows =
        Skill.popularEffects dm
            |> List.map
                (\( effect, count ) ->
                    [ StringCell effect
                    , IntCell count
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
                                [ ul [ style "min-width" "15em" ] (ls |> List.map (\l -> li [] [ text l ])) ]

                            DescCell s ->
                                [ div [ style "min-width" "20em" ] (View.Desc.format s) ]

                            ImgCell s ->
                                [ img [ src s ] [] ]

                            RouteCell r s ->
                                [ a [ Route.href r ] [ text s ] ]

                            SourceCell type_ id ->
                                [ text "[", a [ Route.href <| Route.Source type_ id ] [ text "Source" ], text "]" ]

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

        SourceCell type_ id ->
            ""

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

        SourceCell type_ id ->
            E.null

        IntCell i ->
            E.int i

        FloatCell f ->
            E.float f

        BoolCell b ->
            E.bool b

        EmptyCell ->
            E.null
