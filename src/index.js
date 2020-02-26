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
  fetch('/all.json'),
  fetch('/searchIndex.json').then(res => res.json()),
])
.then(([datamine, searchIndex]) => {
  const [d1, d2] = datamine.body.tee()
  console.log(d1, d2)
  app.ports.loadAssets.send({datamine, searchIndex})
})

function ProgressResponse(response, onProgress) {
  // thanks, https://github.com/AnthumChris/fetch-progress-indicators/blob/master/fetch-basic/supported-browser.js
}

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
