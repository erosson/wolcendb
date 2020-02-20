module View.Item exposing (imgAccessory, imgArmor, imgGem, imgNormal, imgShield, imgUArmor, imgUnique, imgWeapon)

import Datamine exposing (Datamine)
import Datamine.NormalItem as NormalItem exposing (NormalItem(..))
import Datamine.UniqueItem as UniqueItem exposing (UniqueItem(..))
import Datamine.Util exposing (Range)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


imgAccessory : { item | hudPicture : String } -> H.Attribute msg
imgAccessory item =
    src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ item.hudPicture


imgGem : { item | hudPicture : String } -> H.Attribute msg
imgGem item =
    src <| "/static/datamine/Game/Libs/UI/u_resources/gems/" ++ item.hudPicture


imgArmor : Datamine -> { item | attachmentName : String } -> H.Attribute msg
imgArmor dm item =
    case Dict.get (String.toLower item.attachmentName) dm.cosmeticTransferTemplates of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ t.hudPicture


imgUArmor : Datamine -> { item | attachmentName : Maybe String } -> H.Attribute msg
imgUArmor dm item =
    case Dict.get (Maybe.withDefault "" item.attachmentName |> String.toLower) dm.cosmeticTransferTemplates of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ t.hudPicture


imgWeapon : Datamine -> { item | name : String, damage : Range (Maybe Int) } -> H.Attribute msg
imgWeapon dm item =
    imgShield dm item


imgShield : Datamine -> { item | name : String } -> H.Attribute msg
imgShield dm item =
    case Dict.get (String.toLower item.name) dm.cosmeticWeaponDescriptors of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/weapons/" ++ t.hudPicture


imgUnique : Datamine -> UniqueItem -> H.Attribute msg
imgUnique dm uitem =
    case uitem of
        UWeapon item ->
            imgWeapon dm item

        UShield item ->
            imgShield dm item

        UArmor item ->
            imgUArmor dm item

        UAccessory item ->
            imgAccessory item


imgNormal : Datamine -> NormalItem -> H.Attribute msg
imgNormal dm nitem =
    case nitem of
        NWeapon item ->
            imgWeapon dm item

        NShield item ->
            imgShield dm item

        NArmor item ->
            imgArmor dm item

        NAccessory item ->
            imgAccessory item
