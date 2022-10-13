port module ProOperate exposing
    ( Error(..)
    , contentsSetVersion
    , firmwareVersion
    , productType
    , terminalId
    )

{-
   ( Config_pro2
   , TouchResponse
   , contentsSetVersion
   , defaultConfig_pro2
   , firmwareVersion
   , observeTouch
   , productType
   , terminalId
   , untilTouch_pro2
   )
-}

import Procedure exposing (Procedure)
import Procedure.Channel as Channel exposing (Channel)


{-| -}
type Error
    = DecodeError String
    | ApiError_ ApiError


{-| -}
type alias ApiError =
    { sender : String
    , message : String
    }



{- ProOperate.productType function handling -}


port signalProductType : () -> Cmd msg


port slotProductType : (String -> msg) -> Sub msg



{- ProOperate.terminalId function handling -}


port signalTerminalId : () -> Cmd msg


port slotTerminalId : (String -> msg) -> Sub msg



{- ProOperate.firmwareVersion function handling -}


port signalFirmwareVersion : () -> Cmd msg


port slotFirmwareVersion : (String -> msg) -> Sub msg



{- ProOperate.contentsSetVersion function handling -}


port signalContentsSetVersion : () -> Cmd msg


port slotContentsSetVersion : (String -> msg) -> Sub msg


{-| -}
productType : Procedure e String msg
productType =
    Channel.open (\_ -> signalProductType ())
        |> Channel.connect slotProductType
        |> Channel.acceptOne


{-| -}
terminalId : Procedure e String msg
terminalId =
    Channel.open (\_ -> signalTerminalId ())
        |> Channel.connect slotTerminalId
        |> Channel.acceptOne


{-| -}
firmwareVersion : Procedure e String msg
firmwareVersion =
    Channel.open (\_ -> signalFirmwareVersion ())
        |> Channel.connect slotFirmwareVersion
        |> Channel.acceptOne


{-| -}
contentsSetVersion : Procedure e String msg
contentsSetVersion =
    Channel.open (\_ -> signalContentsSetVersion ())
        |> Channel.connect slotContentsSetVersion
        |> Channel.acceptOne
