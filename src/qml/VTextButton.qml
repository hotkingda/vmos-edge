import QtQuick

Item{
    id: control
    implicitWidth: 120
    implicitHeight: 40

    property alias text: text.text
    property color textColor: ThemeUI.blueColor

    signal btnClicked()

    Text {
        id: text
        anchors.centerIn: parent
        color: textColor
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        width: parent.width - 6
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
    }

    MouseArea{
        anchors.fill: parent
        onClicked: {
            btnClicked()
        }
    }
}
