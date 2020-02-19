module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Page.Affixes
import Page.Changelog
import Page.Gems
import Page.Home
import Page.NormalItem
import Page.NormalItems
import Page.Privacy
import Page.Skill
import Page.Skills
import Page.UniqueItem
import Page.UniqueItems
import Route exposing (Route)
import Set exposing (Set)
import Url exposing (Url)
import View.Affix



---- MODEL ----


type alias Model =
    Result String OkModel


type alias OkModel =
    { nav : Nav.Key
    , datamine : Datamine
    , changelog : String
    , route : Maybe Route

    -- TODO: this really belongs in a per-page model
    , expandedAffixClasses : Set String
    }


type alias Flags =
    { datamine : Datamine.Flag
    , changelog : String
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    case Datamine.decode flags.datamine of
        Err err ->
            ( Err err, Cmd.none )

        Ok datamine ->
            ( Ok
                { nav = nav
                , datamine = datamine
                , changelog = flags.changelog
                , route = Route.parse url
                , expandedAffixClasses = Set.empty
                }
            , Cmd.none
            )



---- UPDATE ----


type Msg
    = OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest
    | AffixMsg View.Affix.ItemMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg mmodel =
    case mmodel of
        Err err ->
            ( mmodel, Cmd.none )

        Ok model ->
            updateOk msg model
                |> Tuple.mapFirst Ok


updateOk : Msg -> OkModel -> ( OkModel, Cmd Msg )
updateOk msg model =
    case msg of
        OnUrlChange url ->
            ( { model | route = Route.parse url }, Cmd.none )

        OnUrlRequest (Browser.Internal url) ->
            ( model, url |> Url.toString |> Nav.pushUrl model.nav )

        OnUrlRequest (Browser.External url) ->
            ( model, Nav.load url )

        AffixMsg (View.Affix.Expand class) ->
            ( { model | expandedAffixClasses = model.expandedAffixClasses |> toggleSet class }, Cmd.none )


toggleSet : comparable -> Set comparable -> Set comparable
toggleSet k ks =
    if Set.member k ks then
        Set.remove k ks

    else
        Set.insert k ks



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "WolcenDB", body = viewBody model }


viewBody : Model -> List (Html Msg)
viewBody mmodel =
    case mmodel of
        Err err ->
            [ code [] [ text err ] ]

        Ok model ->
            case model.route of
                Nothing ->
                    viewNotFound

                Just route ->
                    case route of
                        Route.Home ->
                            Page.Home.view

                        Route.Weapons ->
                            Page.NormalItems.viewWeapons model.datamine

                        Route.Shields ->
                            Page.NormalItems.viewShields model.datamine

                        Route.Armors ->
                            Page.NormalItems.viewArmors model.datamine

                        Route.Accessories ->
                            Page.NormalItems.viewAccessories model.datamine

                        Route.Weapon name ->
                            Page.NormalItem.viewWeapon model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Shield name ->
                            Page.NormalItem.viewShield model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Armor name ->
                            Page.NormalItem.viewArmor model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Accessory name ->
                            Page.NormalItem.viewAccessory model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueWeapons ->
                            Page.UniqueItems.viewWeapons model.datamine

                        Route.UniqueShields ->
                            Page.UniqueItems.viewShields model.datamine

                        Route.UniqueArmors ->
                            Page.UniqueItems.viewArmors model.datamine

                        Route.UniqueAccessories ->
                            Page.UniqueItems.viewAccessories model.datamine

                        Route.UniqueWeapon name ->
                            Page.UniqueItem.viewWeapon model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueShield name ->
                            Page.UniqueItem.viewShield model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueArmor name ->
                            Page.UniqueItem.viewArmor model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueAccessory name ->
                            Page.UniqueItem.viewAccessory model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.Skills ->
                            Page.Skills.view model.datamine

                        Route.Skill s ->
                            Page.Skill.view model.datamine s
                                |> Maybe.withDefault viewNotFound

                        Route.Affixes ->
                            Page.Affixes.view model.datamine

                        Route.Gems ->
                            Page.Gems.view model.datamine

                        Route.Changelog ->
                            Page.Changelog.view model

                        Route.Privacy ->
                            Page.Privacy.view


viewNotFound =
    [ code [] [ text "404 not found" ], div [] [ a [ Route.href Route.Home ] [ text "Back to safety" ] ] ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
