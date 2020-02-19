module Page.Source exposing (view)

import Datamine exposing (Datamine, Source, SourceNode, SourceNodeChildren(..))
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Route exposing (Route)
import View.Nav


view : Datamine -> String -> String -> Maybe (List (Html msg))
view dm type_ id =
    getSource dm type_ id
        |> Maybe.map
            (\( label, sources, breadcrumb ) ->
                [ div [ class "container" ]
                    [ View.Nav.view
                    , ol [ class "breadcrumb" ]
                        (a [ class "breadcrumb-item active", Route.href Route.Home ] [ text "Home" ] :: breadcrumb)
                    , h4 [] [ text label, text ": ", code [] [ text id ] ]
                    , ul [ class "list-group" ] <| List.map (viewSource >> li [ class "list-group-item" ]) sources
                    ]
                ]
            )


getSource : Datamine -> String -> String -> Maybe ( String, List Source, List (Html msg) )
getSource dm type_ id =
    case type_ of
        "skill" ->
            Dict.get (String.toLower id) dm.skillsByUid
                |> Maybe.map
                    (\s ->
                        let
                            label =
                                Datamine.lang dm s.uiName |> Maybe.withDefault "???"

                            ast =
                                Dict.get s.uid dm.skillASTsByName
                                    |> Maybe.map .source
                        in
                        ( label
                        , [ Just s.source, ast ] |> List.filterMap identity
                        , [ a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skills" ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Skill id ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "skill-variant" ->
            Dict.get (String.toLower id) dm.skillVariantsByUid
                |> Maybe.map
                    (\s ->
                        let
                            label =
                                Datamine.lang dm s.uiName |> Maybe.withDefault "???"

                            ast =
                                Dict.get (String.toLower id) dm.skillASTVariantsByUid
                                    |> Maybe.map .source
                        in
                        ( label
                        , [ Just s.source, ast ] |> List.filterMap identity
                        , [ a [ class "breadcrumb-item active", Route.href Route.Skills ] [ text "Skill Variants" ]
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
                                Datamine.lang dm gem.uiName |> Maybe.withDefault "???"
                        in
                        ( label
                        , [ gem.source ]
                        , [ a [ class "breadcrumb-item active", Route.href Route.Gems ] [ text "Gems" ]
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
                            ( source, uiName, affixes ) =
                                case nitem of
                                    Datamine.NWeapon i ->
                                        ( i.source, i.uiName, i.implicitAffixes )

                                    Datamine.NShield i ->
                                        ( i.source, i.uiName, i.implicitAffixes )

                                    Datamine.NArmor i ->
                                        ( i.source, i.uiName, i.implicitAffixes )

                                    Datamine.NAccessory i ->
                                        ( i.source, i.uiName, i.implicitAffixes )

                            label =
                                Datamine.lang dm uiName |> Maybe.withDefault "???"
                        in
                        ( label
                        , source :: List.filterMap (\a -> Dict.get a dm.nonmagicAffixesById |> Maybe.map .source) affixes
                        , [ a [ class "breadcrumb-item active" ] [ text "Normal Loot" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "unique-loot" ->
            Dict.get (String.toLower id) dm.uniqueLootByName
                |> Maybe.map
                    (\uitem ->
                        let
                            ( source, uiName, affixes ) =
                                case uitem of
                                    Datamine.UWeapon i ->
                                        ( i.source, i.uiName, i.implicitAffixes ++ i.defaultAffixes )

                                    Datamine.UShield i ->
                                        ( i.source, i.uiName, i.implicitAffixes ++ i.defaultAffixes )

                                    Datamine.UArmor i ->
                                        ( i.source, i.uiName, i.implicitAffixes ++ i.defaultAffixes )

                                    Datamine.UAccessory i ->
                                        ( i.source, i.uiName, i.implicitAffixes ++ i.defaultAffixes )

                            label =
                                Datamine.lang dm uiName |> Maybe.withDefault "???"
                        in
                        ( label
                        , source :: List.filterMap (\a -> Dict.get a dm.nonmagicAffixesById |> Maybe.map .source) affixes
                        , [ a [ class "breadcrumb-item active" ] [ text "Unique Loot" ]
                          , a [ class "breadcrumb-item active" ] [ text label ]
                          , a [ class "breadcrumb-item active", Route.href <| Route.Source type_ id ] [ text "Source" ]
                          ]
                        )
                    )

        "magic-affix" ->
            Dict.get (String.toLower id) dm.magicAffixesById
                |> Maybe.map
                    (\affix ->
                        ( "Magic Affix"
                        , [ affix.source ]
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

        _ ->
            Nothing


viewSource : Source -> List (Html msg)
viewSource source =
    let
        file =
            String.replace ".json" ".xml" source.file
    in
    [ div []
        [ a [ target "_blank", href <| "https://gitlab.com/erosson/wolcendb/-/tree/master/datamine/" ++ file ]
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
