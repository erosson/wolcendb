module Datamine.Cosmetic exposing (CCosmeticTransferTemplate, CCosmeticWeaponDescriptor, transferTemplateDecoder, weaponDescriptorDecoder)

import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as D
import Json.Decode.Pipeline as P


{-| where weapon icons come from
-}
type alias CCosmeticWeaponDescriptor =
    { name : String
    , hudPicture : String
    }


{-| where armor icons come from
-}
type alias CCosmeticTransferTemplate =
    { name : String
    , hudPicture : String
    }


transferTemplateDecoder : D.Decoder (Dict String CCosmeticTransferTemplate)
transferTemplateDecoder =
    D.map2 CCosmeticTransferTemplate
        (D.at [ "$", "name" ] D.string)
        (D.at [ "$", "hud_picture" ] D.string)
        |> D.maybe
        |> D.list
        |> D.map (List.filterMap identity)
        |> D.at
            [ "Game/Umbra/SkinParams/TransferTemplate/TransferTemplateBank.json"
            , "CCosmeticTransferTemplateBank"
            , "CCosmeticTransferTemplate"
            ]
        |> D.map (Dict.Extra.fromListBy (.name >> String.toLower))


weaponDescriptorDecoder : D.Decoder (Dict String CCosmeticWeaponDescriptor)
weaponDescriptorDecoder =
    D.map2 CCosmeticWeaponDescriptor
        (D.at [ "$", "name" ] D.string)
        (D.at [ "$", "hud_picture" ] D.string)
        |> D.list
        |> D.at
            [ "Game/Umbra/SkinParams/WeaponSkins/CosmeticWeaponDescriptorBankGameplay.json"
            , "CCosmeticWeaponDescriptorBank"
            , "CCosmeticWeaponDescriptor"
            ]
        |> D.map (Dict.Extra.fromListBy (.name >> String.toLower))
