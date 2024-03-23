/* Utils */
function uuid() {
    var S4 = function () {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    return (S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4());
}

function subscribe(obj, f) {
    if ((ref$ = obj) != null) {
        ref$.subscribe(f);
    }
}

function send(obj, v) {
    if ((ref$ = obj) != null) {
        ref$.send(v);
    }
}

function mifareArray(xs) {
    var result = [];
    for (var i=xs.length; i--;) {
        a = xs[i];
        result.unshift({
            type: a.type_,
            readData: a.services
        });
    }
    return result;
}

function felicaArray(xs) {
    var result = [];
    for (var i=xs.length; i--;) {
        a = xs[i];
        result.unshift({
            systemCode: a.systemCode,
            useMasterIDm: a.useMasterIDm,
            service: a.services
        });
    }
    return result;
}

function elmConfigToJsConfig(config_) {
    var config = {
        successSound: config_.successSound,
        failSound: config_.failSound,
        successLamp: config_.successLamp,
        failLamp: config_.failLamp,
        waitLamp: config_.waitLamp,
        felica: felicaArray(config_.felicaList),
        mifare: mifareArray(config_.mifareList),
        onetime: true,
        typeB: config_.typeB,
        onEvent: undefined
    };
    return config;
}

/* IoT Core */
function SigV4Utils(){}

SigV4Utils.sign = function(key, msg) {
  var hash = CryptoJS.HmacSHA256(msg, key);
  return hash.toString(CryptoJS.enc.Hex);
};

SigV4Utils.sha256 = function(msg) {
  var hash = CryptoJS.SHA256(msg);
  return hash.toString(CryptoJS.enc.Hex);
};

SigV4Utils.getSignatureKey = function(key, dateStamp, regionName, serviceName) {
  var kDate = CryptoJS.HmacSHA256(dateStamp, 'AWS4' + key);
  var kRegion = CryptoJS.HmacSHA256(regionName, kDate);
  var kService = CryptoJS.HmacSHA256(serviceName, kRegion);
  var kSigning = CryptoJS.HmacSHA256('aws4_request', kService);
  return kSigning;
};

function createEndpoint(regionName, awsIotEndpoint, accessKey, secretKey) {
  var time = moment.utc();
  var dateStamp = time.format('YYYYMMDD');
  var amzdate = dateStamp + 'T' + time.format('HHmmss') + 'Z';
  var service = 'iotdevicegateway';
  var region = regionName;
  var secretKey = secretKey;
  var accessKey = accessKey;
  var algorithm = 'AWS4-HMAC-SHA256';
  var method = 'GET';
  var canonicalUri = '/mqtt';
  var host = awsIotEndpoint;

  var credentialScope = dateStamp + '/' + region + '/' + service + '/' + 'aws4_request';
  var canonicalQuerystring = 'X-Amz-Algorithm=AWS4-HMAC-SHA256';
  canonicalQuerystring += '&X-Amz-Credential=' + encodeURIComponent(accessKey + '/' + credentialScope);
  canonicalQuerystring += '&X-Amz-Date=' + amzdate;
  canonicalQuerystring += '&X-Amz-SignedHeaders=host';

  var canonicalHeaders = 'host:' + host + '\n';
  var payloadHash = SigV4Utils.sha256('');
  var canonicalRequest = method + '\n' + canonicalUri + '\n' + canonicalQuerystring + '\n' + canonicalHeaders + '\nhost\n' + payloadHash;

  var stringToSign = algorithm + '\n' +  amzdate + '\n' +  credentialScope + '\n' +  SigV4Utils.sha256(canonicalRequest);
  var signingKey = SigV4Utils.getSignatureKey(secretKey, dateStamp, region, service);
  var signature = SigV4Utils.sign(signingKey, stringToSign);

  canonicalQuerystring += '&X-Amz-Signature=' + signature;
  return 'wss://' + host + canonicalUri + '?' + canonicalQuerystring;
}

