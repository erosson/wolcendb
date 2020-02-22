module Datamine.City exposing
    ( Project
    , label
    , lore
    , projectsDecoder
    )

import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Project =
    { source : Source
    , name : String
    , categoryName : String
    , repeatable : Bool
    , uiName : String
    , uiLore : String
    , iconType : Maybe String
    }


label : Lang.Datamine d -> { s | uiName : String } -> Maybe String
label dm s =
    Lang.get dm s.uiName


lore : Lang.Datamine d -> { s | uiLore : String } -> Maybe String
lore dm s =
    Lang.get dm s.uiLore


projectsDecoder : D.Decoder (List Project)
projectsDecoder =
    Util.filteredJsons (String.contains "/CityBuilding/Projects/")
        |> D.map (List.map (\( f, d ) -> D.decodeValue (projectsDecoder_ f) d))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder
        |> D.map List.concat


projectsDecoder_ : String -> D.Decoder (List Project)
projectsDecoder_ file =
    D.succeed Project
        |> P.custom (Source.decoder file "Project")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "CategoryName" ] D.string
        |> P.requiredAt [ "$", "Repeatable" ] Util.boolString
        |> P.requiredAt [ "UIParams", "0", "$", "UIName" ] D.string
        |> P.requiredAt [ "UIParams", "0", "$", "UILore" ] D.string
        |> P.optionalAt [ "UIParams", "0", "$", "IconType" ] (D.string |> D.map Just) Nothing
        |> D.list
        |> D.at [ "MetaData", "Project" ]
