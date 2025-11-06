import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import FluentUI

FluPopup {
    id: control
    property string title: ""
    property string message: ""
    property string neutralText: qsTr("Close")
    property string negativeText: qsTr("Cancel")
    property string positiveText: qsTr("OK")
    property int messageTextFormat: Text.AutoText
    property int delayTime: 100
    property int buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
    property var contentDelegate: Component { Item {} }
    property var onNeutralClickListener
    property var onNegativeClickListener
    property var onPositiveClickListener

    signal neutralClicked
    signal negativeClicked
    signal positiveClicked

    implicitWidth: 320
    implicitHeight: layout_content.height
    focus: true

    Rectangle {
        id: layout_content
        width: parent.width
        height: layout_column.implicitHeight
        color: 'transparent'
        radius: 5

        ColumnLayout {
            id: layout_column
            width: parent.width
            spacing: 0

            FluText {
                id: text_title
                font: FluTextStyle.Subtitle
                text: title
                topPadding: 20
                leftPadding: 20
                rightPadding: 20
                bottomPadding: message === "" ? 20 : 4
                wrapMode: Text.WordWrap
                visible: title !== ""
                Layout.fillWidth: true
            }

            Flickable {
                id: scroll_message
                Layout.fillWidth: true
                Layout.preferredHeight: {
                    if (message === "") return 0;
                    return Math.min(text_message.implicitHeight, 300);
                }
                contentHeight: text_message.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: message !== ""
                ScrollBar.vertical: FluScrollBar {}

                FluText {
                    id: text_message
                    width: layout_column.width
                    font: FluTextStyle.Body
                    wrapMode: Text.WordWrap
                    text: message
                    textFormat: control.messageTextFormat
                    topPadding: 4
                    leftPadding: 20
                    rightPadding: 20
                    bottomPadding: 20
                }
            }

            Loader {
                id: content_loader
                Layout.fillWidth: true
                sourceComponent: contentDelegate
            }

            Rectangle {
                id: layout_actions
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 5
                // color: FluTheme.dark ? Qt.rgba(32/255, 32/255, 32/255, 1) : Qt.rgba(243/255, 243/255, 243/255, 1)

                RowLayout {
                    anchors {
                        centerIn: parent
                        margins: spacing
                        fill: parent
                    }
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        visible: control.buttonFlags & FluContentDialogType.NeutralButton
                        FluButton {
                            id: neutral_btn
                            visible: control.buttonFlags & FluContentDialogType.NeutralButton
                            text: neutralText
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent
                            onClicked: {
                                if (control.onNeutralClickListener) {
                                    control.onNeutralClickListener();
                                } else {
                                    neutralClicked();
                                    control.close();
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        visible: control.buttonFlags & FluContentDialogType.NegativeButton
                        FluButton {
                            id: negative_btn
                            visible: control.buttonFlags & FluContentDialogType.NegativeButton
                            width: parent.width
                            height: parent.height
                            anchors.centerIn: parent
                            text: negativeText
                            onClicked: {
                                if (control.onNegativeClickListener) {
                                    control.onNegativeClickListener();
                                } else {
                                    negativeClicked();
                                    control.close();
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        visible: control.buttonFlags & FluContentDialogType.PositiveButton
                        FluFilledButton {
                            id: positive_btn
                            visible: control.buttonFlags & FluContentDialogType.PositiveButton
                            text: positiveText
                            width: parent.width
                            height: parent.height
                            normalColor: ThemeUI.primaryColor
                            anchors.centerIn: parent
                            onClicked: {
                                if (control.onPositiveClickListener) {
                                    control.onPositiveClickListener();
                                } else {
                                    positiveClicked();
                                    control.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
