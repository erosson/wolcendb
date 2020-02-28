module Page.UniqueItem exposing (view, viewTitle)

import Datamine exposing (Datamine)
import Datamine.UniqueItem as UniqueItem exposing (UItem, UniqueItem(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Desc
import View.Item


viewTitle : Datamine -> String -> String
viewTitle dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.andThen (UniqueItem.label dm)
        |> Maybe.withDefault ""


view : Datamine -> String -> Maybe (List (Html msg))
view dm name =
    Dict.get (String.toLower name) dm.uniqueLootByName
        |> Maybe.map (viewMain dm)


viewMain : Datamine -> UniqueItem -> List (Html msg)
viewMain dm uitem =
    let
        label =
            UniqueItem.label dm uitem |> Maybe.withDefault "???" |> text
    in
    [ ol [ class "breadcrumb" ]
        [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItems Nothing ] [ text "Unique Loot" ]
        , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItem <| UniqueItem.name uitem ] [ label ]
        ]
    , div [ class "card" ]
        [ div [ class "card-header" ] [ label ]
        , div [ class "card-body" ]
            [ span [ class "item float-right" ]
                [ img [ View.Item.imgUnique dm uitem ] []
                , div [] [ text "[", a [ Route.href <| Route.Source "unique-loot" <| UniqueItem.name uitem ] [ text "Source" ], text "]" ]
                , div [] [ text "[", a [ Route.href <| Route.Offline "unique-loot" <| UniqueItem.name uitem ] [ text "Offline" ], text "]" ]
                ]
            , p [] [ text "Level: ", text <| Maybe.Extra.unwrap "-" String.fromInt <| UniqueItem.levelPrereq uitem ]
            , ul [ class "list-group affixes" ] (uitem |> UniqueItem.baseEffects dm |> List.map (\s -> li [ class "list-group-item" ] [ text s ]))
            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm <| UniqueItem.implicitAffixes uitem
            , ul [ class "list-group affixes" ] <| View.Affix.viewNonmagicIds dm <| UniqueItem.defaultAffixes uitem
            , small [ class "text-muted" ] [ text "Keywords: ", text <| String.join ", " <| UniqueItem.keywords uitem ]
            , UniqueItem.lore dm uitem |> View.Desc.mformat |> Maybe.withDefault [] |> p []
            ]
        ]
    ]
