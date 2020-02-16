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
    List.concatMap .effects >> List.map (viewEffect dm >> li [ class "list-group-item" ])


formatEffect : Datamine -> MagicEffect -> Maybe String
formatEffect dm effect =
    let
        stats =
            -- TODO: sometimes stats are out of order, but I haven't been able to find a pattern. JSON decoding seems fine.
            if effect.effectId == "default_attacks_chain" then
                effect.stats |> List.reverse

            else
                effect.stats
    in
    "@ui_eim_"
        ++ effect.effectId
        |> Datamine.lang dm
        |> Maybe.map
            (\template ->
                stats
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

        suffix =
            if String.contains "percent" (String.toLower name) then
                "%"

            else
                ""
    in
    String.replace ("%" ++ String.fromInt (index + 1)) <| val ++ suffix



-- >> String.replace "-+" "-"


viewEffect : Datamine -> MagicEffect -> List (Html msg)
viewEffect dm effect =
    -- [ text effect.effectId
    [ span [ title <| "@ui_eim_" ++ effect.effectId ++ "; " ++ (effect.stats |> List.map Tuple.first |> String.join ", ") ]
        [ text <| Maybe.withDefault "???" <| formatEffect dm effect

        -- , text <| Debug.toString effect
        ]
    ]
