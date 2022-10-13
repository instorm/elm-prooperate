port module ProOperate.Keypad exposing
    ( Event(..)
    , KeyCode
    , UsbStatus(..)
    , getDisplay
    , getKeyDownEventProcessor
    , keyDown
    , keyUp
    , observe
    , processKeyDown
    , setDisplay
    , updateDisplay
    , usb
    )

{-| -}

import Procedure exposing (Procedure)
import Procedure.Channel as Channel
import Tuple.Trio as Trio


{-| -}
type alias KeyCode =
    Int


{-| -}
type alias EventType =
    String


{-| -}
usb : EventType
usb =
    "usb"


{-| -}
keyUp : EventType
keyUp =
    "keyup"


{-| -}
keyDown : EventType
keyDown =
    "keydown"


{-| -}
type UsbStatus
    = KeypadConnected
    | KeypadDisconnection
    | SystemBusy


{-| -}
toUsbStatus : Int -> UsbStatus
toUsbStatus v =
    case v of
        0 ->
            KeypadDisconnection

        1 ->
            KeypadConnected

        _ ->
            SystemBusy


{-| -}
type Event
    = Usb UsbStatus
    | KeyUp KeyCode
    | KeyDown KeyCode


{-| -}
toEvent : ( String, Int ) -> Event
toEvent ( key, value ) =
    case key of
        "keydown" ->
            KeyDown value

        "keyup" ->
            KeyUp value

        _ ->
            Usb <| toUsbStatus value


{-| -}
port signalProcessKeyDown : Int -> Cmd msg


{-| -}
port signalKeypadEvent : () -> Cmd msg


{-| -}
port slotKeypadEvent : (( String, Int ) -> msg) -> Sub msg


{-| -}
port signalGetKeypadDisplay : () -> Cmd msg


{-| -}
port slotGetKeypadDisplay : (( String, String, Int ) -> msg) -> Sub msg


{-| -}
port signalSetKeypadDisplay : ( String, String ) -> Cmd msg


{-| -}
port slotSetKeypadDisplay : (Int -> msg) -> Sub msg


{-| -}
port signalKeypadConnected : () -> Cmd msg


{-| -}
port slotKeypadConnected : (Int -> msg) -> Sub msg


{-| -}
observe : List EventType -> Procedure e Event msg
observe eventList =
    Channel.open (\_ -> signalKeypadEvent ())
        |> Channel.connect slotKeypadEvent
        |> Channel.filter (\_ ev -> List.member (Tuple.first ev) eventList)
        |> Channel.accept
        |> Procedure.map toEvent


{-| -}
getUsbStatus : Procedure Never UsbStatus msg
getUsbStatus =
    Channel.open (\_ -> signalKeypadConnected ())
        |> Channel.connect slotKeypadConnected
        |> Channel.acceptOne
        |> Procedure.map toUsbStatus


{-| -}
getDisplay : Procedure Never ( String, String, Int ) msg
getDisplay =
    Channel.open (\_ -> signalGetKeypadDisplay ())
        |> Channel.connect slotGetKeypadDisplay
        |> Channel.acceptOne


{-| -}
setDisplay : ( String, String ) -> Procedure Never Int msg
setDisplay data =
    Channel.open (\_ -> signalSetKeypadDisplay data)
        |> Channel.connect slotSetKeypadDisplay
        |> Channel.acceptOne


{-| -}
updateDisplay :
    (String -> String)
    -> (String -> String)
    -> Procedure Never Int msg
updateDisplay f g =
    getDisplay
        |> Procedure.map (Trio.mapFirst f)
        |> Procedure.map (Trio.mapSecond g)
        |> Procedure.map (\a -> ( Trio.first a, Trio.second a ))
        |> Procedure.andThen setDisplay



-- Event Processor


{-| -}
swapLast : String -> String -> String
swapLast s n =
    removeLast s ++ n


{-| -}
shiftLastChar : Int -> String -> String
shiftLastChar direc s =
    let
        charas =
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        last =
            String.right 1 s

        maybeIndex =
            List.head <| String.indices last charas
    in
    case ( last, maybeIndex ) of
        ( "Z", _ ) ->
            swapLast s <|
                if direc > 0 then
                    "A"

                else
                    "Y"

        ( "9", _ ) ->
            swapLast s <|
                if direc > 0 then
                    "0"

                else
                    "8"

        ( "A", _ ) ->
            swapLast s <|
                if direc < 0 then
                    "Z"

                else
                    "B"

        ( "0", _ ) ->
            swapLast s <|
                if direc < 0 then
                    "9"

                else
                    "1"

        ( _, Just index ) ->
            swapLast s <| String.slice (index + direc) (index + direc + 1) charas

        ( _, Nothing ) ->
            s


{-| -}
removeLast : String -> String
removeLast s =
    String.left (String.length s - 1) s


{-| -}
append : String -> String -> String
append c s =
    if String.length s < 16 then
        s ++ c

    else
        swapLast s c


{-| -}
keycodeToString : Int -> String
keycodeToString =
    Char.fromCode >> String.fromChar


{-| -}
processKeyDown : KeyCode -> Procedure Never () msg
processKeyDown keycode =
    Procedure.do (signalProcessKeyDown keycode)


{-| -}
getKeyDownEventProcessor : KeyCode -> (String -> String)
getKeyDownEventProcessor keycode =
    case keycode of
        {- 00キー -}
        58 ->
            shiftLastChar -1

        {- クリアキー -}
        106 ->
            always ""

        {- 次へキー -}
        107 ->
            shiftLastChar 1

        {- 戻るキー -}
        109 ->
            removeLast

        {- F1 -}
        112 ->
            append "A"

        {- F2 -}
        113 ->
            append "H"

        {- F3 -}
        114 ->
            append "O"

        {- F4 -}
        115 ->
            append "V"

        {- DEFAULT -}
        _ ->
            append <| keycodeToString keycode
