import '!!style-loader!css-loader!sass-loader!./main.scss';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import datamine from '../datamine/imports.js'
import changelog from '!!raw-loader!../CHANGELOG.md'
import searchIndex from '../datamine/searchIndex.json'
import analytics from './analytics'

const app = Elm.Main.init({
  flags: {changelog, datamine, searchIndex},
  node: document.getElementById('root')
});
analytics(app)

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
