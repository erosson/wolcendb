module Page.Affixes exposing (Msg, update, view)

import Datamine exposing (Datamine)
import Datamine.Affix as Affix exposing (MagicAffix, MagicEffect)
import Datamine.NormalItem as NormalItem
import Dict exposing (Dict)
import Dict.Extra
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import List.Extra
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)
import Util
import View.Affix
import View.AffixFilterForm


type alias Model m =
    View.AffixFilterForm.Model m


type Msg
    = ExpandClass String
    | FormMsg View.AffixFilterForm.Msg


update : Msg -> Model m -> Model m
update msg model =
    case msg of
        ExpandClass cls ->
            { model | expandedAffixClasses = model.expandedAffixClasses |> Util.toggleSet cls }

        FormMsg msg_ ->
            View.AffixFilterForm.update msg_ model


view : Model m -> List (Html Msg)
view model =
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Affixes ] [ text "Affixes" ]
        ]
    , View.AffixFilterForm.viewLevelForm model |> H.map FormMsg
    , View.AffixFilterForm.viewGemForm model |> H.map FormMsg
    , View.AffixFilterForm.viewKeywordForm model |> H.map FormMsg
    , table [ class "table affixes" ]
        [ thead []
            [ tr []
                -- , th [] [ text "file" ]
                [ th [ class "sticky" ] []
                , th [ class "sticky" ] [ text "effects" ]
                , th [ class "sticky" ] [ text "tier" ]
                , th [ class "sticky" ] [ text "level" ]
                , th [ class "sticky" ] [ text "keywords" ]
                , th [ class "sticky" ] [ text "gemFamilies" ]
                , th [ class "sticky" ] [ text "source" ]
                ]
            ]
        , tbody []
            (model.datamine.affixes.magic
                |> (if Set.isEmpty model.filterKeywords then
                        identity

                    else
                        -- Simulating item keyword rules here is too confusing, just match any one keyword
                        -- List.filter (NormalItem.isKeywordAffix model.filterKeywords)
                        List.filter (\a -> a.drop.mandatoryKeywords ++ a.drop.optionalKeywords |> List.any (\k -> Set.member k model.filterKeywords))
                   )
                |> List.filter (View.AffixFilterForm.isVisible model)
                |> View.Affix.affixesByClass
                |> List.concatMap (viewAffixClass model)
            )
        ]
    ]


viewAffixClass : Model m -> ( String, List MagicAffix ) -> List (Html Msg)
viewAffixClass model ( cls, affixes ) =
    case affixes of
        [] ->
            []

        [ affix ] ->
            [ viewAffixRow model affix ]

        head :: _ ->
            let
                isExpanded =
                    Set.member cls model.expandedAffixClasses
            in
            viewAffixClassRow model ( cls, affixes )
                :: (if isExpanded then
                        List.map (viewAffixRow model) affixes

                    else
                        []
                   )


viewAffixClassRow : Model m -> ( String, List MagicAffix ) -> Html Msg
viewAffixClassRow model ( cls, affixes ) =
    let
        isExpanded =
            Set.member cls model.expandedAffixClasses

        effects : List String
        effects =
            affixes
                |> List.concatMap .effects
                |> View.Affix.summarizeEffects
                |> List.filterMap (Affix.formatEffect model.datamine)

        keywords : List String
        keywords =
            case affixes |> List.map (\a -> a.drop.mandatoryKeywords ++ a.drop.optionalKeywords) of
                [] ->
                    []

                head :: tail ->
                    let
                        all =
                            List.foldl (Set.fromList >> Set.intersect) (Set.fromList head) tail
                    in
                    head |> List.filter (\k -> Set.member k all)
    in
    tr
        [ class "expand-affix-class"
        , title <| "Affix class: " ++ cls ++ " \nNo more than one affix from the same class may appear on an item"
        , onClick <| ExpandClass cls
        ]
        [ td []
            [ span
                [ class "fas"
                , classList
                    [ ( "fa-caret-down", isExpanded )
                    , ( "fa-caret-right", not isExpanded )
                    ]
                ]
                []
            ]
        , td [] (effects |> List.map (\e -> div [] [ text e ]))
        , td [] []
        , td [] [{- level -}]

        -- , td [] (keywords |> List.map (\k -> span [ class "badge" ] [ text k ]))
        -- , td [ class "nowrap" ] (View.Affix.viewGemFamiliesList model.datamine affixes)
        , td [] [{- keywords -}]
        , td [] [{- gems -}]
        , td []
            [ button [ class "btn btn-outline-secondary p-1 nowrap" ]
                (if isExpanded then
                    [ span [ class "fas fa-caret-down", style "display" "inline" ] [], text " Hide" ]

                 else
                    [ span [ class "fas fa-caret-right", style "display" "inline" ] [], text " Expand" ]
                )
            ]
        ]


viewAffixRow : Model m -> MagicAffix -> Html msg
viewAffixRow model a =
    tr []
        [ td [] []
        , td [] [ ul [ title a.affixId, class "affixes" ] <| View.Affix.viewAffix model.datamine a ]

        -- , td [] [ text <| Maybe.withDefault "???CLASS???" a.class ]
        , td [] [ text <| String.fromInt a.tier ]
        , td [ class "nowrap" ] [ text <| String.fromInt a.drop.itemLevel.min ++ "-" ++ String.fromInt a.drop.itemLevel.max ]
        , td []
            ([ a.drop.mandatoryKeywords
                |> List.map
                    (\k ->
                        span
                            [ title "MandatoryKeyword: items must have this keyword to spawn this affix"
                            , class "badge badge-primary"
                            ]
                            [ text k ]
                    )
             , a.drop.optionalKeywords
                |> List.map
                    (\k ->
                        span
                            [ title "OptionalKeyword: items must have any one of these keywords to spawn this affix"
                            , class "badge badge-info"
                            ]
                            [ text k ]
                    )
             , if a.drop.sarisel then
                [ span
                    [ title "Sarisel: only spawns from Sarisel expeditions"
                    , class "badge badge-success"
                    ]
                    [ text "Sarisel" ]
                ]

               else
                []
             , if a.drop.craftOnly then
                [ span
                    [ title "CraftOnly: only spawns from using crafting reagents with socketed gems"
                    , class "badge badge-success"
                    ]
                    [ text "CraftOnly" ]
                ]

               else
                []
             , [ span [ class "badge" ] [ text a.type_ ] ]
             ]
                |> List.concat
            )
        , td [ class "nowrap" ] (View.Affix.viewGemFamilies model.datamine a)
        , td [] [ text "[", H.a [ Route.href <| Route.Source "magic-affix" a.affixId ] [ text "Source" ], text "]" ]
        ]
