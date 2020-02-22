module Datamine exposing
    ( Datamine
    , Flag
    , decode
    , decoder
    )

{-| Import JSON files from the `datamine` directory.

These are passed in as Elm flags.

We used to decode the xml directly in Elm using the `ymtszw/elm-xml-decode` package.
Converting to JSON and parsing that instead is a little awkward, but it runs much
faster in development (webpack imports - not sure why!) and the JSON decoder has
some features we need (ex. `Json.Decode.keyValuePairs`).

-}

import Datamine.Affix as Affix exposing (Affixes, MagicAffix, NonmagicAffix)
import Datamine.City as City
import Datamine.Cosmetic as Cosmetic exposing (CCosmeticTransferTemplate, CCosmeticWeaponDescriptor)
import Datamine.Gem as Gem exposing (Gem)
import Datamine.Lang as Lang
import Datamine.NormalItem as NormalItem exposing (Item, NormalItem(..))
import Datamine.Passive as Passive exposing (Passive, PassiveTree, PassiveTreeEntry)
import Datamine.Reagent as Reagent exposing (Reagent)
import Datamine.Skill as Skill exposing (Skill, SkillAST, SkillASTVariant, SkillVariant)
import Datamine.Source as Source exposing (Source)
import Datamine.UniqueItem as UniqueItem exposing (UItem, UniqueItem(..))
import Datamine.Util as Util exposing (..)
import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra
import Set exposing (Set)


type alias Flag =
    D.Value


type alias Datamine =
    { revision : Revision
    , loot : List NormalItem
    , uniqueLoot : List UniqueItem
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : Affixes
    , cosmeticTransferTemplates : Dict String CCosmeticTransferTemplate
    , cosmeticWeaponDescriptors : Dict String CCosmeticWeaponDescriptor
    , gems : List Gem
    , passives : List Passive
    , passiveTrees : List PassiveTree
    , reagents : List Reagent
    , cityProjects : List City.Project
    , en : Dict String String

    -- indexes
    , lootByName : Dict String NormalItem
    , uniqueLootByName : Dict String UniqueItem
    , skillsByUid : Dict String Skill
    , skillASTsByName : Dict String SkillAST
    , skillVariantsByUid : Dict String ( SkillVariant, Skill )
    , skillASTVariantsByUid : Dict String SkillASTVariant
    , gemsByName : Dict String Gem
    , nonmagicAffixesById : Dict String NonmagicAffix
    , magicAffixesById : Dict String MagicAffix
    , passivesByName : Dict String Passive
    , passiveTreesByName : Dict String PassiveTree
    , passiveTreeEntries : List ( PassiveTreeEntry, Passive, PassiveTree )
    , passiveTreeEntriesByName : Dict String ( PassiveTreeEntry, Passive, PassiveTree )
    , reagentsByName : Dict String Reagent
    , cityProjectsByName : Dict String City.Project
    }


type alias RawDatamine =
    { revision : Revision
    , loot : List NormalItem
    , uniqueLoot : List UniqueItem
    , skills : List Skill
    , skillASTs : List SkillAST
    , affixes : Affixes
    , cosmeticTransferTemplates : Dict String CCosmeticTransferTemplate
    , cosmeticWeaponDescriptors : Dict String CCosmeticWeaponDescriptor
    , gems : List Gem
    , passives : List Passive
    , passiveTrees : List PassiveTree
    , reagents : List Reagent
    , cityProjects : List City.Project
    , en : Dict String String
    }


type alias Revision =
    { buildRevision : String
    , date : String
    }


index : RawDatamine -> Datamine
index raw =
    let
        passivesByName =
            raw.passives |> Dict.Extra.fromListBy (.name >> String.toLower)

        passiveTreeEntries : List ( PassiveTreeEntry, Passive, PassiveTree )
        passiveTreeEntries =
            raw.passiveTrees
                |> List.concatMap
                    (\t ->
                        t.entries
                            |> List.filterMap
                                (\e ->
                                    Dict.get (String.toLower e.name) passivesByName
                                        |> Maybe.map (\p -> ( e, p, t ))
                                )
                    )

        skillVariants : List ( SkillVariant, Skill )
        skillVariants =
            raw.skills |> List.concatMap (\s -> s.variants |> List.map (\v -> ( v, s )))
    in
    -- raw copies
    { revision = raw.revision
    , loot = raw.loot
    , uniqueLoot = raw.uniqueLoot
    , skills = raw.skills
    , skillASTs = raw.skillASTs
    , affixes = raw.affixes
    , cosmeticTransferTemplates = raw.cosmeticTransferTemplates
    , cosmeticWeaponDescriptors = raw.cosmeticWeaponDescriptors
    , gems = raw.gems
    , passives = raw.passives
    , passiveTrees = raw.passiveTrees
    , cityProjects = raw.cityProjects
    , reagents = raw.reagents
    , en = raw.en

    -- indexes
    , lootByName = raw.loot |> Dict.Extra.fromListBy (NormalItem.name >> String.toLower)
    , uniqueLootByName = raw.uniqueLoot |> Dict.Extra.fromListBy (UniqueItem.name >> String.toLower)
    , skillsByUid = raw.skills |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , skillASTsByName = raw.skillASTs |> Dict.Extra.fromListBy (.name >> String.toLower)
    , skillVariantsByUid = skillVariants |> Dict.Extra.fromListBy (Tuple.first >> .uid >> String.toLower)
    , skillASTVariantsByUid = raw.skillASTs |> List.concatMap .variants |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , gemsByName = raw.gems |> Dict.Extra.fromListBy (.name >> String.toLower)
    , nonmagicAffixesById = raw.affixes.nonmagic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
    , magicAffixesById = raw.affixes.magic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
    , passivesByName = passivesByName
    , passiveTreesByName = raw.passiveTrees |> Dict.Extra.fromListBy (.name >> String.toLower)
    , passiveTreeEntries = passiveTreeEntries
    , passiveTreeEntriesByName =
        passiveTreeEntries
            |> Dict.Extra.fromListBy (\( e, p, t ) -> e.name |> String.toLower)
    , reagentsByName = raw.reagents |> Dict.Extra.fromListBy (.name >> String.toLower)
    , cityProjectsByName = raw.cityProjects |> Dict.Extra.fromListBy (.name >> String.toLower)
    }


decode : Flag -> Result String Datamine
decode =
    D.decodeValue decoder
        >> Result.mapError D.errorToString


decoder : D.Decoder Datamine
decoder =
    D.succeed RawDatamine
        |> P.custom revisionDecoder
        |> P.custom NormalItem.decoder
        |> P.custom UniqueItem.decoder
        |> P.custom Skill.decoder
        |> P.custom Skill.astsDecoder
        |> P.custom Affix.decoder
        |> P.custom Cosmetic.transferTemplateDecoder
        |> P.custom Cosmetic.weaponDescriptorDecoder
        |> P.custom Gem.decoder
        |> P.custom Passive.decoder
        |> P.custom Passive.treesDecoder
        |> P.custom Reagent.decoder
        |> P.custom City.projectsDecoder
        |> P.custom Lang.decoder
        |> D.map index


revisionDecoder : D.Decoder Revision
revisionDecoder =
    D.map2 Revision
        (D.at [ "revision.json", "build-revision" ] D.string)
        (D.at [ "revision.json", "date" ] D.string)
