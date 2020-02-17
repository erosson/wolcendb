module Page.UniqueAccessory exposing (view)

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
    dm.loot.uniqueAccessories
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
                        , a [ class "breadcrumb-item active", Route.href Route.UniqueAccessories ] [ text "Unique Accessories" ]
                        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueAccessory item.name ] [ label ]
                        ]
                    , p [] [ label ]
                    , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt item.levelPrereq ]
                    , p [] [ text "Keywords: ", text <| String.join ", " item.keywords ]
                    , ul [ class "list-group affixes" ] <| View.Affix.viewAffixIds dm item.implicitAffixes
                    , ul [ class "list-group affixes" ] <| View.Affix.viewAffixIds dm item.defaultAffixes
                    , p [] <| (View.Desc.mdesc dm item.lore |> Maybe.withDefault [ text "???" ])
                    ]
                ]
            )
