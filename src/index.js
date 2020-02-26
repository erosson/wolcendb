import '!!style-loader!css-loader!sass-loader!./main.scss';
import 'bootstrap'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
// import datamine from '../datamine/imports.js'
import changelog from '!!raw-loader!../CHANGELOG.md'
// import searchIndex from '../datamine/searchIndex.json'
import analytics from './analytics'
import sizes from '../datamine/sizes.json'

const app = Elm.Main.init({
  flags: {changelog},
  node: document.getElementById('root')
})
analytics(app)

onProgress('datamine')(0)
onProgress('searchIndex')(0)
Promise.all([
  fetch('/datamine.json').then(res => ProgressResponse(res, {onProgress: onProgress('datamine')}).json()),
  fetch('/searchIndex.json').then(res => ProgressResponse(res, {onProgress: onProgress('searchIndex')}).json()),
])
.then(([datamine, searchIndex]) => {
  app.ports.loadAssets.send({datamine, searchIndex})
})

function onProgress(label) {
  return progress => {
    app.ports.loadAssetsProgress.send({label, progress, size: sizes[label]})
  }
}
function ProgressResponse(response, {onProgress}) {
  // thanks, https://github.com/AnthumChris/fetch-progress-indicators/blob/master/fetch-basic/supported-browser.js
  // don't trust content-length, it fails with gzip. sizes.json tells expected unzipped sizes.
  let loaded = 0
  return new Response(
    new ReadableStream({
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
            console.error(error)
            controller.error(error)
          })
        }
      }
    })
  )
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
