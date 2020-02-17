module Page.Affixes exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Dict.Extra
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import List.Extra
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Nav


view : Datamine -> List (Html msg)
view dm =
    let
        groups =
            dm.affixes.magic |> Dict.Extra.groupBy (.class >> Maybe.withDefault "")

        groupNames =
            -- different than `Dict.keys groups` - this preserves the original order
            dm.affixes.magic |> List.map (.class >> Maybe.withDefault "") |> List.Extra.unique
    in
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Affixes ] [ text "Affixes" ]
            ]
        , div [ class "alert alert-warning" ] [ text "Yes, this is nearly unreadable. Sorry. Consider selecting an item to view its possible mods instead." ]
        , table [ class "table affixes" ]
            [ thead []
                [ tr []
                    -- , th [] [ text "file" ]
                    [ th [ class "sticky" ] [ text "affixId" ]
                    , th [ class "sticky" ] [ text "effects" ]
                    , th [ class "sticky" ] [ text "class" ]
                    , th [ class "sticky" ] [ text "tier" ]
                    , th [ class "sticky" ] [ text "level" ]
                    , th [ class "sticky" ] [ text "mandatoryKeywords" ]
                    , th [ class "sticky" ] [ text "optionalKeywords" ]
                    , th [ class "sticky" ] [ text "frequency" ]
                    , th [ class "sticky" ] [ text "craftOnly" ]
                    , th [ class "sticky" ] [ text "sarisel?" ]
                    , th [ class "sticky" ] [ text "type" ]
                    ]
                ]
            , tbody []
                (dm.affixes.magic
                    |> List.map
                        (\a ->
                            tr []
                                [ td [] [ text a.affixId ]
                                , td [] [ ul [ class "affixes nowrap" ] <| View.Affix.viewAffix dm a ]

                                -- , td [] [ text a.filename ]
                                , td [] [ text <| Maybe.withDefault "???CLASS???" a.class ]

                                -- , td [] [ text <| Maybe.Extra.unwrap "-" String.fromInt a.tier ]
                                , td [] [ text <| String.fromInt a.tier ]
                                , td [] [ text <| String.fromInt a.drop.itemLevel.min ++ "-" ++ String.fromInt a.drop.itemLevel.max ]
                                , td [] [ text <| String.join ", " a.drop.mandatoryKeywords ]
                                , td [] [ text <| String.join ", " a.drop.optionalKeywords ]
                                , td [] [ text <| String.fromInt a.drop.frequency ]
                                , td []
                                    [ text <|
                                        if a.drop.craftOnly then
                                            "CraftOnly"

                                        else
                                            "-"
                                    ]
                                , td []
                                    [ text <|
                                        if a.drop.sarisel then
                                            "Sarisel?"

                                        else
                                            "-"
                                    ]
                                , td [] [ text a.type_ ]
                                ]
                        )
                )
            ]
        ]
    ]
