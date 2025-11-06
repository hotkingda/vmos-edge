import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import FluentUI
import Utils

FluWindow {
    id: root
    width: (savedWindowWidth > 0 && savedWindowHeight > 0) ? savedWindowWidth : (initWidth + spaceWidth)
    height: (savedWindowWidth > 0 && savedWindowHeight > 0) ? savedWindowHeight : ((initWidth * aspectRatio) + spaceHeight)
    fitsAppBarWindows: true
    launchMode: FluWindowType.Standard
    useSystemAppBar: false
    autoCenter: true
    showClose: false
    showMinimize: false
    showMaximize: false
    minimumWidth: (direction === 0 ? 160 : 284) + spaceWidth
    minimumHeight: (direction === 0 ? 284 : 160) + spaceHeight -40
    title: root.argument.displayName

    // minimumHeight: (width - spaceHeight) / aspectRatio
    // maximumHeight: (width - spaceWidth) / aspectRatio

    property int initWidth: 160
    property string _fingerprint: ""
    property int direction: 0 // 0、竖屏 1、横屏
    property int lastDirection: 0
    property var client: null
    property bool isConnect: false
    property int remoteDirection: 0
    property real aspectRatio : (16.0 / 9.0)
    property int spaceWidth: 40
    property int spaceHeight: 80
    property bool isRestoringWindow: false  // 标记是否正在恢复窗口大小
    property int savedWindowWidth: 0  // 保存的窗口宽度（用于恢复时）
    property int savedWindowHeight: 0  // 保存的窗口高度（用于恢复时）
    // property bool isEventSyncMaster: groupControl.isEventSyncMaster(root.argument.padCode)
    property var videoList: []
    property var audioList: []
    property var videoFileListModel: []
    property string currentInjectFile: ""
    property real startTime: Utils.milliseconds()
    property var joystickStatus: []
    property var joystickState: ({ active: false, x: 0.0, y: 0.0, keys: [] })
    property real joystickUpdateInterval: 50 // ms
    property string deviceAddress: `${root.argument.hostIp}:${root.argument.adb}`

    function getFileSize(size) {
        const KB = 1024;
        const MB = KB * 1024;
        const GB = MB * 1024;

        if (size < KB) {
            return `${size} B`;
        } else if (size < MB) {
            return `${(size / KB).toFixed(2)} KB`;
        } else if (size < GB) {
            return `${(size / MB).toFixed(2)} MB`;
        } else {
            return `${(size / GB).toFixed(2)} GB`;
        }
    }

    function getVideoFile(fileName){
        for (var i = 0; i < videoFileListModel.length; i++) {
            if (videoFileListModel[i].downloadUrl.includes(fileName)) {
                return videoFileListModel[i]
            }
        }
        return null
    }

    function mapMouseToVideo(mouseX, mouseY, viewWidth, viewHeight, aspectRatio) {
        const isPortrait = (direction === 0 || direction === 180)
        const viewRatio = isPortrait ? (viewHeight / viewWidth) : (viewWidth / viewHeight)

        let contentRatio = aspectRatio
        let displayWidth, displayHeight, offsetX, offsetY

        // 根据方向确定裁剪方式
        if ((isPortrait && viewRatio > contentRatio) || (!isPortrait && viewRatio < contentRatio)) {
            // 黑边在上下
            displayWidth = viewWidth
            displayHeight = isPortrait
                    ? viewWidth * contentRatio
                    : viewWidth / contentRatio
            offsetX = 0
            offsetY = (viewHeight - displayHeight) / 2
        } else {
            // 黑边在左右
            displayHeight = viewHeight
            displayWidth = isPortrait
                    ? viewHeight / contentRatio
                    : viewHeight * contentRatio
            offsetX = (viewWidth - displayWidth) / 2
            offsetY = 0
        }

        // 映射坐标（去除黑边）
        let x = mouseX - offsetX
        let y = mouseY - offsetY

        // 方向不一致则旋转坐标
        if (direction !== remoteDirection) {
            if(remoteDirection == 0){
                const rotatedX = displayHeight - y
                const rotatedY = x
                x = rotatedX
                y = rotatedY

                const tmp = displayWidth
                displayWidth = displayHeight
                displayHeight = tmp
            }else{
                const rotatedX = y
                const rotatedY = displayWidth - x
                x = rotatedX
                y = rotatedY

                const tmp = displayWidth
                displayWidth = displayHeight
                displayHeight = tmp
            }
        }

        return {
            x: x,
            y: y,
            videoWidth: displayWidth,
            videoHeight: displayHeight
        }
    }

    function stop(){
        // client.stop()
        const deviceAddress = `${root.argument.hostIp}:${root.argument.adb}`
        deviceManager.disconnectDevice(deviceAddress)
        isConnect = false
        ReportHelper.reportLog("phone_play_stop", root.argument.padCode, {duration: Utils.milliseconds() - startTime})
    }

    function start(token){
        startTime = Utils.milliseconds()

        // const config = {
        //     padCode: root.argument.padCode,
        //     userId: Utils.getMachineId() + "_" + SettingsHelper.get("userId"),
        //     token: token,
        //     uuid: Utils.getMachineId(),
        //     level: AppConfig.videoLevel[SettingsHelper.get("videoLevel", AppConfig.defaultVideoLevel)],
        //     expireTime: 3600, // 云机token有效时间
        //     idleExpireTime: 1800 // 云机空闲超时时间
        // };

        // client = ArmcloudEngine.createPhoneClient();
        // client.setVideoSink(videoItem)
        // client.setSessionObserver(sessionObserver)
        // client.start(config)

        var quality = "hd"
        const videoLevel = SettingsHelper.get("videoLevel", AppConfig.defaultVideoLevel)
        if (videoLevel == 0) {
            quality = "uhd";
        }
        else if (videoLevel == 1) {
            quality = "hd";
        }
        else if (videoLevel == 2) {
            quality = "sd";
        }
        else if (videoLevel == 3) {
            quality = "smooth";
        }
        ReportHelper.reportLog("phone_play", root.argument.padCode, {label: "start", str1: "pro", str2: quality, str3: "multiWindow", str4: "local"})
    }

    ScrcpyController {
        id: scrcpyController

        onScreenInfo:
            (width, height) => {
                const rotation = height > width ? 0 : 1
                console.log("Screen changed: ", width, height, rotation)

                aspectRatio = rotation === 0 ? (height / width) : (width / height)
                console.log("云机实际比例", aspectRatio)
                remoteDirection = rotation === 0 ? 0 : 1

                // 如果正在恢复窗口大小，只更新方向和旋转，不改变窗口大小
                if(isRestoringWindow){
                    if(direction !== remoteDirection){
                        direction = remoteDirection
                        if(direction == 0){
                            videoItem.rotation = 0
                        }else{
                            videoItem.rotation = 270
                        }
                    }
                    return
                }

                if(direction !== remoteDirection){
                    direction = remoteDirection
                    console.log("云机方向", direction == 0 ? "竖屏" : "横屏")
                    if(direction == 0){
                        // 竖屏
                        const realWidth = root.width - spaceWidth
                        const realHeight = root.height - spaceHeight

                        root.width = realHeight + spaceWidth
                        root.height= (realHeight * aspectRatio) + spaceHeight
                    }else if(direction == 1){
                        // 横屏
                        const realWidth = root.width - spaceWidth
                        const realHeigth = root.height - spaceHeight

                        root.width= (realWidth * aspectRatio) + spaceWidth
                        root.height= realWidth + spaceHeight
                    }
                    if(direction == 0){
                        // 竖屏
                        videoItem.rotation = 0

                    }else{
                        // 横屏
                        videoItem.rotation = 270
                    }
                }
            }

        onConnectionEstablished: {

        }

        onConnectionLost: {
            dialog.title = qsTr("系统提示")
            dialog.message = qsTr("连接已断开，请稍后重连")
            dialog.negativeText = qsTr("退出")
            dialog.onNegativeClickListener = function(){
                root.close()
            }
            dialog.positiveText = qsTr("确定")
            dialog.onPositiveClickListener = function(){
                root.close()
                dialog.close()
            }
            dialog.open()
        }
    }

    Component.onCompleted: {
        console.log(root.argument.status, root.argument.cvmStatus)
        root.appBar.height = 40
        setHitTestVisible(layout_appbar)
        setHitTestVisible(btnExtraReturn)
        setHitTestVisible(btnHideTool)
        setHitTestVisible(textHostIp)
        console.log("云机初始比例", aspectRatio)

        // if(groupControl.isEventSync() && groupControl.isEventSyncMasterEmpty() && root.argument.checked){
        //     groupControl.setEventSyncMaster(root.argument.padCode)
        //     isEventSyncMaster = true
        // }

        initWidth = 0
        const windowModify = SettingsHelper.get("windowModify", 1)
        if(windowModify == 0){
            // 读取窗口上次记录
            const savedDirection = windowSizeHelper.get(root.argument.dbId, "direction", 0)
            initWidth = windowSizeHelper.get(root.argument.dbId, "w", 0)
            const savedHeight = windowSizeHelper.get(root.argument.dbId, "h", 0)
            const savedX = windowSizeHelper.get(root.argument.dbId, "x", -1)
            const savedY = windowSizeHelper.get(root.argument.dbId, "y", -1)
            
            // 如果读取到了有效的位置信息，恢复窗口位置
            if(savedX >= 0 && savedY >= 0){
                Qt.callLater(function() {
                    root.x = savedX
                    root.y = savedY
                })
            }
            
            // 如果读取到了大小信息，恢复窗口大小（根据保存时的方向）
            if(savedHeight > 0 && initWidth > 0){
                // 先设置方向，避免 onScreenInfo 触发时重新计算窗口大小
                direction = savedDirection
                // 标记正在恢复窗口，避免 onScreenInfo 改变窗口大小
                isRestoringWindow = true
                // 根据恢复的大小更新aspectRatio
                if(savedDirection == 0){
                    // 竖屏：realWidth = initWidth, realHeight = savedHeight
                    aspectRatio = savedHeight / initWidth
                    // 设置保存的窗口大小，绑定属性会使用这些值
                    savedWindowWidth = initWidth + spaceWidth
                    savedWindowHeight = savedHeight + spaceHeight
                }else{
                    // 横屏：realWidth = savedHeight, realHeight = initWidth
                    aspectRatio = initWidth / savedHeight
                    // 设置保存的窗口大小，绑定属性会使用这些值
                    savedWindowWidth = savedHeight + spaceWidth
                    savedWindowHeight = initWidth + spaceHeight
                }
                // 使用延迟确保窗口大小正确设置
                Qt.callLater(function() {
                    if(savedDirection == 0){
                        videoItem.rotation = 0
                    }else{
                        videoItem.rotation = 270
                    }
                    // 再次延迟确认窗口大小，然后清除保存的大小标志，恢复绑定属性
                    Qt.callLater(function() {
                        // 延迟恢复标志，确保窗口大小设置完成后再允许 onScreenInfo 改变窗口
                        Qt.callLater(function() {
                            // 清除保存的大小，允许后续使用绑定属性
                            savedWindowWidth = 0
                            savedWindowHeight = 0
                            isRestoringWindow = false
                        })
                    })
                })
            }
        }

        if(initWidth == 0){
            // 读取设置
            const windowSize = SettingsHelper.get("windowSize", 1)
            if(windowSize == 3){
                // 自定义
                initWidth = SettingsHelper.get("customWidth", 160)
            }else{
                initWidth = AppConfig.windowSize[windowSize].width
            }
        }

        console.log("屏幕比例", aspectRatio)
        // reqStsToken(root.argument.supplierType, root.argument.equipmentId)

        const deviceAddress = `${root.argument.hostIp}:${root.argument.adb}`
        var deviceObject = deviceManager.getDevice(deviceAddress)
        if (deviceObject) {
            // 将设备对象(deviceObject)和渲染组件(videoRenderer)都传给控制器
            scrcpyController.initialize(deviceObject, videoItem)
        }
    }

    Component.onDestruction: {
        // if(groupControl.isEventSync() && groupControl.isEventSyncMaster(root.argument.padCode)){
        //     groupControl.setEventSyncMaster("")
        // }

        stop()
    }

    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: [
            "All files(*)",
            "APK (*.apk)",
            "Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.heic *.tif *.tiff)",
            "Videos (*.mp4 *.avi *.mkv *.mov *.webm *.flv *.3gp)",
            "Audio (*.mp3 *.aac *.wav *.flac *.m4a *.ogg)",
            "Documents (*.pdf *.doc *.docx *.xls *.xlsx *.ppt *.pptx *.txt *.md)"
        ]
        property string actionType: "upload"  // "apk" 或 "upload"，用于区分操作类型
        
        onAccepted: {
            console.log("onAccepted", fileDialog.files, "actionType:", actionType)
            
            // 检查设备是否连接
            // if (!deviceManager.hasDevice(deviceAddress)) {
            //     if (actionType === "apk") {
            //         showError(qsTr("设备未连接，无法安装APK"))
            //     } else {
            //         showError(qsTr("设备未连接，无法导入文件"))
            //     }
            //     return
            // }
            
            fileDialog.files.forEach(
                        item => {
                            const localPath = FluTools.toLocalPath(item)
                            const lower = localPath.toLowerCase()
                            const fileName = localPath.split("/").pop()

                            if (actionType === "apk") {
                                // APK 安装按钮：只安装 APK 文件
                                if (lower.endsWith(".apk")) {
                                    if(scrcpyController){
                                        scrcpyController.sendInstallApkRequest(localPath)
                                    }

                                } else {
                                    console.warn("APK按钮选择了非APK文件，忽略:", localPath)
                                    showError(qsTr("只能选择APK文件"))
                                }
                            } else {
                                // 导入按钮：所有文件（包括APK）都上传到云机，不执行安装
                                if(scrcpyController){
                                    scrcpyController.sendPushFileRequest(localPath, "/sdcard/Download")
                                }
                            }
                        })
        }

        onRejected: {
            console.log("onRejected", fileDialog.files)
        }
    }


    GenericDialog {
        id:dialog
        title: qsTr("系统提示")
    }

    // SharePopup{
    //     id: sharePopup
    // }

    // SessionObserver{
    //     id: sessionObserver
    //     onWsStatusChanged:
    //         (status) => {
    //             console.log("WebSocket Status:", status)
    //         }
    //     onConnected: {
    //         isConnect = true
    //         console.log("Connected to session")
    //     }
    //     onDisconnected: {
    //         isConnect = false
    //         console.log("Disconnected from session")
    //     }
    //     onClosed: {
    //         isConnect = false
    //         console.log("Session closed")
    //     }
    //     onScreenChanged:
    //         (width, height,rotation) => {
    //             console.log("Screen changed: ", width, height, rotation)

    //             aspectRatio = rotation === 0 ? (height / width) : (width / height)
    //             console.log("云机实际比例", aspectRatio)
    //             remoteDirection = rotation === 0 ? 0 : 1

    //             if(direction !== remoteDirection){
    //                 direction = remoteDirection
    //                 console.log("云机方向", direction == 0 ? "竖屏" : "横屏")
    //                 if(direction == 0){
    //                     // 竖屏
    //                     const realWidth = root.width - spaceWidth
    //                     const realHeight = root.height - spaceHeight

    //                     root.width = realHeight + spaceWidth
    //                     root.height= (realHeight * aspectRatio) + spaceHeight
    //                 }else if(direction == 1){
    //                     // 横屏
    //                     const realWidth = root.width - spaceWidth
    //                     const realHeigth = root.height - spaceHeight

    //                     root.width= (realWidth * aspectRatio) + spaceWidth
    //                     root.height= realWidth + spaceHeight
    //                 }
    //                 if(direction == 0){
    //                     // 竖屏
    //                     videoItem.rotation = 0

    //                 }else{
    //                     // 横屏
    //                     videoItem.rotation = 270
    //                 }
    //             }
    //         }
    //     onClipboardMessageReceived:
    //         (text) => {
    //             console.log("Clipboard message: ", text)
    //             FluTools.clipText(text)
    //         }
    //     onFirstVideoFrameReceived: {
    //         isConnect = true
    //         console.log("First video frame received")
    //         ReportHelper.reportLog("phone_play", root.argument.padCode, {label: "success", duration: Utils.milliseconds() - startTime})
    //     }
    //     onNetworkQualityChanged:
    //         (rtt) => {
    //             // console.log("Network quality: RTT =", rtt)
    //             textDelay.text = rtt + "ms"
    //             if(rtt < 90){
    //                 imageDelay.source = "qrc:/res/pad/pad_delay_green.png"
    //                 textDelay.color = "#30BF8F"
    //             }else if(rtt < 150){
    //                 imageDelay.source = "qrc:/res/pad/pad_delay_yellow.png"
    //                 textDelay.color = "#FFAC00"
    //             }else{
    //                 imageDelay.source = "qrc:/res/pad/pad_delay_red.png"
    //                 textDelay.color = "#FF4D4D"

    //                 ReportHelper.reportLog("phone_delay_ge_150", root.argument.padCode)
    //             }
    //         }
    //     onIdleTimeout: {
    //         isConnect = false
    //         dialog.title = qsTr("系统提示")
    //         dialog.message = qsTr("长时间未操作云机，已自动托管到云端(云机内应用仍在运行)")
    //         dialog.negativeText = qsTr("退出")
    //         dialog.onNegativeClickListener = function(){
    //             root.close()
    //             ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "idleQuit"})
    //         }
    //         dialog.positiveText = qsTr("重连")
    //         dialog.onPositiveClickListener = function(){
    //             if(!isConnect){
    //                 reqStsToken(root.argument.supplierType, root.argument.equipmentId)
    //                 ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "idleReconnect"})
    //             }
    //             dialog.close()
    //         }
    //         dialog.open()

    //         ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "idlePopup", duration: Utils.milliseconds() - startTime})
    //     }
    //     onErrorOccurred:
    //         (error, msg) => {
    //             console.log("Error:", error, msg)
    //             dialog.title = qsTr("系统提示")
    //             dialog.message = msg
    //             dialog.buttonFlags = FluContentDialogType.PositiveButton
    //             dialog.positiveText = qsTr("确定")
    //             dialog.onPositiveClickListener = function(){
    //                 root.close()
    //                 dialog.close()
    //             }
    //             dialog.open()

    //             ReportHelper.reportLog("phone_play", root.argument.padCode, {label: "failed", str1: error, str2: msg, duration: Utils.milliseconds() - startTime})
    //         }
    //     onRoomErrorOccurred:
    //         (error) => {
    //             console.log("onRoomErrorOccurred", error)
    //             isConnect = false
    //             dialog.title = qsTr("系统提示")
    //             dialog.message = qsTr("长时间未操作云机，已自动托管到云端(云机内应用仍在运行)")
    //             dialog.negativeText = qsTr("退出")
    //             dialog.onNegativeClickListener = function(){
    //                 root.close()
    //                 ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "idleQuit"})
    //             }
    //             dialog.positiveText = qsTr("重连")
    //             dialog.onPositiveClickListener = function(){
    //                 if(!isConnect){
    //                     reqStsToken(root.argument.supplierType, root.argument.equipmentId)
    //                     ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "idleReconnect"})
    //                 }
    //                 dialog.close()
    //             }
    //             dialog.open()
    //             ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "expiredPopup", str1: error, duration: Utils.milliseconds() - startTime})
    //         }
    //     onCameraChanged:
    //         (isFront, isOpen)=> {
    //             console.log("Camera changed: Front =", isFront, " Open =", isOpen)
    //             const cameraId = SettingsHelper.get("cameraId", 0)
    //             const microphoneId = SettingsHelper.get("microphoneId", 0)
    //             if (isOpen) {
    //                 if(client){
    //                     client.startVideoCapture(cameraId)
    //                     client.publishStream(0)

    //                     client.startAudioCapture(microphoneId)
    //                     client.publishStream(1)
    //                 }
    //             }
    //             else {
    //                 if(client){
    //                     client.unPublishStream(0)
    //                     client.stopVideoCapture()

    //                     client.unPublishStream(1)
    //                     client.stopAudioCapture()
    //                 }
    //             }
    //         }

    //     onMicrophoneChanged:
    //         (isOpen) => {
    //             console.log("Microphone changed: Open =", isOpen)
    //             const microphoneId = SettingsHelper.get("microphoneId", 0)
    //             if (isOpen) {
    //                 if(client){
    //                     client.startAudioCapture(microphoneId)
    //                     client.publishStream(1)
    //                 }
    //             }
    //             else {
    //                 if(client){
    //                     client.unPublishStream(1)
    //                     client.stopAudioCapture()
    //                 }
    //             }
    //         }

    //     onInjectVideoStreamResult:
    //         (action, result, code, msg)=>{
    //             console.log("onInjectVideoStreamResult", action, result, code, msg)
    //             if(result){
    //                 if(action == "start"){
    //                     if(client){
    //                         client.injectVideoStats()
    //                     }
    //                 }else if(action == "stop"){
    //                     currentInjectFile = ""
    //                 }
    //             }else{
    //                 showError(msg)
    //             }
    //         }

    //     onInjectVideoStats:
    //         (path) => {
    //             console.log("onInjectVideoStats", path)
    //             currentInjectFile = path.split("/").pop()
    //         }

    //     onVideoCaptureResult:
    //         (code, msg) => {
    //             console.log("onVideoCaptureResult", code, msg)
    //         }

    //     onAudioCaptureResult:
    //         (code, msg) => {
    //             console.log("onAudioCaptureResult", code, msg)
    //         }

    //     onImeInputState:
    //         (isOpen, option)=>{
    //             console.log("ime state changed: isOpen =", isOpen, " option =", option)
    //             if(isOpen){
    //                 inputField.focus = true
    //             }else{
    //                 rootContainer.focus = true
    //             }
    //         }
    // }

    onWindowStateChanged:
        (windowState) => {
            if (windowState === Qt.WindowMaximized) {
                console.log("窗口最大化")
                btn_restore.visible = true
                btn_max.visible = false
                // 记录最后的状态
                lastDirection = direction
            } else if (windowState === Qt.WindowNoState) {
                console.log("窗口从最大化状态还原了")
                btn_restore.visible = false
                btn_max.visible = true
                // 恢复为最后的状态
                direction = lastDirection
                if(direction == 0){
                    // 竖屏
                    videoItem.rotation = 0
                }else{
                    // 横屏
                    videoItem.rotation = 270
                }
            }
        }

    onVisibleChanged: {
        // 当窗口变为可见且选择"保持不变"时，确保窗口居中显示
        if (visible) {
            const windowModify = SettingsHelper.get("windowModify", 1)
            if (windowModify == 1) {
                Qt.callLater(function() {
                    root.moveWindowToDesktopCenter()
                })
            }
        }
    }

    function findJoystickModel() {
        for (var i = 0; i < keymapperModel.rowCount(); ++i) {
            if (keymapperModel.get(i).type === 1) {
                return { model: keymapperModel.get(i), index: i };
            }
        }
        return null;
    }

    function calculateJoystickPosition(joystick) {
        let dx = 0;
        let dy = 0;
        const keys = joystick.model.key.split('|');

        const keysToProcess = joystickState.keys.slice(0, 2);

        if (keysToProcess.indexOf(keys[0]) > -1) dy -= 1; // W
        if (keysToProcess.indexOf(keys[1]) > -1) dy += 1; // S
        if (keysToProcess.indexOf(keys[2]) > -1) dx -= 1; // A
        if (keysToProcess.indexOf(keys[3]) > -1) dx += 1; // D

        const len = Math.sqrt(dx * dx + dy * dy);
        if (len > 0) {
            dx /= len;
            dy /= len;
        }

        const radiusX = (joystick.model.cx / 2) / maskRect.width;
        const radiusY = (joystick.model.cy / 2) / maskRect.height;

        return {
            x: joystick.model.px + dx * radiusX,
            y: joystick.model.py + dy * radiusY
        };
    }

    function updateJoystickState(joystick) {
        const hasActiveKeys = joystickState.keys.length > 0;

        if (hasActiveKeys && !joystickState.active) {
            // First key was pressed: Start the touch gesture (simplified version).
            joystickState.active = true;

            // 1. Send a `touchDown` at the joystick's CENTER.
            const centerX = joystick.model.px;
            const centerY = joystick.model.py;
            client.sendMultiEvent("AWSD", 0, centerX * width, centerY * height, width, height)
            console.log("joystick down", centerX * width, centerY * height)


            // 2. Immediately send a `touchMove` to the key's direction.
            const newPos = calculateJoystickPosition(joystick);
            joystickState.lastSentX = newPos.x;
            joystickState.lastSentY = newPos.y;
            Qt.callLater(
                        () => {
                            client.sendMultiEvent("AWSD", 2, newPos.x * width, newPos.y * height, width, height)
                            console.log("joystick move 1", newPos.x * width, newPos.y * width)
                        })


        } else if (hasActiveKeys && joystickState.active) {
            // Keys changed while gesture is active: Send a move event ONLY if position changes.
            const newPos = calculateJoystickPosition(joystick);
            if (newPos.x !== joystickState.lastSentX || newPos.y !== joystickState.lastSentY) {
                joystickState.lastSentX = newPos.x;
                joystickState.lastSentY = newPos.y;
                client.sendMultiEvent("AWSD", 2, newPos.x * width, newPos.y * height, width, height)
                console.log("joystick move 2", newPos.x * width, newPos.y * height)
            }

        } else if (!hasActiveKeys && joystickState.active) {
            // Last key was released: End the touch gesture.
            joystickState.active = false;
            client.sendMultiEvent("AWSD", 1, joystickState.lastSentX * width, joystickState.lastSentY * height, width, height)
            console.log("joystick up", joystickState.lastSentX * width, joystickState.lastSentY * height)
        }
    }

    function handleKeyPress(key, isPressed) {
        console.log("handleKeyPress", key, isPressed)

        const joystick = findJoystickModel();
        if (joystick) {
            const keys = joystick.model.key.split('|');
            const keyIndex = keys.indexOf(key);
            if (keyIndex !== -1) {
                // The pressed key belongs to the joystick. Handle it and exit.
                const keyWasPressed = joystickState.keys.indexOf(key) > -1;
                if (isPressed && !keyWasPressed) {
                    joystickState.keys.push(key);
                } else if (!isPressed && keyWasPressed) {
                    joystickState.keys.splice(joystickState.keys.indexOf(key), 1);
                }
                updateJoystickState(joystick);
                return; // IMPORTANT: Stop processing after handling the joystick key.
            }
        }

        const action = isPressed ? 0 : 1;
        for (var i = 0; i < keymapperModel.rowCount(); ++i) {
            var itemModel = keymapperModel.get(i);
            console.log("======================", itemModel.key, itemModel.type, key, action)
            if(itemModel.type === 2 && itemModel.key === key){
                client.sendMultiEvent(key, action, itemModel.px * width, itemModel.py * height, width, height)
                return;
            }
        }
    }

    DropArea{
        anchors.fill: parent

        onEntered: (drag) => {
                       console.log("有文件拖动")
                       drag.accepted = true
                   }

        onDropped: (drop) => {
                       if (drop.hasUrls) {
                           console.log("拖入文件路径:", drop.urls)
                           drop.urls.forEach(item => {
                                                 const localPath = FluTools.toLocalPath(item)
                                                 const lower = localPath.toLowerCase()

                                                 if (lower.endsWith(".apk")){
                                                     if (scrcpyController){
                                                         scrcpyController.sendInstallApkRequest(localPath)
                                                     }
                                                 } else {
                                                     scrcpyController.sendPushFileRequest(localPath, "/sdcard/Download")
                                                 }
                                             })
                       }
                   }
    }

    Item{
        id: rootContainer
        anchors.fill: parent
        // focus: true

        // Keys.onPressed:
        //     (event) => {
        //         if (event.isAutoRepeat) return;
        //         console.log("onPressed2")
        //         if(1 == SettingsHelper.get("keymap", 0)){
        //             // 按键映射
        //             console.log("onPressed3")
        //             handleKeyPress(event.text.toUpperCase(), true);
        //         }else{
        //             console.log("onPressed4")
        //             scrcpyController.sendKeyEvent(keyEventToVariant(event))
        //         }
        //         event.accepted = true;
        //     }
        // Keys.onReleased:
        //     (event) => {
        //         if (event.isAutoRepeat) return;
        //         if(1 == SettingsHelper.get("keymap", 0)){
        //             // 按键映射
        //             console.log("onReleased2")
        //             handleKeyPress(event.text.toUpperCase(), false);
        //         }else{
        //             console.log("onReleased3")
        //             scrcpyController.sendKeyEvent(keyEventToVariant(event))
        //         }
        //         event.accepted = true;
        //     }

        TextInput {
            id: inputField
            width: parent.width
            height: 50
            focus: true

            function eventToVariant(event, eventType) {
                return {
                    "type": eventType,
                    "key": event.key,
                    "text": event.text,
                    "modifiers ": event.modifiers
                };
            }

            onTextChanged: {
                console.log("onTextChanged:", inputField.text)
                if(!inputField.text){
                    // 排除空字符串
                    return
                }

                if (scrcpyController) {
                    scrcpyController.sendTextInput(inputField.text);
                    inputField.text = ""
                }
            }

            // 监听按键
            Keys.onPressed:
                (event) => {
                    console.log("Keys.onPressed:", event.text, event.text.length, event.key)
                    if (event.key >= Qt.Key_Space && event.key <= Qt.Key_ydiaeresis) {
                        // 可打印字符交给 onTextChanged 处理
                        return
                    }

                    const newKey = KeyMapper.getAndroidKeyCode(event.key)
                    if(newKey !== -1){
                        console.log("Keys.onPressed2")
                        scrcpyController.sendKeyEvent(eventToVariant(event, 6))
                    }
                    event.accepted = true;
                }

            // 监听释放事件
            Keys.onReleased:
                (event) => {
                    console.log("Keys.onReleased:", event.key)
                    if (event.key >= Qt.Key_Space && event.key <= Qt.Key_ydiaeresis) {
                        return
                    }
                    const newKey = KeyMapper.getAndroidKeyCode(event.key)
                    if(newKey !== -1){
                        scrcpyController.sendKeyEvent(eventToVariant(event, 7))
                    }
                }
        }

        RowLayout{
            anchors.fill: parent
            spacing: 0

            ColumnLayout{
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle{
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                    color: "#FF0B2F52"

                    RowLayout{
                        id: layout_title
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 10

                        // Image {
                        //     source: root.argument.androidVersionAvatar
                        //     Layout.preferredHeight: 20
                        //     Layout.preferredWidth: implicitWidth * (height / implicitHeight)
                        //     fillMode: Image.PreserveAspectFit
                        // }

                        Column{
                            visible: root.width >= 300
                            FluText{
                                text: root.argument.displayName
                                textColor: "#FF637199"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: 100
                            }
                            FluText{
                                id: textHostIp
                                text: root.argument.hostIp + ":" + root.argument.adb
                                textColor: "#FFB7BCCC"
                                font.pixelSize: 10

                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        FluTools.clipText(root.argument.hostIp + ":" + root.argument.adb)
                                        showSuccess(qsTr("复制成功"))
                                    }
                                }
                            }
                        }

                        // Rectangle{
                        //     width: 80
                        //     height: 30
                        //     border.width: 1
                        //     border.color: ThemeUI.primaryColor
                        //     radius: 15
                        //     // visible: groupControl.isEventSync() && isEventSyncMaster && root.argument.checked
                        //     color: "transparent"

                        //     RowLayout{
                        //         anchors.fill: parent
                        //         anchors.margins: 8

                        //         Rectangle{
                        //             width: 8
                        //             height: 8
                        //             radius: 4
                        //             color: ThemeUI.primaryColor
                        //         }

                        //         FluText{
                        //             text: qsTr("操作中")
                        //             font.pixelSize: 10
                        //             color: ThemeUI.primaryColor
                        //         }
                        //     }
                        // }

                        // Rectangle{
                        //     width: 80
                        //     height: 30
                        //     radius: 15
                        //     // visible: groupControl.isEventSync() && !isEventSyncMaster && root.argument.checked
                        //     color: "#f0f3ff"

                        //     RowLayout{
                        //         anchors.fill: parent
                        //         anchors.margins: 8

                        //         Rectangle{
                        //             width: 8
                        //             height: 8
                        //             radius: 4
                        //             color: ThemeUI.primaryColor
                        //         }

                        //         FluText{
                        //             text: qsTr("同步中")
                        //             font.pixelSize: 10
                        //             color: ThemeUI.primaryColor
                        //         }
                        //     }
                        // }
                    }

                    RowLayout{
                        id: layout_appbar
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        implicitWidth: childrenRect.width
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        ComboBox{
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 22
                            visible: false
                            editable: false
                            model: [qsTr("超清"), qsTr("高清"), qsTr("普通"), qsTr("流畅")]
                            currentIndex: SettingsHelper.get("videoLevel", AppConfig.defaultVideoLevel)
                            onActivated: {
                                SettingsHelper.save("videoLevel", currentIndex)
                                const videoLevel = AppConfig.videoLevel[currentIndex]
                                if(client){
                                    client.setVideoLevel(videoLevel.resolution, videoLevel.fps, videoLevel.bitrate)
                                }
                            }
                        }

                        Item{
                            implicitWidth: 24
                            implicitHeight: 24

                            Image {
                                source: root.stayTop ? "qrc:/res/pad/pad_top_selected.png" : "qrc:/res/pad/pad_top.png"
                            }

                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    root.stayTop = !root.stayTop
                                }
                            }
                        }

                        FluImageButton{
                            implicitWidth: 24
                            implicitHeight: 24
                            normalImage: "qrc:/res/pad/pad_min.png"
                            hoveredImage: "qrc:/res/pad/pad_min.png"
                            pushedImage: "qrc:/res/pad/pad_min.png"
                            onClicked: {
                                root.showMinimized()
                            }
                        }

                        FluImageButton{
                            id: btn_restore
                            implicitWidth: 24
                            implicitHeight: 24
                            visible: false
                            normalImage: "qrc:/res/pad/pad_restore.png"
                            hoveredImage: "qrc:/res/pad/pad_restore.png"
                            pushedImage: "qrc:/res/pad/pad_restore.png"
                            onClicked: {
                                btn_restore.visible = false
                                btn_max.visible = true
                                root.showNormal()
                            }
                        }
                        FluImageButton{
                            id: btn_max
                            implicitWidth: 24
                            implicitHeight: 24
                            normalImage: "qrc:/res/pad/pad_max.png"
                            hoveredImage: "qrc:/res/pad/pad_max.png"
                            pushedImage: "qrc:/res/pad/pad_max.png"
                            onClicked: {
                                btn_restore.visible = true
                                btn_max.visible = false
                                root.showMaximized()
                            }
                        }

                        FluImageButton{
                            implicitWidth: 24
                            implicitHeight: 24
                            normalImage: "qrc:/res/pad/pad_close.png"
                            hoveredImage: "qrc:/res/pad/pad_close.png"
                            pushedImage: "qrc:/res/pad/pad_close.png"
                            onClicked: {
                                ReportHelper.reportLog("phone_play", root.argument.padCode, {label: "close"})
                                // 保存窗口大小
                                const windowModify = SettingsHelper.get("windowModify", 1)
                                if(windowModify == 0 && (root.visibility != Window.Maximized)){
                                    // 记录上次
                                    const realWidth = root.width - spaceWidth
                                    const realHeigth = root.height - spaceHeight

                                    windowSizeHelper.save(root.argument.dbId, "x", root.x)
                                    windowSizeHelper.save(root.argument.dbId, "y", root.y)
                                    windowSizeHelper.save(root.argument.dbId, "w", direction == 0 ? realWidth : realHeigth)
                                    windowSizeHelper.save(root.argument.dbId, "h", direction == 0 ? realHeigth : realWidth)
                                    windowSizeHelper.save(root.argument.dbId, "direction", direction)  // 保存方向
                                }

                                root.close()
                            }
                        }

                        FluImageButton{
                            id: btnShowTool
                            implicitWidth: 24
                            implicitHeight: 24
                            visible: false
                            normalImage: "qrc:/res/pad/pad_show.png"
                            hoveredImage: "qrc:/res/pad/pad_show.png"
                            pushedImage: "qrc:/res/pad/pad_show.png"
                            onClicked: {
                                if(expandableToolBar.expanded){
                                    expandableToolBar.expanded = false
                                }
                                const realWidth = root.width - spaceWidth
                                spaceWidth = 40
                                root.width = realWidth + spaceWidth
                                layoutTool.visible = true
                                btnShowTool.visible = false
                            }
                        }
                    }
                }

                Rectangle{
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "black"

                    VideoRenderItem {
                        id: videoItem
                        anchors.fill: parent
                        property bool isPressed: false
                        property real lastMoveTime: 0

                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.AllButtons

                            function mouseEventToVariant(mouse, eventType, newX, newY) {
                                return {
                                    "type": eventType,
                                    "x": newX,
                                    "y": newY,
                                    "button": mouse.button,
                                    "buttons": mouse.buttons
                                };
                            }

                            onPressed:
                                (mouse)=> {
                                    // 如果按下的是鼠标滚轮（中键），发送HOME键
                                    if (mouse.button === Qt.MiddleButton) {
                                        scrcpyController.sendGoHome()
                                        return
                                    }
                                    
                                    // 如果按下的是鼠标右键，发送返回键
                                    if (mouse.button === Qt.RightButton) {
                                        scrcpyController.sendGoBack()
                                        return
                                    }
                                    
                                    videoItem.isPressed = true
                                    const result = mapMouseToVideo(mouse.x, mouse.y, parent.width, parent.height, aspectRatio)
                                    var mappedEvent = mouseEventToVariant(mouse, 2, result.x, result.y)
                                    scrcpyController.sendMouseEvent(mappedEvent, result.videoWidth, result.videoHeight)
                                }

                            onPositionChanged:
                                (mouse)=> {
                                    if(!videoItem.isPressed || !mouse.buttons){
                                        return
                                    }
                                    // const now = Utils.milliseconds()
                                    // if (now - videoItem.lastMoveTime >= 10) {
                                    const result = mapMouseToVideo(mouse.x, mouse.y, parent.width, parent.height, aspectRatio)
                                    var mappedEvent = mouseEventToVariant(mouse, 5, result.x, result.y)
                                    scrcpyController.sendMouseEvent(mappedEvent, result.videoWidth, result.videoHeight)
                                    // videoItem.lastMoveTime = now
                                    // }
                                }

                            onReleased:
                                (mouse)=> {
                                    const result = mapMouseToVideo(mouse.x, mouse.y, parent.width, parent.height, aspectRatio)
                                    var mappedEvent = mouseEventToVariant(mouse, 3, result.x, result.y)
                                    scrcpyController.sendMouseEvent(mappedEvent, result.videoWidth, result.videoHeight)
                                    videoItem.isPressed = false
                                }

                            onCanceled:
                                (mouse)=> {
                                    videoItem.isPressed = false
                                }
                        }

                        WheelHandler{
                            onWheel:
                                (event) => {
                                    const result = mapMouseToVideo(event.x, event.y, parent.width, parent.height, aspectRatio)
                                    var wheelEventData = {
                                        "x": result.x,
                                        "y": result.y,
                                        "angleDelta": event.angleDelta,
                                        "buttons": event.buttons,
                                        "modifiers": event.modifiers
                                    };
                                    scrcpyController.sendWheelEvent(wheelEventData, result.videoWidth, result.videoHeight);
                                }
                        }

                        Rectangle{
                            anchors.fill: parent
                            color: "white"
                            visible: videoItem.hasVideo ? false : true

                            Image {
                                anchors.centerIn: parent
                                source: ThemeUI.loadRes("login/logo-head.png")
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle{
                        id: maskRect
                        anchors.fill: parent
                        visible: false
                        color: "#A0000000"

                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                        }

                        Repeater{
                            id: keymapperRepeater
                            model: keymapperModel

                            delegate: Loader {
                                sourceComponent: model.type === 1 ? joystickComponent : buttonComponent
                                property var modelData: model
                                property real containerWidth: maskRect.width
                                property real containerHeight: maskRect.height

                                onLoaded: {
                                    if (model.type === 1) {
                                        item.radius = model.cx / 2;
                                    } else {
                                        item.width = model.cx;
                                        item.height = model.cy;
                                    }

                                    item.x = Qt.binding(() => (model.px * parent.width) - (item.width / 2))
                                    item.y = Qt.binding(() => (model.py * parent.height) - (item.height / 2))

                                    // Set type-specific properties and connect their signals.
                                    if (model.type === 1) { // Joystick
                                        item.radiusChanged.connect(() => {
                                                                       model.cx = item.radius * 2
                                                                       model.cy = item.radius * 2
                                                                   });
                                        var keys = model.key.split('|');
                                        if (keys.length === 4) {
                                            item.keyW.keyText = keys[0];
                                            item.keyS.keyText = keys[1];
                                            item.keyA.keyText = keys[2];
                                            item.keyD.keyText = keys[3];
                                        }
                                        function updateJoystickKey() {
                                            var newKey = [item.keyW.keyText, item.keyS.keyText, item.keyA.keyText, item.keyD.keyText].join('|')
                                            model.key = newKey
                                        }
                                        item.keyW.keyTextChanged.connect(updateJoystickKey);
                                        item.keyS.keyTextChanged.connect(updateJoystickKey);
                                        item.keyA.keyTextChanged.connect(updateJoystickKey);
                                        item.keyD.keyTextChanged.connect(updateJoystickKey);
                                    } else { // Button
                                        item.width = model.cx; item.height = model.cy;
                                        item.keyText = model.key;
                                        item.keyTextChanged.connect(() => {
                                                                        model.key = item.keyText
                                                                    });
                                    }
                                    item.deleteRequested.connect(() => {
                                                                     keymapperModel.deleteItem(model.key)
                                                                 });
                                }
                            }
                        }

                        // Component { id: buttonComponent; KeyMappingButton {} }
                        // Component { id: joystickComponent; JoystickMapping {} }
                    }
                }

                Rectangle{
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                    color: "#FF0B2F52"

                    RowLayout{
                        anchors.fill: parent

                        Item{
                            Layout.fillWidth: true
                        }

                        FluImageButton{
                            implicitWidth: 32
                            implicitHeight: 32
                            normalImage: "qrc:/res/pad/pad_back.png"
                            hoveredImage: "qrc:/res/pad/pad_back.png"
                            pushedImage: "qrc:/res/pad/pad_back.png"
                            onClicked: {
                                scrcpyController.sendGoBack()
                            }
                        }
                        Item{
                            Layout.fillWidth: true
                        }
                        FluImageButton{
                            implicitWidth: 32
                            implicitHeight: 32
                            normalImage: "qrc:/res/pad/pad_home.png"
                            hoveredImage: "qrc:/res/pad/pad_home.png"
                            pushedImage: "qrc:/res/pad/pad_home.png"
                            onClicked: {
                                scrcpyController.sendGoHome()
                            }
                        }
                        Item{
                            Layout.fillWidth: true
                        }
                        FluImageButton{
                            implicitWidth: 32
                            implicitHeight: 32
                            normalImage: "qrc:/res/pad/pad_task.png"
                            hoveredImage: "qrc:/res/pad/pad_task.png"
                            pushedImage: "qrc:/res/pad/pad_task.png"
                            onClicked: {
                                scrcpyController.sendAppSwitch()
                            }
                        }
                        Item{
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Rectangle{
                id: layoutTool
                Layout.preferredWidth: root.spaceWidth
                Layout.fillHeight: true
                color: "#FF0B2F52"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item{
                        id: btnHideTool
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Image{
                            anchors.centerIn: parent
                            source: "qrc:/res/pad/pad_hide.png"
                        }

                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                const realWidth = root.width - root.spaceWidth
                                root.spaceWidth = 0
                                root.width = realWidth + root.spaceWidth
                                layoutTool.visible = false
                                btnShowTool.visible = true
                            }
                        }
                    }

                    // Item{
                    //     Layout.preferredWidth: 40
                    //     Layout.preferredHeight: 50
                    //     ColumnLayout{
                    //         anchors.fill: parent
                    //         spacing: 0
                    //         Image {
                    //             id: imageDelay
                    //             source: "qrc:/res/pad/pad_delay_green.png"
                    //             Layout.alignment: Qt.AlignHCenter
                    //         }
                    //         Text {
                    //             id: textDelay
                    //             text: "0ms"
                    //             color: "#30BF8F"
                    //             font.pixelSize: 10
                    //             Layout.maximumWidth: 40
                    //             wrapMode: Text.WordWrap
                    //             horizontalAlignment: Text.AlignHCenter
                    //             Layout.alignment: Qt.AlignHCenter
                    //         }
                    //         Item{
                    //             Layout.fillHeight: true
                    //         }
                    //     }
                    // }

                    ExpandableToolBar {
                        id: expandableToolBar
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        onExpandedChanged: {
                            const realWidth = root.width - root.spaceWidth
                            root.spaceWidth = expandableToolBar.expanded ? 80 : 40
                            layoutTool.Layout.preferredWidth = root.spaceWidth
                            root.width = realWidth + root.spaceWidth
                        }

                        onToolClicked:
                            (modelData) => {
                                console.log("点击了按钮", modelData.name)
                                if(modelData.name === "apk"){
                                    fileDialog.title = qsTr("选择安装文件")
                                    fileDialog.nameFilters = ["APK (*.apk)"]
                                    fileDialog.actionType = "apk"  // 标记为 APK 安装操作
                                    fileDialog.folder = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                    fileDialog.open()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "apk"})
                                }else if(modelData.name === "upload"){
                                    fileDialog.title = qsTr("选择上传文件")
                                    fileDialog.nameFilters = [
                                        "All files(*)",
                                        "APK (*.apk)",
                                        "Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.heic *.tif *.tiff)",
                                        "Videos (*.mp4 *.avi *.mkv *.mov *.webm *.flv *.3gp)",
                                        "Audio (*.mp3 *.aac *.wav *.flac *.m4a *.ogg)",
                                        "Documents (*.pdf *.doc *.docx *.xls *.xlsx *.ppt *.pptx *.txt *.md)"
                                    ]
                                    fileDialog.actionType = "upload"  // 标记为文件上传操作
                                    fileDialog.folder = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                    fileDialog.open()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "upload"})
                                }else if(modelData.name === "volume_up"){
                                    // client.volumeUp()
                                    scrcpyController.sendVolumeUp()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "volUp"})
                                }else if(modelData.name === "volume_down"){
                                    // client.volumeDown()
                                    scrcpyController.sendVolumeDown()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "volDown"})
                                }else if(modelData.name === "rotation"){
                                    direction += 1
                                    direction %= 2
                                    console.log("云机方向", remoteDirection == 0 ? "竖屏" : "横屏")
                                    console.log("本地方向", direction == 0 ? "竖屏" : "横屏")
                                    console.log("是否最大化", root.visibility, Window.Maximized)
                                    if(root.visibility == Window.Maximized){
                                        // 最大化窗口大小不变
                                    }else{
                                        if(direction == 0){
                                            // 竖屏
                                            const realWidth = root.width - spaceWidth
                                            const realHeight = root.height - spaceHeight

                                            root.width = realHeight + spaceWidth
                                            root.height= (realHeight * aspectRatio) + spaceHeight
                                        }else if(direction == 1){
                                            // 横屏
                                            const realWidth = root.width - spaceWidth
                                            const realHeight = root.height - spaceHeight

                                            root.width= (realWidth * aspectRatio) + spaceWidth
                                            root.height= realWidth + spaceHeight
                                        }
                                    }
                                    if(direction == 0){
                                        // 竖屏
                                        videoItem.rotation = 0
                                    }else{
                                        // 横屏
                                        videoItem.rotation = 270
                                    }
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "rotation"})
                                }else if(modelData.name == "live"){
                                    const realWidth = root.width - spaceWidth
                                    spaceWidth = 240
                                    root.width = realWidth + spaceWidth
                                    layoutTool.visible = false
                                    layoutExtra.visible = true
                                    stackLayoutExtra.currentIndex = 0
                                    videoList = ArmcloudEngine.getVideoDeviceList()
                                    audioList = ArmcloudEngine.getAudioDeviceList()

                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "live"})
                                }else if(modelData.name === "reboot"){
                                    dialog.title = qsTr("操作确认")
                                    dialog.message = qsTr("确定要重启云机？")
                                    dialog.negativeText = qsTr("取消")
                                    dialog.onNegativeClickListener = function(){
                                        dialog.close()
                                    }
                                    dialog.positiveText = qsTr("确定")
                                    dialog.onPositiveClickListener = function(){
                                        const padName = root.argument.name || root.argument.displayName
                                        reqRebootDevice(root.argument.hostIp, [padName])
                                        dialog.close()
                                    }
                                    dialog.open()
                                }else if(modelData.name === "onekey"){

                                    dialog.title = qsTr("操作确认")
                                    dialog.message = qsTr("一键新机将清除云手机上的所有数据，云手机参数会重新生成，请谨慎操作！")
                                    dialog.negativeText = qsTr("取消")
                                    dialog.onNegativeClickListener = function(){
                                        dialog.close()
                                    }
                                    dialog.positiveText = qsTr("确定")
                                    dialog.onPositiveClickListener = function(){
                                        const padName = root.argument.name || root.argument.displayName
                                        reqOneKeyNewDevice(root.argument.hostIp, [padName])
                                        dialog.close()
                                        FluRouter.removeWindow(root)
                                    }
                                    dialog.open()
                                }else if(modelData.name === "change_machine"){

                                    dialog.title = qsTr("操作确认")
                                    dialog.message = qsTr("当前云机换机后，将会清空云机全部数据，无法恢复，确定进行换机？")
                                    dialog.buttonFlags = FluContentDialogType.PositiveButton | FluContentDialogType.NegativeButton
                                    dialog.negativeText = qsTr("取消")
                                    dialog.positiveText = qsTr("确定")
                                    dialog.onPositiveClickListener = function(){
                                        FluEventBus.post("reqBatchExchange", {equipmentId: root.argument.equipmentId})
                                        dialog.close()
                                        FluRouter.removeWindow(root)
                                    }
                                    dialog.open()
                                    // ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "reset"})
                                }else if(modelData.name === "reset"){

                                    dialog.title = qsTr("操作确认")
                                    dialog.message = qsTr("确定要关闭云手机吗？")
                                    dialog.buttonFlags = FluContentDialogType.PositiveButton | FluContentDialogType.NegativeButton
                                    dialog.negativeText = qsTr("取消")
                                    dialog.positiveText = qsTr("确定")
                                    dialog.onPositiveClickListener = function(){
                                        const padName = root.argument.name || root.argument.displayName
                                        reqStopDevice(root.argument.hostIp, [padName])
                                        dialog.close()
                                        FluRouter.removeWindow(root)
                                    }
                                    dialog.open()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "stop"})
                                }else if(modelData.name === "clipboard"){
                                    FluRouter.navigate("/clipboard", {control: client})
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "clipboard"})
                                }else if(modelData.name === "share"){
                                    sharePopup.padInfo = root.argument
                                    sharePopup.open()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "share"})
                                }else if(modelData.name === "screenshot_remote"){
                                    if(scrcpyController){
                                        scrcpyController.localScreenshot()
                                    }
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "screenshot_remote"})
                                }else if(modelData.name === "screenshot_local"){
                                    if(scrcpyController){
                                        scrcpyController.localScreenshot()
                                    }
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "screenshot_local"})
                                }else if(modelData.name === "screenshot_dir"){
                                    // 截图目录改为使用 vmosedge 目录
                                    const downloadPath = StandardPaths.writableLocation(StandardPaths.PicturesLocation) + "/vmosedge"
                                    Qt.openUrlExternally(FluTools.toLocalPath(downloadPath))
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "screenshot_dir"})
                                }else if(modelData.name === "keymap"){
                                    const realWidth = root.width - spaceWidth
                                    spaceWidth = 240
                                    root.width = realWidth + spaceWidth
                                    layoutTool.visible = false
                                    layoutExtra.visible = true
                                    stackLayoutExtra.currentIndex = 2
                                    maskRect.visible = true
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "keymap"})
                                }else if(modelData.name === "keyboard"){

                                }else if(modelData.name === "adb"){
                                    const realWidth = root.width - spaceWidth
                                    spaceWidth = 240
                                    root.width = realWidth + spaceWidth
                                    layoutTool.visible = false
                                    layoutExtra.visible = true
                                    stackLayoutExtra.currentIndex = 1
                                    // 查询ADB信息
                                    reqCheckADB(root.argument.padCode)
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "adb"})
                                }else if(modelData.name === "blow"){
                                    client.enableBlow(true)
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "blow"})
                                }else if(modelData.name === "shake"){
                                    client.shake()
                                    ReportHelper.reportLog("phone_play_action", root.argument.padCode, {label: "shake"})
                                }else if(modelData.name === "more"){

                                }
                            }
                    }
                }
            }

            Rectangle{
                id: layoutExtra
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: "#FF0B2F52"
                visible: false

                ColumnLayout{
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 1

                    RowLayout{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        Item{
                            id: btnExtraReturn
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 40

                            RowLayout{
                                anchors.fill: parent

                                Image{
                                    source: "qrc:/res/pad/btn_hide_normal.png"
                                }

                                FluText{
                                    text: qsTr("返回")
                                    color: "white"
                                }

                                Item{
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea{
                                anchors.fill: parent

                                onClicked: {
                                    const realWidth = root.width - spaceWidth
                                    spaceWidth = 40
                                    root.width = realWidth + spaceWidth
                                    layoutTool.visible = true
                                    layoutExtra.visible = false
                                    maskRect.visible = false
                                }
                            }
                        }

                        Item{
                            Layout.fillWidth: true
                        }
                    }

                    StackLayout{
                        id: stackLayoutExtra
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: 0

                        // 直播
                        Item{

                            ColumnLayout{
                                anchors.fill: parent
                                anchors.bottomMargin: 10
                                spacing: 20

                                TabListView{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    color: "#f5f6fa"
                                    radius: 4
                                    model: [qsTr("摄像头推流"), qsTr("无人直播推流")]
                                    onMenuSelected:
                                        (index)=> {
                                            stackLayoutVideo.currentIndex = index
                                            if(index == 0){

                                            }else if(index == 1){
                                                reqVideoFileList()

                                                if(client){
                                                    client.injectVideoStats()
                                                }
                                            }
                                        }
                                }

                                StackLayout{
                                    id: stackLayoutVideo
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    ColumnLayout{

                                        RowLayout{
                                            Layout.preferredHeight: 30
                                            Layout.fillWidth: true

                                            Image {
                                                source: "qrc:/res/pad/btn_live_camera1.png"
                                            }
                                            FluText{
                                                text: qsTr("摄像头")
                                                color: "white"
                                            }

                                            Item{
                                                Layout.fillWidth: true
                                            }

                                            FluToggleSwitch{
                                                enabled: videoList.length > 0
                                                visible: false
                                                onClicked: {
                                                    if(checked){
                                                        client.startVideoCapture(videoComboBox.currentIndex)
                                                        client.publishStream(0)
                                                    }else{
                                                        client.stopVideoCapture()
                                                        client.unPublishStream(0)
                                                    }
                                                }
                                            }
                                        }
                                        ComboBox{
                                            id: videoComboBox
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            visible: videoList.length > 0
                                            editable: false
                                            textRole: "deviceName"
                                            model: videoList
                                            onActivated: {
                                                SettingsHelper.save("cameraId", currentIndex)
                                            }
                                            onModelChanged: {
                                                if(videoList.length <= 0){
                                                    return
                                                }

                                                const cameraId = SettingsHelper.get("cameraId", 0)
                                                if(cameraId > videoList.length){
                                                    cameraId = 0
                                                }
                                                currentIndex = cameraId
                                            }
                                        }


                                        Item{
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 130
                                            visible: videoList.length <= 0
                                            Image {
                                                anchors.fill: parent
                                                source: "qrc:/res/pad/bk_mic.png"
                                            }
                                            ColumnLayout{
                                                anchors.centerIn: parent
                                                spacing: 10

                                                Image{
                                                    source: "qrc:/res/pad/btn_live_camera2.png"
                                                    Layout.alignment: Qt.AlignHCenter
                                                }

                                                FluText{
                                                    text: qsTr("未发现摄像头，无法开启")
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                        }

                                        RowLayout{
                                            Layout.preferredHeight: 30
                                            Layout.fillWidth: true

                                            Image {
                                                source: "qrc:/res/pad/btn_live_mic.png"
                                            }
                                            FluText{
                                                text: qsTr("麦克风")
                                                color: "white"
                                            }
                                            Item{
                                                Layout.fillWidth: true
                                            }
                                            FluToggleSwitch{
                                                enabled: audioList.length > 0
                                                visible: false
                                                onClicked: {
                                                    if(checked){
                                                        client.startAudioCapture(audioComboBox.currentIndex)
                                                        client.publishStream(1)
                                                    }else{
                                                        client.stopAudioCapture()
                                                        client.unPublishStream(1)
                                                    }
                                                }
                                            }
                                        }

                                        ComboBox{
                                            id: audioComboBox
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            visible: audioList.length > 0
                                            editable: false
                                            model: audioList
                                            textRole: "deviceName"
                                            onActivated: {
                                                SettingsHelper.save("microphoneId", currentIndex)
                                            }
                                            onModelChanged: {
                                                if(audioList.length <= 0){
                                                    return
                                                }

                                                const microphoneId = SettingsHelper.get("microphoneId", 0)
                                                if(microphoneId > audioList.length){
                                                    microphoneId = 0
                                                }
                                                currentIndex = microphoneId
                                            }
                                        }

                                        Item{
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 130
                                            visible: audioList.length <= 0

                                            Image {
                                                anchors.fill: parent
                                                source: "qrc:/res/pad/bk_mic.png"
                                            }

                                            ColumnLayout{
                                                anchors.centerIn: parent
                                                spacing: 10

                                                Image{
                                                    source: "qrc:/res/pad/btn_live_camera2.png"
                                                    Layout.alignment: Qt.AlignHCenter
                                                }

                                                FluText{
                                                    text: qsTr("未发现麦克风，无法开启")
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                        }

                                        Item{
                                            Layout.fillHeight: true
                                        }
                                    }

                                    ColumnLayout{
                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 62
                                            visible: !root.currentInjectFile
                                            radius: 8
                                            color: "#FFF5F6FA"

                                            FluText{
                                                anchors.centerIn: parent
                                                width: parent.width - 20
                                                // elide: Text.ElideRight
                                                wrapMode: Text.WrapAnywhere
                                                text: qsTr("请在列表中选择要推流的视频文件")
                                            }
                                        }

                                        Rectangle{
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 62
                                            visible: root.currentInjectFile
                                            radius: 8
                                            color: "white"

                                            RowLayout{
                                                anchors.fill: parent

                                                Image{
                                                    source: "qrc:/res/pad/pad_file.png"
                                                }

                                                ColumnLayout{
                                                    Layout.preferredWidth: 90
                                                    Layout.fillHeight: true

                                                    FluText{
                                                        font.pixelSize: 12
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                        text: currentInjectFile ? getVideoFile(currentInjectFile).fileName : ""
                                                    }
                                                    FluText{
                                                        font.pixelSize: 12
                                                        text: getFileSize(currentInjectFile ? getVideoFile(currentInjectFile).fileSize : 0)
                                                    }
                                                }

                                                IconButton {
                                                    id: btnStartPush
                                                    Layout.preferredHeight: 32
                                                    backgroundColor: "transparent"
                                                    textColor: "red"
                                                    iconSource: "qrc:/res/pad/btn_stop_push.png"
                                                    text: qsTr("结束")
                                                    onClicked: {
                                                        if(client){
                                                            client.stopInjectVideoStream()
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout{
                                            Layout.preferredHeight: 30
                                            Layout.fillWidth: true

                                            FluText{
                                                text: qsTr("全部视频(") + videoFileListModel.length + ")"
                                                color: "white"
                                            }

                                            Item{
                                                Layout.fillWidth: true
                                            }

                                            IconButton {
                                                id: btnUpload
                                                Layout.preferredHeight: 32
                                                borderRadius: 8
                                                textColor: "white"
                                                iconSource: "qrc:/res/pad/btn_upload_video.png"
                                                text: qsTr("上传视频")
                                                onClicked: {
                                                    fileDialog.title = qsTr("选择上传视频")
                                                    fileDialog.folder = StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                                    fileDialog.open()
                                                }
                                            }
                                        }

                                        ListView{
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 4
                                            boundsBehavior: Flickable.StopAtBounds
                                            clip: true
                                            model: videoFileListModel
                                            delegate: Rectangle{
                                                width: parent.width
                                                height: 62
                                                radius: 8
                                                color: "white"

                                                RowLayout{
                                                    anchors.fill: parent

                                                    Image{
                                                        source: "qrc:/res/pad/pad_file.png"
                                                    }

                                                    ColumnLayout{
                                                        Layout.preferredWidth: 90
                                                        Layout.fillHeight: true

                                                        FluText{
                                                            font.pixelSize: 12
                                                            Layout.fillWidth: true
                                                            elide: Text.ElideRight
                                                            text: modelData.fileName
                                                        }
                                                        FluText{
                                                            font.pixelSize: 12
                                                            text: getFileSize(modelData.fileSize)
                                                        }
                                                    }

                                                    ColumnLayout{
                                                        Layout.preferredWidth: 90
                                                        Layout.fillHeight: true

                                                        IconButton {
                                                            id: btnStopPush
                                                            Layout.preferredHeight: 22
                                                            backgroundColor: "transparent"
                                                            textColor: "blue"
                                                            iconSource: "qrc:/res/pad/blue.png"
                                                            text: qsTr("开启推流")
                                                            visible: !currentInjectFile || !modelData.downloadUrl.includes(currentInjectFile)
                                                            onClicked: {
                                                                if(client){
                                                                    client.startInjectVideoStream(modelData.downloadUrl, true)
                                                                }
                                                            }
                                                        }
                                                        FluText{
                                                            text: qsTr("推流中")
                                                            color: "blue"
                                                            Layout.leftMargin: 20
                                                            visible: currentInjectFile && modelData.downloadUrl.includes(currentInjectFile)
                                                        }

                                                        IconButton {
                                                            id: btnDelete
                                                            Layout.preferredHeight: 22
                                                            backgroundColor: "transparent"
                                                            textColor: "red"
                                                            iconSource: "qrc:/res/pad/btn_delete_video.png"
                                                            text: qsTr("删除")
                                                            visible: !currentInjectFile || !modelData.downloadUrl.includes(currentInjectFile)
                                                            onClicked: {
                                                                reqDeleteVideoFile(modelData.fileId)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }


                            }
                        }
                        // adb
                        Item{

                            ColumnLayout{
                                anchors.fill: parent
                                spacing: 10

                                RowLayout{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    FluText{
                                        text: qsTr("连接命令")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                    }

                                    TextButtonEx{
                                        text: qsTr("复制")
                                        textColor: "#FF30BF8F"
                                        onClicked: {
                                            FluTools.clipText(textCmd.text)
                                            showSuccess(qsTr("已复制到剪贴板"))
                                        }
                                    }
                                }
                                FluText{
                                    id: textCmd
                                    Layout.preferredWidth: 220
                                    text: "未开启"
                                    wrapMode: Text.WrapAnywhere
                                    color: "white"
                                }
                                RowLayout{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    FluText{
                                        text: qsTr("连接密钥")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                    }

                                    TextButtonEx{
                                        text: qsTr("复制")
                                        textColor: "#FF30BF8F"
                                        onClicked: {
                                            FluTools.clipText(textPass.text)
                                            showSuccess(qsTr("已复制到剪贴板"))
                                        }
                                    }
                                }

                                FluText{
                                    id: textPass
                                    Layout.preferredWidth: 220
                                    text: "未开启"
                                    wrapMode: Text.WrapAnywhere
                                    color: "white"
                                }

                                RowLayout{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    FluText{
                                        text: qsTr("ADB地址")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                    }

                                    TextButtonEx{
                                        text: qsTr("复制")
                                        textColor: "#FF30BF8F"
                                        onClicked: {
                                            FluTools.clipText(textADB.text)
                                            showSuccess(qsTr("已复制到剪贴板"))
                                        }
                                    }
                                }

                                FluText{
                                    id: textADB
                                    text: "未开启"
                                    wrapMode: Text.WrapAnywhere
                                    color: "white"
                                }

                                FluText{
                                    text: qsTr("ADB过期时间")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "white"
                                }
                                FluText{
                                    id: textADBExpireTime
                                    text: "未开启"
                                    color: "white"
                                }

                                RowLayout{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    FluText{
                                        text: qsTr("开启ADB")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                    }

                                    FluToggleSwitch{
                                        id: btnADBSwitch
                                        onClicked: {
                                            reqOpenADB(root.argument.padCode, checked)
                                        }
                                    }
                                }
                                Item{
                                    Layout.fillHeight: true
                                }
                            }
                        }
                        // 键盘映射
                        Item{

                            ColumnLayout{
                                anchors.fill: parent
                                spacing: 10

                                Rectangle{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 64
                                    radius: 8
                                    color: "#EFF3FF"

                                    RowLayout{
                                        anchors.fill: parent
                                        anchors.margins: 8

                                        Image{
                                            source: "qrc:/res/pad/btn_onekey.png"
                                        }

                                        ColumnLayout{

                                            FluText{
                                                text: qsTr("新增按键")
                                            }

                                            FluText{
                                                text: qsTr("使用“鼠标左键”新增按键")
                                                wrapMode: Text.WordWrap
                                                Layout.maximumWidth: 140
                                                color: "#637199"
                                                font.pixelSize: 10
                                            }
                                        }
                                    }

                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            keymapperModel.addItem(2, "J")
                                        }
                                    }
                                }


                                Rectangle{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 64
                                    radius: 8
                                    color: "#EFF3FF"

                                    RowLayout{
                                        anchors.fill: parent
                                        anchors.margins: 8

                                        Image{
                                            source: "qrc:/res/pad/btn_joystick.png"
                                        }

                                        ColumnLayout{

                                            FluText{
                                                text: qsTr("方向摇杆")
                                            }

                                            FluText{
                                                text: qsTr("使用“AWSD”控制人物移动")
                                                wrapMode: Text.WordWrap
                                                Layout.maximumWidth: 140
                                                color: "#637199"
                                                font.pixelSize: 10
                                            }
                                        }
                                    }

                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            keymapperModel.addItem(1, "W|S|A|D")
                                        }
                                    }
                                }

                                RowLayout{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    FluText{
                                        text: qsTr("键盘映射开关")
                                        // font.pixelSize: 16
                                        // font.bold: true
                                        color: "white"
                                    }

                                    Item{
                                        Layout.fillWidth: true
                                    }

                                    FluToggleSwitch{
                                        checked: 1 == SettingsHelper.get("keymap", 0)
                                        onClicked: {
                                            SettingsHelper.save("keymap", checked ? 1 : 0)
                                        }
                                    }
                                }

                                // 底部按钮栏
                                RowLayout {
                                    Layout.topMargin: 24
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 20

                                    TextButton{
                                        Layout.preferredHeight: 40
                                        Layout.fillWidth: true
                                        backgroundColor: "lightgray"
                                        borderRadius: 4
                                        textColor: "black"
                                        text: qsTr("还原")
                                        onClicked: {
                                            keymapperModel.loadConfig()
                                        }
                                    }

                                    TextButton{
                                        Layout.preferredHeight: 40
                                        Layout.fillWidth: true
                                        borderRadius: 4
                                        textColor: "white"
                                        backgroundColor: ThemeUI.primaryColor
                                        text: qsTr("保存")
                                        onClicked: {
                                            keymapperModel.saveConfig()

                                            const realWidth = root.width - spaceWidth
                                            spaceWidth = 40
                                            root.width = realWidth + spaceWidth
                                            layoutTool.visible = true
                                            layoutExtra.visible = false
                                            maskRect.visible = false
                                        }
                                    }
                                }

                                Item{
                                    Layout.fillHeight: true
                                }
                            }

                        }
                    }
                }
            }

        }
    }

    NetworkCallable {
        id: checkADB
        onError:
            (status, errorString, result) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            result => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    if(res.data){
                        btnADBSwitch.checked = !!res.data?.enable
                        textCmd.text = res.data?.command
                        textPass.text = res.data.key
                        textADB.text = res.data.adb
                        textADBExpireTime.text = res.data.expireTime
                    }else{
                        btnADBSwitch.checked = false
                        textCmd.text = qsTr("未开启")
                        textPass.text = qsTr("未开启")
                        textADB.text = qsTr("未开启")
                        textADBExpireTime.text = qsTr("未开启")
                    }
                }else{
                    showError(res.msg)
                }
            }
    }
    // 查询ADB状态
    function reqCheckADB(padCode){
        Network.postJson(AppConfig.apiHost + "/userEquipment/padAdb")
        .add("padCode", padCode)
        .add("enabled", true)
        .bind(root)
        .go(checkADB)
    }

    NetworkCallable {
        id: openADB
        onError:
            (status, errorString, result) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            result => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    reqCheckADB(root.argument.padCode)
                }else{
                    showError(res.msg)
                }
            }
    }

    // 打开ADB
    function reqOpenADB(padCode, isOpen){
        Network.postJson(AppConfig.apiHost + "/userEquipment/openOnlineAdb")
        .add("padCode", padCode)
        .add("enabled", isOpen)
        .bind(root)
        .go(openADB)
    }

    NetworkCallable {
        id: videoFileList
        onError:
            (status, errorString, result) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            result => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    videoFileListModel = res.data
                }else{
                    showError(res.msg)
                }
            }
    }

    // 获取云空间视频文件
    function reqVideoFileList(){
        Network.postJson(AppConfig.apiHost + "/cloudFile/selectFilesByUserId?operType=2&fileType=6")
        .bind(root)
        .go(videoFileList)
    }

    NetworkCallable {
        id: deletevideoFile
        onError:
            (status, errorString, result) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            result => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    reqVideoFileList()
                }else{
                    showError(res.msg)
                }
            }
    }

    // 删除云空间视频文件
    function reqDeleteVideoFile(fileId){
        Network.postBody(AppConfig.apiHost + "/cloudFile/deleteUploadFiles")
        .setBody(JSON.stringify([fileId]))
        .bind(root)
        .go(deletevideoFile)
    }

    NetworkCallable {
        id: stsToken
        onError:
            (status, errorString, result) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            result => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    const token = res.data.token
                    root.start(token)
                }else{
                    dialog.title = qsTr("系统提示")
                    dialog.message = res.msg
                    dialog.buttonFlags = FluContentDialogType.PositiveButton
                    dialog.positiveText = qsTr("确定")
                    dialog.onPositiveClickListener = function(){
                        root.close()
                        dialog.close()
                    }
                    dialog.open()
                }
            }
    }

    // 获取token
    function reqStsToken(supplierType, equipmentId){
        Network.get(AppConfig.apiHost + `/padManage/getStsToken?supplierType=${supplierType}&equipmentId=${equipmentId}`)
        .bind(root)
        .go(stsToken)
    }

    NetworkCallable {
        id: rebootDevice
        onStart: {
            showLoading(qsTr("正在重启云机..."))
        }
        onFinish: {
            hideLoading()
        }
        onError:
            (status, errorString, result, userData) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            (result, userData) => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    showSuccess(qsTr("重启云机成功"))
                    // 重启后可能需要关闭窗口或重新连接
                    FluRouter.removeWindow(root)
                }else{
                    showError(res.msg)
                }
            }
    }

    // 重启云机
    function reqRebootDevice(ip, padNames){
        Network.postJson(`http://${ip}:18182/container_api/v1` + "/reboot")
        .addList("db_ids", padNames)
        .bind(root)
        .setUserData(ip)
        .go(rebootDevice)
    }

    NetworkCallable {
        id: stopDevice
        onStart: {
            showLoading(qsTr("正在停止云机..."))
        }
        onFinish: {
            hideLoading()
        }
        onError:
            (status, errorString, result, userData) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            (result, userData) => {
                var res = JSON.parse(result)
                if(res.code === 200 && res.data){
                    showSuccess(qsTr("关闭云机成功"))
                    // 关闭后需要关闭窗口
                    FluRouter.removeWindow(root)
                }else{
                    showError(res.msg)
                }
            }
    }

    // 关闭云机
    function reqStopDevice(ip, padNames){
        Network.postJson(`http://${ip}:18182/container_api/v1` + "/stop")
        .addList("db_ids", padNames)
        .bind(root)
        .setUserData(ip)
        .go(stopDevice)
    }

    NetworkCallable {
        id: oneKeyNewDevice
        onStart: {
            showLoading(qsTr("正在一键新机..."))
        }
        onFinish: {
            hideLoading()
        }
        onError:
            (status, errorString, result, userData) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
            }
        onSuccess:
            (result, userData) => {
                var res = JSON.parse(result)
                if(res.code === 200){
                    showSuccess(qsTr("一键新机成功"))
                    // 新机后需要关闭窗口
                    FluRouter.removeWindow(root)
                }else{
                    showError(res.msg)
                }
            }
    }

    // 一键新机
    function reqOneKeyNewDevice(ip, padNames){
        Network.postJson(`http://${ip}:18182/container_api/v1` + "/replace_devinfo")
        .addList("db_ids", padNames)
        .bind(root)
        .setUserData(ip)
        .go(oneKeyNewDevice)
    }
}
