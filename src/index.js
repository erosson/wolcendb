import '!!style-loader!css-loader!sass-loader!./main.scss';
import 'bootstrap'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
// import datamine from '../datamine/imports.js'
import changelog from '!!raw-loader!../CHANGELOG.md'
// import searchIndex from '../datamine/searchIndex.json'
import analytics from './analytics'

const app = Elm.Main.init({
  flags: {changelog},
  node: document.getElementById('root')
})
analytics(app)

Promise.all([
  fetch('/all.json').then(res => ProgressResponse(res, {onProgress: console.log}).json()),
  fetch('/searchIndex.json').then(res => ProgressResponse(res, {onProgress: console.log}).json()),
])
.then(([datamine, searchIndex]) => {
  app.ports.loadAssets.send({datamine, searchIndex})
})

function ProgressResponse(response, {onProgress}) {
  // thanks, https://github.com/AnthumChris/fetch-progress-indicators/blob/master/fetch-basic/supported-browser.js
  const contentLength = response.headers.get('content-length')
  console.log([...response.headers.keys()], contentLength)
  let total = parseInt(contentLength, 10)
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
            onProgress({loaded, total})
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
