module Datamine.GemFamily exposing
    ( GemFamily
    , decoder
    , fromAffix
    , img
    , label
    )

{-| Socketed gems influence crafting results. This data describes how.
-}

import Datamine.Affix as Affix exposing (Affix, NonmagicAffix)
import Datamine.Gem as Gem exposing (Gem)
import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias GemFamily =
    { source : Source
    , gemFamilyId : String
    , relatedGems : List RelatedGem
    , craftRelatedAffixes : List String
    }


type alias RelatedGem =
    { tier : Int, gemId : String }


type alias Datamine d =
    Lang.Datamine
        { d
            | gemsByName : Dict String Gem
            , gemFamiliesByAffixId : Dict String (List GemFamily)
        }


gems : Datamine d -> GemFamily -> List Gem
gems dm fam =
    fam.relatedGems |> List.filterMap (\g -> Dict.get (String.toLower g.gemId) dm.gemsByName)


img : Datamine d -> GemFamily -> String
img dm =
    gems dm
        >> List.reverse
        >> List.head
        >> Maybe.map Gem.img
        >> Maybe.withDefault ""


fromAffix : Datamine d -> Affix a -> List GemFamily
fromAffix dm affix =
    Dict.get (String.toLower affix.affixId) dm.gemFamiliesByAffixId
        |> Maybe.withDefault []


{-| The gem in this family with the shortest name

Gem families don't appear in the UI, but the shortest gem name works well for it

-}
label : Datamine d -> GemFamily -> String
label dm =
    gems dm
        >> List.filterMap (Gem.label dm)
        >> List.sortBy String.length
        >> List.head
        >> Maybe.withDefault ""


decoder : D.Decoder (List GemFamily)
decoder =
    let
        file =
            "Game/Umbra/Loot/MagicEffects/Affixes/Craft/GemFamiliesAndCoveredEffectIDs.json"
    in
    D.succeed GemFamily
        |> P.custom (Source.decoder file "GemFamily")
        |> P.requiredAt [ "$", "GemFamilyId" ] D.string
        |> P.requiredAt [ "RelatedGems", "0", "Gem" ]
            (D.succeed RelatedGem
                |> P.requiredAt [ "$", "Tier" ] Util.intString
                |> P.requiredAt [ "$", "GemId" ] D.string
                |> D.list
            )
        |> P.requiredAt [ "CraftRelatedAffixes", "0", "Entry" ]
            (D.at [ "$", "EffectId" ] D.string |> D.list)
        |> D.list
        |> D.at [ file, "MetaData", "GemFamily" ]
