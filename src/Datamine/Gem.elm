module Datamine.Gem exposing (Gem, Socket(..), decoder, label)

import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Gem =
    { source : Source
    , name : String
    , uiName : String
    , hudPicture : String
    , levelPrereq : Int
    , gemTier : Int
    , dropLevel : Util.Range Int
    , keywords : List String
    , effects : List ( Socket, String )
    }


type Socket
    = Offensive Int
    | Defensive Int
    | Support Int


label : Lang.Datamine d -> Gem -> Maybe String
label dm s =
    Lang.get dm s.uiName


decoder : D.Decoder (List Gem)
decoder =
    let
        file =
            "Game/Umbra/Loot/Gems/gems.json"
    in
    D.succeed Gem
        |> P.custom (Source.decoder file "Gem")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.requiredAt [ "$", "UIName" ] D.string
        |> P.requiredAt [ "$", "HUDPicture" ] D.string
        |> P.requiredAt [ "$", "LevelPrereq" ] Util.intString
        |> P.requiredAt [ "$", "GemTier" ] Util.intString
        |> P.custom
            (D.succeed Util.Range
                |> P.requiredAt [ "$", "MinDropLevel" ] Util.intString
                |> P.requiredAt [ "$", "MaxDropLevel" ] Util.intString
            )
        |> P.requiredAt [ "$", "Keywords" ] Util.csStrings
        |> P.requiredAt [ "SupportedMagicEffects" ] gemEffectsDecoder
        |> D.list
        |> D.at [ file, "Gems", "Gem" ]


gemEffectsDecoder : D.Decoder (List ( Socket, String ))
gemEffectsDecoder =
    D.keyValuePairs (D.at [ "$", "Id" ] D.string |> Util.single)
        |> D.map
            (List.map
                (\( key, id ) ->
                    case key |> String.split "_" of
                        [ type_, index_ ] ->
                            case ( type_, String.toInt index_ ) of
                                ( "Offensive", Just i ) ->
                                    Ok ( Offensive i, id )

                                ( "Defensive", Just i ) ->
                                    Ok ( Defensive i, id )

                                ( "Support", Just i ) ->
                                    Ok ( Support i, id )

                                _ ->
                                    Err <| "unknown gem-effect key: " ++ key

                        _ ->
                            Err <| "unknown gem-effect key: " ++ key
                )
                >> Result.Extra.combine
            )
        |> Util.resultDecoder
        |> Util.single