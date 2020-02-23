module View.Affix exposing
    ( ItemMsg(..)
    , formatRarity
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
import List.Extra
import Route exposing (Route)
import Set exposing (Set)
import Util


viewNonmagicIds : Datamine -> List String -> List (Html msg)
viewNonmagicIds dm =
    Affix.getNonmagicIds dm >> viewAffixes dm


viewMagicIds : Datamine -> List String -> List (Html msg)
viewMagicIds dm =
    Affix.getMagicIds dm >> viewAffixes dm


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


viewEffect : Datamine -> MagicEffect -> List (Html msg)
viewEffect dm effect =
    [ span [ title <| "@ui_eim_" ++ effect.effectId ++ "; " ++ (effect.stats |> List.map Tuple.first |> String.join ", ") ]
        [ text <| Maybe.withDefault "???" <| Affix.formatEffect dm effect
        ]
    ]


viewGemFamilies : Datamine -> Affix a -> List (Html msg)
viewGemFamilies dm affix =
    viewGemFamiliesList dm [ affix ]


{-| Show gem families that all these affixes have in common
-}
viewGemFamiliesList : Datamine -> List (Affix a) -> List (Html msg)
viewGemFamiliesList dm affixes =
    GemFamily.fromAffixes dm affixes
        |> List.map
            (\fam ->
                img
                    [ class "gem-icon"
                    , title <| GemFamily.label dm fam ++ " (" ++ fam.gemFamilyId ++ ") in a socket makes this affix more likely to appear with crafting reagents"
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
            [ viewItemAffixes "Craft-only affixes" dm expandeds craftables ]
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
            affixes |> List.filter (\a -> not a.drop.sarisel) |> List.map (\a -> a.drop.frequency) |> List.sum
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
            div []
                [ span [ class "badge badge-outline-light float-right" ] [ viewWeights totalWeight affixes ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamiliesList dm affixes)
                , affixes
                    |> List.concatMap .effects
                    |> viewItemAffixClassSummary dm totalWeight expanded
                    |> div
                        [ title <| "Affix class: " ++ name
                        , onClick <| Expand name
                        ]
                , div [ style "clear" "right" ] []
                ]
                :: (if expanded then
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
                , span [ class "badge badge-outline-light float-right" ] [ viewWeight totalWeight affix ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamilies dm affix)
                ]

            else
                [ small [ class "badge badge-outline-light float-right" ] [ text "[", a [ Route.href <| Route.Source "magic-affix" affix.affixId ] [ text "s" ], text "]" ]
                , span
                    [ class "badge badge-outline-light float-right"
                    , title <| "Monsters between levels " ++ ilvl ++ " can drop items with this affix"
                    ]
                    [ text <| "ilvl" ++ ilvl ]
                , span [ class "badge badge-outline-light float-right" ] [ viewWeight totalWeight affix ]
                , span [ class "badge badge-outline-light float-right" ] (viewGemFamilies dm affix)
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
        |> List.filterMap (Affix.formatEffect dm)
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
