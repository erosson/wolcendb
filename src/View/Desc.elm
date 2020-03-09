module View.Desc exposing (desc, format, mdesc, mformat)

{-| datamined Wolcen descriptions have embedded html. Interpret it as html.

Beware XSS when trusting someone else's HTML - but we trust the datamined strings.

-}

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Html.Parser
import Html.Parser.Util
import Lang exposing (Lang)


mdesc : Lang -> Maybe String -> Maybe (List (Html msg))
mdesc lang =
    Maybe.andThen (desc lang)


desc : Lang -> String -> Maybe (List (Html msg))
desc lang key =
    Lang.get lang key |> mformat


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
