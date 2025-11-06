import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI

Item {
    id: root
    implicitWidth: 100
    implicitHeight: 40
    property string languageId: "zh"
    property int currentIndex: 0
    signal menuSelected(string name)

    // Define the language model as a property for easier access
    property var languageModel: [
        {name: "简体中文", icon: "qrc:/res/common/zh.svg", flag: "zh"},
        {name: "繁体中文", icon: "qrc:/res/common/zh-hant.svg", flag: "zh-hant"},
        {name: "English", icon: "qrc:/res/common/en.svg", flag: "en"},
        {name: "Русский", icon: "qrc:/res/common/ru.svg", flag: "ru"},
        {name: "한국인", icon: "qrc:/res/common/ko.svg", flag: "ko"},
        {name: "日本語", icon: "qrc:/res/common/ja.svg", flag: "ja"},
        {name: "Tiếng Việt", icon: "qrc:/res/common/vi.svg", flag: "vi"},
        {name: "แบบไทย", icon: "qrc:/res/common/th.svg", flag: "th"},
        {name: "Melayu", icon: "qrc:/res/common/ms.svg", flag: "ms"},
        {name: "العربية", icon: "qrc:/res/common/ar.svg", flag: "ar"},
        {name: "Español", icon: "qrc:/res/common/es.svg", flag: "es"},
        {name: "Indonesia", "icon": "qrc:/res/common/id.svg", flag: "id"},
        {name: "Português", icon: "qrc:/res/common/pt.svg", flag: "pt"},
        {name: "اردو", icon: "qrc:/res/common/ur.svg", flag: "ur"},
        {name: "Filipino", icon: "qrc:/res/common/fil.svg", flag: "fil"},
        {name: "ភាសាខ្មែរ", icon: "qrc:/res/common/km.svg", flag: "km"},
        {name: "Français", icon: "qrc:/res/common/fr.svg", flag: "fr"},
        {name: "Українська", icon: "qrc:/res/common/uk.svg", flag: "uk"}
    ]

    // Use a function to find the data for the current languageId
    function getLanguageData(flagId) {
        for (var i = 0; i < languageModel.length; i++) {
            if (languageModel[i].flag === flagId) {
                return languageModel[i]
            }
        }
        return null // Return null if not found
    }

    // Set currentIndex based on languageId when the component initializes
    Component.onCompleted: {
        var data = getLanguageData(languageId)
        if (data) {
            currentIndex = languageModel.indexOf(data)
        }
    }

    Item{
        id: control
        anchors.fill: parent

        RowLayout{
            anchors.fill: parent
            spacing: 2

            Item{
                Layout.fillWidth: true
            }

            FluText {
                id: text_language
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 20
                wrapMode: Text.WordWrap
                text: root.getLanguageData(root.languageId) ? root.getLanguageData(root.languageId).name : ""
            }


            FluIcon {
                id: language_icon
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                iconSource:FluentIcons.ChevronDown
                iconSize: 15
            }
        }

        MouseArea{
            anchors.fill: parent
            onClicked: {
                var controlPosInRoot = control.mapToItem(root, 0, 0);

                // 计算 popup 的 x 坐标，使其在 rootItem 坐标系下居中
                var popupXInRoot = controlPosInRoot.x + (control.width - popup.width) / 2
                var popupYInRoot = controlPosInRoot.y + control.height + 16

                popup.x = popupXInRoot
                popup.y = popupYInRoot
                popup.open()
            }
        }
    }

    FluPopup{
        id: popup
        width: 120
        height: 600
        parent: control
        closePolicy: Popup.CloseOnPressOutside
        z: 100

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: root.languageModel

                delegate: Rectangle {
                    id: menuItem
                    width: parent.width
                    height: 32
                    color: mouseArea.containsMouse ? "#e0e0e0" : (index === root.currentIndex ? "#c4dcfe" : "transparent")
                    border.color: "transparent"


                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        // Image {
                        //     Layout.preferredWidth: 24
                        //     Layout.preferredHeight: 16
                        //     Layout.alignment: Qt.AlignVCenter
                        //     Layout.leftMargin: 14
                        //     source: modelData.icon
                        // }

                        FluText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 20
                            wrapMode: Text.WordWrap
                            text: modelData.name
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (root.currentIndex === index) {
                                return
                            }

                            menuSelected(modelData.flag)
                            popup.close()
                        }

                        states: [
                            State {
                                when: mouseArea.containsMouse && root.currentIndex !== index
                                PropertyChanges {
                                    target: menuItem
                                    color: "#e0e0e0"
                                }
                            },
                            State {
                                when: root.currentIndex === index
                                PropertyChanges {
                                    target: menuItem
                                    color: "#c4dcfe"
                                }
                            }
                        ]

                        transitions: [
                            Transition {
                                ColorAnimation {
                                    properties: "color"
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }
                        ]
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
