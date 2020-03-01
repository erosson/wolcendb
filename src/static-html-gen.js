// https://korban.net/posts/elm/2019-04-23-how-i-generate-static-html-from-elm-elmstatic/
// TODO: this is a solid start, but we're still missing everything else in index.js. actual elm loading, bootstrap css, main css, es6, analytics...
// Also need some approach to deployment.
// Still, this is a solid start!
const fs = require('fs').promises
const jsdom = require('jsdom')
const datamine = require('../public/datamine.json')
const searchIndex = require('../public/searchIndex.json')
const mkdirp = require('mkdirp')
const path = require('path')

function staticElm({template, src, flags, dest}) {
  // const dom = new jsdom.JSDOM('<!DOCTYPE html><html><body><div id="root">Elm StaticHtmlGen failed</div></body></html>', {
  const dom = new jsdom.JSDOM(template, {runScripts: 'outside-only'})
  return fs.readFile(src)
  .then(elm => elm.toString())
  .then(elm => {
    dom.window.eval(`${elm}\n\nlet app = Elm.StaticHtmlGen.init({node: document.getElementById('root'), flags: ${JSON.stringify(flags || {})}})`)
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
function run_(template, changelog) {
  return path => {
    const flags = {datamine, searchIndex, changelog, url: "https://wolcendb.erosson.org"+path}
    const dest = './ssr' + path + '/index.html'
    // console.log('dest', dest)
    staticElm({src: './StaticHtmlGen.elm.js', flags, template, dest})
    // staticElm({src: './StaticHtmlGen.elm.js', flags, template}).then(console.log)
  }
}
function main() {
  Promise.all([
    fs.readFile('./public/index.html').then(f => f.toString()).then(f => f.replace(/%PUBLIC_URL%/g, '')),
    fs.readFile('./CHANGELOG.md').then(f => f.toString()),
  ])
  .then(([template, changelog]) => {
    const run = run_(template, changelog)
    return Promise.all(
      [
        ['', '/changelog', '/privacy'],
      ]
      .reduce((a, b) => a.concat(b))
      .map(path => run(path))
    )
  })
  .catch(console.error)
}
main()
