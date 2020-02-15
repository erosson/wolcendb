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
import Page.Armors
import Page.Home
import Page.Shields
import Page.Skill
import Page.Skills
import Page.UniqueAccessories
import Page.UniqueArmors
import Page.UniqueShields
import Page.UniqueWeapons
import Page.Weapons
import Route exposing (Route)
import Url exposing (Url)



---- MODEL ----


type alias Model =
    Result String OkModel


type alias OkModel =
    { nav : Nav.Key
    , datamine : Datamine
    , route : Maybe Route
    }


type alias Flags =
    { datamine : Datamine.Flag
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
                , route = Route.parse url
                }
            , Cmd.none
            )



---- UPDATE ----


type Msg
    = OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest


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

                        Route.UniqueWeapons ->
                            Page.UniqueWeapons.view model.datamine

                        Route.UniqueShields ->
                            Page.UniqueShields.view model.datamine

                        Route.UniqueArmors ->
                            Page.UniqueArmors.view model.datamine

                        Route.UniqueAccessories ->
                            Page.UniqueAccessories.view model.datamine

                        Route.Skills ->
                            Page.Skills.view model.datamine

                        Route.Skill s ->
                            Page.Skill.view model.datamine s
                                |> Maybe.withDefault viewNotFound


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
