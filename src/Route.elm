module Route exposing
    ( Route(..)
    , href
    , parse
    , pushUrl
    , replaceUrl
    , toAnalytics
    , toUrl
    )

import Browser.Navigation as Nav
import Html
import Html.Attributes
import Url exposing (Url)
import Url.Builder as B
import Url.Parser as P exposing ((</>), (<?>))
import Url.Parser.Query as Q


type Route
    = Home
    | Weapons
    | Shields
    | Armors
    | Accessories
    | Weapon String
    | Shield String
    | Armor String
    | Accessory String
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
    | Affixes
    | Gems
    | Passives
    | Reagents
    | Source String String
    | Search (Maybe String)
    | Table String
    | Changelog
    | Privacy


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
        , P.map Weapon <| P.s "loot" </> P.s "weapon" </> P.string
        , P.map Shield <| P.s "loot" </> P.s "shield" </> P.string
        , P.map Armor <| P.s "loot" </> P.s "armor" </> P.string
        , P.map Accessory <| P.s "loot" </> P.s "accessory" </> P.string
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
        , P.map Affixes <| P.s "affix"
        , P.map Gems <| P.s "gem"
        , P.map Passives <| P.s "passive"
        , P.map Reagents <| P.s "reagent"
        , P.map Source <| P.s "source" </> P.string </> P.string
        , P.map Search <| P.s "search" <?> Q.string "q"
        , P.map Table <| P.s "table" </> P.string
        , P.map Changelog <| P.s "changelog"
        , P.map Privacy <| P.s "privacy"
        ]


toPath : Route -> String
toPath r =
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

        Weapon id ->
            "/loot/weapon/" ++ id

        Shield id ->
            "/loot/shield/" ++ id

        Armor id ->
            "/loot/armor/" ++ id

        Accessory id ->
            "/loot/accessory/" ++ id

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

        Skill id ->
            "/skill/" ++ id

        Affixes ->
            "/affix"

        Gems ->
            "/gem"

        Passives ->
            "/passive"

        Reagents ->
            "/reagent"

        Source type_ id ->
            "/source/" ++ type_ ++ "/" ++ id

        Search _ ->
            "/search"

        Table t ->
            "/table/" ++ t

        Changelog ->
            "/changelog"

        Privacy ->
            "/privacy"


toQuery : Route -> List B.QueryParameter
toQuery route =
    case route of
        Search query ->
            [ query |> Maybe.map (B.string "q") ] |> List.filterMap identity

        _ ->
            []


toString : Route -> String
toString route =
    toPath route ++ (route |> toQuery |> B.toQuery)


toAnalytics : Maybe Route -> String
toAnalytics mroute =
    case mroute of
        Nothing ->
            "/404"

        Just route ->
            case route of
                Weapon _ ->
                    toPath <| Weapon "ID"

                Shield _ ->
                    toPath <| Shield "ID"

                Armor _ ->
                    toPath <| Armor "ID"

                Accessory _ ->
                    toPath <| Accessory "ID"

                UniqueWeapon _ ->
                    toPath <| UniqueWeapon "ID"

                UniqueShield _ ->
                    toPath <| UniqueShield "ID"

                UniqueArmor _ ->
                    toPath <| UniqueArmor "ID"

                UniqueAccessory _ ->
                    toPath <| UniqueAccessory "ID"

                Skill _ ->
                    toPath <| Skill "ID"

                Source _ _ ->
                    toPath <| Source "TYPE" "ID"

                Table _ ->
                    toPath <| Table "ID"

                _ ->
                    toPath route


href : Route -> Html.Attribute msg
href =
    toString >> Html.Attributes.href


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl nav =
    toString >> Nav.pushUrl nav


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl nav =
    toString >> Nav.replaceUrl nav


toUrl : Route -> Url
toUrl route =
    { protocol = Url.Https
    , host = "wolcendb.erosson.org"
    , port_ = Nothing
    , path = toPath route
    , query =
        case toQuery route of
            [] ->
                Nothing

            qs ->
                qs |> B.toQuery |> Just
    , fragment = Nothing
    }
