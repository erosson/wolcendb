module View.Affix exposing (viewAffixIds, viewAffixes)

import Datamine exposing (Affix, Datamine, MagicEffect)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


viewAffixIds : Datamine -> List String -> List (Html msg)
viewAffixIds dm =
    Datamine.affixes dm >> viewAffixes dm


viewAffixes : Datamine -> List Affix -> List (Html msg)
viewAffixes dm =
    List.concatMap .effects >> List.map (viewEffect dm >> li [])


viewEffect : Datamine -> MagicEffect -> List (Html msg)
viewEffect dm effect =
    -- [ text effect.effectId
    [ span [ title <| "@ui_eim_" ++ effect.effectId ]
        [ text <| Maybe.withDefault "???" <| Datamine.lang dm <| "@ui_eim_" ++ effect.effectId ]
    ]
