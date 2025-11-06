import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI
import Utils

FluPopup {
    id: root
    implicitWidth: 480
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property var modelData: null
    property int maxPhones: 16
    property int remainingPhones: 10
    property int phoneCount: 1
    property int downloadProgress: 0
    property bool isDownloading: false
    property var createDeviceParams: null
    property bool isChaining: false
    // 主机已有的 ADI 列表
    property var downloadedAdiList: []

    ListModel {
        id: localImagesModel
    }

    // property var androidVersions: ["10", "13", "14", "15"]
    // property int selectedAndroidVersion: 1

    // property var resolutionModel: [
    //     "720x1280",
    //     "1080x1920",
    //     "1080x2160",
    //     "1080x2340",
    //     "1080x2400",
    //     "1080x2460",
    //     "1440x2560",
    //     "1440x3200"
    // ]

    // property var dpiModel: [
    //     "320",
    //     "420",
    //     "420",
    //     "440",
    //     "440",
    //     "440",
    //     "560",
    //     "640"
    // ]


    // property var dnsTypeModel: [qsTr("Google DNS(8.8.8.8)"), "阿里 DNS(223.5.5.5)", qsTr("自定义 DNS")]

    signal upgradeResult(string hostIp, var list)

    function processChunkData(data) {
        var lines = data.split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue

            try {
                console.log("=============", line)
                const res = JSON.parse(line)
                if(res.stage){
                    if(res.stage == "Uploading"){
                        stateText.text = qsTr("镜像上传中...")
                        const match = res.upload_progress
                        if(match){
                            root.isDownloading = true
                            root.downloadProgress = match
                        }
                    }else if(res.stage == "Loading"){
                        stateText.text = qsTr("镜像加载中...")
                        const match = res.load_progress
                        if(match){
                            root.isDownloading = true
                            root.downloadProgress = match
                            if (match === 100 && root.createDeviceParams) {
                                reqUpgradDeviceImage(root.createDeviceParams.hostIp,
                                                     root.createDeviceParams.dbId,
                                                     root.createDeviceParams.repoName)
                                root.createDeviceParams = null;
                            }
                        }
                    }else if(res.stage == "Creating"){
                        stateText.text = qsTr("创建中...")
                    }else if(res.stage == "Failed"){
                        stateText.text = qsTr("创建失败...")
                        showError(res.message)
                        hideLoading()
                    }else if(res.stage == "Success"){
                        stateText.text = qsTr("镜像加载成功")
                        const match = res.load_progress
                        if(match){
                            root.isDownloading = true
                            root.downloadProgress = match
                            if (match === 100 && root.createDeviceParams) {
                                reqUpgradDeviceImage(root.createDeviceParams.hostIp,
                                                     root.createDeviceParams.dbId,
                                                     root.createDeviceParams.repoName)
                                root.createDeviceParams = null;
                            }
                        }
                    }
                }else if(res.code || res.code == 0){

                }else{
                    console.log("============", res.code, res.msg)
                    console.log("==================== not found")
                }
            } catch (e) {
                console.warn("无法将行解析为JSON:", line, e)
            }
        }
    }

    // function updateDnsInput(index) {
    //     if (index === 2) { // "自定义 DNS"
    //         dnsInput.text = ""
    //         dnsInput.readOnly = false
    //         dnsInput.placeholderText = qsTr("请输入DNS地址")
    //     } else {
    //         var currentItemText = dnsTypeModel[index]
    //         var match = currentItemText.match(/\(([^)]+)\)/)
    //         if (match && match[1]) {
    //             dnsInput.text = match[1]
    //         } else {
    //             dnsInput.text = "" // Fallback
    //         }
    //         dnsInput.readOnly = true
    //     }
    // }

    // function validateName(name){
    //     name = name.trim()
    //     if (name.length < 2 || name.length > 11) {
    //         showError(qsTr("长度限制：2-11字符"))
    //         return ""
    //     }
    //     if (/[^a-zA-Z0-9_.-]/.test(name)) {
    //         showError(qsTr("支持字符：[a-zA-Z0-9_.-]"))
    //         return ""
    //     }
    //     if (!/^[a-zA-Z0-9]/.test(name) || !/[a-zA-Z0-9]$/.test(name)) {
    //         showError(qsTr("首字符和尾字符必须为[a-zA-Z0-9]"))
    //         return ""
    //     }
    //     return name
    // }

    // function isValidIp(ip) {
    //     var regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    //     return regex.test(ip);
    // }

    property var downloadedImages: []

    Component.onCompleted: {
        // updateDnsInput(dnsTypeComboBox.currentIndex)
        // filterImages()
    }

    onOpened: {
        root.isDownloading = false
        // root.remainingPhones = root.maxPhones - root.modelData.hostPadCount
        // if(root.remainingPhones < 0){
        //     root.remainingPhones = 0
        // }
        // root.phoneCount = Math.min(1, root.remainingPhones)
        // phoneCountSpinBox.value = root.phoneCount
        reqDeviceImageList(root.modelData.hostIp)
        reqAdiList(root.modelData.hostIp)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.leftMargin: 20
            Layout.rightMargin: 10

            FluText {
                text: qsTr("修改镜像")
                font.bold: true
                font.pixelSize: 16
            }

            Item { Layout.fillWidth: true }

            FluImageButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                normalImage: "qrc:/res/common/btn_close_normal.png"
                hoveredImage: "qrc:/res/common/btn_close_normal.png"
                pushedImage: "qrc:/res/common/btn_close_normal.png"
                onClicked: root.close()
            }
        }

        ColumnLayout {
            width: parent.width
            Layout.margins: 20
            spacing: 15

            FluText {
                text: qsTr("云机名称：%1").arg(root.modelData?.displayName ?? "")
                color: "#666666"
            }

            FluText {
                text: qsTr("镜像版本：%1").arg(root.modelData?.image ?? "")
                color: "#666666"
            }

            FluText {
                text: qsTr("Android版本：Android %1").arg(root.modelData?.aospVersion ?? "")
                color: "#666666"
            }

            FluText {
                text: qsTr("选择镜像");
                font.bold: true
            }

            FluComboBox {
                id: imageComboBox
                Layout.fillWidth: true
                model: localImagesModel
                textRole: "displayText"
            }

            // ColumnLayout{

            //     FluText {
            //         text: qsTr("分辨率");
            //         font.bold: true
            //     }

            //     FluComboBox {
            //         id: resolutionComboBox
            //         Layout.fillWidth: true
            //         model: root.resolutionModel
            //     }
            // }

            // RowLayout{
            //     FluText { text: qsTr("DNS类型"); font.bold: true }
            //     FluComboBox {
            //         id: dnsTypeComboBox
            //         Layout.fillWidth: true
            //         model: root.dnsTypeModel
            //         onCurrentIndexChanged: {
            //             updateDnsInput(currentIndex)
            //         }
            //     }

            //     Item{
            //         Layout.preferredWidth: 20
            //     }

            //     FluText { text: qsTr("DNS地址"); font.bold: true }
            //     FluTextBox {
            //         id: dnsInput
            //         Layout.fillWidth: true
            //         placeholderText: qsTr("请输入DNS地址")
            //     }
            // }

            // RowLayout{

            //     FluText {
            //         id: textName
            //         text: phoneCountSpinBox.value > 1 ? qsTr("云机名称前缀") : qsTr("云机名称");
            //         font.bold: true
            //     }
            //     FluTextBox {
            //         id: nameInput
            //         Layout.fillWidth: true
            //         text: "vmos"
            //         placeholderText: qsTr("请输入云机名称")
            //         maximumLength: 11
            //     }
            // }


            // ColumnLayout{

            //     FluText {
            //         text: qsTr("云机数量");
            //         font.bold: true
            //     }

            //     RowLayout {
            //         spacing: 20

            //         FluSpinBox{
            //             id: phoneCountSpinBox
            //             Layout.alignment: Qt.AlignLeft
            //             editable: true
            //             from: root.remainingPhones >= 1 ? 1 : 0
            //             to: root.remainingPhones
            //             value: root.phoneCount
            //         }

            //         FluText{
            //             text: qsTr("剩余可创建云机数: %1").arg(root.remainingPhones)
            //             color: "#999"
            //         }
            //     }

            //     FluText{
            //         text: phoneCountSpinBox.value > 1 ? qsTr("将按前缀自动编号生成%1个云机：").arg(phoneCountSpinBox.value) :  qsTr("将创建%1台云机：").arg(phoneCountSpinBox.value)
            //     }

            //     Flow {
            //         Layout.fillWidth: true
            //         spacing: 10
            //         layoutDirection: Qt.LeftToRight

            //         Repeater{
            //             model: phoneCountSpinBox.value

            //             delegate: FluText{
            //                 font.pixelSize: 12
            //                 text: nameInput.text + (phoneCountSpinBox.value > 1 ? `-${(index + 1).toString().padStart(3, '0')}` : "")
            //             }
            //         }
            //     }
            // }

            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: "#FEF8F3"

                RowLayout{
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.topMargin: 6

                    ColumnLayout{
                        Layout.preferredWidth: 70
                        Layout.fillHeight: true

                        RowLayout{
                            FluIcon {
                                Layout.alignment: Qt.AlignTop
                                iconSource: FluentIcons.Info
                                iconSize: 14
                                color: "#E6A23C"
                            }
                            FluText {
                                Layout.alignment: Qt.AlignTop
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                text: qsTr("注意事项: ")
                            }
                        }

                        Item{
                            Layout.fillHeight: true
                        }
                    }
                    ColumnLayout{
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        FluText {
                            Layout.fillWidth: true
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            text: qsTr("1、升级到相同 Android 版本时，将保留现有数据。")
                        }

                        FluText {
                            Layout.fillWidth: true
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            color: "red"
                            text: qsTr("2、升级到不同 Android 版本时，将清除所有数据。")
                        }

                        Item{
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: root.isDownloading

                RowLayout{
                    Layout.fillWidth: true
                    FluText {
                        id: stateText
                        text: qsTr("镜像上传中..")
                        Layout.alignment: Qt.AlignLeft
                    }
                    Item{Layout.fillWidth: true}
                    FluText {
                        text: root.downloadProgress + "%"
                        Layout.alignment: Qt.AlignRight
                    }
                }
                FluProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    indeterminate: false
                    value: root.downloadProgress
                }
            }
        }

        Item { Layout.fillHeight: true }

        // 操作按钮
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.rightMargin: 20
            spacing: 10

            Item { Layout.fillWidth: true }

            FluButton {
                text: qsTr("取消")
                onClicked: root.close()
            }

            FluFilledButton {
                id: btnOk
                text: qsTr("确定")
                normalColor: ThemeUI.primaryColor
                enabled: root.phoneCount > 0
                onClicked: {
                    if (imageComboBox.currentIndex < 0) {
                        console.log("No image selected.")
                        return;
                    }

                    btnOk.enabled = false

                    var item = localImagesModel.get(imageComboBox.currentIndex);
                    var fileName = item.fileName;
                    var imageName = item.name; // 镜像版本
                    var path = item.path;

                    // 使用镜像版本与主机已存在的镜像列表比较
                    var isDownloaded = root.downloadedImages.indexOf(imageName) !== -1;

                    // 解析 Android 版本，选择对应 ADI 模板
                    var androidVersion = getAndroidVersionForImage(imageName, fileName)
                    var defaultTpl = findDefaultTemplateByVersion(androidVersion)
                    var adiName = defaultTpl ? defaultTpl.name : ""
                    var needUploadAdi = false
                    var adiPath = ""
                    if (defaultTpl && adiName) {
                        needUploadAdi = root.downloadedAdiList.indexOf(adiName) === -1
                        if (needUploadAdi) {
                            adiPath = defaultTpl.filePath || (FluTools.getApplicationDirPath() + "/adi/" + adiName)
                            if (adiPath.indexOf('/') === -1 && adiPath.indexOf('\\') === -1) {
                                adiPath = FluTools.getApplicationDirPath() + "/adi/" + adiName
                            }
                        }
                    }

                    // 如果是主机镜像（没有本地路径），直接升级镜像（必要时先上传 ADI）
                    if (!path || path === "") {
                        if (defaultTpl && needUploadAdi) {
                            root.isChaining = true
                            root.createDeviceParams = {
                                "hostIp": root.modelData.hostIp,
                                "dbId": root.modelData?.dbId,
                                "name": root.modelData?.name, // 向后兼容
                                "repoName": imageName,
                                "adiName": adiName
                            }
                            console.log("[升级云机] 需先上传ADI:", adiPath, "adiName=", adiName)
                            reqImportAdi(root.modelData.hostIp, adiPath)
                        } else {
                            console.log("[升级云机] 直接升级(主机镜像)", "repo=", imageName, "adiName=", adiName)
                            reqUpgradDeviceImage(root.modelData?.hostIp, root.modelData?.dbId, imageName, adiName);
                        }
                        btnOk.enabled = true
                        return;
                    }

                    if (isDownloaded) {
                        if (defaultTpl && needUploadAdi) {
                            root.isChaining = true
                            root.createDeviceParams = {
                                "hostIp": root.modelData.hostIp,
                                "dbId": root.modelData?.dbId,
                                "name": root.modelData?.name, // 向后兼容
                                "repoName": imageName,
                                "adiName": adiName
                            }
                            console.log("[升级云机] 镜像已存在, 需先上传ADI:", adiPath, "adiName=", adiName)
                            reqImportAdi(root.modelData.hostIp, adiPath)
                        } else {
                            console.log("[升级云机] 镜像已存在, 直接升级", "repo=", imageName, "adiName=", adiName)
                            reqUpgradDeviceImage(root.modelData?.hostIp, root.modelData?.dbId, imageName, adiName);
                        }
                    } else {
                        root.isChaining = true
                        root.createDeviceParams = {
                            "hostIp": root.modelData.hostIp,
                            "dbId": root.modelData?.dbId,
                            "name": root.modelData?.name, // 向后兼容
                            "repoName": imageName,
                            "needUploadAdi": !!(defaultTpl && needUploadAdi),
                            "adiPath": adiPath,
                            "adiName": adiName
                        }
                        console.log("[升级云机] 镜像需上传, needUploadAdi=", (!!(defaultTpl && needUploadAdi)), "adiPath=", adiPath, "adiName=", adiName)
                        reqUploadImage(root.modelData.hostIp, path);
                    }
                    btnOk.enabled = true
                }
            }
        }
    }


    NetworkCallable {
        id: deviceImageList
        onSuccess:
            (result, userData) => {
                try {
                    localImagesModel.clear()
                    var hostRepos = []
                    var res = JSON.parse(result)
                    if(res.code === 200 && res.data && Array.isArray(res.data)){
                        hostRepos = res.data.map(function(img) { return img.repository; });
                        root.downloadedImages = hostRepos;
                    } else {
                        console.debug("get_img_list returned error or no data:", res.msg);
                        root.downloadedImages = [];
                    }

                    // 首先添加本地模型中的镜像
                    for (var i = 0; i < imagesModel.rowCount(); i++) {
                        var index = imagesModel.index(i, 0);

                        var name = imagesModel.data(index, ImagesModel.NameRole).toString(); // 镜像版本
                        var fileName = imagesModel.data(index, ImagesModel.FileNameRole).toString(); // 镜像文件名
                        var version = imagesModel.data(index, ImagesModel.VersionRole).toString(); // Android版本
                        var path = imagesModel.data(index, ImagesModel.PathRole).toString();

                        // repository是镜像版本，应该与本地模型中的镜像版本（NameRole）比较
                        var isDownloaded = hostRepos.indexOf(name) !== -1;

                        // 显示格式：镜像文件名（已上传）- 安卓版本
                        var displayText = fileName;
                        if (isDownloaded) {
                            displayText += qsTr(" (已上传)");
                        }
                        if (version) {
                            displayText += " - " + version;
                        }

                        localImagesModel.append({
                                                    "displayText": displayText,
                                                    "fileName": fileName,
                                                    "name": name, // 镜像版本，用于与主机比较
                                                    "path": path
                                                });
                    }

                    // 然后添加主机中存在但本地模型中没有的镜像
                    for (var j = 0; j < hostRepos.length; j++) {
                        var hostRepo = hostRepos[j];
                        var isInLocalModel = false;

                        // 检查是否已在本地模型中
                        for (var k = 0; k < imagesModel.rowCount(); k++) {
                            var localIndex = imagesModel.index(k, 0);
                            var localName = imagesModel.data(localIndex, ImagesModel.NameRole).toString();
                            if (localName === hostRepo) {
                                isInLocalModel = true;
                                break;
                            }
                        }

                        // 如果主机镜像不在本地模型中，添加到列表
                        if (!isInLocalModel) {
                            var displayText = hostRepo + qsTr(" (已上传)");
                            localImagesModel.append({
                                                        "displayText": displayText,
                                                        "fileName": hostRepo, // 使用镜像版本作为文件名
                                                        "name": hostRepo, // 镜像版本
                                                        "path": "" // 主机镜像没有本地路径
                                                    });
                        }
                    }
                    if (localImagesModel.count > 0) {
                        imageComboBox.currentIndex = 0;
                    } else {
                        imageComboBox.currentIndex = -1;
                    }
                } catch (e) {
                    console.error("Error in deviceImageList.onSuccess:", e);
                }
            }
        onError: (status, errorString, result, userData) => {
                     console.error("deviceImageList error:", errorString);
                     root.downloadedImages = [];
                 }
    }

    // 获取云机内已下载镜像列表
    function reqDeviceImageList(ip){
        console.log("reqDeviceImageList called with ip:", ip);
        if (!ip) {
            console.error("reqDeviceImageList: IP address is null or empty. Aborting request.");
            return;
        }
        Network.get(`http://${ip}:18182/v1` + "/get_img_list")
        .setUserData(ip)
        .bind(root)
        .go(deviceImageList)
    }

    NetworkCallable {
        id: upgradDeviceImage
        onStart: {
            showLoading(qsTr("正在升级云机镜像..."))
        }
        onFinish: {
            hideLoading()
            root.isChaining = false
        }

        onError:
            (status, errorString, result, userData) => {
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
                root.upgradeResult(false)
                root.close()
            }
        onSuccess:
            (result, userData) => {
                try {
                    const res = JSON.parse(result)
                    if(res.code == 200){
                        // 创建成功
                        root.upgradeResult(res.data.host_ip, res.data.list)
                        root.close()
                    }else if(res.code == 202){
                        showError("正在执行镜像更新，请稍后再试", 3000)
                    }
                    else{
                        showError(res.msg, 3000)
                    }
                } catch (e) {
                    console.warn("无法将行解析为JSON:", result, e)
                }
            }
    }

    // 升级云机镜像
    function reqUpgradDeviceImage(ip, dbId, image_url, adiName){
        console.log("[升级云机] 请求升级", "ip=", ip, "dbId=", dbId, "repo=", image_url, "adiName=", adiName)
        Network.postJson(`http://${ip}:18182/container_api/v1` + "/upgrade_image")
        .add("repository", image_url)
        .addList("db_ids", [dbId])
        .add("adiName", adiName || "")
        .add("adiPass", "")
        .setUserData(ip)
        .bind(root)
        .setTimeout(600000)
        .go(upgradDeviceImage)
    }

    NetworkCallable {
        id: uploadImage
        property string _buffer: ""

        onStart: {
            _buffer = ""
            showLoading(qsTr("镜像上传中..."))
            root.isDownloading = true
        }
        onFinish: {
            if(_buffer.length > 0){
                processChunkData(_buffer)
                _buffer = ""
            }
            if (!root.isChaining) {
                hideLoading()
            }
            root.isDownloading = false
        }
        onChunck:
            (chunk, userData) => {
                _buffer += chunk
                var separator = '\n'
                var lastIndex = _buffer.lastIndexOf(separator)

                if (lastIndex !== -1) {
                    var processable = _buffer.substring(0, lastIndex)
                    _buffer = _buffer.substring(lastIndex + 1)
                    processChunkData(processable)
                }
            }

        onError:
            (status, errorString, result, userData) => {
                hideLoading()
                console.debug(status + ";" + errorString + ";" + result)
                showError(errorString)
                root.upgradeResult(false)
                root.close()
            }
        onSuccess:
            (result, userData) => {
                // 镜像上传完毕后，如需要也上传 ADI，然后再执行升级
                if (root.createDeviceParams && root.isChaining) {
                    if (root.createDeviceParams.needUploadAdi && root.createDeviceParams.adiPath) {
                        reqImportAdi(root.createDeviceParams.hostIp, root.createDeviceParams.adiPath)
                    } else {
                        reqUpgradDeviceImage(root.createDeviceParams.hostIp,
                                             root.createDeviceParams.name,
                                             root.createDeviceParams.repoName,
                                             root.createDeviceParams.adiName)
                        root.createDeviceParams = null
                        root.isChaining = false
                    }
                }
            }
        onUploadProgress:
            (sent,total)=>{
                stateText.text = qsTr("镜像上传中...")
                root.downloadProgress = (sent * 1.0 / total) * 100
            }
    }

    // 上传镜像
    function reqUploadImage(ip, path){
        Network.postForm(`http://${ip}:18182/v1` + "/import_image")
        .setRetry(1)
        .addFile("file", path)
        .bind(root)
        .go(uploadImage)
    }

    // 解析本地镜像的 Android 版本，用于匹配 ADI 模板
    function normalizeAndroidVersion(v){
        var s = (v === undefined || v === null) ? "" : ("" + v)
        var m = s.match(/(\d{1,2})/)
        return m && m[1] ? m[1] : ""
    }

    function getAndroidVersionForImage(imageName, fileName) {
        for (var i = 0; i < imagesModel.rowCount(); i++) {
            var idx = imagesModel.index(i, 0)
            var n = imagesModel.data(idx, ImagesModel.NameRole).toString()
            var fn = imagesModel.data(idx, ImagesModel.FileNameRole).toString()
            var v = imagesModel.data(idx, ImagesModel.VersionRole).toString()
            if ((imageName && n === imageName) || (fileName && fn === fileName)) {
                return normalizeAndroidVersion(v)
            }
        }
        var source = (imageName || "") + "_" + (fileName || "")
        var m = source.match(/android\s*(\d{1,2})/i)
        if (m && m[1]) return m[1]
        return ""
    }

    function findDefaultTemplateByVersion(androidVersion) {
        if (!androidVersion)
            return null
        for (var i = 0; i < tempLateModel.rowCount(); i++) {
            var idx = tempLateModel.index(i, 0)
            var v = tempLateModel.data(idx, TemplateModel.AsopVersionRole).toString()
            if (normalizeAndroidVersion(v) === normalizeAndroidVersion(androidVersion)) {
                return {
                    brand: tempLateModel.data(idx, TemplateModel.BrandRole).toString(),
                    model: tempLateModel.data(idx, TemplateModel.ModelRole).toString(),
                    layout: tempLateModel.data(idx, TemplateModel.LayoutRole).toString(),
                    name: tempLateModel.data(idx, TemplateModel.NameRole).toString(),
                    filePath: tempLateModel.data(idx, TemplateModel.FilePathRole).toString(),
                    version: v
                }
            }
        }
        return null
    }

    // 主机 ADI 列表
    NetworkCallable {
        id: adiList
        onSuccess:
            (result, userData) => {
                try {
                    var res = JSON.parse(result);
                    if(res.code === 200 && res.data){
                        if (Array.isArray(res.data.files)) {
                            root.downloadedAdiList = res.data.files.slice();
                        } else if (Array.isArray(res.data)) {
                            root.downloadedAdiList = res.data.map(function(item){
                                if (typeof item === 'string') return item;
                                if (item && item.name) return item.name;
                                if (item && item.brand && item.model) return item.brand + '_' + item.model;
                                return '';
                            }).filter(function(s){ return !!s; });
                        } else {
                            root.downloadedAdiList = [];
                        }
                    } else {
                        root.downloadedAdiList = [];
                    }
                } catch (e) {
                    root.downloadedAdiList = [];
                }
            }
        onError: (status, errorString, result, userData) => {
                     // ignore
                 }
    }

    function reqAdiList(ip){
        if (!ip) return;
        Network.get(`http://${ip}:18182/v1` + "/get_adi_list")
        .setUserData(ip)
        .bind(root)
        .go(adiList)
    }

    // 导入 ADI（沿用创建弹窗相同接口）
    NetworkCallable {
        id: importAdi
        onStart: { showLoading(qsTr("ADI 导入中...")) }
        onFinish: { hideLoading() }
        onError:
            (status, errorString, result, userData) => {
                hideLoading()
                showError(errorString)
            }
        onSuccess:
            (result, userData) => {
                // 成功后直接执行升级
                if (root.createDeviceParams) {
                    reqUpgradDeviceImage(root.createDeviceParams.hostIp,
                                         root.createDeviceParams.name,
                                         root.createDeviceParams.repoName,
                                         root.createDeviceParams.adiName)
                    root.createDeviceParams = null
                    root.isChaining = false
                }
            }
    }

    function reqImportAdi(ip, adiPath){
        Network.postForm(`http://${ip}:18182/v1` + "/import_adi")
        .setRetry(1)
        .addFile("adiZip", adiPath)
        .setUserData(ip)
        .bind(root)
        .go(importAdi)
    }
}
