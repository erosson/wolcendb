port module SearchIndex exposing (main)

import Datamine exposing (Datamine)
import ElmTextSearch.Json.Encoder
import Json.Encode as E
import Search


port stdout : E.Value -> Cmd msg


port stderr : E.Value -> Cmd msg


type alias Flags =
    { datamine : Datamine.Flag }


main : Platform.Program Flags () ()
main =
    Platform.worker
        { init = init
        , update = \msg model -> ( model, Cmd.none )
        , subscriptions = \model -> Sub.none
        }


init : Flags -> ( (), Cmd () )
init flags =
    --if True then
    --    ( (), stdout <| E.object [] )
    --
    --else
    ( ()
    , case Datamine.decode flags.datamine of
        Err err ->
            stderr <| E.string err

        Ok dm ->
            case Search.createIndex dm of
                Err errList ->
                    errList
                        |> E.list (\( i, id, err ) -> E.list identity [ E.int i, E.string id, E.string err ])
                        |> stderr

                Ok index ->
                    ElmTextSearch.Json.Encoder.encoder index
                        |> stdout
    )
