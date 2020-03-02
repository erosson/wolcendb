import '!!style-loader!css-loader!sass-loader!./main.scss';
import 'bootstrap'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import changelog from '!!raw-loader!../CHANGELOG.md'
import analytics from './analytics'
import sizes from '../datamine/sizes.json'
// import datamine from '../datamine/imports.js'
// import searchIndex from '../public/searchIndex.json'

// Elm will overwrite this node. For SSR'ed pages (see `yarn build:ssr`), this
// also contains the pre-rendered page content.
const root = document.getElementById('root')
const ssrHTML = root.innerHTML

const app = Elm.Main.init({
  // flags: {changelog, datamine, searchIndex},
  flags: {changelog, datamine: null, searchIndex: null},
  node: document.getElementById('root')
})
analytics(app)
app.ports.ssr.subscribe(id => {
  // console.log('ssr', id, ssrHTML)
  document.getElementById(id).innerHTML = ssrHTML
})

fetchAssets(app)
.then(([datamine, searchIndex]) => {
  app.ports.loadAssets.send({datamine, searchIndex})
})
.catch(err => console.log('fetch error', err))
function fetchAssets(app) {
  const isProgressSupported = window.Response && window.ReadableStream
  if (isProgressSupported) {
    onProgress('datamine')(0)
    onProgress('searchIndex')(0)
    return Promise.all([
      fetch('/datamine.json').then(res => ProgressResponse(res, {onProgress: onProgress('datamine')}).json()),
      fetch('/searchIndex.json').then(res => ProgressResponse(res, {onProgress: onProgress('searchIndex')}).json()),
    ])
  }
  else {
    console.warn('loading progressbar unsupported by this browser, trying to load without it')
    return Promise.all([
      fetch('/datamine.json').then(res => res.json()),
      fetch('/searchIndex.json').then(res => res.json()),
    ])
  }
}

function onProgress(label) {
  return progress => {
    app.ports.loadAssetsProgress.send({label, progress, size: sizes[label]})
  }
}
function ProgressResponse(response, {onProgress}) {
  // thanks, https://github.com/AnthumChris/fetch-progress-indicators/blob/master/fetch-basic/supported-browser.js
  // don't trust content-length, it fails with gzip. sizes.json tells expected unzipped sizes.
  let loaded = 0
  try {
    const stream = new ReadableStream({
      start(controller) {
        const reader = response.body.getReader()
        read()

        function read() {
          reader.read().then(({done, value}) => {
            if (done) {
              return controller.close()
            }
            loaded += value.byteLength;
            onProgress(loaded)
            controller.enqueue(value)
            read()
          })
          .catch(error => {
            console.error('ReadableStream error', error)
            controller.error(error)
          })
        }
      },
      pull(controller){},
      cancel(){},
    })
    return new Response(stream)
  }
  catch (e) {
    // Edge, I thought you were supposed to be better than IE. C'mon.
    // https://stackoverflow.com/questions/55294816/how-do-i-create-a-readablestream-in-microsoft-edge
    console.warn('ProgressResponse failed, trying original response.', e)
    return response
  }
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
