import QtQuick
import QtQuick.Layouts
import FluentUI
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int currentIndex: 0
    property var model: []
    signal menuSelected(string name)

    RowLayout {
        id: rootLayout
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0

        Repeater {
            id: buttonRepeater
            model: root.model

            delegate: Item {
                width: contentColumn.implicitWidth + contentColumn.anchors.leftMargin + contentColumn.anchors.rightMargin
                height: 42

                ColumnLayout{
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 14

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        spacing: 4

                        Image {
                            id: svgImage
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit

                            ColorOverlay {
                                anchors.fill: parent
                                source: svgImage
                                color: root.currentIndex == index ? ThemeUI.primaryColor : "#333"
                            }
                        }

                        Text {
                            text: modelData.text
                            font.pixelSize: 12
                            font.bold: index < 3 ? true : false
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap

                            Layout.alignment: Qt.AlignVCenter
                            color: root.currentIndex == index ? ThemeUI.primaryColor : "#333"
                        }
                    }

                    Rectangle{
                        Layout.preferredHeight: 2
                        Layout.preferredWidth: parent.width * 0.7
                        Layout.alignment: Qt.AlignHCenter
                        color: root.currentIndex == index ? ThemeUI.primaryColor : "transparent"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(index < 3){
                            root.currentIndex = index
                        }
                        menuSelected(modelData.name)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
