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
    | NormalItems (Maybe Int) (Maybe String)
    | NormalItem String
    | UniqueItems (Maybe String)
    | UniqueItem String
    | Skills
    | Skill String
    | SkillVariant String
    | Affixes
    | Gems
    | Passives
    | Reagents
    | City String
    | Ailments
    | Source String String
    | Offline String String
    | Search (Maybe String)
    | Table String
    | BuildRevisions
    | Langs
    | Changelog
    | Privacy
    | Redirect Route


parse : Url -> Maybe Route
parse =
    P.parse parser


parser : P.Parser (Route -> a) a
parser =
    P.oneOf
        [ P.map Home <| P.top
        , P.map Skills <| P.s "skill"
        , P.map Skill <| P.s "skill" </> P.string
        , P.map SkillVariant <| P.s "skill-variant" </> P.string
        , P.map Affixes <| P.s "affix"
        , P.map Gems <| P.s "gem"
        , P.map Passives <| P.s "passive"
        , P.map Reagents <| P.s "reagent"
        , P.map City <| P.s "city" </> P.string
        , P.map Ailments <| P.s "ailment"
        , P.map Source <| P.s "source" </> P.string </> P.string
        , P.map Offline <| P.s "offline" </> P.string </> P.string
        , P.map Search <| P.s "search" <?> Q.string "q"
        , P.map Table <| P.s "table" </> P.string
        , P.map BuildRevisions <| P.s "build-revisions"
        , P.map Langs <| P.s "language"
        , P.map Changelog <| P.s "changelog"
        , P.map Privacy <| P.s "privacy"

        -- legacy routes
        , P.map (Redirect (NormalItems Nothing (Just "weapon"))) <| P.s "loot" </> P.s "weapon"
        , P.map (Redirect (NormalItems Nothing (Just "shield"))) <| P.s "loot" </> P.s "shield"
        , P.map (Redirect (NormalItems Nothing (Just "armor"))) <| P.s "loot" </> P.s "armor"
        , P.map (Redirect (NormalItems Nothing (Just "accessory"))) <| P.s "loot" </> P.s "accessory"
        , P.map (Redirect << NormalItem) <| P.s "loot" </> P.s "weapon" </> P.string
        , P.map (Redirect << NormalItem) <| P.s "loot" </> P.s "shield" </> P.string
        , P.map (Redirect << NormalItem) <| P.s "loot" </> P.s "armor" </> P.string
        , P.map (Redirect << NormalItem) <| P.s "loot" </> P.s "accessory" </> P.string
        , P.map (Redirect (UniqueItems (Just "weapon"))) <| P.s "loot" </> P.s "unique" </> P.s "weapon"
        , P.map (Redirect (UniqueItems (Just "shield"))) <| P.s "loot" </> P.s "unique" </> P.s "shield"
        , P.map (Redirect (UniqueItems (Just "armor"))) <| P.s "loot" </> P.s "unique" </> P.s "armor"
        , P.map (Redirect (UniqueItems (Just "accessory"))) <| P.s "loot" </> P.s "unique" </> P.s "accessory"
        , P.map (Redirect << UniqueItem) <| P.s "loot" </> P.s "unique" </> P.s "weapon" </> P.string
        , P.map (Redirect << UniqueItem) <| P.s "loot" </> P.s "unique" </> P.s "shield" </> P.string
        , P.map (Redirect << UniqueItem) <| P.s "loot" </> P.s "unique" </> P.s "armor" </> P.string
        , P.map (Redirect << UniqueItem) <| P.s "loot" </> P.s "unique" </> P.s "accessory" </> P.string

        -- modern item routes
        , P.map UniqueItems <| P.s "loot" </> P.s "unique" <?> Q.string "keywords"
        , P.map UniqueItem <| P.s "loot" </> P.s "unique" </> P.string
        , P.map NormalItems <| P.s "loot" <?> Q.int "tier" <?> Q.string "keywords"
        , P.map NormalItem <| P.s "loot" </> P.string
        ]


toPath : Route -> String
toPath r =
    case r of
        Redirect next ->
            toPath next

        Home ->
            "/"

        NormalItems _ _ ->
            "/loot"

        NormalItem id ->
            "/loot/" ++ id

        UniqueItems _ ->
            "/loot/unique"

        UniqueItem id ->
            "/loot/unique/" ++ id

        Skills ->
            "/skill"

        Skill id ->
            "/skill/" ++ id

        SkillVariant id ->
            "/skill-variant/" ++ id

        Affixes ->
            "/affix"

        Gems ->
            "/gem"

        Passives ->
            "/passive"

        Reagents ->
            "/reagent"

        City name ->
            "/city/" ++ name

        Ailments ->
            "/ailment"

        Source type_ id ->
            "/source/" ++ type_ ++ "/" ++ id

        Offline type_ id ->
            "/offline/" ++ type_ ++ "/" ++ id

        Search _ ->
            "/search"

        Table t ->
            "/table/" ++ t

        BuildRevisions ->
            "/build-revisions"

        Langs ->
            "/language"

        Changelog ->
            "/changelog"

        Privacy ->
            "/privacy"


toQuery : Route -> List B.QueryParameter
toQuery route =
    case route of
        Search query ->
            [ query |> Maybe.map (B.string "q") ] |> List.filterMap identity

        UniqueItems tags ->
            [ tags |> Maybe.map (B.string "keywords") ] |> List.filterMap identity

        NormalItems tier tags ->
            [ tags |> Maybe.map (B.string "keywords")
            , tier |> Maybe.map (B.int "tier")
            ]
                |> List.filterMap identity

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
                NormalItem _ ->
                    toPath <| NormalItem "ID"

                UniqueItem _ ->
                    toPath <| UniqueItem "ID"

                Skill _ ->
                    toPath <| Skill "ID"

                SkillVariant _ ->
                    toPath <| SkillVariant "ID"

                City _ ->
                    toPath <| City "ID"

                Source _ _ ->
                    toPath <| Source "TYPE" "ID"

                Offline _ _ ->
                    toPath <| Offline "TYPE" "ID"

                Table _ ->
                    toPath <| Table "ID"

                _ ->
                    toPath route


href : Route -> Html.Attribute msg
href =
    toString >> Html.Attributes.href


pushUrl : Maybe Nav.Key -> Route -> Cmd msg
pushUrl mnav =
    case mnav of
        Nothing ->
            -- Unit tests or statichtmlgen
            always Cmd.none

        Just nav ->
            toString >> Nav.pushUrl nav


replaceUrl : Maybe Nav.Key -> Route -> Cmd msg
replaceUrl mnav =
    case mnav of
        Nothing ->
            -- Unit tests or statichtmlgen
            always Cmd.none

        Just nav ->
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
