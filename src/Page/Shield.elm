module Page.Shield exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import Set exposing (Set)
import View.Affix
import View.Desc
import View.Item
import View.Nav


view : { m | datamine : Datamine, expandedAffixClasses : Set String } -> String -> Maybe (List (Html View.Affix.ItemMsg))
view m name =
    let
        dm =
            m.datamine
    in
    dm.loot.shields
        |> List.filter (\w -> w.name == name)
        |> List.head
        |> Maybe.map
            (\item ->
                let
                    label =
                        Datamine.lang dm item.uiName |> Maybe.withDefault "???" |> text
                in
                [ div [ class "container" ]
                    [ View.Nav.view
                    , ol [ class "breadcrumb" ]
                        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
                        , a [ class "breadcrumb-item active", Route.href Route.Shields ] [ text "Shields" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Shield item.name ] [ label ]
                        ]
                    , div [ class "card" ]
                        [ div [ class "card-header" ] [ label ]
                        , div [ class "card-body" ]
                            [ span [ class "item float-right" ] [ img [ View.Item.imgShield dm item ] [] ]
                            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.implicitAffixes
                            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                            ]
                        ]
                    , div [] <| View.Affix.viewItem dm m.expandedAffixClasses <| Datamine.itemAffixes dm item
                    ]
                ]
            )
