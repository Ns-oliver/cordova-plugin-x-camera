var exec = require('cordova/exec');

/**
*	调用原生webview来加载url类课程、外部链接
*	param success: 成功回调	
*	param failed: 失败回调
*	param courseURL: url
*	param courseTitle:外部链接标题
*/
var Camera = {
    callNative: function (succcess,failed, service, args) {
        exec(succcess, failed, "CDVCamera", service, args);
    },
};

module.exports = Camera;
