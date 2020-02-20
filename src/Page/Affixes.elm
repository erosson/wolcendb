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


view : Datamine -> List (Html msg)
view dm =
    let
        groups =
            dm.affixes.magic |> Dict.Extra.groupBy (.class >> Maybe.withDefault "")

        groupNames =
            -- different than `Dict.keys groups` - this preserves the original order
            dm.affixes.magic |> List.map (.class >> Maybe.withDefault "") |> List.Extra.unique
    in
    [ ol [ class "breadcrumb" ]
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
                , th [ class "sticky" ] [ text "rarity" ]
                , th [ class "sticky" ] [ text "craftOnly?" ]
                , th [ class "sticky" ] [ text "sarisel?" ]
                , th [ class "sticky" ] [ text "type" ]
                , th [ class "sticky" ] [ text "source" ]
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
                            , td [] [ text <| View.Affix.formatRarity a.drop.rarity ]
                            , td [] [ text <| ifval a.drop.craftOnly "CraftOnly" "-" ]
                            , td [] [ text <| ifval a.drop.sarisel "Sarisel" "-" ]
                            , td [] [ text a.type_ ]
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
