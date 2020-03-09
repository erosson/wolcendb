module Fixture exposing (datamine, lang)

import Datamine exposing (Datamine)
import Fixture.Json
import Json.Decode as D exposing (Decoder)
import Lang exposing (Lang)


datamine : Datamine
datamine =
    case D.decodeString Datamine.decoder Fixture.Json.datamine of
        Err err ->
            -- this is fine, it's tests
            Debug.todo <| "datamine decoder failed: " ++ D.errorToString err

        Ok dm ->
            dm


lang : Lang
lang =
    case D.decodeString Lang.decoder Fixture.Json.datamine of
        Err err ->
            -- this is fine, it's tests
            Debug.todo <| "lang decoder failed: " ++ D.errorToString err

        Ok dm ->
            dm
