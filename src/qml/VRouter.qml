pragma Singleton

import QtQuick


QtObject {
    property var routes : ({})
    property var windows: []

    function addWindow(window){
        console.log("addWindow")
        if(!window.transientParent){
            console.log("addWindow2")
            windows.push(window)
        }
        console.log("addWindow3")
    }

    function removeWindow(win) {
        console.log("removeWindow")
        if(!win.transientParent){
            console.log("removeWindow2")
            var index = windows.indexOf(win)
            if (index !== -1) {
                console.log("removeWindow3")
                windows.splice(index, 1)
                win.deleteLater()
                console.log("delete window")
            }
            console.log("removeWindow4")
        }
    }

    function exit(retCode){
        for(var i =0 ;i< windows.length; i++){
            var win = windows[i]
            win.deleteLater()
        }
        windows = []
        Qt.exit(retCode)
    }

    function navigate(route, argument={}, windowRegister = undefined, fingerprint = undefined){
        if(!routes.hasOwnProperty(route)){
            console.error("Not Found Route",route)
            return
        }

        // 2. 首先尝试按指纹查找窗口
        var targetWindow = undefined;
        if (fingerprint !== undefined) {
            for(var i = 0; i < windows.length; i++){
                var item = windows[i];
                console.log("check fingerprint", item._fingerprint)
                if(item._fingerprint === fingerprint){
                    targetWindow = item;
                    console.log("find sameple window ", fingerprint)
                    break;
                }
            }

            // 3. 如果找到了指纹匹配的窗口
            if (targetWindow) {
                // 激活并更新参数，然后函数结束
                targetWindow.argument = argument;
                targetWindow.show();
                targetWindow.raise();
                targetWindow.requestActivate();
                return;
            }
        }

        var windowComponent = Qt.createComponent(routes[route])
        if (windowComponent.status !== Component.Ready) {
            console.error(windowComponent.errorString())
            return
        }

        var properties = {}
        properties._route = route
        if(fingerprint){
            properties._fingerprint = fingerprint // 将指纹参数也传递给新窗口的属性
        }
        if(windowRegister){
            properties._windowRegister = windowRegister
        }
        properties.argument = argument

        var win = undefined
        for(var i = 0 ;i< windows.length; i++){
            var item = windows[i]
            if(route === item._route){
                win = item
                break
            }
        }

        if(win){
            var launchMode = win.launchMode
            if(launchMode === 1){
                win.argument = argument
                win.show()
                win.raise()
                win.requestActivate()
                return
            }else if(launchMode === 2){
                win.close()
            }
        }

        win = windowComponent.createObject(null,properties)
        if(windowRegister){
            windowRegister._to = win
        }
    }
}
