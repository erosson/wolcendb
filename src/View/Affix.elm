module View.Affix exposing
    ( ItemMsg(..)
    , affixesByClass
    , formatRarity
    , summarizeEffects
    , update
    , viewAffix
    , viewAffixes
    , viewEffect
    , viewGemFamilies
    , viewGemFamiliesList
    , viewItem
    , viewMagicId
    , viewMagicIds
    , viewNonmagicId
    , viewNonmagicIds
    )

import Datamine exposing (Datamine)
import Datamine.Affix as Affix exposing (Affix, MagicAffix, MagicEffect, Rarity)
import Datamine.GemFamily as GemFamily exposing (GemFamily)
import Datamine.Passive as Passive exposing (Passive, PassiveEffect)
import Datamine.Util exposing (Range)
import Dict exposing (Dict)
import Dict.Extra
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import List.Extra
import Route exposing (Route)
import Set exposing (Set)
import Util


viewNonmagicIds : Lang -> Datamine -> List String -> List (Html msg)
viewNonmagicIds lang dm =
    Affix.getNonmagicIds dm >> viewAffixes lang


viewMagicIds : Lang -> Datamine -> List String -> List (Html msg)
viewMagicIds lang dm =
    Affix.getMagicIds dm >> viewAffixes lang


viewAffixes : Lang -> List (Affix a) -> List (Html msg)
viewAffixes lang =
    List.concatMap .effects >> List.map (viewEffect lang >> li [ class "list-group-item" ])


viewNonmagicId : Lang -> Datamine -> String -> List (Html msg)
viewNonmagicId lang dm a =
    viewNonmagicIds lang dm [ a ]


viewMagicId : Lang -> Datamine -> String -> List (Html msg)
viewMagicId lang dm a =
    viewMagicIds lang dm [ a ]


viewAffix : Lang -> Affix a -> List (Html msg)
viewAffix lang a =
    viewAffixes lang [ a ]


viewEffect : Lang -> MagicEffect -> List (Html msg)
viewEffect lang effect =
    [ span [ title <| "@ui_eim_" ++ effect.effectId ++ "; " ++ (effect.stats |> List.map Tuple.first |> String.join ", ") ]
        [ text <| Maybe.withDefault "???" <| Affix.formatEffect lang effect
        ]
    ]


viewGemFamilies : Lang -> Datamine -> Affix a -> List (Html msg)
viewGemFamilies lang dm affix =
    viewGemFamiliesList lang dm [ affix ]


{-| Show gem families that all these affixes have in common
-}
viewGemFamiliesList : Lang -> Datamine -> List (Affix a) -> List (Html msg)
viewGemFamiliesList lang dm affixes =
    GemFamily.fromAffixes dm affixes
        |> List.map
            (\fam ->
                img
                    [ class "gem-icon"
                    , title <| GemFamily.label lang dm fam ++ " (" ++ fam.gemFamilyId ++ ") in a socket makes this affix more likely to appear with crafting reagents"
                    , src <| GemFamily.img dm fam
                    ]
                    []
            )


type ItemMsg
    = Expand String


type alias Model m =
    { m | expandedAffixClasses : Set String }


update : ItemMsg -> Model m -> Model m
update msg model =
    case msg of
        Expand class ->
            { model | expandedAffixClasses = model.expandedAffixClasses |> Util.toggleSet class }


viewItem : Lang -> Datamine -> Set String -> List MagicAffix -> List (Html ItemMsg)
viewItem lang dm expandeds affixes =
    let
        -- ( craftables, naturals ) =
        ( craftables, affixes1 ) =
            affixes
                |> List.partition (\a -> a.drop.craftOnly)

        ( sarisels, naturals ) =
            affixes1
                |> List.partition (\a -> a.drop.sarisel)

        ( naturalPre, naturalSuf ) =
            naturals |> List.partition (\a -> a.type_ == "prefix")

        ( sariselPre, sariselSuf ) =
            sarisels |> List.partition (\a -> a.type_ == "prefix")

        ( craftablePre, craftableSuf ) =
            craftables |> List.partition (\a -> a.type_ == "prefix")
    in
    --[ div [ class "alert alert-warning" ]
    --    [ text "Beware: affix possibilities below might be wrong - the developer isn't completely sure how they work yet. "
    --    , a [ href "https://gitlab.com/erosson/wolcendb/issues" ] [ text "Please file an issue if these are wrong!" ]
    --    ]
    [ div [ class "row" ]
        [ div [ class "col-sm" ] [ viewItemAffixes "Magic prefixes [click to expand]" lang dm expandeds naturalPre ]
        , div [ class "col-sm" ] [ viewItemAffixes "Magic suffixes" lang dm expandeds naturalSuf ]
        ]
    , div [ class "row" ]
        [ div [ class "col-sm" ] [ viewItemAffixes "Sarisel prefixes" lang dm expandeds sariselPre ]
        , div [ class "col-sm" ] [ viewItemAffixes "Sarisel suffixes" lang dm expandeds sariselSuf ]
        ]
    , div [ class "row" ]
        [ div [ class "col-sm" ] [ viewItemAffixes "Craft-only prefixes" lang dm expandeds craftablePre ]
        , div [ class "col-sm" ] [ viewItemAffixes "Craft-only suffixes" lang dm expandeds craftableSuf ]
        ]
    ]


{-| Group affixes by affix-class, with minimal order changes
-}
affixesByClass : List MagicAffix -> List ( String, List MagicAffix )
affixesByClass affixes =
    let
        classOrId : MagicAffix -> String
        classOrId a =
            Maybe.withDefault a.affixId a.class

        byClass =
            affixes |> Dict.Extra.groupBy classOrId

        classOrder : List String
        classOrder =
            affixes |> List.map classOrId |> List.Extra.unique
    in
    classOrder |> List.filterMap (\c -> Dict.get c byClass |> Maybe.map (Tuple.pair c))


viewItemAffixes : String -> Lang -> Datamine -> Set String -> List MagicAffix -> Html ItemMsg
viewItemAffixes title lang dm expandeds affixes =
    if affixes == [] then
        div [] []

    else
        let
            classes =
                affixesByClass affixes

            totalWeight =
                affixes |> List.filter (\a -> not a.drop.sarisel) |> List.map (\a -> a.drop.frequency) |> List.sum
        in
        div [ class "card" ]
            [ div [ class "card-header" ] [ text title ]
            , ul [ class "list-group list-group-flush" ]
                (classes |> List.map (viewItemAffixClass lang dm totalWeight expandeds >> li [ class "list-group-item py-1" ]))
            ]


viewItemAffixClass : Lang -> Datamine -> Int -> Set String -> ( String, List MagicAffix ) -> List (Html ItemMsg)
viewItemAffixClass lang dm totalWeight expandeds ( name, affixes ) =
    case affixes of
        [] ->
            []

        [ affix ] ->
            viewItemAffixRow lang dm totalWeight affix

        head :: _ ->
            let
                expanded =
                    Set.member name expandeds
            in
            div []
                [ span [ class "badge badge-outline-light float-right" ] [ viewWeights totalWeight affixes ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamiliesList lang dm affixes)
                , affixes
                    |> List.concatMap .effects
                    |> viewItemAffixClassSummary lang totalWeight expanded
                    |> div
                        [ class "expand-affix-class"
                        , title <| "Affix class: " ++ name ++ " \nNo more than one affix from the same class may appear on an item"
                        , onClick <| Expand name
                        ]
                , div [ style "clear" "right" ] []
                ]
                :: (if expanded then
                        [ ul [ class "list-group" ] (affixes |> List.map (viewItemAffixRow lang dm totalWeight >> li [ class "list-group-item py-1" ])) ]

                    else
                        []
                   )


viewItemAffixRow : Lang -> Datamine -> Int -> MagicAffix -> List (Html msg)
viewItemAffixRow lang dm totalWeight affix =
    let
        ilvl =
            String.fromInt affix.drop.itemLevel.min
                ++ "-"
                ++ String.fromInt affix.drop.itemLevel.max
    in
    (affix.effects |> List.concatMap (viewEffect lang))
        ++ (if affix.drop.craftOnly then
                [ small [ class "badge badge-outline-light float-right" ] [ text "[", a [ Route.href <| Route.Source "magic-affix" affix.affixId ] [ text "s" ], text "]" ]
                , span [ class "badge badge-outline-light float-right" ] [ viewWeight totalWeight affix ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamilies lang dm affix)
                ]

            else
                [ small [ class "badge badge-outline-light float-right" ] [ text "[", a [ Route.href <| Route.Source "magic-affix" affix.affixId ] [ text "s" ], text "]" ]
                , span
                    [ class "badge badge-outline-light float-right"
                    , title <| "Monsters between levels " ++ ilvl ++ " can drop items with this affix"
                    ]
                    [ text <| "ilvl" ++ ilvl ]
                , span [ class "badge badge-outline-light float-right" ] [ viewWeight totalWeight affix ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamilies lang dm affix)
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


viewItemAffixClassSummary : Lang -> Int -> Bool -> List MagicEffect -> List (Html msg)
viewItemAffixClassSummary lang totalWeight expanded effects =
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
        |> List.filterMap (Affix.formatEffect lang)
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
            affixes |> List.filter (\a -> not a.drop.sarisel) |> List.map (\a -> a.drop.frequency) |> List.sum
    in
    if totalWeight == 0 || w == 0 then
        span [] []

    else
        span [ title <| String.fromInt w ++ "/" ++ String.fromInt totalWeight ]
            [ text <| Util.percent <| toFloat w / toFloat totalWeight ]


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
