import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Item {
//     id: root
//     implicitWidth: 280
//     implicitHeight: 40
//     property alias text: input.text
//     property alias placeholderText: input.placeholderText
//     property url clearIconSource: "qrc:/res/login/btn_delete_normal.png"
//     property bool fieldFocus: input.focus
//     property bool enabled: input.enabled
//     property bool password: false
//     property bool hovering: false

//     signal enterPressed(string text)

//     Rectangle {
//         id: bg
//         anchors.fill: parent
//         color: "white"
//         radius: 4
//         border.width: 1
//         border.color: input.focus ? "#007aff" : (hovering ? "#999999" : "#cccccc")
//     }

//     MouseArea {
//         id: hoverArea
//         anchors.fill: parent
//         hoverEnabled: true
//         propagateComposedEvents: true
//         onEntered: hovering = true
//         onExited: hovering = false
//         onClicked: mouse.accepted = false
//     }

//     RowLayout {
//         anchors.fill: parent
//         anchors.leftMargin: 8
//         anchors.rightMargin: 8
//         anchors.topMargin: 4
//         anchors.bottomMargin: 4
//         spacing: 6

//         TextField {
//             id: input
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             font.pixelSize: 16
//             selectByMouse: true
//             background: Item{

//             }
//             echoMode: password ? TextInput.Password : TextInput.Normal
//             placeholderText: root.placeholderText
//             placeholderTextColor: "gray"
//             color: "black"

//             Keys.onReturnPressed: {
//                 root.enterPressed(input.text)
//             }
//         }

//         Item {
//             id: clearButton
//             width: 24
//             height: 24
//             visible: input.text.length > 0
//             opacity: visible ? 1.0 : 0.0

//             Behavior on opacity {
//                 NumberAnimation { duration: 100 }
//             }

//             Rectangle {
//                 anchors.fill: parent
//                 color: mouseArea.containsMouse ? "#00000011" : "transparent"
//                 radius: 4
//             }

//             Image {
//                 anchors.centerIn: parent
//                 source: root.clearIconSource
//                 width: 16
//                 height: 16
//                 fillMode: Image.PreserveAspectFit
//             }

//             MouseArea {
//                 id: mouseArea
//                 anchors.fill: parent
//                 hoverEnabled: true
//                 cursorShape: Qt.PointingHandCursor
//                 property bool pressed: false

//                 onPressed: pressed = true
//                 onReleased: {
//                     pressed = false
//                     input.clear()
//                 }
//                 onCanceled: pressed = false

//                 scale: pressed ? 0.9 : 1.0
//                 Behavior on scale {
//                     NumberAnimation { duration: 80; easing.type: Easing.InOutQuad }
//                 }
//             }
//         }
//     }
// }


Item {
    id: root
    implicitWidth: 280
    implicitHeight: 40

    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property url clearIconSource: "qrc:/res/login/btn_delete_normal.png"
    property bool fieldFocus: input.focus
    property bool enabled: input.enabled
    property bool password: false
    property bool hovering: false
    property bool readonly: false   // ✅ 新增只读属性

    signal enterPressed(string text)

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "white"
        radius: 4
        border.width: 1
        border.color: root.readonly ? "#cccccc"
                     : (input.focus ? ThemeUI.primaryColor : (hovering ? "#999999" : "#cccccc")) // ✅ 只读无高亮
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: hovering = !root.readonly  // ✅ 只读不触发 hover
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
            readOnly: root.readonly
            background: Item { }
            echoMode: password ? TextInput.Password : TextInput.Normal
            placeholderText: root.placeholderText
            placeholderTextColor: "gray"
            color: root.readonly ? "#999999" : "black"

            Keys.onPressed: (event) => {
                if(event.key === Qt.Key_Return || event.key === Qt.Key_Enter){
                    root.enterPressed(input.text)
                    event.accepted = true
                }
            }
        }

        Item {
            id: clearButton
            width: 24
            height: 24
            visible: !root.readonly && input.text.length > 0
            opacity: visible ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            Rectangle {
                anchors.fill: parent
                color: mouseArea.containsMouse ? "#00000011" : "transparent"
                radius: 4
            }

            Image {
                anchors.centerIn: parent
                source: root.clearIconSource
                width: 16
                height: 16
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool pressed: false

                onPressed: pressed = true
                onReleased: {
                    pressed = false
                    input.clear()
                }
                onCanceled: pressed = false

                scale: pressed ? 0.9 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 80; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
