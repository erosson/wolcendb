import '!!style-loader!css-loader!sass-loader!./main.scss';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import datamine from '../datamine/imports'
// import enLoot from '!!raw-loader!../datamine/localization/text_ui_Loot.xml'
import enLoot from '!!json-loader!@erosson/xlsx-loader!../datamine/localization/text_ui_Loot.xml'
// import Passives from '../datamine/Game/Umbra/Skills/Trees/PassivesSkills/'
console.dir(datamine)

Elm.Main.init({
  flags: {datamine},
  node: document.getElementById('root')
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
