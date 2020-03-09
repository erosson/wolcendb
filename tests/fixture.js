const util = require('../scripts/util.js')
const path = require('path')
const datamine = require(path.join(util.PATH.DATAMINE_BUILD, 'datamine.json'))
const fs = require('fs').promises

async function main() {
  const tmpl = await fs.readFile('./tests/Fixture/Json.elm.template', 'utf8')
  // Stringifying twice escapes the JSON string so it pastes into Elm cleanly.
  // Elm isn't JSON, but the escaping seems similar enough!
  const elm = tmpl.replace('%(datamine)s', JSON.stringify(JSON.stringify(datamine)))
  return await fs.writeFile('./tests/Fixture/Json.elm', elm)
}
if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
