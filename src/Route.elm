module Route exposing
    ( Options
    , Route(..)
    , base
    , emptyOptions
    , href
    , hrefOptions
    , keywords
    , mapOptions
    , normalItems
    , parse
    , pushUrl
    , replaceUrl
    , toAnalytics
    , toMOptions
    , toOptions
    , toUrl
    )

import Browser.Navigation as Nav
import Html
import Html.Attributes
import Maybe.Extra
import Url exposing (Url)
import Url.Builder as B
import Url.Parser as P exposing ((</>), (<?>))
import Url.Parser.Query as Q


type Route
    = Home
    | NormalItems (Maybe Int) (Maybe String) (Maybe String)
    | NormalItem String
    | UniqueItems (Maybe String)
    | UniqueItem String
    | Skills (Maybe String)
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
    | WithOptions Options Route


type alias Options =
    { lang : Maybe String
    , revision : Maybe String
    , features : Maybe String
    }


emptyOptions : Options
emptyOptions =
    Options Nothing Nothing Nothing


parse : Url -> Maybe Route
parse =
    P.parse parser
        >> Maybe.andThen
            (\( o, route ) ->
                if o == emptyOptions then
                    route

                else
                    route |> Maybe.map (WithOptions o)
            )


parser : P.Parser (( Options, Maybe Route ) -> a) a
parser =
    P.map Tuple.pair <| optionsParser </> P.oneOf [ P.map Just baseParser, P.map Nothing P.top ]


optionsParser : P.Parser (Options -> a) a
optionsParser =
    P.map Options <|
        P.top
            </> maybeStringParser "l"
            </> maybeStringParser "v"
            </> maybeStringParser "f"


maybeStringParser : String -> P.Parser (Maybe String -> a) a
maybeStringParser path =
    P.oneOf
        [ P.map Just <| P.s path </> P.string
        , P.map Nothing P.top
        ]


baseParser : P.Parser (Route -> a) a
baseParser =
    P.oneOf
        [ P.map Home <| P.top
        , P.map Skills <| P.s "skill" <?> Q.string "form"
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
        , P.map BuildRevisions <| P.s "build-revision"
        , P.map Langs <| P.s "language"
        , P.map Changelog <| P.s "changelog"
        , P.map Privacy <| P.s "privacy"

        -- legacy routes
        , P.map (Redirect (NormalItems Nothing (Just "weapon") Nothing)) <| P.s "loot" </> P.s "weapon"
        , P.map (Redirect (NormalItems Nothing (Just "shield") Nothing)) <| P.s "loot" </> P.s "shield"
        , P.map (Redirect (NormalItems Nothing (Just "armor") Nothing)) <| P.s "loot" </> P.s "armor"
        , P.map (Redirect (NormalItems Nothing (Just "accessory") Nothing)) <| P.s "loot" </> P.s "accessory"
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
        , P.map NormalItems <| P.s "loot" <?> Q.int "tier" <?> Q.string "keywords" <?> Q.string "optional_keywords"
        , P.map NormalItem <| P.s "loot" </> P.string
        ]


toPath : Route -> String
toPath r =
    case r of
        Redirect next ->
            toPath next

        WithOptions _ next ->
            toPath next

        Home ->
            ""

        NormalItems _ _ _ ->
            "loot"

        NormalItem id ->
            "loot/" ++ id

        UniqueItems _ ->
            "loot/unique"

        UniqueItem id ->
            "loot/unique/" ++ id

        Skills form ->
            "skill"

        Skill id ->
            "skill/" ++ id

        SkillVariant id ->
            "skill-variant/" ++ id

        Affixes ->
            "affix"

        Gems ->
            "gem"

        Passives ->
            "passive"

        Reagents ->
            "reagent"

        City name ->
            "city/" ++ name

        Ailments ->
            "ailment"

        Source type_ id ->
            "source/" ++ type_ ++ "/" ++ id

        Offline type_ id ->
            "offline/" ++ type_ ++ "/" ++ id

        Search _ ->
            "search"

        Table t ->
            "table/" ++ t

        BuildRevisions ->
            "build-revision"

        Langs ->
            "language"

        Changelog ->
            "changelog"

        Privacy ->
            "privacy"


toQuery : Route -> List B.QueryParameter
toQuery route =
    case route of
        Redirect next ->
            toQuery next

        WithOptions o next ->
            toQuery next

        Search query ->
            [ query |> Maybe.map (B.string "q") ] |> List.filterMap identity

        UniqueItems tags ->
            [ tags |> Maybe.map (B.string "keywords") ] |> List.filterMap identity

        NormalItems tier kws okws ->
            [ kws |> Maybe.map (B.string "keywords")
            , okws |> Maybe.map (B.string "optional_keywords")
            , tier |> Maybe.map (B.int "tier")
            ]
                |> List.filterMap identity

        Skills form ->
            [ form |> Maybe.map (B.string "form") ] |> List.filterMap identity

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
                WithOptions _ next ->
                    toAnalytics <| Just next

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


hrefOptions : Options -> Route -> Html.Attribute msg
hrefOptions o =
    toString >> (++) (optionsPath o) >> Html.Attributes.href


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


keywords : List String -> Maybe String
keywords kws =
    case kws of
        [] ->
            Nothing

        _ ->
            Just <| String.join "," kws


normalItems : Maybe Int -> List String -> List String -> Route
normalItems tier kws okws =
    NormalItems tier (keywords kws) (keywords okws)


toOptions : Route -> Options
toOptions route =
    case route of
        WithOptions o _ ->
            o

        _ ->
            emptyOptions


toMOptions : Maybe Route -> Options
toMOptions =
    Maybe.Extra.unwrap emptyOptions toOptions


mapOptions : (Options -> Options) -> Route -> Route
mapOptions fn route0 =
    let
        apply opts route =
            if opts == emptyOptions then
                route

            else
                WithOptions opts route
    in
    case route0 of
        WithOptions opts0 next ->
            apply (fn opts0) next

        _ ->
            apply (fn emptyOptions) route0


{-| Turn Options from a withOptions url into a <base> tag, defining the leading path.

I want every url to accept a set of possible options - language, Wolcen version,
feature switches. But I _don't_ want to have to pass those options through every
view to every possible href; an extra parameter literally everywhere would be messy.
The rarely-seen <base> solves this problem - it affects all links in my program,
without requiring that I parameterize this context throughout the rest of my program!

<https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base>

Technically this is only allowed in <head>, but it seems to work just fine in <body>.
If it stops working there, this approach is still possible with ports, which can
update <head> just fine - but this is easier to implement.

I have not seen this technique used in any other programs; I made it up myself.
It's unproven, so it might be an awful idea? Be careful about copying it!

-}
base : Options -> Html.Html msg
base o =
    Html.node "base" [ Html.Attributes.href <| optionsPath o ] []


optionsPath : Options -> String
optionsPath o =
    [ [ "" ]
    , o.lang |> Maybe.Extra.unwrap [] (\l -> [ "l", l ])
    , o.revision |> Maybe.Extra.unwrap [] (\v -> [ "v", v ])
    , o.features |> Maybe.Extra.unwrap [] (\f -> [ "f", f ])
    , [ "" ]
    ]
        |> List.concat
        |> String.join "/"
