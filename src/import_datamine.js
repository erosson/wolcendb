const {promisify} = require('util')
const glob = promisify(require('glob'))
const fs = require('fs').promises
const path = require('path')
const mkdirp = require('mkdirp')
const xml2js = require('xml2js')
const _ = require('lodash/fp')
const imagemin = require('imagemin')
const imageminPngquant = require('imagemin-pngquant')

// const jsonLoader = require('json-loader').default
const xlsxLoader = require('@erosson/xlsx-loader').default

const prefix = "datamine.tmp/"
const dest = "datamine/"
const pngdest = "build-img/"

function main() {
  return Promise.all([
    xmlMain(),
    pngMain(),
    revisionMain(),
  ])
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
}
function xmlMain() {
  return Promise.all([
    glob(prefix + "localization/text_ui_{Loot,Activeskills,EIM,passiveskills,Endgame}.xml", null),
    glob(prefix + "Game/Umbra/Loot/Armors/{Armors,Accessories,Armors_unique,UniquesAccessories,UniqueArmors}*", null),
    glob(prefix + "Game/Umbra/Loot/Weapons/{Unique,}{Weapons,Shields}*", null),
    glob(prefix + "Game/Umbra/Loot/MagicEffects/Affixes/Armors_Weapons/Affixes{Implicit,Uniques,Armors,Weapons\.,Accessories,Gems}*", null),
    glob(prefix + "Game/Umbra/Skills/NewSkills/Player/Player_*", null),
    glob(prefix + "Game/Umbra/Skills/Trees/ActiveSkills/*.xml", null),
    glob(prefix + "Game/Umbra/SkinParams/WeaponSkins/CosmeticWeaponDescriptorBankGameplay.xml", null),
    glob(prefix + "Game/Umbra/SkinParams/TransferTemplate/TransferTemplateBank.xml", null),
    glob(prefix + "Game/Umbra/Loot/Gems/*", null),
    glob(prefix + "Game/Umbra/Skills/Passive/PST/*", null),
    glob(prefix + "Game/Umbra/Skills/Trees/PassiveSkills/*", null),
    glob(prefix + "Game/Umbra/Loot/Reagents/Reagents.xml", null),
    glob(prefix + "Game/Umbra/CityBuilding/**/*.xml", null),
    glob(prefix + "Game/Umbra/Loot/MagicEffects/Affixes/Craft/GemFamiliesAndCoveredEffectIDs.xml", null),
    glob(prefix + "Game/Umbra/Gameplay/Curve_StatusAilments/*.xml", null),
  ])
  .then(groups => groups.map(group => group.map(path => path.replace(/^datamine.tmp\//, ''))))
  .then(groups => {
    const allpaths = flatten(groups)
    const paths = flatten(groups.slice(1))
    // console.log('paths', paths)
    // create directory structure first
    return Promise.all(allpaths.map(p =>
      mkdirp(path.dirname(dest + p))
    ))
    .then(() => Promise.all([
      // copy the unchanged xml files.
      // copied files are committed to git
      Promise.all(allpaths.map(p => fs.copyFile(prefix + p, dest + p))),
      // convert xml to json
      Promise.all(paths.map(p => {
        fs.readFile(prefix + p)
        .then(xml => promisify((new xml2js.Parser()).parseString)(xml))
        .then(json => fs.writeFile(dest + p.replace(/\.xml$/, '.json'), JSON.stringify(json, null, 2)))
      }))
      .then(() =>
        // localization files have a special xml -> json conversion process
        Promise.all(groups[0].map(p => {
          const jsonString = xlsxLoader.apply({resourcePath: prefix + p})
          return fs.writeFile(dest + p.replace(/\.xml$/, '.json'), jsonString)
        }))
      ),
      // create a js file that imports the above stuff
      generateImports(groups),
    ]))
  })
}
function pngMain() {
  return Promise.all([
    // from Libs_UI_*.pak
    glob(prefix + "Game/Libs/UI/u_resources/armors/**/*.png", null),
    glob(prefix + "Game/Libs/UI/u_resources/weapons/**/*.png", null),
    glob(prefix + "Game/Libs/UI/u_resources/spells/Active_Skills/**/*.png", null),
    glob(prefix + "Game/Libs/UI/u_resources/spells/variants/**/*.png", null),
    glob(prefix + "Game/Libs/UI/u_resources/gems/**/*.png", null),
    glob(prefix + "Game/Libs/UI/u_resources/reagents/**/*.png", null),
  ])
  .then(flatten)
  .then(paths => paths.map(path => path.replace(/^datamine.tmp\//, '')))
  .then(paths => {
    return Promise.all(paths.map(p =>
      mkdirp(path.dirname(pngdest + p.toLowerCase()))
    ))
    // .then(() => Promise.all(paths.map(p => fs.copyFile(prefix + p, pngdest + p.toLowerCase()))))
    .then(() => Promise.all(paths.map(p => imagemin([prefix + p], {
      destination: path.dirname(pngdest + p.toLowerCase()),
      plugins: [imageminPngquant({
        quality: [0.3, 0.7],
        strip: true,
      })]
    }))))
    // imagemin destination must be a directory. Lowercasing the file basename is a separate step.
    .then(() => Promise.all(
      paths
      .filter(p => path.basename(p) !== path.basename(p).toLowerCase())
      .map(p => fs.rename(pngdest + path.dirname(p).toLowerCase() + "/" + path.basename(p), pngdest + p.toLowerCase()))
    ))
  })
}
function revisionMain() {
  const p = "revision.txt"
  return Promise.all([
    fs.copyFile(prefix + p, dest + p),
    fs.readFile(prefix + p)
    .then(txt =>
      _.fromPairs(
        txt.toString()
        .split('\n')
        .filter(line => line.trim() !== '')
        .map(line => line.split(':').map(s => s.trim()))
      )
    )
    .then(json =>
      fs.writeFile(
        dest + p.replace(/\.txt$/, '.json'),
        JSON.stringify(json),
      )
    ),
  ])
}
function generateImports(groups) {
  const _output = []
  const output = line => _output.push(line)

  // const localization = groups[0]
  const localization = groups[0].map(p => p.replace(/\.xml$/, '.json'))
  const game = flatten(groups.slice(1)).map(p => p.replace(/\.xml$/, '.json'))

  output("// Autogenerated by src/import_datamine.js. Do not edit!")
  output()
  output(`import revision from "../datamine/revision.json"`)
  for (let [i, json] of game.entries()) {
    output(`import game_${i} from "../datamine/${json}"`)
  }
  for (let [i, json] of localization.entries()) {
    // xml files under datamine/localization/ are excel spreadsheets! They also break Elm's xml parser.
    // So, convert them to json with spreadsheet tools we've used in the past. Elm parses them as json.
    // output(`import localization_${i} from "!!json-loader!@erosson/xlsx-loader!../datamine/${xml}"`)
    output(`import localization_${i} from "../datamine/${json}"`)
  }
  output()
  output("export default {")
  output(`  "revision.json": revision,`)
  for (let [i, json] of game.entries()) {
    output(`  "${json}": game_${i},`)
  }
  for (let [i, json] of localization.entries()) {
    // let json = xml.replace(/\.xml$/, '.json')
    output(`  "${json}": localization_${i},`)
  }
  output("}")
  return Promise.all([
    fs.writeFile(dest + 'imports.js', _output.join('\n')),
    fs.writeFile(dest + 'imports.mjs', _output.join('\n')),
  ])
}
const flatten = as => [].concat.apply([], as)

main()
