module View.Search exposing (Model, search)

import Browser.Navigation as Nav
import Datamine exposing (Datamine)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData)
import Search exposing (Index, SearchResult)


type alias Model m =
    { m
        | nav : Maybe Nav.Key
        , globalSearch : String
        , globalSearchResults : Result String (List SearchResult)
        , searchIndex : RemoteData String Index
        , progress : Dict String ( Int, Int )
    }


search : String -> Datamine -> Model m -> Model m
search q dm model =
    case model.searchIndex of
        RemoteData.Success searchIndex ->
            case Search.search dm q searchIndex of
                Err err ->
                    { model | globalSearch = q, globalSearchResults = Err err }

                Ok ( index, res ) ->
                    { model | globalSearch = q, globalSearchResults = Ok res, searchIndex = RemoteData.Success index }

        _ ->
            { model | globalSearch = q }
