module View.Desc exposing (desc, format, mdesc, mformat)

{-| datamined Wolcen descriptions have embedded html. Interpret it as html.

Beware XSS when trusting someone else's HTML - but we trust the datamined strings.

-}

import Datamine exposing (Datamine)
import Datamine.Lang as Lang
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Html.Parser
import Html.Parser.Util


mdesc : Datamine -> Maybe String -> Maybe (List (Html msg))
mdesc dm =
    Maybe.andThen (desc dm)


desc : Datamine -> String -> Maybe (List (Html msg))
desc dm key =
    Lang.get dm key |> mformat


format : String -> List (Html msg)
format =
    String.replace "\\n" "<br />"
        >> (\raw ->
                case Html.Parser.run raw of
                    Ok nodes ->
                        [ Html.Parser.Util.toVirtualDom nodes |> p [ class "desc", title raw ] ]

                    Err err ->
                        [ p [ class "desc" ] [ text raw ] ]
           )


mformat : Maybe String -> Maybe (List (Html msg))
mformat =
    Maybe.map format
