module SSRPagesCLI exposing (main)

{-| Output a list of pages to prerender with SSRRenderCLI via a port.
-}

import Browser
import Main


main =
    Platform.worker
        { init = Main.initSSRPages
        , update = Main.update
        , subscriptions = always Sub.none
        }
