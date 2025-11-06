import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI


Item {
    id: root
    implicitWidth: 280
    implicitHeight: 40
    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property bool fieldFocus: input.focus
    property bool enabled: input.enabled
    property int countdown: 60
    property color textColor: ThemeUI.primaryColor
    property bool hovering: false

    signal sendSms() // 定义信号

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "white"
        radius: 4
        border.width: 1
        border.color: input.focus ? ThemeUI.primaryColor : (hovering ? "#999999" : "#cccccc")
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: hovering = true
        onExited: hovering = false
        onClicked: mouse.accepted = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 6

        TextField {
            id: input
            Layout.fillWidth: true
            Layout.fillHeight: true
            font.pixelSize: 16
            selectByMouse: true
            background: Item{}
            echoMode: TextInput.Normal
            validator: IntValidator{
                bottom: 100000
                top: 999999
            }
            placeholderText: root.placeholderText
            placeholderTextColor: "gray"
            color: "black"
        }

        // 创建按钮
        VTextButton {
            id: button
            Layout.preferredWidth: 100
            Layout.fillHeight: true
            textColor: root.textColor
            text: qsTr("发送验证码")
            onBtnClicked: {
                handleSendSms()
                sendSms()
            }
        }
    }

    // 定义计时器
    Timer {
        id: timer
        interval: 1000 // 每秒触发一次
        running: false // 初始化时不启动计时器
        repeat: true
        onTriggered: {
            if (countdown > 0) {
                countdown -= 1
                button.text = countdown + qsTr("秒后重发")
            } else {
                button.text = qsTr("发送验证码")
                button.enabled = true  // 启用按钮
                timer.stop()           // 停止计时器
            }
        }
    }


    function handleSendSms(){
        // 点击按钮时，禁用按钮并开始倒计时
        button.enabled = false
        timer.start()  // 启动计时器
        countdown = 60  // 重置倒计时
        button.text = countdown + qsTr("秒后重发")
    }

    // 处理短信发送状态
    function handleSmsResult(success) {
        if (success) {
            console.log("短信发送成功！");
            // 短信发送成功时，可以选择是否继续倒计时等操作
        } else {
            console.log("短信发送失败！");
            // 短信发送失败时恢复按钮状态和文本
            timer.stop()
            button.enabled = true
            button.text = qsTr("发送验证码")
        }
    }
}
