module Page.Gems exposing (view)

import Datamine exposing (Datamine, Socket(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Route exposing (Route)
import View.Affix
import View.Item
import View.Nav


view : Datamine -> List (Html msg)
view dm =
    [ div [ class "container" ]
        [ View.Nav.view
        , ol [ class "breadcrumb" ]
            [ a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ]
            , a [ class "breadcrumb-item active", Route.href Route.Gems ] [ text "Gems" ]
            ]
        , table [ class "table" ]
            --[ thead []
            --    [ tr []
            --        [ th [] [ text "name" ]
            --        , th [] [ text "affixes" ]
            --        ]
            --    ]
            [ tbody []
                (dm.gems
                    |> List.map
                        (\gem ->
                            tr []
                                [ td [ title gem.uiName ]
                                    [ div [] [ img [ class "skill-icon", View.Item.imgGem gem ] [] ]
                                    , Datamine.lang dm gem.uiName |> Maybe.withDefault "???" |> text
                                    ]
                                , td []
                                    [ ul [ class "list-group affixes nowrap" ]
                                        (gem.effects
                                            |> List.map
                                                (\( socket, affixId ) ->
                                                    li [ class "list-group-item", style "display" "inline" ]
                                                        -- (viewSocket socket :: View.Affix.viewNonmagicId dm affixId)
                                                        (viewSocket socket
                                                            :: (Datamine.nonmagicAffixes dm [ affixId ]
                                                                    |> List.concatMap .effects
                                                                    |> List.concatMap (View.Affix.viewEffect dm)
                                                               )
                                                        )
                                                )
                                        )
                                    ]
                                ]
                        )
                )
            ]
        ]
    ]


viewSocket : Socket -> Html msg
viewSocket socket =
    text <|
        case socket of
            Offensive 1 ->
                "Offensive I: "

            Offensive 2 ->
                "Offensive II: "

            Offensive 3 ->
                "Offensive III: "

            Defensive 1 ->
                "Defensive I: "

            Defensive 2 ->
                "Defensive II: "

            Defensive 3 ->
                "Defensive III: "

            Support 1 ->
                "Support I: "

            Support 2 ->
                "Support II: "

            Support 3 ->
                "Support III: "

            _ ->
                "???SOCKET???"
