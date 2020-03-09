#!/usr/bin/env node
const util = require('./util')
const path = require('path')
const mkdirp = require('mkdirp')
const fs = require('fs').promises
const {promisify} = require('util')
const rimraf = promisify(require('rimraf'))
const glob = promisify(require('glob'))

async function main() {
  await fs.access(util.PATH.DATAMINE_TMP)
  await rimraf(util.PATH.DATAMINE)
  return util.copyGlobs({
    src: util.PATH.DATAMINE_TMP,
    dest: util.PATH.DATAMINE,
    patterns: [
      "revision.txt",
      "{localization,lang/*}/text_ui_{Loot,Activeskills,EIM,passiveskills,Endgame}.xml",
      "Game/Umbra/Loot/Armors/{Armors,Accessories,Armors_unique,UniquesAccessories,UniqueArmors}*",
      "Game/Umbra/Loot/Weapons/{Unique,}{Weapons,Shields}*",
      "Game/Umbra/Loot/MagicEffects/Affixes/Armors_Weapons/Affixes{Implicit,Uniques,Armors,Weapons\.,Accessories,Gems}*",
      "Game/Umbra/Skills/NewSkills/Player/Player_*",
      "Game/Umbra/Skills/Trees/ActiveSkills/*.xml",
      "Game/Umbra/SkinParams/WeaponSkins/CosmeticWeaponDescriptorBankGameplay.xml",
      "Game/Umbra/SkinParams/TransferTemplate/TransferTemplateBank.xml",
      "Game/Umbra/Loot/Gems/*",
      "Game/Umbra/Skills/Passive/PST/*",
      "Game/Umbra/Skills/Trees/PassiveSkills/*",
      "Game/Umbra/Loot/Reagents/Reagents.xml",
      "Game/Umbra/CityBuilding/**/*.xml",
      "Game/Umbra/Loot/MagicEffects/Affixes/Craft/GemFamiliesAndCoveredEffectIDs.xml",
      "Game/Umbra/Gameplay/Curve_StatusAilments/*.xml",
    ],
  })
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
