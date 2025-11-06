import QtQuick

Item {
    id: control
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property alias  text: label.text
    property color textColor: "#666"
    property int textSize:  14
    property bool textBold: false
    property bool textUnderline: false

    signal clicked()

    Text {
        id: label
        text: text
        font.pixelSize: textSize
        font.bold: textBold
        font.underline: textUnderline
        color: textColor
    }

    MouseArea{
        anchors.fill: parent
        onClicked: {
            control.clicked()
        }
    }
}
