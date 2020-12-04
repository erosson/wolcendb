module Datamine.Ailment exposing (Ailment, decoder)

import Datamine.Affix as Affix exposing (NonmagicAffix)
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra
import Set exposing (Set)


type alias Ailment =
    { name : String
    , source : Source
    , params : List AilmentParam
    }


type alias AilmentParam =
    { level : Int
    , values : List ( String, Float )
    }


{-| Revisions where this data is inaccessible; before we stored this data in git
-}
oldRevisions =
    Set.fromList [ "1.0.6.0_ER", "1.0.4.3_ER" ]


decoder : String -> D.Decoder (List Ailment)
decoder buildRevision =
    if Set.member buildRevision oldRevisions then
        D.succeed []

    else
        List.foldl (\d -> D.map (\ails ail -> ail :: ails) >> P.custom d)
            (D.succeed [])
            -- Only interested in damaging ailments. The others are flat values, anyway
            [ ailmentDecoder "Game/Umbra/Gameplay/Curve_StatusAilments/Bleed.json" "Bleed"
            , ailmentDecoder "Game/Umbra/Gameplay/Curve_StatusAilments/Burn.json" "Burn"
            , ailmentDecoder "Game/Umbra/Gameplay/Curve_StatusAilments/Poison.json" "Poison"
            , ailmentDecoder "Game/Umbra/Gameplay/Curve_StatusAilments/Shock.json" "Shock"
            ]
            |> D.map List.reverse


ailmentDecoder : String -> String -> D.Decoder Ailment
ailmentDecoder file name =
    D.succeed (Ailment name)
        |> P.custom (Source.decoder file "MetaData")
        |> P.required "Params"
            (D.succeed AilmentParam
                |> P.requiredAt [ "$", "Level" ] Util.intString
                |> P.requiredAt [ "$" ] (D.keyValuePairs Util.floatString |> D.map (List.filter (\( k, v ) -> k /= "Level")))
                |> D.list
            )
        |> D.at [ file, "MetaData" ]
