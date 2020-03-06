module SSRRenderCLI exposing (main)

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
import Ports
import Url exposing (Url)


notFound : Url
notFound =
    Url Url.Https "" Nothing "" Nothing Nothing


main =
    Browser.element
        { view = Main.viewBody { ssr = True } >> div [ id "root", style "display" "none" ]
        , init = Main.initSSRRender
        , update = Main.update
        , subscriptions =
            \_ ->
                Ports.ssrCliRender (Url.fromString >> Maybe.withDefault notFound >> Main.OnUrlChange)
        }
