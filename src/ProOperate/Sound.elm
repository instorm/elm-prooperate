port module ProOperate.Sound exposing (play)

{-| -}

import Procedure exposing (Procedure)
import Procedure.Channel as Channel


{-| -}
port signalPlaySound : String -> Cmd msg


{-| -}
port slotPlaySound : (Int -> msg) -> Sub msg


{-| -}
play : String -> Procedure Never Int msg
play filePath =
    Channel.open (\_ -> signalPlaySound filePath)
        |> Channel.connect slotPlaySound
        |> Channel.acceptOne
