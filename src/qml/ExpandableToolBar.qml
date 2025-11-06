import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: expandableToolBarRoot
    property var toolModel: [
        {name: "apk", icon: "qrc:/res/pad/pad_apk.png", title: qsTr("安装")},
        {name: "upload", icon: "qrc:/res/pad/pad_upload.png", title: qsTr("导入")},
        {name: "volume_up", icon: "qrc:/res/pad/pad_audio_add.png", title: qsTr("音量+")},
        {name: "volume_down", icon: "qrc:/res/pad/pad_audio_sub.png", title: qsTr("音量-")},
        {name: "rotation", icon: "qrc:/res/pad/pad_rotate.png", title: qsTr("旋转")},
        // {name: "live", icon: "qrc:/res/pad/pad_live.png", title: qsTr("直播")},
        // {name: "keymap", icon: "qrc:/res/pad/pad_keymap.png", title: qsTr("按键映射")},
        // {name: "change_machine", icon: "qrc:/res/pad/pad_changemachine.png", title: qsTr("换机")},
        {name: "reset", icon: "qrc:/res/pad/pad_reboot.png", title: qsTr("关机")},
        // {name: "more", icon: "qrc:/res/pad/pad_more.png", title: qsTr("更多")},
        // {name: "clipboard", icon: "qrc:/res/pad/pad_board.png", title: qsTr("剪贴板")},
        // {name: "share", icon: "qrc:/res/pad/pad_share.png", title: qsTr("分享")},
        // {name: "screenshot_remote", icon: "qrc:/res/pad/pad_screenshot.png", title: qsTr("云机截图")},
        {name: "screenshot_local", icon: "qrc:/res/pad/pad_screenshot.png", title: qsTr("截图")},
        {name: "screenshot_dir", icon: "qrc:/res/pad/pad_file.png", title: qsTr("截图目录")},
        // {name: "keyboard", icon: "qrc:/res/pad/pad_keyboard.png", title: qsTr("本地输入")},
        {name: "reboot", icon: "qrc:/res/pad/pad_reset.png", title: qsTr("重启")},
        {name: "onekey", icon: "qrc:/res/pad/pad_onekey.png", title: qsTr("一键新机")},
        // {name: "adb", icon: "qrc:/res/pad/pad_adb.png", title: "ADB"},
        // {name: "blow", icon: "qrc:/res/pad/pad_blow.png", title: qsTr("吹一吹")},
        // {name: "shake", icon: "qrc:/res/pad/pad_shake.png", title: qsTr("摇一摇")},
    ]

    property bool expanded: false
    property int buttonHeight: 56
    property int buttonWidth: 40
    property bool moreButtonNeeded: true
    property int columnCount: expanded && moreButtonNeeded ? 2 : 1
    property var displayModel: []

    signal toolClicked(var name)

    Component.onCompleted: updateState()
    onHeightChanged: updateState()
    onExpandedChanged: updateState()

    function handleItemClick(modelData) {
        if (modelData.name === "more") {
            expanded = !expanded;
            toolClicked(modelData);
        } else {
            if(expanded){
                expanded = false
            }
            toolClicked(modelData);
        }
    }

    function updateState() {
        const maxRows = Math.floor(expandableToolBarRoot.height / expandableToolBarRoot.buttonHeight);
        if (maxRows <= 0) {
            displayModel = [];
            return;
        }

        if (toolModel.length <= maxRows) {
            moreButtonNeeded = false;
            displayModel = toolModel;
            if (expanded) {
                expanded = false;
            }
        } else {
            moreButtonNeeded = true;
            let newModel = [];
            const moreButtonTemplate = { name: "more", icon: "qrc:/res/pad/pad_more.png" };

            if (expanded) {
                const firstColCount = maxRows - 1;
                let firstColTools = toolModel.slice(0, firstColCount);
                let restOfTools = toolModel.slice(firstColCount);
                
                newModel = firstColTools;
                newModel.push({ name: moreButtonTemplate.name, icon: moreButtonTemplate.icon, title: qsTr("收起") });
                newModel = newModel.concat(restOfTools);
            } else {
                const visibleCount = Math.min(toolModel.length, maxRows - 1);
                newModel = toolModel.slice(0, visibleCount);
                newModel.push({ name: moreButtonTemplate.name, icon: moreButtonTemplate.icon, title: qsTr("更多") });
            }
            displayModel = newModel;
        }
    }

    width: buttonWidth * columnCount
    height: parent ? parent.height : 400

    Rectangle {
        anchors.fill: parent
        color: "#FF0B2F52"

        Flow {
            anchors.fill: parent
            spacing: 0
            flow: Flow.TopToBottom

            Repeater {
                model: expandableToolBarRoot.displayModel

                delegate: Item {
                    width: expandableToolBarRoot.buttonWidth
                    height: expandableToolBarRoot.buttonHeight

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        Image {
                            source: modelData.icon
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: modelData.title
                            color: "white"
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: expandableToolBarRoot.buttonWidth
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: expandableToolBarRoot.handleItemClick(modelData)
                    }
                }
            }
        }
    }
}

