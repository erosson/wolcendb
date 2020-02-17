module View.Item exposing (imgAccessory, imgArmor, imgUArmor, imgWeapon)

import Datamine exposing (Datamine)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)


imgAccessory : { item | hudPicture : String } -> H.Attribute msg
imgAccessory item =
    src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ item.hudPicture


imgArmor : Datamine -> { item | attachmentName : String } -> H.Attribute msg
imgArmor dm item =
    case Dict.get item.attachmentName dm.cosmeticTransferTemplates of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ t.hudPicture


imgUArmor : Datamine -> { item | attachmentName : Maybe String } -> H.Attribute msg
imgUArmor dm item =
    case Dict.get (Maybe.withDefault "" item.attachmentName) dm.cosmeticTransferTemplates of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/armors/" ++ t.hudPicture


imgWeapon : Datamine -> { item | name : String } -> H.Attribute msg
imgWeapon dm item =
    case Dict.get item.name dm.cosmeticWeaponDescriptors of
        Nothing ->
            style "display" "none"

        Just t ->
            src <| "/static/datamine/Game/Libs/UI/u_resources/weapons/" ++ t.hudPicture
