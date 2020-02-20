module View.Affix exposing
    ( ItemMsg(..)
    , formatEffect
    , formatPassiveEffect
    , formatRarity
    , viewAffix
    , viewAffixes
    , viewEffect
    , viewItem
    , viewMagicId
    , viewMagicIds
    , viewNonmagicId
    , viewNonmagicIds
    )

import Datamine exposing (Affix, Datamine, MagicAffix, MagicEffect, PassiveEffect, Range, Rarity)
import Dict exposing (Dict)
import Dict.Extra
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import List.Extra
import Route exposing (Route)
import Set exposing (Set)


viewNonmagicIds : Datamine -> List String -> List (Html msg)
viewNonmagicIds dm =
    Datamine.nonmagicAffixes dm >> viewAffixes dm


viewMagicIds : Datamine -> List String -> List (Html msg)
viewMagicIds dm =
    Datamine.magicAffixes dm >> viewAffixes dm


viewAffixes : Datamine -> List (Affix a) -> List (Html msg)
viewAffixes dm =
    List.concatMap .effects >> List.map (viewEffect dm >> li [ class "list-group-item" ])


viewNonmagicId : Datamine -> String -> List (Html msg)
viewNonmagicId dm a =
    viewNonmagicIds dm [ a ]


viewMagicId : Datamine -> String -> List (Html msg)
viewMagicId dm a =
    viewMagicIds dm [ a ]


viewAffix : Datamine -> Affix a -> List (Html msg)
viewAffix dm a =
    viewAffixes dm [ a ]


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


formatPassiveEffect : Datamine -> PassiveEffect -> Maybe String
formatPassiveEffect dm effect =
    effect.hudDesc
        |> Maybe.andThen (Datamine.lang dm)
        |> Maybe.map
            (\template ->
                effect.semantics
                    |> List.map (Tuple.mapSecond (\v -> Range v v))
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


type ItemMsg
    = Expand String


viewItem : Datamine -> Set String -> List MagicAffix -> List (Html ItemMsg)
viewItem dm expandeds affixes =
    let
        -- ( craftables, naturals ) =
        ( craftables, affixes1 ) =
            affixes
                |> List.partition (\a -> a.drop.craftOnly)

        ( sarisels, naturals ) =
            affixes1
                |> List.partition (\a -> a.drop.sarisel)
    in
    --[ div [ class "alert alert-warning" ]
    --    [ text "Beware: affix possibilities below might be wrong - the developer isn't completely sure how they work yet. "
    --    , a [ href "https://gitlab.com/erosson/wolcendb/issues" ] [ text "Please file an issue if these are wrong!" ]
    --    ]
    [ div [ class "row" ]
        [ div [ class "col-sm" ]
            [ viewItemAffixes "Magic affixes" dm expandeds naturals
            , viewItemAffixes "Sarisel affixes" dm expandeds sarisels
            ]
        , div [ class "col-sm" ]
            [ viewItemAffixes "Craftable affixes" dm expandeds craftables ]
        ]
    ]


viewItemAffixes : String -> Datamine -> Set String -> List MagicAffix -> Html ItemMsg
viewItemAffixes title dm expandeds affixes =
    let
        classOrId : MagicAffix -> String
        classOrId a =
            Maybe.withDefault a.affixId a.class

        byClass =
            affixes |> Dict.Extra.groupBy classOrId

        classOrder =
            affixes |> List.map classOrId |> List.Extra.unique

        totalWeight =
            affixes |> List.map (.drop >> .frequency) |> List.sum
    in
    if affixes == [] then
        div [] []

    else
        div [ class "card" ]
            [ div [ class "card-header" ] [ text title ]
            , ul [ class "list-group list-group-flush" ]
                (classOrder
                    |> List.filterMap (\c -> Dict.get c byClass |> Maybe.map (Tuple.pair c))
                    |> List.map (viewItemAffixClass dm totalWeight expandeds >> li [ class "list-group-item py-1" ])
                )
            ]


viewItemAffixClass : Datamine -> Int -> Set String -> ( String, List MagicAffix ) -> List (Html ItemMsg)
viewItemAffixClass dm totalWeight expandeds ( name, affixes ) =
    case affixes of
        [] ->
            []

        [ affix ] ->
            viewItemAffixRow dm totalWeight affix

        head :: _ ->
            let
                expanded =
                    Set.member name expandeds
            in
            (if not head.drop.craftOnly then
                [ span [ class "badge badge-outline-light float-right" ] [ viewWeights totalWeight affixes ] ]

             else
                []
            )
                ++ [ affixes
                        |> List.concatMap .effects
                        |> viewItemAffixClassSummary dm totalWeight expanded
                        |> div
                            [ title <| "Affix class: " ++ name
                            , onClick <| Expand name
                            ]
                   ]
                ++ (if expanded then
                        [ ul [ class "list-group" ] (affixes |> List.map (viewItemAffixRow dm totalWeight >> li [ class "list-group-item py-1" ])) ]

                    else
                        []
                   )


viewItemAffixRow : Datamine -> Int -> MagicAffix -> List (Html msg)
viewItemAffixRow dm totalWeight affix =
    let
        ilvl =
            String.fromInt affix.drop.itemLevel.min
                ++ "-"
                ++ String.fromInt affix.drop.itemLevel.max
    in
    (affix.effects |> List.concatMap (viewEffect dm))
        ++ (if affix.drop.craftOnly then
                [ small [ class "badge badge-outline-light float-right" ] [ text "[", a [ Route.href <| Route.Source "magic-affix" affix.affixId ] [ text "s" ], text "]" ]
                ]

            else
                [ small [ class "badge badge-outline-light float-right" ] [ text "[", a [ Route.href <| Route.Source "magic-affix" affix.affixId ] [ text "s" ], text "]" ]
                , span
                    [ class "badge badge-outline-light float-right"
                    , title <| "Monsters between levels " ++ ilvl ++ " can drop items with this affix"
                    ]
                    [ text <| "ilvl" ++ ilvl ]
                , span [ class "badge badge-outline-light float-right" ] [ viewWeight totalWeight affix ]
                ]
           )


summarizeEffects : List MagicEffect -> List MagicEffect
summarizeEffects effects =
    let
        byId : Dict String MagicEffect
        byId =
            effects
                |> Dict.Extra.groupBy .effectId
                |> Dict.Extra.filterMap
                    (\k es ->
                        case es of
                            [] ->
                                Nothing

                            [ e ] ->
                                Just e

                            head :: tail ->
                                List.foldl foldStats head tail |> Just
                    )

        foldStats : MagicEffect -> MagicEffect -> MagicEffect
        foldStats a b =
            let
                bStats : Dict String (Range Float)
                bStats =
                    Dict.fromList b.stats
            in
            { a
                | stats =
                    a.stats
                        |> List.map
                            (\( k, av ) ->
                                ( k
                                , case Dict.get k bStats of
                                    Nothing ->
                                        av

                                    Just bv ->
                                        { min = Basics.min av.min bv.min
                                        , max = Basics.max av.max bv.max
                                        }
                                )
                            )
            }
    in
    effects
        |> List.map .effectId
        |> List.Extra.unique
        |> List.filterMap (\e -> Dict.get e byId)


viewItemAffixClassSummary : Datamine -> Int -> Bool -> List MagicEffect -> List (Html msg)
viewItemAffixClassSummary dm totalWeight expanded effects =
    -- List.Extra.uniqueBy .effectId
    -- >> List.filterMap (\effect -> "@ui_eim_" ++ effect.effectId |> Datamine.lang dm)
    [ span
        [ class "fas collapse-caret"
        , classList
            [ ( "fa-caret-down", expanded )
            , ( "fa-caret-right", not expanded )
            ]
        ]
        []
    , effects
        |> summarizeEffects
        |> List.filterMap (formatEffect dm)
        |> List.map (\s -> div [] [ text s ])
        |> div []
    ]


viewWeight : Int -> MagicAffix -> Html msg
viewWeight totalWeight affix =
    viewWeights totalWeight [ affix ]


viewWeights : Int -> List MagicAffix -> Html msg
viewWeights totalWeight affixes =
    let
        w =
            affixes |> List.map (\a -> a.drop.frequency) |> List.sum
    in
    span [ title <| String.fromInt w ++ "/" ++ String.fromInt totalWeight ]
        [ text <| percent <| toFloat w / toFloat totalWeight ]


percent : Float -> String
percent p =
    (p * 100 |> String.fromFloat |> String.left 5) ++ "%"


formatRarity : Rarity -> String
formatRarity r =
    [ ( r.magic, "Magic" )
    , ( r.rare, "Rare" )
    , ( r.set, "Set" )
    , ( r.legendary, "Legendary" )
    ]
        |> List.filter Tuple.first
        |> List.map Tuple.second
        |> String.join ", "



-- |> (++) (Debug.toString r)
