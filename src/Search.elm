module Search exposing
    ( Doc
    , Index
    , SearchResult
    , createIndex
    , decodeIndex
    , search
    )

import Datamine exposing (Datamine)
import Datamine.Affix as Affix
import Datamine.Gem as Gem exposing (Gem)
import Datamine.Skill as Skill exposing (Skill)
import Dict exposing (Dict)
import ElmTextSearch exposing (Index)
import Json.Decode as D
import Route exposing (Route)
import View.Affix


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


docs : Datamine -> List Doc
docs dm =
    [ dm.gems
        |> List.map
            (\gem ->
                { id = "gem/" ++ gem.name
                , localId = gem.name
                , title = Gem.label dm gem |> Maybe.withDefault ""
                , body = ""
                , effects = Gem.effects dm gem
                , keywords = gem.keywords
                , lore = ""
                }
            )
    , dm.skills
        |> List.map
            (\skill ->
                { id = "skill/" ++ skill.uid
                , localId = skill.uid
                , title = Skill.label dm skill |> Maybe.withDefault ""
                , body = Skill.desc dm skill |> Maybe.withDefault ""
                , effects = []
                , keywords = skill.keywords
                , lore = Skill.lore dm skill |> Maybe.withDefault ""
                }
            )
    , dm.skills
        |> List.concatMap .variants
        |> List.map
            (\var ->
                { id = "skill-variant/" ++ var.uid
                , localId = var.uid
                , title = Skill.label dm var |> Maybe.withDefault ""
                , body = Skill.desc dm var |> Maybe.withDefault ""
                , effects = []
                , keywords = []
                , lore = Skill.lore dm var |> Maybe.withDefault ""
                }
            )
    ]
        |> List.concat


type alias SearchResult =
    { id : String
    , score : Float
    , category : List String
    , route : Route
    , label : String
    }


toSearchResult : Datamine -> ( String, Float ) -> Maybe SearchResult
toSearchResult dm ( docId, score ) =
    let
        result =
            SearchResult docId score
    in
    case String.split "/" docId of
        [ "gem", id ] ->
            Dict.get (String.toLower id) dm.gemsByName
                |> Maybe.map
                    (\gem ->
                        gem
                            |> Gem.label dm
                            |> Maybe.withDefault "???"
                            |> result [ "Gem" ] Route.Gems
                    )

        [ "skill", id ] ->
            Dict.get (String.toLower id) dm.skillsByUid
                |> Maybe.map
                    (\skill ->
                        skill
                            |> Skill.label dm
                            |> Maybe.withDefault "???"
                            |> result [ "Skill" ] (Route.Skill id)
                    )

        [ "skill-variant", id ] ->
            Dict.get (String.toLower id) dm.skillVariantsByUid
                |> Maybe.map
                    (\( var, skill ) ->
                        var
                            |> Skill.label dm
                            |> Maybe.withDefault "???"
                            |> result [ "Skill Variant", Skill.label dm skill |> Maybe.withDefault "???" ]
                                (Route.Skill skill.uid)
                    )

        _ ->
            Nothing


createIndex : Datamine -> Result (List ( Int, String )) Index
createIndex dm =
    case ElmTextSearch.addDocs (docs dm) empty of
        ( index, [] ) ->
            Ok index

        ( _, errList ) ->
            Err errList


decodeIndex : D.Value -> Result String Index
decodeIndex =
    ElmTextSearch.fromValue config
        >> Result.mapError D.errorToString


search : Datamine -> String -> Index -> Result String ( Index, List SearchResult )
search dm q =
    ElmTextSearch.search q >> Result.map (Tuple.mapSecond (List.filterMap (toSearchResult dm)))
