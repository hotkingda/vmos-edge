import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property color borderColor: "#007aff"
    property real borderSize: 0
    property real borderRadius: 4
    property alias text: contentRow.text
    property color textColor: "white"
    property int textSize: 12
    property color backgroundColor: "#007aff"
    property bool enabled: true  // 新增：启用/禁用状态
    property color disabledBackgroundColor: "#cccccc"  // 新增：禁用时的背景色
    property color disabledTextColor: "#999999"  // 新增：禁用时的文字色
    property color disabledBorderColor: "#dddddd"  // 新增：禁用时的边框色

    signal clicked()

    radius: borderRadius
    border.color: enabled ? borderColor : disabledBorderColor
    border.width: borderSize

    // 按内容自适应大小
    implicitWidth: contentRow.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentRow.implicitHeight + topPadding + bottomPadding

    property int leftPadding: 12
    property int rightPadding: 12
    property int topPadding: 8
    property int bottomPadding: 8

    // 动态背景色 - 根据启用状态和悬停状态
    color: enabled ? (hoverArea.containsMouse ? Qt.darker(backgroundColor, 1.1) : backgroundColor) : disabledBackgroundColor

    Text {
        id: contentRow
        anchors.centerIn: parent
        text: ""
        color: enabled ? textColor : disabledTextColor
        font.pixelSize: textSize
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        Layout.alignment: Qt.AlignVCenter
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: enabled
        enabled: root.enabled

        property bool pressed: false

        onPressed: {
            if (enabled) {
                pressed = true
            }
        }
        onReleased: {
            pressed = false
            if (enabled) {
                root.clicked()
            }
        }
        onCanceled: pressed = false
    }

    property bool pressed: hoverArea.pressed
}
