// import {promises as fs} from 'fs'
import datamine from '../datamine/imports.mjs'
import {promisify} from 'util'
import fs from 'fs'

async function main() {
  const tmpl = await promisify(fs.readFile)('./tests/Fixture/Json.elm.template', 'utf8')
  // Stringifying twice escapes the JSON string so it pastes into Elm cleanly.
  // Elm isn't JSON, but the escaping seems similar enough!
  const elm = tmpl.replace('%(datamine)s', JSON.stringify(JSON.stringify(datamine)))
  return await promisify(fs.writeFile)('./tests/Fixture/Json.elm', elm)
}
main()
