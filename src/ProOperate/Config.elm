module ProOperate.Config exposing (Config_pro2, defaultConfig_pro2)

{-| -}

import ProOperate.Card as Card exposing (Felica, Mifare)


{-| -}
type alias Config_pro2 =
    { successSound : String
    , failSound : String
    , successLamp : String
    , failLamp : String
    , waitLamp : String
    , felicaList : List Felica
    , mifareList : List Mifare
    , typeB : Bool
    }


{-| -}
defaultConfig_pro2 : Config_pro2
defaultConfig_pro2 =
    { successSound = "/pjf/sound/success.wav"
    , failSound = "/pjf/sound/fail.wav"
    , successLamp = "BB0N"
    , failLamp = "RR0N"
    , waitLamp = "BG1L"
    , felicaList = [ Card.suica, Card.felica ]
    , mifareList = []
    , typeB = False
    }
