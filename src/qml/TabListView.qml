import QtQuick
import QtQuick.Layouts

Rectangle{
    id: rootRect
    property int currentIndex: 0
    property var model: []
    color: "white"
    signal menuSelected(int index)

    RowLayout {
        id: rootLayout
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0


        Repeater {
            id: buttonRepeater
            model: rootRect.model

            Rectangle {
                id: item
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "white"
                border.color: "#ccc"
                border.width: 1
                topLeftRadius: 8
                topRightRadius: 8

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 8
                    topRightRadius: 8
                    visible: currentIndex === index
                    color: currentIndex === index ? ThemeUI.primaryColor : "transport"
                }

                Text {
                    text: modelData
                    anchors.centerIn: parent
                    color: currentIndex === index ? "white" : "black"
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(currentIndex == index){
                            return
                        }

                        currentIndex = index
                        menuSelected(currentIndex)
                    }
                }
            }
        }
    }
}
