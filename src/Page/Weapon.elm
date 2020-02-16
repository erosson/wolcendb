module Page.Weapon exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Nav


view : Datamine -> String -> Maybe (List (Html msg))
view dm name =
    dm.loot.weapons
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
                        , a [ class "breadcrumb-item active", Route.href Route.Weapons ] [ text "Weapons" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.Weapon item.name ] [ label ]
                        ]
                    , p [] [ label ]
                    , p []
                        [ text "Damage: "
                        , Maybe.Extra.unwrap "?" String.fromInt item.damage.min
                            ++ "-"
                            ++ Maybe.Extra.unwrap "?" String.fromInt item.damage.max
                            |> text
                        ]
                    , p [] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                    , ul [ class "list-group affixes" ] <| View.Affix.viewAffixIds dm item.implicitAffixes
                    ]
                ]
            )
