import '!!style-loader!css-loader!sass-loader!./main.scss';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import Weapons from '!!raw-loader!../datamine/Game/Umbra/Loot/Weapons/Weapons.xml'
import Shields from '!!raw-loader!../datamine/Game/Umbra/Loot/Weapons/Shields.xml'
import Armors from '!!raw-loader!../datamine/Game/Umbra/Loot/Armors/Armors.xml'
import Accessories from '!!raw-loader!../datamine/Game/Umbra/Loot/Armors/Accessories.xml'
import UniqueWeapons from '!!raw-loader!../datamine/Game/Umbra/Loot/Weapons/UniqueWeapons.xml'
import UniqueShields from '!!raw-loader!../datamine/Game/Umbra/Loot/Weapons/UniqueShields.xml'
import UniqueArmors from '!!raw-loader!../datamine/Game/Umbra/Loot/Armors/Armors_uniques.xml'
import UniqueAccessories from '!!raw-loader!../datamine/Game/Umbra/Loot/Armors/UniquesAccessories.xml'
// import enLoot from '!!raw-loader!../datamine/localization/text_ui_Loot.xml'
import enLoot from '!!json-loader!@erosson/xlsx-loader!../datamine/localization/text_ui_Loot.xml'
// import Passives from '../datamine/Game/Umbra/Skills/Trees/PassivesSkills/'
const datamine = {
  Weapons,
  Shields,
  Armors,
  Accessories,
  UniqueWeapons,
  UniqueShields,
  UniqueArmors,
  UniqueAccessories,
  en: {
    Loot: enLoot,
  }
}
console.dir(datamine)

Elm.Main.init({
  flags: {
    datamine,
  },
  node: document.getElementById('root')
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
