module Datamine.City exposing
    ( Building
    , Category
    , Level
    , Project
    , ProjectReward
    , ProjectScaling
    , Reward
    , buildingsDecoder
    , categoriesDecoder
    , label
    , levelsDecoder
    , lore
    , projectOutcomes
    , projectRewards
    , projectScalingDecoder
    , projects
    , projectsDecoder
    , rewardFormat
    , rewardToString
    , rewardsDecoder
    , rolledProjects
    )

import Array exposing (Array)
import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Regex exposing (Regex)
import Result.Extra


type alias Project =
    { source : Source
    , name : String
    , categoryName : String
    , repeatable : Bool
    , uiName : String
    , uiLore : String
    , iconType : Maybe String
    , rewards : List ProjectReward
    }


type alias ProjectScaling =
    { source : Source
    , name : String
    , factor : Array Int
    }


type alias ProjectReward =
    { rewardName : String
    , weight : Int
    }


type alias Reward =
    { source : Source
    , name : String
    , uiName : String
    , uiLore : String
    , gold : Maybe RewardCurrency
    , pa : Maybe RewardCurrency
    , fixedItems : List RewardFixedItems
    }


type alias RewardCurrency =
    { min : Int
    , max : Int
    , perPlayerLevel : Float
    }


type alias RewardFixedItems =
    { name : String
    , min : Int
    , max : Int
    }


type alias Building =
    { source : Source
    , name : String
    , baseProduction : Int
    , uiName : String
    , uiLore : String
    , projects : List String
    , rolledProjects : List BuildingRolledProject
    }


type alias BuildingRolledProject =
    { projectName : String, weight : Int, difficulty : String }


type alias Category =
    { source : Source
    , name : String
    , uiName : String
    , order : Int
    }


type alias Level =
    { source : Source
    , level : Int
    , pptThreshold : Int
    }


label : Lang.Datamine d -> { s | uiName : String } -> Maybe String
label dm s =
    Lang.get dm s.uiName


lore : Lang.Datamine d -> { s | uiLore : String } -> Maybe String
lore dm s =
    Lang.get dm s.uiLore


type alias Datamine d =
    Lang.Datamine
        { d
            | cityProjectsByName : Dict String Project
            , cityRewardsByName : Dict String Reward
        }


projects : Datamine d -> Building -> List Project
projects dm =
    .projects >> List.filterMap (\name -> Dict.get (String.toLower name) dm.cityProjectsByName)


rolledProjects : Datamine d -> Building -> List { project : Project, weight : Int, difficulty : String }
rolledProjects dm =
    .rolledProjects
        >> List.filterMap
            (\r ->
                Dict.get (String.toLower r.projectName) dm.cityProjectsByName
                    |> Maybe.map (\p -> { project = p, weight = r.weight, difficulty = r.difficulty })
            )


projectRewards : Datamine d -> Project -> List { weight : Int, reward : Reward }
projectRewards dm =
    .rewards
        >> List.filterMap
            (\{ rewardName, weight } ->
                Dict.get (String.toLower rewardName) dm.cityRewardsByName
                    |> Maybe.map (\r -> { reward = r, weight = weight })
            )


{-| Extract the "outcomes" section of the lore text.

Awkward string processing, but this is the part most folks pay attention to

-}
projectOutcomes : Datamine d -> Project -> Maybe String
projectOutcomes dm proj =
    lore dm proj
        |> Maybe.andThen
            (\lore_ ->
                case String.split "Outcomes:" lore_ of
                    [ head, tail ] ->
                        let
                            out =
                                tail
                                    |> Regex.replace htmlTagRegex (always "")
                                    |> String.replace "\\n" ""

                            -- |> Debug.log proj.name
                        in
                        if out == "" then
                            Nothing

                        else
                            Just out

                    _ ->
                        Nothing
            )


htmlTagRegex =
    Regex.fromString "<[^>]*>" |> Maybe.withDefault Regex.never


rewardFormat : { playerLevel : Int } -> Reward -> List String
rewardFormat { playerLevel } reward =
    if playerLevel == 0 then
        rewardToString reward

    else
        List.filterMap identity
            [ reward.gold |> Maybe.andThen (rewardCurrencyFormat "Gold" playerLevel)
            , reward.pa |> Maybe.andThen (rewardCurrencyFormat "Primordial affinity" playerLevel)
            ]
            ++ (reward.fixedItems |> List.map (\f -> rangeToString { parens = False } f ++ " items: " ++ f.name))


rewardCurrencyFormat : String -> Int -> RewardCurrency -> Maybe String
rewardCurrencyFormat label_ playerLevel curr =
    if curr.min == 0 && curr.max == 0 && curr.perPlayerLevel == 0 then
        Nothing

    else
        Just <|
            label_
                ++ ": "
                ++ rangeToString { parens = False }
                    { min = curr.min + round (toFloat playerLevel * curr.perPlayerLevel)
                    , max = curr.max + round (toFloat playerLevel * curr.perPlayerLevel)
                    }


rewardToString : Reward -> List String
rewardToString reward =
    List.filterMap identity
        [ reward.gold |> Maybe.andThen (rewardCurrencyToString "Gold")
        , reward.pa |> Maybe.andThen (rewardCurrencyToString "Primordial affinity")
        ]
        ++ (reward.fixedItems |> List.map (\f -> "Items: " ++ rangeToString { parens = False } f ++ " (" ++ f.name ++ ")"))


rangeToString : { parens : Bool } -> { a | min : Int, max : Int } -> String
rangeToString { parens } r =
    if r.min == r.max then
        String.fromInt r.min

    else if parens then
        "("
            ++ String.fromInt r.min
            ++ " to "
            ++ String.fromInt r.max
            ++ ")"

    else
        String.fromInt r.min
            ++ " to "
            ++ String.fromInt r.max


rewardCurrencyToString : String -> RewardCurrency -> Maybe String
rewardCurrencyToString label_ curr =
    if curr.min == 0 && curr.max == 0 && curr.perPlayerLevel == 0 then
        Nothing

    else
        Just <|
            label_
                ++ ": "
                ++ rangeToString { parens = True } curr
                ++ " + (playerLevel * "
                ++ String.fromFloat curr.perPlayerLevel
                ++ ")"


projectsDecoder : D.Decoder (List Project)
projectsDecoder =
    Util.filteredJsons (String.contains "/CityBuilding/Projects/")
        |> D.map (List.map (\( f, d ) -> D.decodeValue (projectsDecoder_ f) d))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map List.concat


projectsDecoder_ : String -> D.Decoder (List Project)
projectsDecoder_ file =
    D.succeed Project
        |> P.custom (Source.decoder file "Project")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "CategoryName" ] D.string
        |> P.requiredAt [ "$", "Repeatable" ] Util.boolString
        |> P.requiredAt [ "UIParams", "0", "$", "UIName" ] D.string
        |> P.requiredAt [ "UIParams", "0", "$", "UILore" ] D.string
        |> P.optionalAt [ "UIParams", "0", "$", "IconType" ] (D.string |> D.map Just) Nothing
        |> P.requiredAt [ "RewardList", "0", "Reward" ]
            (D.succeed ProjectReward
                |> P.requiredAt [ "$", "RewardName" ] D.string
                |> P.requiredAt [ "$", "Weight" ] Util.intString
                |> D.list
            )
        |> D.list
        |> D.at [ "MetaData", "Project" ]


projectScalingDecoder : D.Decoder (List ProjectScaling)
projectScalingDecoder =
    let
        file =
            "Game/Umbra/CityBuilding/ScalingTables/project_tables.json"
    in
    D.succeed ProjectScaling
        |> P.custom (Source.decoder file "Table")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "Factor" ] (D.array <| D.at [ "$", "Factor" ] Util.intString)
        |> D.list
        |> D.at [ file, "MetaData", "Table" ]


rewardsDecoder : D.Decoder (List Reward)
rewardsDecoder =
    Util.filteredJsons (String.contains "/CityBuilding/Rewards/")
        |> D.map (List.map (\( f, d ) -> D.decodeValue (rewardsDecoder_ f) d))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map List.concat


rewardsDecoder_ : String -> D.Decoder (List Reward)
rewardsDecoder_ file =
    D.succeed Reward
        |> P.custom (Source.decoder file "Reward")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UITitle" ] D.string
        |> P.requiredAt [ "$", "UILore" ] D.string
        |> P.custom
            (D.succeed RewardCurrency
                |> P.requiredAt [ "Currency", "0", "$", "Gold_Min" ] Util.intString
                |> P.requiredAt [ "Currency", "0", "$", "Gold_Max" ] Util.intString
                |> P.requiredAt [ "Currency", "0", "$", "Gold_PerPlayerLevel" ] Util.floatString
                |> D.maybe
            )
        |> P.custom
            (D.succeed RewardCurrency
                |> P.requiredAt [ "Currency", "0", "$", "PA_Min" ] Util.intString
                |> P.requiredAt [ "Currency", "0", "$", "PA_Max" ] Util.intString
                |> P.requiredAt [ "Currency", "0", "$", "PA_PerPlayerLevel" ] Util.floatString
                |> D.maybe
            )
        |> P.optionalAt [ "FixedItems" ]
            (D.succeed RewardFixedItems
                |> P.requiredAt [ "$", "Name" ] D.string
                |> P.requiredAt [ "$", "MinItemNumber" ] Util.intString
                |> P.requiredAt [ "$", "MaxItemNumber" ] Util.intString
                |> D.list
            )
            []
        |> D.list
        |> D.at [ "MetaData", "Reward" ]


buildingsDecoder : D.Decoder (List Building)
buildingsDecoder =
    let
        file =
            "Game/Umbra/CityBuilding/Buildings/buildings.json"
    in
    D.succeed Building
        |> P.custom (Source.decoder file "Building")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "BaseProduction" ] Util.intString
        |> P.requiredAt [ "UIParams", "0", "$", "UIName" ] D.string
        |> P.requiredAt [ "UIParams", "0", "$", "UILore" ] D.string
        |> P.requiredAt [ "ProjectList", "0", "ProjectParams" ] (D.at [ "$", "ProjectName" ] D.string |> D.list)
        |> P.optionalAt [ "RolledProjects", "0", "RolledProjectParams" ]
            (D.succeed BuildingRolledProject
                |> P.requiredAt [ "$", "ProjectName" ] D.string
                |> P.requiredAt [ "$", "Weight" ] Util.intString
                |> P.requiredAt [ "$", "Difficulty" ] D.string
                |> D.list
            )
            []
        |> D.list
        |> D.at [ file, "MetaData", "Building" ]


categoriesDecoder : D.Decoder (List Category)
categoriesDecoder =
    let
        file =
            "Game/Umbra/CityBuilding/Categories/categories.json"
    in
    D.succeed Category
        |> P.custom (Source.decoder file "Category")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "Order" ] Util.intString
        |> D.list
        |> D.at [ file, "MetaData", "Category" ]


levelsDecoder : D.Decoder (List Level)
levelsDecoder =
    let
        file =
            "Game/Umbra/CityBuilding/City/city.json"
    in
    D.succeed Level
        |> P.custom (Source.decoder file "Level")
        |> P.requiredAt [ "$", "Level" ] Util.intString
        |> P.requiredAt [ "$", "PPTThreshold" ] Util.intString
        |> D.list
        |> D.at [ file, "MetaData", "City", "0", "Levels", "0", "Level" ]
