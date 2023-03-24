module Page.Source exposing (view)

import Datamine exposing (Datamine)
import Datamine.City as City
import Datamine.Gem as Gem
import Datamine.GemFamily as GemFamily exposing (GemFamily)
import Datamine.NormalItem as NormalItem
import Datamine.Passive as Passive
import Datamine.Reagent as Reagent
import Datamine.Skill as Skill
import Datamine.Source exposing (Source, SourceNode, SourceNodeChildren(..))
import Datamine.UniqueItem as UniqueItem
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Lang exposing (Lang)
import Route exposing (Route)


view : Lang -> Datamine -> String -> String -> Maybe (List (Html msg))
view lang dm type_ id =
    getSource lang dm type_ id
        |> Maybe.map
            (\( label, sources, breadcrumb ) ->
                [ ol [ class "breadcrumb" ]
                    (a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ] :: breadcrumb)
                , h4 [] [ text label, text ": ", code [] [ text id ] ]
                , p [] [ text "This is the raw data we've exported from the Wolcen game files. It's not very pretty, but it might be useful if Wolcen and other WolcenDB pages don't yet have the information you're looking for, or if you're programming something." ]
                , ul [ class "list-group" ] <| List.map (viewSource >> li [ class "list-group-item" ]) sources
                ]
            )


getSource : Lang -> Datamine -> String -> String -> Maybe ( String, List Source, List (Html msg) )
getSource lang dm type_ id =
    case type_ of
        "skill" ->
            Dict.get (String.toLower id) dm.skillsByUid
                |> Maybe.map
                    (\s ->
                        let
                            label =
                                Skill.label lang s |> Maybe.withDefault "???"

                            ast =
                                Dict.get s.uid dm.skillASTsByName
                                    |> Maybe.map .source
                        in
                        ( label
                        , [ Just s.source, ast ] |> List.filterMap identity
                        , [ a [ class "breadcrumb-item active", Route.href <| Route.Skills <| Skill.apocForm s ] [ text "Skills" ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Skill id ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "skill-variant" ->
            Dict.get (String.toLower id) dm.skillVariantsByUid
                |> Maybe.map
                    (\( v, s ) ->
                        let
                            label =
                                Skill.label lang v |> Maybe.withDefault "???"

                            ast =
                                Dict.get (String.toLower id) dm.skillASTVariantsByUid
                                    |> Maybe.map .source
                        in
                        ( label
                        , [ Just v.source, ast ] |> List.filterMap identity
                        , [ a [ class "breadcrumb-item active", Route.href <| Route.Skills <| Skill.apocForm s ] [ text "Skill Variants" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "gem" ->
            Dict.get (String.toLower id) dm.gemsByName
                |> Maybe.map
                    (\gem ->
                        let
                            label =
                                Gem.label lang gem |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ Just gem.source
                          , Dict.get (String.toLower id) dm.gemFamiliesByGemId |> Maybe.map .source
                          ]
                            |> List.filterMap identity
                        , [ a [ class "breadcrumb-item active", Route.href Route.Gems ] [ text "Gems" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "reagent" ->
            Dict.get (String.toLower id) dm.reagentsByName
                |> Maybe.map
                    (\reagent ->
                        let
                            label =
                                Reagent.label lang reagent |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ reagent.source ]
                        , [ a [ class "breadcrumb-item active", Route.href Route.Reagents ] [ text "Reagents" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "normal-loot" ->
            Dict.get (String.toLower id) dm.lootByName
                |> Maybe.map
                    (\nitem ->
                        let
                            label =
                                NormalItem.label lang nitem |> Maybe.withDefault "???"
                        in
                        ( label
                        , NormalItem.source nitem :: List.filterMap (\a -> Dict.get a dm.nonmagicAffixesById |> Maybe.map .source) (NormalItem.implicitAffixes nitem)
                        , [ a [ class "breadcrumb-item active", Route.href <| Route.NormalItems Nothing Nothing Nothing ] [ text "Normal Loot" ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.NormalItem id ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "unique-loot" ->
            Dict.get (String.toLower id) dm.uniqueLootByName
                |> Maybe.map
                    (\uitem ->
                        let
                            label =
                                UniqueItem.label lang uitem |> Maybe.withDefault "???"
                        in
                        ( label
                        , UniqueItem.source uitem
                            :: List.filterMap (\a -> Dict.get a dm.nonmagicAffixesById |> Maybe.map .source)
                                (UniqueItem.implicitAffixes uitem ++ UniqueItem.defaultAffixes uitem)
                        , [ a [ class "breadcrumb-item active", Route.href <| Route.UniqueItems Nothing ] [ text "Unique Loot" ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.UniqueItem id ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "magic-affix" ->
            Dict.get (String.toLower id) dm.magicAffixesById
                |> Maybe.map
                    (\affix ->
                        ( "Magic Affix"
                        , affix.source :: (affix |> GemFamily.fromAffix dm |> List.map .source)
                        , [ a [ class "breadcrumb-item active", Route.href Route.Affixes ] [ text "Affixes" ]
                          , a [ class "breadcrumb-item active" ] [ text affix.affixId ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "nonmagic-affix" ->
            Dict.get (String.toLower id) dm.nonmagicAffixesById
                |> Maybe.map
                    (\affix ->
                        ( "Nonmagic Affix"
                        , [ affix.source ]
                        , [ a [ class "breadcrumb-item active", Route.href Route.Affixes ] [ text "Affixes" ]
                          , a [ class "breadcrumb-item active" ] [ text affix.affixId ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "passive" ->
            Dict.get (String.toLower id) dm.passiveTreeEntriesByName
                |> Maybe.map
                    (\( entry, passive, tree ) ->
                        let
                            label =
                                Passive.label lang passive |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ passive.source, entry.source ]
                        , [ a [ class "breadcrumb-item active", Route.href Route.Passives ] [ text "Passives" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "city-project" ->
            Dict.get (String.toLower id) dm.cityProjectsByName
                |> Maybe.map
                    (\proj ->
                        let
                            label =
                                City.label lang proj |> Maybe.withDefault "???"
                        in
                        ( label
                        , proj.source :: (City.projectRewards dm proj |> List.map (.reward >> .source))
                        , [ a [ class "breadcrumb-item active" ] [ text "City" ]
                          , a [ class "breadcrumb-item active" ] [ text "Projects" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "city-reward" ->
            Dict.get (String.toLower id) dm.cityRewardsByName
                |> Maybe.map
                    (\reward ->
                        let
                            label =
                                City.label lang reward |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ reward.source ]
                        , [ a [ class "breadcrumb-item active" ] [ text "City" ]
                          , a [ class "breadcrumb-item active" ] [ text "Rewards" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "ailment" ->
            Dict.get (String.toLower id) dm.ailmentsByName
                |> Maybe.map
                    (\ail ->
                        ( ail.name
                        , [ ail.source ]
                        , [ a [ class "breadcrumb-item active", Route.href Route.Ailments ] [ text "Ailments" ]
                          , a [ class "breadcrumb-item active" ] [ text ail.name ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        _ ->
            Nothing


viewSource : Source -> List (Html msg)
viewSource source =
    let
        file =
            String.replace ".json" ".xml" source.file
    in
    [ div []
        [ a [ target "_blank", href <| "https://github.com/erosson/wolcendb/blob/master/datamine/" ++ file ]
            [ text file ]
        ]
    , pre [] [ text <| viewSourceNode 0 source.node ]
    ]


viewSourceNode : Int -> SourceNode -> String
viewSourceNode indentN node =
    let
        (SourceNodeChildren childNodes) =
            node.children

        indent =
            String.repeat indentN " "

        openTag : String -> List ( String, String ) -> String
        openTag tag attrs0 =
            let
                attrs =
                    attrs0 |> List.map (\( k, v ) -> k ++ "=\"" ++ v ++ "\"")

                line =
                    String.join " " <| tag :: attrs
            in
            if String.length line <= 80 then
                line

            else
                (tag
                    :: List.map ((++) (indent ++ "    ")) attrs
                    |> String.join "\n"
                )
                    ++ "\n"
                    ++ indent

        ( open, children, close ) =
            if childNodes == [] then
                ( indent ++ "<" ++ openTag node.tag node.attrs ++ " />"
                , ""
                , ""
                )

            else
                ( indent ++ "<" ++ openTag node.tag node.attrs ++ ">"
                , "\n" ++ String.join "\n" (List.map (viewSourceNode (indentN + 2)) childNodes) ++ "\n" ++ indent
                , "</" ++ node.tag ++ ">"
                )
    in
    open ++ children ++ close
