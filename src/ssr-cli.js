// https://korban.net/posts/elm/2019-04-23-how-i-generate-static-html-from-elm-elmstatic/
const fs = require('fs').promises
const jsdom = require('jsdom')
const datamine = require('../public/datamine.json')
const searchIndex = require('../public/searchIndex.json')
const mkdirp = require('mkdirp')
const path = require('path')
const ncp = require('ncp')
const {promisify} = require('util')

const SSR_BUILD_DIR = './build-ssr'

main()

function main() {
  promisify(ncp.ncp)('./build', SSR_BUILD_DIR)
  .then(() => mkdirp(SSR_BUILD_DIR+'/no-ssr'))
  .then(() => fs.copyFile(SSR_BUILD_DIR+'/index.html', SSR_BUILD_DIR+'/no-ssr/index.html'))
  .then(() => Promise.all([
    fs.readFile(SSR_BUILD_DIR+'/index.html').then(f => f.toString()),
    fs.readFile('./CHANGELOG.md').then(f => f.toString()),
  ]))
  .then(([template, changelog, _]) => {
    const run = run_(template, changelog)
    return Promise.all(
      [
        ['', '/changelog', '/privacy', '/affix', '/ailment', '/passive', '/skill', '/city/building_seekers_garrison', '/city/building_trade_assembly', '/gem', '/reagent'],
        // TODO: every normal item
        // TODO: every unique item

        // TODO: every source
        // TODO: every table [data,output] combination
      ]
      .reduce((a, b) => a.concat(b))
      .map(path => run(path))
    )
  })
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
}
function run_(template, changelog) {
  return path => {
    const flags = {datamine, searchIndex, changelog, url: "https://wolcendb.erosson.org"+path}
    const dest = SSR_BUILD_DIR + path + '/index.html'
    // console.log('dest', dest)
    staticElm({src: './datamine.tmp/SSR_CLI.elm.js', flags, template, dest})
    // staticElm({src: './SSR_CLI.elm.js', flags, template}).then(console.log)
  }
}
function staticElm({template, src, flags, dest}) {
  // const dom = new jsdom.JSDOM('<!DOCTYPE html><html><body><div id="root">Elm SSR failed</div></body></html>', {
  const dom = new jsdom.JSDOM(template, {runScripts: 'outside-only'})
  return fs.readFile(src)
  .then(elm => elm.toString())
  .then(elm => {
    dom.window.eval(`${elm}\n\nlet app = Elm.SSR_CLI.init({node: document.getElementById('root'), flags: ${JSON.stringify(flags || {})}})`)
    // ssr'ed content is non-interactive, since Elm can't access it. Disable interactive elements.
    dom.window.eval(`Array.from(document.getElementsByTagName('a')).map(el => {el.setAttribute('href', '#'); el.removeAttribute('target'); el.removeAttribute('onClick');})`)
    dom.window.eval(`Array.from(document.getElementsByTagName('input')).map(el => el.setAttribute('readonly', 'readonly'))`)
    dom.window.eval(`Array.from(document.getElementsByTagName('textarea')).map(el => el.setAttribute('readonly', 'readonly'))`)
    // return Promise.resolve(dom.window.document.getElementById('root').innerHTML)
    return Promise.resolve('<!DOCTYPE html>\n' + dom.window.document.documentElement.outerHTML)
  })
  .then(html => {
    if (dest) {
      return mkdirp(path.dirname(dest))
      .then(() => fs.writeFile(dest, html))
    }
    else {
      return Promise.resolve(html)
    }
  })
}
