import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI
import Utils

Item {
    id: root
    implicitWidth: 1000
    implicitHeight: 800

    signal goBack()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            FluIconButton {
                iconSource: FluentIcons.ChevronLeft
                display: Button.TextBesideIcon
                iconSize: 13
                text: qsTr("返回")

                onClicked: {
                    root.goBack()
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            radius: 10

            ScrollView {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                ScrollBar.vertical.interactive: false
                ScrollBar.horizontal.interactive: false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    spacing: 30

                    FluText {
                        text: qsTr("云机窗口初始化大小设置（设备按9:16比例自适应调整大小）")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        spacing: 20

                        ButtonGroup {
                            id: windowSizeGroup
                            exclusive: true
                            buttons: windowSizeRow.children
                        }

                        Row {
                            id: windowSizeRow
                            spacing: 20

                            VCheckBox {
                                text: qsTr("大窗口（宽480）")
                                textColor: ThemeUI.blackColor
                                checked: 0 == SettingsHelper.get("windowSize", 1)
                                onClicked: {
                                    SettingsHelper.save("windowSize", 0)
                                }
                            }
                            VCheckBox {
                                text: qsTr("中窗口（宽320）")
                                textColor: ThemeUI.blackColor
                                checked: 1 == SettingsHelper.get("windowSize", 1)
                                onClicked: {
                                    SettingsHelper.save("windowSize", 1)
                                }
                            }
                            VCheckBox {
                                text: qsTr("小窗口（宽160）")
                                textColor: ThemeUI.blackColor
                                checked: 2 == SettingsHelper.get("windowSize", 1)
                                onClicked: {
                                    SettingsHelper.save("windowSize", 2)
                                }
                            }
                            VCheckBox {
                                text: qsTr("自定义")
                                textColor: ThemeUI.blackColor
                                checked: 3 == SettingsHelper.get("windowSize", 1)
                                onClicked: {
                                    SettingsHelper.save("windowSize", 3)
                                }
                            }
                        }

                        FluText {
                            text: qsTr("宽")
                        }

                        TextField {
                            id: textFieldWidth
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: SettingsHelper.get("customWidth", 160)
                            color: "black"
                            background: Rectangle {
                                color: "white"
                                border.width: 1
                                border.color: "#fff5f6fa"
                                radius: 4
                            }
                            validator: IntValidator {
                                top: 9999
                                bottom: 160
                            }
                            onTextChanged: {
                                if (activeFocus && text !== "") {
                                    console.log("width ", text)
                                    textFieldHeight.text = Math.round(Number(text) / (9.0 / 16.0))
                                    SettingsHelper.save("customWidth", text)
                                    SettingsHelper.save("customHeight", textFieldHeight.text)
                                }
                            }
                        }
                        FluText {
                            text: "*"
                            color: "red"
                        }
                        FluText {
                            text: qsTr("高")
                        }
                        TextField {
                            id: textFieldHeight
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: SettingsHelper.get("customHeight", 284)
                            color: "black"
                            background: Rectangle {
                                color: "white"
                                border.width: 1
                                border.color: "#fff5f6fa"
                                radius: 4
                            }
                            validator: IntValidator {
                                top: 9999
                                bottom: 284
                            }
                            onTextChanged: {
                                if (activeFocus && text !== "") {
                                    console.log("height ", text)
                                    textFieldWidth.text = Math.round(Number(text) * (9.0 / 16.0))
                                    SettingsHelper.save("customWidth", textFieldWidth.text)
                                    SettingsHelper.save("customHeight", text)
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        height: 1
                        color: "#e0e0e0"
                        Layout.fillWidth: true
                    }

                    FluText {
                        text: qsTr("云机窗口修改大小设置")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    ButtonGroup {
                        id: windowModifyGroup
                        exclusive: true
                        buttons: windowModifyRow.children
                    }

                    Row {
                        id: windowModifyRow
                        spacing: 20

                        VCheckBox {
                            text: qsTr("记录上次")
                            textColor: ThemeUI.blackColor
                            checked: 0 == SettingsHelper.get("windowModify", 1)
                            onClicked: {
                                SettingsHelper.save("windowModify", 0)
                            }
                        }
                        VCheckBox {
                            text: qsTr("保持不变")
                            textColor: ThemeUI.blackColor
                            checked: 1 == SettingsHelper.get("windowModify", 1)
                            onClicked: {
                                SettingsHelper.save("windowModify", 1)
                            }
                        }
                    }

                    Rectangle {
                        height: 1
                        color: "#e0e0e0"
                        Layout.fillWidth: true
                    }

                    FluText {
                        text: qsTr("关闭主面板时")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    ButtonGroup {
                        id: exitAppGroup
                        exclusive: true
                        buttons: exitAppRow.children
                    }

                    Row {
                        id: exitAppRow
                        spacing: 20

                        VCheckBox {
                            text: qsTr("退出程序")
                            textColor: ThemeUI.blackColor
                            checked: 0 == SettingsHelper.get("exitApp", 0)
                            onClicked: {
                                SettingsHelper.save("exitApp", 0)
                            }
                        }
                        VCheckBox {
                            text: qsTr("最小化托盘")
                            textColor: ThemeUI.blackColor
                            checked: 1 == SettingsHelper.get("exitApp", 0)
                            onClicked: {
                                SettingsHelper.save("exitApp", 1)
                            }
                        }
                    }

                    Rectangle {
                        visible: false
                        height: 1
                        color: "#e0e0e0"
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}

