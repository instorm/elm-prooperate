port module WebSQL exposing
    ( Error(..)
    , openDatabase
    , querySQL
    , runSQL
    )

{-| -}

import Json.Decode as Json exposing (Decoder)
import Maybe.Extra
import Procedure exposing (Procedure)
import Procedure.Channel as Channel
import Result.Extra
import Task exposing (Task)


{-| Error
-}
type Error
    = SQLError String
    | DecodeError String


{-| -}
type alias PortResult =
    { ok : Maybe String
    , err : Maybe String
    , rows : Maybe String
    }


{-| -}
type alias OpenParam =
    { name : String
    , version : String
    , desc : String
    , size : Int
    }


{-| -}
type alias QueryParam =
    { sql : String
    , params : List String
    , dbh : String
    }


port signalOpenDatabase : OpenParam -> Cmd msg


port slotOpenDatabase : (Json.Value -> msg) -> Sub msg


port signalRunSQL : QueryParam -> Cmd msg


port slotRunSQL : (Json.Value -> msg) -> Sub msg


{-| -}
jsonToProcedure : Json.Value -> Procedure Error PortResult msg
jsonToProcedure json =
    let
        decoder : Json.Decoder PortResult
        decoder =
            Json.map3 PortResult
                (Json.maybe (Json.field "ok" Json.string))
                (Json.maybe (Json.field "err" Json.string))
                (Json.maybe (Json.field "rows" Json.string))

        portResultToResult r =
            case r.ok of
                Just handle ->
                    Ok r

                Nothing ->
                    Err (SQLError <| Maybe.withDefault "no error" r.err)
    in
    json
        |> Json.decodeValue decoder
        |> Result.mapError (Json.errorToString >> DecodeError)
        |> Result.andThen portResultToResult
        |> Result.Extra.toTask
        |> Procedure.fromTask


{-| -}
openDatabase : String -> String -> String -> Int -> Procedure Error String msg
openDatabase name version desc size =
    Channel.open (\_ -> signalOpenDatabase <| OpenParam name version desc size)
        |> Channel.connect slotOpenDatabase
        |> Channel.acceptOne
        |> Procedure.andThen jsonToProcedure
        |> Procedure.map (.ok >> Maybe.withDefault "")


{-| -}
runSQL : String -> List String -> String -> Procedure Error String msg
runSQL sql param dbh =
    Channel.open (\_ -> signalRunSQL <| QueryParam sql param dbh)
        |> Channel.connect slotRunSQL
        |> Channel.acceptOne
        |> Procedure.andThen jsonToProcedure
        |> Procedure.map (.ok >> Maybe.withDefault "")


{-| -}
querySQL :
    Decoder a
    -> String
    -> List String
    -> String
    -> Procedure Error a msg
querySQL decoder sql param dbh =
    Channel.open (\_ -> signalRunSQL <| QueryParam sql param dbh)
        |> Channel.connect slotRunSQL
        |> Channel.acceptOne
        |> Procedure.andThen jsonToProcedure
        |> Procedure.map (.rows >> Maybe.withDefault "[]")
        |> Procedure.andThen (decode decoder)


{-| -}
decode : Json.Decoder a -> String -> Procedure Error a msg
decode decoder encoded =
    Json.decodeString decoder encoded
        |> Result.mapError (DecodeError << Json.errorToString)
        |> Result.Extra.toTask
        |> Procedure.fromTask
