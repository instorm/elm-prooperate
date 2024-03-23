function setupPro3(app) {
    /* ProOperate.productType */
    subscribe(app.ports.signalProductType, function () {
        send(app.ports.slotProductType, ProOperate().productType);
    });

    /* ProOperate.terminalId */
    subscribe(app.ports.signalTerminalId, function () {
        send(app.ports.slotTerminalId, ProOperate().getTerminalID());
    });

    /* ProOperate.firmwareVersion */
    subscribe(app.ports.signalFirmwareVersion, function () {
        send(app.ports.slotFirmwareVersion, ProOperate().getFirmwareVersion());
    });

    /* ProOperate.contentsSetVersion */
    subscribe(app.ports.signalContentsSetVersion, function () {
        send(app.ports.slotContentsSetVersion, ProOperate().getContentsSetVersion());
    });
    function swapLast(s, n) {
        return (removeLast(s) + n);
    }

    function removeLast(s) {
        return s.slice(0, -1);
    }

    function append(c, s) {
        if (s.length < 16) {
            s = s + c;
        }
        else {
            s = swapLast(s, c);
        }
        return s;
    }
    function shiftLastChar(direc, s) {
        charas =
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        last = s.slice(-1);
        index = charas.indexOf(last);
        if (index >= 0) {
            switch (last) {
                case "Z":
                    if (direc > 0) {
                        s = swapLast(s, "A");
                    }
                    else {
                        s = swapLast(s, "Y");
                    }
                    break;
                case "9":
                    if (direc > 0) {
                        s = swapLast(s, "0");
                    }
                    else {
                        s = swapLast(s, "8");
                    }
                    break;
                case "A":
                    if (direc < 0) {
                        s = swapLast(s, "Z");
                    }
                    else {
                        s = swapLast(s, "B");
                    }
                    break;
                case "0":
                    if (direc < 0) {
                        s = swapLast(s, "9");
                    }
                    else {
                        s = swapLast(s, "1");
                    }
                    break;
                default:
                    s = swapLast(s, charas.slice(index+direc, index+direc+1));
                    break;
            }
        }
        return s;
    }
    /* ProOperate.Keypad.processKeyDown */
    subscribe(app.ports.signalProcessKeyDown, function (keycode) {
        if (keycode < 32) {
            return;
        }
        var display = ProOperate().getKeypadDisplay();
        var chr = String.fromCharCode(keycode);
        var s = display.firstLine;
        switch (keycode)  {
            /* 00キー */
            case 58:
                s = shiftLastChar(-1, s);
                break;
            /* クリアキー */ 
            case 106:
                s = "";
                break;
            /* 次へキー */
            case 107:
                s = shiftLastChar(1, s);
                break;
            /* 戻るキー */
            case 109:
                s = removeLast(s);
                break;

            /* F1 */
            case 112:
                s = append("A", s);
                break;

            /* F2 */
            case 113:
                s = append("H", s);
                break;

            /* F3 */
            case 114:
                s = append("O", s);
                berak;

            /* F4 */
            case 115:
                s = append("V", s);
                break;

            /* DEFAULT */
            default:
                s = append(chr, s); 
                break;
        }
        display.firstLine = s;
        ProOperate().setKeypadDisplay(display);
    });

    /* ProOperate.Keypad.getKeypadDisplay */
    subscribe(app.ports.signalGetKeypadDisplay, function () {
        var ret = ProOperate().getKeypadDisplay();
        var trio = undefined; 
        if (typeof ret == 'object') {
            trio = [ret.firstLine, ret.secondLine, 0];
        }
        else {
            trio = ["", "", ret];
        }
        send(app.ports.slotGetKeypadDisplay, trio);
    });

    /* ProOperate.Keypad.setKeypadDisplay */
    subscribe(app.ports.signalSetKeypadDisplay, function (a) {
        var display = {
            firstLine : a[0],
            secondLine : a[1]
        };
        send(app.ports.slotSetKeypadDisplay, ProOperate().setKeypadDisplay(display));
    });

    /* ProOperate.Keypad.getUsbStatus */
    subscribe(app.ports.signalKeypadConnected, function () {
        send(app.ports.slotKeypadConnected, ProOperate().getKeypadConnected());
    });

    /* ProOperate.Sound.play */
    subscribe(app.ports.signalPlaySound, function (path) {
        var playPromise = new Promise((resolve, reject) => {
            function event(eventCode) {
                playPromise.then((value) => {
                    send(app.ports.slotPlaySound, value);
                });
            };
            var param = {
                filePath : path,
                loop : false,
                onEvent : event
            };
            ret = ProOperate().playSound(param);
            if (ret < 0) { 
                send(app.ports.slotPlaySound, ret);
            } else {
                resolve(ret);
            }
        })
    });
    
    /* ProOperate.Keypad.observe */
    subscribe(app.ports.signalKeypadEvent, function () {
        function onEvent(eventCode) {
            send(app.ports.slotKeypadEvent, ["usb", eventCode])
        }
        function onKeyDown(eventCode) {
            send(app.ports.slotKeypadEvent, ["keydown", eventCode])
        }
        function onKeyUp(eventCode) {
            send(app.ports.slotKeypadEvent, ["keyup", eventCode])
        }
        var param = {
            onKeyDown : onKeyDown,
            onKeyUp : onKeyUp,
            onEvent : onEvent
        };
        ProOperate().startKeypadListen(param);
    });

    /* ProOperate.Touch.stopObserve */
    subscribe(app.ports.signalStopTouchResponse, function () {
        send(app.ports.slotStopTouchResponse, ProOperate().stopCommunication());
    });

    /* ProOperate.Touch.observeOnce */
    subscribe(app.ports.signalTouchResponseOnce_pro2, function (config_) {
        var config = elmConfigToJsConfig(config_);
        var touchPromise = new Promise((resolve, reject) => {
            config.onEvent = done;
            function done(eventCode, response) {
                if (eventCode == 1) {
                    resolve(response);
                }
                else {
                    touchPromise.then(value => {
                        send(app.ports.slotTouchResponse, value);
                    });
                }
            }
        });
        ProOperate().startCommunication(config);
    });

    /* ProOperate.Touch.observe */
    subscribe(app.ports.signalTouchResponseUntil_pro2, function (config_) {
        var config = elmConfigToJsConfig(config_);
        var touchPromise = new Promise((resolve) => {
            config.onEvent = done;
            config.onetime = false;
            function done(eventCode, response) {
                if (eventCode == 1) {
                    resolve(response);
                }
                else {
                    touchPromise.then(value => {
                        send(app.ports.slotTouchResponse, value);
                        touchPromise = new Promise((a) => { resolve = a; });
                    });
                }
            }
        });
        ProOperate().startCommunication(config);
    });
    /*
            WebSQL
    */
    var DBHandles = {};
    var DBH = null; 

    /* WebSQL.openDatabase */
    subscribe(app.ports.signalOpenDatabase, function (params) {
        var result = {};
        try {
            var db = openDatabase(params.name, params.version, params.desc, params.size);
            DBH = DBH || uuid(); 
            console.log("open:"+DBH);
            DBHandles[DBH] = db;
            result['ok'] = DBH;
        }
        catch (e) {
            result['err'] = e.message;
        }
        send(app.ports.slotOpenDatabase, result);
    });

    /* WebSQL.runSQL */
    subscribe(app.ports.signalRunSQL, function (query) {
        var dbh = query.dbh;
        var db = DBHandles[dbh];
        db.transaction(function (tx) {
            var result = {};
            function success(tx, rs) {
                var rows = [];
                for (var i=rs.rows.length; i--;) {
                    rows.unshift(rs.rows.item(i));
                }
                result['ok'] = dbh;
                result['rows'] = JSON.stringify(rows);
                send(app.ports.slotRunSQL, result);
            }
            function error(e) {
                result['err'] = JSON.stringify(e);
                send(app.ports.slotRunSQL, result);
            }
            tx.executeSql(query.sql, query.params, success, error);
        });
    });
}
