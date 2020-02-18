module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Maybe.Extra
import Page.Accessories
import Page.Accessory
import Page.Affixes
import Page.Armor
import Page.Armors
import Page.Changelog
import Page.Home
import Page.Shield
import Page.Shields
import Page.Skill
import Page.Skills
import Page.UniqueAccessories
import Page.UniqueAccessory
import Page.UniqueArmor
import Page.UniqueArmors
import Page.UniqueShield
import Page.UniqueShields
import Page.UniqueWeapon
import Page.UniqueWeapons
import Page.Weapon
import Page.Weapons
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
                            Page.Weapons.view model.datamine

                        Route.Shields ->
                            Page.Shields.view model.datamine

                        Route.Armors ->
                            Page.Armors.view model.datamine

                        Route.Accessories ->
                            Page.Accessories.view model.datamine

                        Route.Weapon name ->
                            Page.Weapon.view model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Shield name ->
                            Page.Shield.view model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Armor name ->
                            Page.Armor.view model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.Accessory name ->
                            Page.Accessory.view model name
                                |> Maybe.map (List.map (H.map AffixMsg))
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueWeapons ->
                            Page.UniqueWeapons.view model.datamine

                        Route.UniqueShields ->
                            Page.UniqueShields.view model.datamine

                        Route.UniqueArmors ->
                            Page.UniqueArmors.view model.datamine

                        Route.UniqueAccessories ->
                            Page.UniqueAccessories.view model.datamine

                        Route.UniqueWeapon name ->
                            Page.UniqueWeapon.view model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueShield name ->
                            Page.UniqueShield.view model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueArmor name ->
                            Page.UniqueArmor.view model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.UniqueAccessory name ->
                            Page.UniqueAccessory.view model.datamine name
                                |> Maybe.withDefault viewNotFound

                        Route.Skills ->
                            Page.Skills.view model.datamine

                        Route.Skill s ->
                            Page.Skill.view model.datamine s
                                |> Maybe.withDefault viewNotFound

                        Route.Affixes ->
                            Page.Affixes.view model.datamine

                        Route.Changelog ->
                            Page.Changelog.view model


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
