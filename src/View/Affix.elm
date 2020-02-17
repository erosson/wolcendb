module View.Affix exposing
    ( formatRarity
    , viewAffix
    , viewAffixes
    , viewItem
    , viewMagicId
    , viewMagicIds
    , viewNonmagicId
    , viewNonmagicIds
    )

import Datamine exposing (Affix, Datamine, MagicAffix, MagicEffect, Range, Rarity)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


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


viewItem : Datamine -> List MagicAffix -> List (Html msg)
viewItem dm affixes =
    let
        -- ( craftables, naturals ) =
        ( craftables, affixes1 ) =
            affixes
                |> List.partition (\a -> a.drop.craftOnly)

        ( sarisels, naturals ) =
            affixes1
                |> List.partition (\a -> a.drop.sarisel)

        -- sarisels =
        -- []
        nTotal =
            naturals
                |> List.map (\a -> a.drop.frequency)
                |> List.sum
                |> Basics.max 1

        sTotal =
            sarisels
                |> List.map (\a -> a.drop.frequency)
                |> List.sum
                |> Basics.max 1
    in
    [ div [ class "alert alert-warning" ]
        [ text "Beware: affix possibilities below might be wrong - the developer isn't completely sure how they work yet. "
        , a [ href "https://gitlab.com/erosson/wolcendb/issues" ] [ text "Please file an issue if these are wrong!" ]
        ]
    , table [ class "table" ]
        [ thead []
            [ tr []
                [ th [] [ text "Possible magic affixes" ]
                , th [] [ text "class" ]
                , th [] [ text "tier" ]
                , th [] [ text "weight" ]
                , th [] [ text "type" ]
                , th [] [ text "rarity" ]
                ]
            ]
        , tbody []
            (naturals
                |> List.map
                    (\affix ->
                        tr []
                            [ td [] [ ul [ class "affixes nowrap" ] <| viewAffix dm affix ]
                            , td [] [ text <| Maybe.withDefault "???" affix.class ]
                            , td [] [ text <| String.fromInt affix.tier ]
                            , td [] [ viewWeight nTotal affix ]
                            , td [] [ text affix.type_ ]
                            , td [] [ text <| formatRarity affix.drop.rarity ]
                            ]
                    )
            )
        ]
    , if sarisels /= [] then
        table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "Possible Sarisel affixes" ]
                    , th [] [ text "tier" ]
                    , th [] [ text "weight" ]
                    , th [] [ text "type" ]

                    -- , th [] [ text "rarity" ]
                    ]
                ]
            , tbody []
                (sarisels
                    |> List.map
                        (\affix ->
                            tr []
                                [ td [] [ ul [ class "affixes nowrap" ] <| viewAffix dm affix ]
                                , td [] [ text <| String.fromInt affix.tier ]
                                , td [] [ viewWeight sTotal affix ]
                                , td [] [ text affix.type_ ]

                                -- , td [] [ text <| formatRarity affix.drop.rarity ]
                                ]
                        )
                )
            ]

      else
        div [] []
    , table [ class "table" ]
        [ thead []
            [ tr []
                [ th [] [ text "Craftable magic affixes" ]
                , th [] [ text "class" ]
                , th [] [ text "tier" ]
                , th [] [ text "type" ]
                ]
            ]
        , tbody []
            (craftables
                |> List.map
                    (\affix ->
                        tr []
                            [ td [] [ ul [ class "affixes nowrap" ] <| viewAffix dm affix ]
                            , td [] [ text <| Maybe.withDefault "???" affix.class ]
                            , td [] [ text <| String.fromInt affix.tier ]
                            , td [] [ text affix.type_ ]
                            ]
                    )
            )
        ]
    ]


viewWeight : Int -> MagicAffix -> Html msg
viewWeight totalWeight affix =
    span [ title <| String.fromInt affix.drop.frequency ++ "/" ++ String.fromInt totalWeight ]
        [ text <| percent <| toFloat affix.drop.frequency / toFloat totalWeight ]


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
