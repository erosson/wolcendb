module SSR_CLI exposing (main)

{-| Prerender a single WolcenDB page.

Most WolcenDB pages are just static html - we can prerender them at build time,
postponing the relatively slow loading time! That way, we can show the user a
non-interactive, readonly version of their page along with the loading bar.

Interactivity has to wait for Elm to load; no way around that.

The name SSR - "server-side rendering" - isn't a perfect fit here, since we're
rendering at build time, no server. It's a general name for the technique.

-}

import Browser
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Main


main =
    Browser.element
        { view = Main.viewBody { ssr = True } >> div [ id "root", style "display" "none" ]
        , init = Main.initStatic
        , update = Main.update
        , subscriptions = always Sub.none
        }
