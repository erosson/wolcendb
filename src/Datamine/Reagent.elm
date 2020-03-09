module Datamine.Reagent exposing
    ( Reagent
    , decoder
    , desc
    , img
    , label
    , lore
    )

import Datamine.Affix as Affix
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Lang exposing (Lang)
import Result.Extra


type alias Reagent =
    { source : Source
    , name : String
    , uiName : String
    , gameplayDesc : String
    , lore : String
    , hudPicture : String
    , reagentType : String
    }


label : Lang -> Reagent -> Maybe String
label lang s =
    Lang.get lang s.uiName


desc : Lang -> Reagent -> Maybe String
desc lang s =
    Lang.get lang s.gameplayDesc


lore : Lang -> Reagent -> Maybe String
lore lang s =
    Lang.get lang s.lore


img : Reagent -> String
img item =
    Util.imghost ++ "/" ++ item.hudPicture


decoder : D.Decoder (List Reagent)
decoder =
    let
        file =
            "Game/Umbra/Loot/Reagents/Reagents.json"
    in
    D.succeed Reagent
        |> P.custom (Source.decoder file "Reagent")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "GameplayDesc" ] D.string
        |> P.requiredAt [ "$", "Lore" ] D.string
        |> P.requiredAt [ "$", "HUDPicture" ] D.string
        |> P.requiredAt [ "$", "ReagentType" ] D.string
        |> D.list
        |> D.at [ file, "Reagents", "Reagent" ]
