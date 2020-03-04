module Datamine.Gem exposing (Gem, Socket(..), affixes, decoder, effects, img, label)

import Datamine.Affix as Affix exposing (NonmagicAffix)
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


img : Gem -> String
img gem =
    Util.imghost ++ "/gems/" ++ String.toLower gem.hudPicture


formatSocket : Socket -> String
formatSocket socket =
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
            "???SOCKET???: "


affixes : Affix.Datamine d -> Gem -> List ( Socket, List NonmagicAffix )
affixes dm =
    .effects
        >> List.map
            (Tuple.mapSecond
                (\affixId ->
                    Affix.getNonmagicIds dm [ affixId ]
                )
            )


effects : Affix.Datamine d -> Gem -> List String
effects dm =
    affixes dm
        >> List.map
            (\( socket, affs ) ->
                affs
                    |> List.concatMap .effects
                    |> List.filterMap (Affix.formatEffect dm)
                    |> List.map ((++) (formatSocket socket))
            )
        >> List.concat


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
