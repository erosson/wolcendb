module Fixture exposing (datamine)

import Datamine exposing (Datamine)
import Fixture.Json
import Json.Decode as D exposing (Decoder)


datamine : Datamine
datamine =
    case D.decodeString Datamine.decoder Fixture.Json.datamine of
        Err err ->
            -- this is fine, it's tests
            Debug.todo <| "datamine decoder failed: " ++ D.errorToString err

        Ok dm ->
            dm
