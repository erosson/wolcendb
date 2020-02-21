module Tests exposing (..)

import Dict exposing (Dict)
import Expect
import Fixture exposing (datamine)
import Search
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
        , test "build search index" <|
            \_ ->
                Expect.ok <| Search.createIndex datamine
        , test "use search index title" <|
            \_ ->
                Search.createIndex datamine
                    |> Result.mapError Debug.toString
                    |> Result.andThen (Search.search datamine "topaz")
                    |> Result.map (Tuple.second >> List.length)
                    |> Expect.equal (Ok 18)
        , test "use search index id" <|
            \_ ->
                Search.createIndex datamine
                    |> Result.mapError Debug.toString
                    |> Result.andThen (Search.search datamine "fire_gem_tier_")
                    |> Result.map (Tuple.second >> List.length)
                    |> Expect.equal (Ok 12)

        -- , test "This test should fail" <|
        -- \_ ->
        -- Expect.fail "failed as expected!"
        ]
