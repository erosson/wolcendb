module Tests exposing (..)

import Dict exposing (Dict)
import Expect
import Fixture exposing (datamine)
import Test exposing (..)



-- Check out https://package.elm-lang.org/packages/elm-explorations/test/latest to learn more about testing in Elm!


all : Test
all =
    describe "A Test Suite"
        [ test "Addition" <|
            \_ ->
                Expect.equal 10 (3 + 7)
        , test "String.left" <|
            \_ ->
                Expect.equal "a" (String.left 1 "abcdefg")
        , test "datamine decoded" <|
            \_ ->
                Expect.equal True <| Dict.member (String.toLower "1H_Axe_Tier1") datamine.lootByName

        -- , test "This test should fail" <|
        -- \_ ->
        -- Expect.fail "failed as expected!"
        ]
