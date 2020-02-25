module Page.Affixes exposing (Msg, update, view)

import Datamine exposing (Datamine)
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
import View.Affix
import View.AffixFilterForm


type alias Model m =
    View.AffixFilterForm.Model m


type alias Msg =
    View.AffixFilterForm.Msg


update =
    View.AffixFilterForm.update


view : Model m -> List (Html Msg)
view model =
    let
        groups =
            model.datamine.affixes.magic |> Dict.Extra.groupBy (.class >> Maybe.withDefault "")

        groupNames =
            -- different than `Dict.keys groups` - this preserves the original order
            model.datamine.affixes.magic |> List.map (.class >> Maybe.withDefault "") |> List.Extra.unique
    in
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href Route.Affixes ] [ text "Affixes" ]
        ]
    , View.AffixFilterForm.viewLevelForm model
    , View.AffixFilterForm.viewGemForm model
    , View.AffixFilterForm.viewKeywordForm model
    , table [ class "table affixes" ]
        [ thead []
            [ tr []
                -- , th [] [ text "file" ]
                [ th [ class "sticky" ] [ text "effects" ]
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
                |> List.map
                    (\a ->
                        tr []
                            [ td [] [ ul [ title a.affixId, class "affixes" ] <| View.Affix.viewAffix model.datamine a ]

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
                    )
            )
        ]
    ]


ifval : Bool -> a -> a -> a
ifval pred t f =
    if pred then
        t

    else
        f
