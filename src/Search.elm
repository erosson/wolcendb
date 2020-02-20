module Search exposing (Doc, Index, createIndex, decodeIndex, search)

import Datamine exposing (Datamine)
import Datamine.Affix as Affix
import Datamine.Gem as Gem exposing (Gem)
import ElmTextSearch exposing (Index)
import Json.Decode as D
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
                , title = Gem.label dm gem |> Maybe.withDefault "???"
                , body = ""
                , effects =
                    gem.effects
                        |> List.map Tuple.second
                        |> List.concatMap (\affixId -> Affix.getNonmagicIds dm [ affixId ])
                        |> List.concatMap .effects
                        |> List.filterMap (Affix.formatEffect dm)
                , keywords = gem.keywords
                , lore = ""
                }
            )
    ]
        |> List.concat


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


search : String -> Index -> Result String ( Index, List ( String, Float ) )
search =
    ElmTextSearch.search
