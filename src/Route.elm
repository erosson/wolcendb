module Route exposing (Route(..), href, parse, pushUrl, replaceUrl)

import Browser.Navigation as Nav
import Html
import Html.Attributes
import Url exposing (Url)
import Url.Parser as P exposing ((</>), (<?>))


type Route
    = Home
    | Weapons
    | Shields
    | Armors
    | Accessories
    | UniqueWeapons
    | UniqueShields
    | UniqueArmors
    | UniqueAccessories
    | UniqueWeapon String
    | UniqueShield String
    | UniqueArmor String
    | UniqueAccessory String
    | Skills
    | Skill String


parse : Url -> Maybe Route
parse =
    P.parse parser


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Home <| P.top
        , P.map Weapons <| P.s "loot" </> P.s "weapon"
        , P.map Shields <| P.s "loot" </> P.s "shield"
        , P.map Armors <| P.s "loot" </> P.s "armor"
        , P.map Accessories <| P.s "loot" </> P.s "accessory"
        , P.map UniqueWeapons <| P.s "loot" </> P.s "unique" </> P.s "weapon"
        , P.map UniqueShields <| P.s "loot" </> P.s "unique" </> P.s "shield"
        , P.map UniqueArmors <| P.s "loot" </> P.s "unique" </> P.s "armor"
        , P.map UniqueAccessories <| P.s "loot" </> P.s "unique" </> P.s "accessory"
        , P.map UniqueWeapon <| P.s "loot" </> P.s "unique" </> P.s "weapon" </> P.string
        , P.map UniqueShield <| P.s "loot" </> P.s "unique" </> P.s "shield" </> P.string
        , P.map UniqueArmor <| P.s "loot" </> P.s "unique" </> P.s "armor" </> P.string
        , P.map UniqueAccessory <| P.s "loot" </> P.s "unique" </> P.s "accessory" </> P.string
        , P.map Skills <| P.s "skill"
        , P.map Skill <| P.s "skill" </> P.string
        ]


toString : Route -> String
toString r =
    case r of
        Home ->
            "/"

        Weapons ->
            "/loot/weapon"

        Shields ->
            "/loot/shield"

        Armors ->
            "/loot/armor"

        Accessories ->
            "/loot/accessory"

        UniqueWeapons ->
            "/loot/unique/weapon"

        UniqueShields ->
            "/loot/unique/shield"

        UniqueArmors ->
            "/loot/unique/armor"

        UniqueAccessories ->
            "/loot/unique/accessory"

        UniqueWeapon id ->
            "/loot/unique/weapon/" ++ id

        UniqueShield id ->
            "/loot/unique/shield/" ++ id

        UniqueArmor id ->
            "/loot/unique/armor/" ++ id

        UniqueAccessory id ->
            "/loot/unique/accessory/" ++ id

        Skills ->
            "/skill"

        Skill s ->
            "/skill/" ++ s


href : Route -> Html.Attribute msg
href =
    toString >> Html.Attributes.href


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl nav =
    toString >> Nav.pushUrl nav


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl nav =
    toString >> Nav.replaceUrl nav
