module Datamine.Passive exposing
    ( Passive
    , PassiveEffect
    , PassiveTree
    , PassiveTreeEntry
    , decoder
    , desc
    , effects
    , label
    , lore
    , nodeTypeLabel
    , treesDecoder
    )

import Datamine.Affix as Affix
import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Passive =
    { source : Source
    , name : String
    , uiName : String
    , hudLoreDesc : Maybe String
    , gameplayDesc : Maybe String
    , effects : List PassiveEffect
    }


type alias PassiveEffect =
    { name : String
    , hudDesc : Maybe String
    , semantics : List ( String, Float )
    }


type alias PassiveTree =
    { source : Source
    , name : String
    , uiName : String
    , category : String
    , entries : List PassiveTreeEntry
    }


type alias PassiveTreeEntry =
    { source : Source
    , name : String
    , rarity : Int
    , category : String
    }


label : Lang.Datamine d -> { s | uiName : String } -> Maybe String
label dm s =
    Lang.get dm s.uiName


desc : Lang.Datamine d -> Passive -> Maybe String
desc dm s =
    Lang.mget dm s.gameplayDesc


lore : Lang.Datamine d -> Passive -> Maybe String
lore dm s =
    Lang.mget dm s.hudLoreDesc


nodeTypeLabel : Lang.Datamine d -> PassiveTreeEntry -> PassiveTree -> String
nodeTypeLabel dm entry tree =
    (label dm tree |> Maybe.withDefault "Unknown")
        ++ (case entry.rarity of
                2 ->
                    " Notable"

                3 ->
                    " Keystone"

                _ ->
                    ""
           )


effects : Affix.Datamine d -> Passive -> List String
effects dm =
    .effects >> List.filterMap (formatEffect dm)


formatEffect : Lang.Datamine d -> PassiveEffect -> Maybe String
formatEffect dm effect =
    Lang.mget dm effect.hudDesc
        |> Maybe.map
            (\template ->
                effect.semantics
                    |> List.map (Tuple.mapSecond (\v -> Util.Range v v))
                    |> List.indexedMap Tuple.pair
                    |> List.foldl Util.formatEffectStat template
            )


treesDecoder : D.Decoder (List PassiveTree)
treesDecoder =
    Util.filteredJsons
        (String.contains "Skills/Trees/PassiveSkills")
        |> D.map (List.map (\( filename, json ) -> D.decodeValue (passiveTreesDecoder filename) json))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder


passiveTreesDecoder : String -> D.Decoder PassiveTree
passiveTreesDecoder file =
    D.succeed PassiveTree
        |> P.custom (Source.decoder file "Tree")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "Category" ] D.string
        |> P.custom (passiveTreeEntriesDecoder file)
        |> Util.single
        |> D.at [ "MetaData", "Tree" ]


passiveTreeEntriesDecoder : String -> D.Decoder (List PassiveTreeEntry)
passiveTreeEntriesDecoder file =
    D.succeed PassiveTreeEntry
        |> P.custom (Source.decoder file "Skill")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "Rarity" ] Util.intString
        |> P.requiredAt [ "$", "Category" ] D.string
        |> D.list
        |> D.at [ "Skill" ]


decoder : D.Decoder (List Passive)
decoder =
    Util.filteredJsons
        (String.contains "Skills/Passive/PST")
        |> D.map (List.map (\( filename, json ) -> D.decodeValue (passivesDecoder filename) json))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map List.concat


passivesDecoder : String -> D.Decoder (List Passive)
passivesDecoder file =
    D.succeed Passive
        |> P.custom (Source.decoder file "Spell")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "HUDLoreDesc" ] Util.nonemptyString
        |> P.requiredAt [ "$", "GameplayDesc" ] Util.nonemptyString
        |> P.custom passiveEffectsDecoder
        |> D.list
        |> D.at [ "MetaData", "Spell" ]


passiveEffectsDecoder : D.Decoder (List PassiveEffect)
passiveEffectsDecoder =
    D.map3 PassiveEffect
        (D.at [ "$", "Name" ] D.string)
        (D.at [ "$", "HUDDesc" ] Util.nonemptyString)
        (D.at [ "Semantics", "0", "$" ] <| D.keyValuePairs Util.floatString)
        |> D.list
        |> D.at [ "EIM" ]
        |> Util.single
        |> D.at [ "MagicEffects" ]
