module Page.UniqueShields exposing (view)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra


view : Datamine -> List (Html msg)
view dm =
    [ h1 [] [ text "Unique Armors" ]
    , table []
        [ thead []
            [ tr []
                [ th [] [ text "name" ]
                , th [] [ text "id" ]
                , th [] [ text "keywords" ]
                , th [] [ text "lore" ]
                ]
            ]
        , tbody []
            (dm.loot.uniqueShields
                |> List.map
                    (\w ->
                        tr []
                            [ td []
                                [ Dict.get (String.replace "@" "" w.uiName) dm.en
                                    |> Maybe.withDefault "???"
                                    |> text
                                ]
                            , td [] [ text w.name ]
                            , td [] [ text <| String.join ", " w.keywords ]
                            , td []
                                [ Dict.get (String.replace "@" "" (Maybe.withDefault "" w.lore)) dm.en
                                    |> Maybe.withDefault "???"
                                    |> text
                                ]
                            ]
                    )
            )
        ]
    ]
