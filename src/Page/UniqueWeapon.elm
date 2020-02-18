module Page.UniqueWeapon exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Item
import View.Nav


view : Datamine -> String -> Maybe (List (Html msg))
view dm name =
    dm.loot.uniqueWeapons
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
                        , a [ class "breadcrumb-item active", Route.href Route.UniqueWeapons ] [ text "Unique Weapons" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueWeapon item.name ] [ label ]
                        ]
                    , div [ class "card" ]
                        [ div [ class "card-header" ] [ label ]
                        , div [ class "card-body" ]
                            [ span [ class "item float-right" ] [ img [ View.Item.imgWeapon dm item ] [] ]
                            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                            , p []
                                [ text "Damage: "
                                , Maybe.Extra.unwrap "?" String.fromInt item.damage.min
                                    ++ "-"
                                    ++ Maybe.Extra.unwrap "?" String.fromInt item.damage.max
                                    |> text
                                ]
                            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.implicitAffixes
                            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm item.defaultAffixes
                            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                            , p [] <| (View.Desc.mdesc dm item.lore |> Maybe.withDefault [ text "???" ])
                            ]
                        ]
                    ]
                ]
            )
