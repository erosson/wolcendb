module Datamine.Skill exposing (Skill, SkillAST, SkillASTVariant, SkillVariant, astsDecoder, decoder, label)

import Datamine.Lang as Lang
import Datamine.Source as Source exposing (Source)
import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Skill =
    { source : Source
    , uid : String
    , uiName : String
    , hudPicture : String
    , lore : Maybe String
    , keywords : List String
    , variants : List SkillVariant
    }


type alias SkillVariant =
    { source : Source
    , uid : String
    , uiName : String
    , lore : Maybe String
    }


type alias SkillAST =
    { source : Source
    , name : String
    , variants : List SkillASTVariant
    }


type alias SkillASTVariant =
    { source : Source
    , uid : String
    , level : Int
    , cost : Int
    }


label : Lang.Datamine d -> { s | uiName : String } -> Maybe String
label dm s =
    Lang.get dm s.uiName


astsDecoder : D.Decoder (List SkillAST)
astsDecoder =
    Util.filteredJsons (String.contains "/Skills/Trees/ActiveSkills/")
        |> D.map (List.map (\( f, d ) -> D.decodeValue (skillASTDecoder f) d))
        -- |> D.map (List.filterMap Result.toMaybe)
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder


skillASTDecoder : String -> D.Decoder SkillAST
skillASTDecoder file =
    D.succeed SkillAST
        |> P.custom (Source.decoder file "AST")
        |> P.requiredAt [ "$", "Name" ] D.string
        |> P.custom
            (D.succeed SkillASTVariant
                |> P.custom (Source.decoder file "SkillVariant")
                |> P.requiredAt [ "$", "UID" ] D.string
                |> P.requiredAt [ "$", "Level" ] Util.intString
                |> P.requiredAt [ "$", "Cost" ] Util.intString
                |> D.list
                |> D.at [ "SkillVariant" ]
            )
        |> Util.single
        |> D.at [ "MetaData", "AST" ]


ignoredSkills =
    [ "ActiveDodge"
    , "AutoDash"
    , "DeathMark_Explosion"
    , "FrostLance_Explosion"
    , "FrostNova_Zone_Shadow"
    , "FrostNova_Zone"
    , "UsePotion"
    ]


decoder : D.Decoder (List Skill)
decoder =
    Util.filteredJsons (\s -> String.contains "/Skills/NewSkills/Player/" s && not (List.any (\c -> String.contains c s) ignoredSkills))
        |> D.map (List.map (\( f, d ) -> D.decodeValue (skillDecoder f) d))
        |> D.map (Result.Extra.combine >> Result.mapError D.errorToString)
        |> Util.resultDecoder


type alias SkillDecoder =
    { source : Source
    , uid : String
    , uiName : Maybe String
    , hudPicture : Maybe String
    , lore : Maybe String
    , keywords : Maybe (List String)
    }


skillDecoder : String -> D.Decoder Skill
skillDecoder file =
    -- The first skill entry is the skill itself; all following entries are its variants (d3 "runes").
    -- The XML decoding is a bit awkward because lists must be homogeneous. Decode them as an
    -- intermediate structure, SkillDecoder, and transform them to Skills/SkillVariants later.
    D.succeed SkillDecoder
        |> P.custom (Source.decoder file "Skill")
        |> P.requiredAt [ "$", "UID" ] D.string
        |> P.optionalAt [ "HUD", "0", "$", "UIName" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "HUDPicture" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Lore" ] (D.string |> D.map Just) Nothing
        |> P.optionalAt [ "HUD", "0", "$", "Keywords" ] (Util.csStrings |> D.map Just) Nothing
        |> D.list
        |> D.at [ "MetaData", "Skill" ]
        |> D.andThen
            (\els ->
                case els of
                    s :: vs ->
                        case ( s.uiName, s.hudPicture ) of
                            ( Just uiName, Just hudPicture ) ->
                                D.succeed
                                    { source = s.source
                                    , uid = s.uid
                                    , uiName = uiName
                                    , lore = s.lore
                                    , hudPicture = hudPicture
                                    , keywords = s.keywords |> Maybe.withDefault []
                                    , variants =
                                        vs
                                            |> List.filterMap
                                                (\v ->
                                                    Maybe.map
                                                        (\vUiName ->
                                                            { source = v.source
                                                            , uid = v.uid
                                                            , uiName = vUiName
                                                            , lore = v.lore
                                                            }
                                                        )
                                                        v.uiName
                                                )
                                    }

                            ( Nothing, _ ) ->
                                D.fail <| "no skill.uiname for skill: " ++ s.uid

                            ( _, Nothing ) ->
                                D.fail <| "no skill.hudPicture for skill: " ++ s.uid

                    [] ->
                        D.fail "skill has no instances"
            )
