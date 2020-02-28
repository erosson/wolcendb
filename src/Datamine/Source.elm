module Datamine.Source exposing (Source, SourceNode, SourceNodeChildren(..), children, decoder)

import Datamine.Util as Util
import Json.Decode as D
import Json.Decode.Pipeline as P
import Result.Extra


type alias Source =
    { file : String, node : SourceNode }


type alias SourceNode =
    { attrs : List ( String, String )
    , children : SourceNodeChildren
    , tag : String
    }


type SourceNodeChildren
    = SourceNodeChildren (List SourceNode)


children : SourceNodeChildren -> List SourceNode
children (SourceNodeChildren ns) =
    ns


decoder : String -> String -> D.Decoder Source
decoder file tag =
    D.map (Source file)
        (sourceNodeDecoder |> D.map (\n -> n tag))


{-| Intermediate data structure for decoding source nodes, as used in `/source/xxx` urls

Game files are originally in xml.
We convert that to json, and `Datamine` parses the json - Elm's much faster at parsing json than xml.
We convert the json back to xml-ish nodes for presentation.

Seems needlessly complex - but Elm xml parsing really was slow, and source excerpts are a pretty cool feature!

-}
type
    DecodingSourceNode
    -- Child nodes; most keys. Tag names are the json key, added afterward
    = DecodingSourceNode (List (String -> SourceNode))
      -- Attributes, the "$"
    | DecodingAttrs (List ( String, String ))
      -- a single <TAG /> has json {... TAG: [""] ...}, and decodes to this. Not sure what's going on here.
    | DecodingEmptyNode String


sourceNodeDecoder : D.Decoder (String -> SourceNode)
sourceNodeDecoder =
    D.map2 SourceNode
        (D.keyValuePairs D.string |> D.field "$" |> D.maybe |> D.map (Maybe.withDefault []))
        (D.keyValuePairs
            (D.lazy
                (\_ ->
                    D.oneOf
                        [ D.list sourceNodeDecoder |> D.map DecodingSourceNode
                        , Util.single D.string |> D.map DecodingEmptyNode

                        -- this should only run once, for the "$" key - attributes
                        , D.keyValuePairs D.string |> D.map DecodingAttrs
                        ]
                )
            )
            |> D.map
                (List.filter (\( k, v ) -> k /= "$")
                    >> List.map
                        (\( k, mv ) ->
                            case mv of
                                DecodingSourceNode nodes ->
                                    nodes |> List.map (\n -> n k) |> Ok

                                DecodingEmptyNode "" ->
                                    Ok []

                                _ ->
                                    Err "decodeSourceNode fail"
                        )
                    >> Result.Extra.combine
                    >> Result.map (List.concat >> SourceNodeChildren)
                )
            |> Util.resultDecoder
        )
