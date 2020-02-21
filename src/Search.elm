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
import Datamine.NormalItem as NormalItem
import Datamine.Passive as Passive exposing (Passive)
import Datamine.Skill as Skill exposing (Skill)
import Datamine.UniqueItem as UniqueItem
import Dict exposing (Dict)
import ElmTextSearch exposing (Index)
import Json.Decode as D
import List.Extra
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
    , dm.passiveTreeEntries
        |> List.map
            (\( entry, passive, tree ) ->
                { id = "passive/" ++ entry.name
                , localId = entry.name
                , title = Passive.label dm passive |> Maybe.withDefault ""
                , body = Passive.desc dm passive |> Maybe.withDefault ""
                , effects = Passive.effects dm passive
                , keywords =
                    [ entry.category
                    , Passive.nodeTypeLabel dm entry tree
                    ]
                , lore = Passive.lore dm passive |> Maybe.withDefault ""
                }
            )
    , dm.loot
        |> List.map
            (\nitem ->
                { id = "normal-loot/" ++ NormalItem.name nitem
                , localId = NormalItem.name nitem
                , title = NormalItem.label dm nitem |> Maybe.withDefault ""
                , body = ""
                , effects = NormalItem.implicitEffects dm nitem
                , keywords = NormalItem.keywords nitem
                , lore = ""
                }
            )
    , dm.uniqueLoot
        |> List.filter (\uitem -> UniqueItem.label dm uitem /= Nothing)
        |> List.map
            (\uitem ->
                { id = "unique-loot/" ++ UniqueItem.name uitem
                , localId = UniqueItem.name uitem
                , title = UniqueItem.label dm uitem |> Maybe.withDefault ""
                , body = ""
                , effects =
                    UniqueItem.implicitEffects dm uitem
                        ++ UniqueItem.defaultEffects dm uitem
                , keywords = UniqueItem.keywords uitem
                , lore = UniqueItem.lore dm uitem |> Maybe.withDefault ""
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


{-| Search results are document ids. Instead of indexing/regenerating the whole document, convert the id to a result.
-}
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
                        result [ "Gem" ]
                            Route.Gems
                            (Gem.label dm gem |> Maybe.withDefault "???")
                    )

        [ "skill", id ] ->
            Dict.get (String.toLower id) dm.skillsByUid
                |> Maybe.map
                    (\skill ->
                        result [ "Skill" ]
                            (Route.Skill id)
                            (Skill.label dm skill |> Maybe.withDefault "???")
                    )

        [ "skill-variant", id ] ->
            Dict.get (String.toLower id) dm.skillVariantsByUid
                |> Maybe.map
                    (\( var, skill ) ->
                        result
                            [ "Skill Variant"
                            , Skill.label dm skill |> Maybe.withDefault "???"
                            ]
                            (Route.Skill skill.uid)
                            (Skill.label dm var |> Maybe.withDefault "???")
                    )

        [ "passive", id ] ->
            Dict.get (String.toLower id) dm.passiveTreeEntriesByName
                |> Maybe.map
                    (\( entry, passive, tree ) ->
                        result
                            [ "Passive"
                            , Passive.label dm tree |> Maybe.withDefault "???"
                            ]
                            Route.Passives
                            (Passive.label dm passive |> Maybe.withDefault "???")
                    )

        [ "normal-loot", id ] ->
            Dict.get (String.toLower id) dm.lootByName
                |> Maybe.map
                    (\nitem ->
                        result
                            [ "Normal Loot" ]
                            (case nitem of
                                NormalItem.NWeapon _ ->
                                    Route.Weapon id

                                NormalItem.NShield _ ->
                                    Route.Shield id

                                NormalItem.NArmor _ ->
                                    Route.Armor id

                                NormalItem.NAccessory _ ->
                                    Route.Accessory id
                            )
                            (NormalItem.label dm nitem |> Maybe.withDefault "???")
                    )

        [ "unique-loot", id ] ->
            Dict.get (String.toLower id) dm.uniqueLootByName
                |> Maybe.map
                    (\uitem ->
                        result
                            [ "Unique Loot" ]
                            (case uitem of
                                UniqueItem.UWeapon _ ->
                                    Route.UniqueWeapon id

                                UniqueItem.UShield _ ->
                                    Route.UniqueShield id

                                UniqueItem.UArmor _ ->
                                    Route.UniqueArmor id

                                UniqueItem.UAccessory _ ->
                                    Route.UniqueAccessory id
                            )
                            (UniqueItem.label dm uitem |> Maybe.withDefault "???")
                    )

        _ ->
            Nothing


createIndex : Datamine -> Result (List ( Int, String, String )) Index
createIndex dm =
    let
        docs_ =
            docs dm
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


search : Datamine -> String -> Index -> Result String ( Index, List SearchResult )
search dm q =
    if String.length q <= 2 then
        always <| Err "Search too short"

    else
        ElmTextSearch.search q >> Result.map (Tuple.mapSecond (List.take 25 >> List.filterMap (toSearchResult dm)))
