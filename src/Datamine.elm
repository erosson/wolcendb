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
import Datamine.Ailment as Ailment exposing (Ailment)
import Datamine.City as City
import Datamine.Cosmetic as Cosmetic exposing (CCosmeticTransferTemplate, CCosmeticWeaponDescriptor)
import Datamine.Gem as Gem exposing (Gem)
import Datamine.GemFamily as GemFamily exposing (GemFamily)
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
import List.Extra
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
    , gemFamilies : List GemFamily
    , cityProjects : List City.Project
    , cityProjectScaling : List City.ProjectScaling
    , cityRewards : List City.Reward
    , cityBuildings : List City.Building
    , cityCategories : List City.Category
    , cityLevels : List City.Level
    , ailments : List Ailment
    , en : Dict String String

    -- indexes
    , lootByName : Dict String NormalItem
    , uniqueLootByName : Dict String UniqueItem
    , uniqueLootByNonmaxName : Dict String (List UniqueItem)
    , skillsByUid : Dict String Skill
    , skillASTsByName : Dict String SkillAST
    , skillVariantsByUid : Dict String ( SkillVariant, Skill )
    , skillASTVariantsByUid : Dict String SkillASTVariant
    , gemsByName : Dict String Gem
    , nonmagicAffixesById : Dict String NonmagicAffix
    , magicAffixesById : Dict String MagicAffix
    , magicAffixesKeywords : List String
    , passivesByName : Dict String Passive
    , passiveTreesByName : Dict String PassiveTree
    , passiveTreeEntries : List ( PassiveTreeEntry, Passive, PassiveTree )
    , passiveTreeEntriesByName : Dict String ( PassiveTreeEntry, Passive, PassiveTree )
    , reagentsByName : Dict String Reagent
    , gemFamiliesById : Dict String GemFamily
    , gemFamiliesByGemId : Dict String GemFamily
    , gemFamiliesByEffectId : Dict String (List GemFamily)
    , gemFamiliesByAffixId : Dict String (List GemFamily)
    , cityProjectsByName : Dict String City.Project
    , cityProjectScalingByName : Dict String City.ProjectScaling
    , cityRewardsByName : Dict String City.Reward
    , cityBuildingsByName : Dict String City.Building
    , cityCategoriesByName : Dict String City.Category
    , ailmentsByName : Dict String Ailment
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
    , gemFamilies : List GemFamily
    , cityProjects : List City.Project
    , cityProjectScaling : List City.ProjectScaling
    , cityRewards : List City.Reward
    , cityBuildings : List City.Building
    , cityCategories : List City.Category
    , cityLevels : List City.Level
    , ailments : List Ailment
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

        gemFamiliesByEffectId =
            raw.gemFamilies
                |> List.concatMap (\fam -> fam.craftRelatedAffixes |> List.map (\eff -> ( eff, fam )))
                |> Dict.Extra.groupBy (Tuple.first >> String.toLower)
                |> Dict.map (always <| List.map Tuple.second)
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
    , reagents = raw.reagents
    , gemFamilies = raw.gemFamilies
    , cityProjects = raw.cityProjects
    , cityProjectScaling = raw.cityProjectScaling
    , cityRewards = raw.cityRewards
    , cityBuildings = raw.cityBuildings
    , cityCategories = raw.cityCategories
    , cityLevels = raw.cityLevels
    , ailments = raw.ailments
    , en = raw.en

    -- indexes
    , lootByName = raw.loot |> Dict.Extra.fromListBy (NormalItem.name >> String.toLower)
    , uniqueLootByName = raw.uniqueLoot |> Dict.Extra.fromListBy (UniqueItem.name >> String.toLower)
    , uniqueLootByNonmaxName =
        raw.uniqueLoot
            |> Dict.Extra.groupBy (UniqueItem.nonmaxName >> String.toLower)
            |> Dict.map (\_ -> List.sortBy (UniqueItem.levelPrereq >> Maybe.withDefault 0))
    , skillsByUid = raw.skills |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , skillASTsByName = raw.skillASTs |> Dict.Extra.fromListBy (.name >> String.toLower)
    , skillVariantsByUid = skillVariants |> Dict.Extra.fromListBy (Tuple.first >> .uid >> String.toLower)
    , skillASTVariantsByUid = raw.skillASTs |> List.concatMap .variants |> Dict.Extra.fromListBy (.uid >> String.toLower)
    , gemsByName = raw.gems |> Dict.Extra.fromListBy (.name >> String.toLower)
    , nonmagicAffixesById = raw.affixes.nonmagic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
    , magicAffixesById = raw.affixes.magic |> Dict.Extra.fromListBy (.affixId >> String.toLower)
    , magicAffixesKeywords =
        raw.affixes.magic
            |> List.concatMap (\a -> a.drop.mandatoryKeywords ++ a.drop.optionalKeywords)
            |> List.Extra.unique
    , passivesByName = passivesByName
    , passiveTreesByName = raw.passiveTrees |> Dict.Extra.fromListBy (.name >> String.toLower)
    , passiveTreeEntries = passiveTreeEntries
    , passiveTreeEntriesByName =
        passiveTreeEntries
            |> Dict.Extra.fromListBy (\( e, p, t ) -> e.name |> String.toLower)
    , reagentsByName = raw.reagents |> Dict.Extra.fromListBy (.name >> String.toLower)
    , gemFamiliesById = raw.gemFamilies |> Dict.Extra.fromListBy (.gemFamilyId >> String.toLower)
    , gemFamiliesByGemId =
        raw.gemFamilies
            |> List.concatMap (\fam -> fam.relatedGems |> List.map (\r -> ( String.toLower r.gemId, fam )))
            |> Dict.fromList
    , gemFamiliesByEffectId = gemFamiliesByEffectId
    , gemFamiliesByAffixId =
        (List.map (\a -> ( a.affixId, Affix.effectIds a )) raw.affixes.magic
            ++ List.map (\a -> ( a.affixId, Affix.effectIds a )) raw.affixes.nonmagic
        )
            |> List.map
                (Tuple.mapBoth
                    String.toLower
                    (List.filterMap (\effectId -> Dict.get (String.toLower effectId) gemFamiliesByEffectId)
                        >> List.concat
                        >> List.Extra.uniqueBy .gemFamilyId
                    )
                )
            |> Dict.fromList
    , cityProjectsByName = raw.cityProjects |> Dict.Extra.fromListBy (.name >> String.toLower)
    , cityProjectScalingByName = raw.cityProjectScaling |> Dict.Extra.fromListBy (.name >> String.toLower)
    , cityRewardsByName = raw.cityRewards |> Dict.Extra.fromListBy (.name >> String.toLower)
    , cityBuildingsByName = raw.cityBuildings |> Dict.Extra.fromListBy (.name >> String.toLower)
    , cityCategoriesByName = raw.cityCategories |> Dict.Extra.fromListBy (.name >> String.toLower)
    , ailmentsByName = raw.ailments |> Dict.Extra.fromListBy (.name >> String.toLower)
    }


decode : Flag -> Result String Datamine
decode =
    D.decodeValue decoder
        >> Result.mapError D.errorToString


decoder : D.Decoder Datamine
decoder =
    D.andThen
        (\revision ->
            D.succeed (RawDatamine revision)
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
                |> P.custom GemFamily.decoder
                |> P.custom City.projectsDecoder
                |> P.custom City.projectScalingDecoder
                |> P.custom City.rewardsDecoder
                |> P.custom City.buildingsDecoder
                |> P.custom City.categoriesDecoder
                |> P.custom City.levelsDecoder
                |> P.custom (Ailment.decoder revision.buildRevision)
                |> P.custom Lang.decoder
                |> D.map index
        )
        revisionDecoder


revisionDecoder : D.Decoder Revision
revisionDecoder =
    D.map2 Revision
        (D.at [ "revision.json", "build-revision" ] D.string)
        (D.at [ "revision.json", "date" ] D.string)
