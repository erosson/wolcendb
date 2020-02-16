module View.Affix exposing (viewAffixIds, viewAffixes)

import Datamine exposing (Affix, Datamine, MagicEffect, Range)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


viewAffixIds : Datamine -> List String -> List (Html msg)
viewAffixIds dm =
    Datamine.affixes dm >> viewAffixes dm


viewAffixes : Datamine -> List Affix -> List (Html msg)
viewAffixes dm =
    List.concatMap .effects >> List.map (viewEffect dm >> li [])


formatEffect : Datamine -> MagicEffect -> Maybe String
formatEffect dm effect =
    "@ui_eim_"
        ++ effect.effectId
        |> Datamine.lang dm
        |> Maybe.map
            (\template ->
                effect.stats
                    |> List.indexedMap Tuple.pair
                    |> List.foldl formatEffectStat template
            )


formatEffectStat : ( Int, ( String, Range Float ) ) -> String -> String
formatEffectStat ( index, ( name, stat ) ) =
    let
        val =
            --(if stat.min > 0 && stat.max > 0 then
            --    "+"
            --
            -- else
            --    ""
            --)
            -- ++
            if stat.min == stat.max then
                String.fromFloat stat.min

            else
                "(" ++ String.fromFloat stat.min ++ "-" ++ String.fromFloat stat.max ++ ")"
    in
    String.replace ("%" ++ String.fromInt (index + 1)) val



-- >> String.replace "-+" "-"


viewEffect : Datamine -> MagicEffect -> List (Html msg)
viewEffect dm effect =
    -- [ text effect.effectId
    [ span [ title <| "@ui_eim_" ++ effect.effectId ]
        [ text <| Maybe.withDefault "???" <| formatEffect dm effect

        -- , text <| Debug.toString effect
        ]
    ]
