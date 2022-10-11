module ProOperate.Card exposing
    ( Felica
    , FelicaService
    , Mifare
    , MifareService
    , felica
    , sapica
    , suica
    )

{-| -}


type alias Felica =
    { systemCode : String
    , useMasterIDm : Bool
    , services : List FelicaService
    }


{-| -}
type alias FelicaService =
    { serviceCode : String
    , offsetBlock : Int
    , block : Int
    }


{-| -}
type alias Mifare =
    { type_ : Int
    , services : List MifareService
    }


{-| -}
type alias MifareService =
    { address : String
    , keyType : Int
    , keyValue : String
    }


{-| -}
felica : Felica
felica =
    Felica "FFFF" True []


{-| -}
suica : Felica
suica =
    Felica "0003" True [ FelicaService "090F" 0 20 ]


{-| -}
sapica : Felica
sapica =
    Felica "865E" True [ FelicaService "090F" 0 20 ]
