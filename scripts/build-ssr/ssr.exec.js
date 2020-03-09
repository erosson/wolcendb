 // https://korban.net/posts/elm/2019-04-23-how-i-generate-static-html-from-elm-elmstatic/
const util = require('../util')
const fs = require('fs').promises
const jsdom = require('jsdom')
const mkdirp = require('mkdirp')
const path = require('path')
const {promisify} = require('util')
const _ = require('lodash/fp')
const {Elm} = require('./ListPages.elm.js')

const buildRevisions = require(path.join(util.PATH.PUBLIC, 'buildRevisions.json'))
const langs = require(path.join(util.PATH.DATAMINE_BUILD, 'lang.json'))
const datamine = require(path.join(util.PATH.DATAMINE_BUILD, 'datamine.json'))
const searchIndex = require(path.join(util.PATH.DATAMINE_BUILD, 'searchIndex.json'))

const rootDest = util.PATH.BUILD_SSR

async function main() {
  await mkdirp(path.join(rootDest, 'no-ssr'))
  await fs.copyFile(path.join(rootDest, 'index.html'), path.join(rootDest, 'no-ssr', 'index.html'))

  const template = await fs.readFile(path.join(rootDest, 'index.html')).then(f => f.toString())
  const changelog = await fs.readFile(path.join(util.PATH.ROOT, 'CHANGELOG.md')).then(f => f.toString())
  const baseFlags = {buildRevisions, langs, datamine, searchIndex, changelog}

  const staticPages = ['', '/changelog', '/privacy', '/affix', '/ailment', '/passive', '/skill', '/city/building_seekers_garrison', '/city/building_trade_assembly', '/gem', '/reagent', '/loot', '/loot/unique']
  // fetch a list of pages to render from Pages.elm
  const genPages = await new Promise(resolve => {
    const pagesApp = Elm.ListPages.init({flags: baseFlags})
    pagesApp.ports.ssrCliPages.subscribe(resolve)
  })
  // const pages = staticPages
  const pages = staticPages.concat(genPages)

  // initialize a SSRRenderCLI renderer. We initialize this once and reuse it for every render.
  // Rerunning the elm program for every render was simpler, but way too slow!
  // This avoids rebuilding datamine indexes, etc.
  const elmJs = await fs.readFile(path.join(__dirname, 'Render.elm.js')).then(f => f.toString())
  const flags = {...baseFlags, url: ''}
  const renderDom = new jsdom.JSDOM(template, {runScripts: 'outside-only'})
  renderDom.window.eval(`${elmJs}\n\nwindow.app = Elm.SSRRenderCLI.init({node: document.getElementById('root'), flags: ${JSON.stringify(flags)}})`)
  // return Promise.all(pages.map(path => run(path)))
  //
  // NOPE, too many pages for that. Run one at a time instead.
  // TODO: batches with multiple renderDoms, for faster processing?
  // https://stackoverflow.com/questions/53964228/how-do-i-perform-a-large-batch-of-promises
  // https://blog.neverendingqs.com/2017/12/02/promises-batches-reduce.html
  const startTime = Date.now()
  return _.reduce.convert({cap: false})((chain, page, i) => chain.then(() => {
    if (i % 50 == 0) console.log('page', i, 'done: ', i , '/', pages.length, ", ", (Date.now() - startTime) / 1000, 'sec')
    return run(renderDom, page)
  }), Promise.resolve(), pages)
}
function run(renderDom, path_) {
  const url = "https://wolcendb.erosson.org"+path_
  const dest = path.join(rootDest, path_, 'index.html')
  // console.log('dest', dest)
  return staticElm({renderDom, url, dest, path_})
  // return staticElm({renderDom, url, dest, path_}).then(([path_, dest, html]) => console.log(path_, dest, html.length))
}
async function staticElm({renderDom, dest, url, path_}) {
  // send port message to change url; wait for port message saying view is rendered
  const oldHtml = renderDom.window.document.documentElement.outerHTML
  renderDom.window.eval(`app.ports.ssrCliRender.send("${url}")`)
  // renderDom.window.app.ports.ssrCliRender.send(url)

  await new Promise(resolve => {
    // renderDom.window.app.ports.urlChange.subscribe(resolve)
    // NOPE that didn't work. Instead of subscribing, poll for html changes
    let i = 0
    function pollUntilChanged() {
      if (oldHtml === renderDom.window.document.documentElement.outerHTML) {
        i += 1
        if (i % 100 == 0) console.log('polling...', url, i, oldHtml)
        setTimeout(pollUntilChanged, 1)
      }
      else {
        // console.log(path_, 'pollUntilChanged done. steps:', i)
        resolve()
      }
    }
    pollUntilChanged()
  })
  // before we grab the ssr'ed content, it should be non-interactive, since Elm isn't running yet. Disable interactive elements.
  renderDom.window.eval(`Array.from(document.getElementsByTagName('a')).map(el => {el.setAttribute('href', '#'); el.removeAttribute('target'); el.removeAttribute('onClick');})`)
  renderDom.window.eval(`Array.from(document.getElementsByTagName('input')).map(el => el.setAttribute('readonly', 'readonly'))`)
  renderDom.window.eval(`Array.from(document.getElementsByTagName('textarea')).map(el => el.setAttribute('readonly', 'readonly'))`)
  // finally, we have the ssr'ed html!
  const html = '<!DOCTYPE html>\n' + renderDom.window.document.documentElement.outerHTML

  if (dest) {
    await mkdirp(path.dirname(dest))
    await fs.writeFile(dest, html)
  }
  return Promise.resolve([path_, dest, html])
}

if (require.main == module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
