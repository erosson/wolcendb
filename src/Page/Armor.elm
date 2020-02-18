module Page.Armor exposing (view)

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
    dm.loot.armors
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
                        , a [ class "breadcrumb-item active", Route.href Route.Armors ] [ text "Armors" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Armor item.name ] [ label ]
                        ]
                    , span [ class "item" ] [ img [ View.Item.imgArmor dm item ] [] ]
                    , p [] [ label ]
                    , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                    , p [] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                    , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.implicitAffixes
                    , div [] <| View.Affix.viewItem dm m.expandedAffixClasses <| Datamine.itemAffixes dm item
                    ]
                ]
            )
