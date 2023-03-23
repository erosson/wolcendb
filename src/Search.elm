module Search exposing
    ( Doc
    , Index
    , SearchResult
    , SearchScore
    , createIndex
    , decodeIndex
    , search
    , toResults
    )

import Datamine exposing (Datamine)
import Datamine.Affix as Affix
import Datamine.Gem as Gem exposing (Gem)
import Datamine.NormalItem as NormalItem
import Datamine.Passive as Passive exposing (Passive)
import Datamine.Skill as Skill exposing (Skill)
import Datamine.UniqueItem as UniqueItem
import Dict exposing (Dict)
import ElmTextSearch exposing (Index)
import Json.Decode as D
import Lang exposing (Lang)
import List.Extra
import Route exposing (Route)
import View.Affix
import Set exposing (Set)


type alias Doc =
    { id : String
    , localId : String
    , title : String
    , keywords : List String
    , body : String
    , effects : List String
    , lore : String
    }


type alias Index =
    ElmTextSearch.Index Doc


config =
    { ref = .id
    , fields =
        [ ( .title, 5.0 )
        , ( .id, 3.0 )
        , ( .localId, 3.0 )
        , ( .body, 1.0 )
        , ( .lore, 0.5 )
        ]
    , listFields =
        [ ( .keywords, 3.0 )
        , ( .effects, 2.0 )
        ]
    }


empty : Index
empty =
    ElmTextSearch.new config


docs : Lang -> Datamine -> List Doc
docs lang dm =
    [ dm.gems
        |> List.map
            (\gem ->
                { id = "gem/" ++ gem.name
                , localId = gem.name
                , title = Gem.label lang gem |> Maybe.withDefault ""
                , body = ""
                , effects = Gem.effects lang dm gem
                , keywords = gem.keywords
                , lore = ""
                }
            )
    , dm.skills
        |> List.map
            (\skill ->
                { id = "skill/" ++ skill.uid
                , localId = skill.uid
                , title = Skill.label lang skill |> Maybe.withDefault ""
                , body = Skill.desc lang skill |> Maybe.withDefault ""
                , effects = []
                , keywords = skill.keywords
                , lore = Skill.lore lang skill |> Maybe.withDefault ""
                }
            )
    , dm.skills
        |> List.concatMap .variants
        |> List.map
            (\var ->
                { id = "skill-variant/" ++ var.uid
                , localId = var.uid
                , title = Skill.label lang var |> Maybe.withDefault ""
                , body = Skill.desc lang var |> Maybe.withDefault ""
                , effects = []
                , keywords = []
                , lore = Skill.lore lang var |> Maybe.withDefault ""
                }
            )
    , dm.passiveTreeEntries
        |> List.map
            (\( entry, passive, tree ) ->
                { id = "passive/" ++ entry.name
                , localId = entry.name
                , title = Passive.label lang passive |> Maybe.withDefault ""
                , body = Passive.desc lang passive |> Maybe.withDefault ""
                , effects = Passive.effects lang passive
                , keywords =
                    [ entry.category
                    , Passive.nodeTypeLabel lang entry tree
                    ]
                , lore = Passive.lore lang passive |> Maybe.withDefault ""
                }
            )
    , dm.loot
        |> List.map
            (\nitem ->
                { id = "normal-loot/" ++ NormalItem.name nitem
                , localId = NormalItem.name nitem
                , title = NormalItem.label lang nitem |> Maybe.withDefault ""
                , body = ""
                , effects = NormalItem.implicitEffects lang dm nitem
                , keywords = NormalItem.keywords nitem
                , lore = ""
                }
            )
    , dm.uniqueLoot
        |> List.filter (\uitem -> UniqueItem.label lang uitem /= Nothing)
        |> List.map
            (\uitem ->
                { id = "unique-loot/" ++ UniqueItem.name uitem
                , localId = UniqueItem.name uitem
                , title = UniqueItem.label lang uitem |> Maybe.withDefault ""
                , body = ""
                , effects =
                    UniqueItem.implicitEffects lang dm uitem
                        ++ UniqueItem.defaultEffects lang dm uitem
                , keywords = UniqueItem.keywords uitem
                , lore = UniqueItem.lore lang uitem |> Maybe.withDefault ""
                }
            )
        -- I don't know why it's generating duplicates, but let's just get this running
        |> List.Extra.uniqueBy .id
    ]
        |> List.concat


type alias SearchScore =
    ( String, Float )


type alias SearchResult =
    { id : String
    , score : Float
    , category : List String
    , route : Route
    , label : String
    }


toResults : Lang -> Datamine -> List SearchScore -> List SearchResult
toResults lang dm =
    List.filterMap (toResult lang dm)


{-| Search results are document ids. Instead of indexing/regenerating the whole document, convert the id to a result.
-}
toResult : Lang -> Datamine -> SearchScore -> Maybe SearchResult
toResult lang dm ( docId, score ) =
    let
        result =
            SearchResult docId score
    in
    case String.split "/" docId of
        [ "gem", id ] ->
            Dict.get (String.toLower id) dm.gemsByName
                |> Maybe.map
                    (\gem ->
                        result [ "Gem" ]
                            Route.Gems
                            (Gem.label lang gem |> Maybe.withDefault "???")
                    )

        [ "skill", id ] ->
            Dict.get (String.toLower id) dm.skillsByUid
                |> Maybe.map
                    (\skill ->
                        result [ "Skill" ]
                            (Route.Skill id)
                            (Skill.label lang skill |> Maybe.withDefault "???")
                    )

        [ "skill-variant", id ] ->
            Dict.get (String.toLower id) dm.skillVariantsByUid
                |> Maybe.map
                    (\( var, skill ) ->
                        result
                            [ "Skill Variant"
                            , Skill.label lang skill |> Maybe.withDefault "???"
                            ]
                            (Route.SkillVariant var.uid)
                            (Skill.label lang var |> Maybe.withDefault "???")
                    )

        [ "passive", id ] ->
            Dict.get (String.toLower id) dm.passiveTreeEntriesByName
                |> Maybe.map
                    (\( entry, passive, tree ) ->
                        result
                            [ "Passive"
                            , Passive.label lang tree |> Maybe.withDefault "???"
                            ]
                            Route.Passives
                            (Passive.label lang passive |> Maybe.withDefault "???")
                    )

        [ "normal-loot", id ] ->
            Dict.get (String.toLower id) dm.lootByName
                |> Maybe.map
                    (\nitem ->
                        result
                            [ "Normal Loot" ]
                            (nitem |> NormalItem.name |> Route.NormalItem)
                            (nitem |> NormalItem.label lang |> Maybe.withDefault "???")
                    )

        [ "unique-loot", id ] ->
            Dict.get (String.toLower id) dm.uniqueLootByName
                |> Maybe.map
                    (\uitem ->
                        result
                            [ "Unique Loot" ]
                            (uitem |> UniqueItem.name |> Route.UniqueItem)
                            (uitem |> UniqueItem.label lang |> Maybe.withDefault "???")
                    )

        _ ->
            Nothing


createIndex : Lang -> Datamine -> Result (List ( Int, String, String )) Index
createIndex lang dm =
    let
        docs_ =
            docs lang dm
    in
    case ElmTextSearch.addDocs docs_ empty of
        ( index, [] ) ->
            Ok index

        ( _, errList ) ->
            errList
                |> List.map
                    (\( errIndex, errMsg ) ->
                        ( errIndex, List.Extra.getAt errIndex docs_ |> Maybe.map .id |> Maybe.withDefault "???", errMsg )
                    )
                |> Err


decodeIndex : D.Value -> Result String Index
decodeIndex =
    ElmTextSearch.fromValue config
        >> Result.mapError D.errorToString


search : Datamine -> String -> Index -> Result String ( Index, List SearchScore )
search dm q =
    if String.length q <= 2 then
        always <| Err "Search too short"

    else
        ElmTextSearch.search q >> Result.map (Tuple.mapSecond (List.take 25))
