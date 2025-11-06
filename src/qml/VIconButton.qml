import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property color borderColor: "#007aff"
    property real borderSize: 0
    property real borderRadius: 4
    property alias text: label.text
    property color textColor: "white"
    property int textSize: 12
    property alias iconSource: icon.source
    property color backgroundColor: "#007aff"


    signal clicked()

    radius: borderRadius
    border.color: borderColor
    border.width: borderSize

    // 按内容自适应大小
    implicitWidth: 200
    implicitHeight: 40

    property int leftPadding: 12
    property int rightPadding: 12
    property int topPadding: 8
    property int bottomPadding: 8

    // 动态背景色
    color: hoverArea.containsMouse ? Qt.darker(backgroundColor, 1.1) : backgroundColor

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: leftPadding
        anchors.rightMargin: rightPadding
        anchors.topMargin: topPadding
        anchors.bottomMargin: bottomPadding
        spacing: 4

        Image {
            id: icon
            source: ""
            visible: source !== ""
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: label
            text: ""
            color: textColor
            font.pixelSize: textSize
            Layout.fillWidth: true
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        property bool pressed: false

        onPressed: pressed = true
        onReleased: {
            pressed = false
            root.clicked()
        }
        onCanceled: pressed = false
    }

    property bool pressed: hoverArea.pressed
}
