module Page.UniqueArmors exposing (view)

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


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.UniqueArmors ] [ text "Unique Armors" ]
            ]
        , table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [] [ text "name" ]
                    , th [] [ text "id" ]
                    , th [] [ text "keywords" ]
                    , th [] [ text "implicits" ]
                    , th [] [ text "affixes" ]
                    , th [] [ text "lore" ]
                    ]
                ]
            , tbody []
                (dm.loot.uniqueArmors
                    |> List.map
                        (\w ->
                            tr []
                                [ td []
                                    [ Datamine.lang dm w.uiName |> Maybe.withDefault "???" |> text ]
                                , td [] [ text w.name ]
                                , td [] [ text <| String.join ", " w.keywords ]
                                , td [] [ ul [] <| View.Affix.viewAffixIds dm w.implicitAffixes ]
                                , td [] [ ul [] <| View.Affix.viewAffixIds dm w.defaultAffixes ]
                                , td []
                                    (View.Desc.mdesc dm w.lore |> Maybe.withDefault [ text "???" ])
                                ]
                        )
                )
            ]
        ]
    ]
