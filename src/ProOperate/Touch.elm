port module ProOperate.Touch exposing (TouchResponse, observeOnce_pro2, observe_pro2)

{-| -}

import Json.Decode as Json
import Maybe exposing (Maybe)
import ProOperate exposing (Error(..))
import ProOperate.Config exposing (Config_pro2)
import Procedure exposing (Procedure)
import Procedure.Channel as Channel exposing (Channel)
import Result.Extra


{-| -}
port signalTouchResponseOnce_pro2 : Config_pro2 -> Cmd msg


{-| -}
port signalTouchResponseUntil_pro2 : Config_pro2 -> Cmd msg


{-| -}
port slotTouchResponse : (Json.Value -> msg) -> Sub msg


{-| -}
type alias TouchResponse =
    { category : Int
    , paramResult : Maybe Int
    , auth : Maybe String
    , idm : Maybe String
    , data : Maybe String
    }


jsonToTouchResponse : Json.Value -> Result Error TouchResponse
jsonToTouchResponse json =
    let
        decoder =
            Json.map5 TouchResponse
                (Json.field "category" Json.int)
                (Json.maybe (Json.field "paramResult" Json.int))
                (Json.maybe (Json.field "auth" Json.string))
                (Json.maybe (Json.field "idm" Json.string))
                (Json.maybe (Json.field "data" Json.string))
    in
    json
        |> Json.decodeValue decoder
        |> Result.mapError (Json.errorToString >> DecodeError)


{-| -}
observeOnce_pro2 : Config_pro2 -> Procedure Error TouchResponse msg
observeOnce_pro2 config =
    Channel.open (\_ -> signalTouchResponseOnce_pro2 config)
        |> Channel.connect slotTouchResponse
        |> Channel.acceptOne
        |> Procedure.map jsonToTouchResponse
        |> Procedure.map Result.Extra.toTask
        |> Procedure.andThen Procedure.fromTask


{-| -}
observe_pro2 : Config_pro2 -> Procedure Error TouchResponse msg
observe_pro2 config =
    Channel.open (\_ -> signalTouchResponseUntil_pro2 config)
        |> Channel.connect slotTouchResponse
        |> Channel.accept
        |> Procedure.map jsonToTouchResponse
        |> Procedure.map Result.Extra.toTask
        |> Procedure.andThen Procedure.fromTask
