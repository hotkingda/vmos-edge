import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI
import Utils

Rectangle {
    id: root
    implicitWidth: 1000
    implicitHeight: 800

    readonly property var itemWidth: [120.00, 120.00, 80.00, 80.00, 120.00, 280.00]
    readonly property int itemTotalWidth: itemWidth.reduce((acc, cur) => acc + cur, 0)
    LevelProxyModel{
        id: hostModel
        level: 2
        sourceModel: treeModel
    }

    signal openDetail(string hostIp)
    signal openBatchMenu(var hostList, var button)
    signal openReset(string hostIp)
    signal openReboot(string hostIp)
    signal openClean(string hostIp)
    signal openDelete(string hostIp)

    ColumnLayout{
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        RowLayout{
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 10

            // Rectangle{
            //     Layout.preferredWidth: 280
            //     Layout.preferredHeight: 32
            //     Layout.alignment: Qt.AlignVCenter
            //     radius: 4
            //     border.width: 1
            //     border.color: "#dcdcdc"
            //     color: "white"

            //     RowLayout{
            //         anchors.fill: parent
            //         anchors.leftMargin: 10
            //         anchors.rightMargin: 4

            //         FluTextBox {
            //             id: search_input
            //             Layout.fillWidth: true
            //             Layout.fillHeight: true
            //             Layout.alignment: Qt.AlignVCenter
            //             placeholderText: qsTr("输入主机ID/IP")
            //             placeholderTextColor: "gray"
            //             color: "black"
            //             background: Item{}
            //             onTextChanged: {
            //                 hostModel.setFilterText(search_input.text)
            //             }
            //         }

            //         Image{
            //             Layout.preferredWidth: 20
            //             Layout.alignment: Qt.AlignVCenter
            //             source: "qrc:/res/main/btn_search1.png"
            //         }
            //     }
            // }


            SearchTextField {
                id: filterTextField
                Layout.preferredHeight: 32
                Layout.preferredWidth: 280
                placeholderText: qsTr("输入主机ID、IP")
                onSearchTextChanged: function(text) {
                    hostModel.setFilterText(filterTextField.text)
                }
            }

            FluText{
                text: qsTr("主机状态")
            }

            FluComboBox{
                Layout.preferredWidth: 150
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                model: [qsTr("全部"), qsTr("在线"), qsTr("离线")]
                onCurrentIndexChanged: {
                    if(currentIndex == 0){
                        hostModel.setFilterState("")
                    }else if(currentIndex == 1){
                        hostModel.setFilterState("online")
                    }else if(currentIndex == 2){
                        hostModel.setFilterState("offline")
                    }
                }
            }

            IconButton {
                id: btnBatch
                backgroundColor: "white"
                borderColor: "lightgray"
                borderRadius: 16
                borderSize: 1
                textColor: "black"
                iconSource: "qrc:/res/icon/icon_batch.png"
                text: qsTr("批量操作")
                onClicked: {
                    const hostList = hostModel.getHostList()
                    openBatchMenu(hostList, btnBatch)
                    // menuBatch.x = -(menuBatch.width - btnBatch.width) / 2
                    // menuBatch.y = 40
                    // menuBatch.open()
                }
            }

            // Rectangle{
            //     Layout.preferredHeight: 32
            //     Layout.preferredWidth: 150
            //     border.color: "#eee"
            //     border.width: 1
            //     radius: 4

            //     RowLayout{
            //         anchors.fill: parent
            //         anchors.leftMargin: 10

            //         spacing: 10

            //         FluText{
            //             text: qsTr("批量操作")
            //         }

            //         FluIcon{
            //             iconSource: FluentIcons.ChevronDown
            //             iconSize: 14
            //         }
            //     }

            //     MouseArea{
            //         anchors.fill: parent
            //         onClicked: {

            //         }
            //     }
            // }

            Item {
                Layout.fillWidth: true
            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#fafafa"
            border.color: "#e0e0e0"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10;
                anchors.rightMargin: 10;
                spacing: 5

                VCheckBox {
                    id: selectAllBox
                    Layout.preferredWidth: 30
                    checked: hostModel.isSelectAll
                    onClicked: {
                        hostModel.selectAll(checked)
                    }
                }

                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[0] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("主机ID");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }

                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[1] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("主机IP");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }
                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[2] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("状态");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }
                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[3] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("实例数");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }
                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[4] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("更新时间");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }
                Item{
                    Layout.fillHeight: true
                    Layout.preferredWidth: listView.width * itemWidth[5] / itemTotalWidth
                    // border.width: 1
                    FluText {
                        text: qsTr("操作");
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                    }
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: hostModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            delegate: Rectangle {
                width: listView.width
                height: 50
                color: "transparent"
                border.color: "#e0e0e0"
                border.width: 1

                // 顶层覆盖层，保留边框1px
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: mouseArea.containsMouse ? "#26000000" : "transparent"
                    z: 999
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 5

                    VCheckBox {
                        Layout.preferredWidth: 30
                        checked: model?.selected ?? false
                        onClicked: {
                            if(model.selected !== checked){
                                model.selected = checked
                            }
                        }
                    }

                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[0] / itemTotalWidth
                        // border.width: 1
                        FluText {
                            text: model.hostId ?? ""
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea{
                                anchors.fill: parent

                                onClicked: {
                                    FluTools.clipText(model?.hostId ?? "")
                                    showSuccess(qsTr("复制成功"))
                                }
                            }
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[1] / itemTotalWidth
                        // border.width: 1

                        RowLayout{
                            anchors.fill: parent
                            spacing: 6

                            FluText {
                                text: model?.ip ?? ""

                                MouseArea{
                                    anchors.fill: parent

                                    onClicked: {
                                        FluTools.clipText(model?.ip ?? "")
                                        showSuccess(qsTr("复制成功"))
                                    }
                                }
                            }

                            Image {
                                source: "qrc:/res/main/host_link.svg"
                                Layout.preferredHeight: 12
                                Layout.preferredWidth: 12
                                MouseArea{
                                    anchors.fill: parent

                                    onClicked: {
                                        Qt.openUrlExternally(qsTr("http://%1:18182/docs").arg(model?.ip ?? ""))
                                    }
                                }
                            }

                            Item{
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[2] / itemTotalWidth
                        // border.width: 1
                        Rectangle{
                            width: 42
                            height: 22
                            border.color: AppUtils.getStateColorBystate(model.state).border
                            border.width: 1
                            color: AppUtils.getStateColorBystate(model.state).bg
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2

                            FluText {
                                anchors.centerIn: parent
                                text: AppUtils.getStateStringBystate(model.state)
                                color: AppUtils.getStateColorBystate(model.state).text
                                font.pixelSize: 12
                            }
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[3] / itemTotalWidth
                        // border.width: 1

                        FluText {
                            text: model?.hostPadCount ?? 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[4] / itemTotalWidth
                        // border.width: 1
                        FluText {
                            text: model?.updateTime ?? ""
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.preferredWidth: listView.width * itemWidth[5] / itemTotalWidth
                        // border.width: 1
                        RowLayout{
                            anchors.verticalCenter: parent.verticalCenter
                            TextButton {
                                text: qsTr("详情")
                                textColor: "white"
                                // Layout.preferredWidth: 70
                                enabled: model.state === "online"
                                onClicked: {
                                    if(model.state !== "online"){
                                        showError(qsTr("主机") + AppUtils.getStateStringBystate(model.state))
                                        return
                                    }
                                    openDetail(model?.ip ?? "")
                                }
                            }

                            TextButton{
                                text: qsTr("重启")
                                textColor: "white"
                                // Layout.preferredWidth: 70
                                enabled: model.state === "online"
                                onClicked: {
                                    if(model.state !== "online"){
                                        showError(qsTr("主机") + AppUtils.getStateStringBystate(model.state))
                                        return
                                    }
                                    openReboot(model?.ip ?? "")
                                }
                            }

                            TextButton{
                                text: qsTr("重置")
                                textColor: "white"
                                // Layout.preferredWidth: 70
                                enabled: model.state === "online"
                                onClicked: {
                                    if(model.state !== "online"){
                                        showError(qsTr("主机") + AppUtils.getStateStringBystate(model.state))
                                        return
                                    }

                                    openReset(model?.ip ?? "")
                                }
                            }

                            TextButton{
                                text: qsTr("清理镜像")
                                textColor: "white"
                                // Layout.preferredWidth: 80
                                enabled: model.state === "online"
                                onClicked: {
                                    if(model.state !== "online"){
                                        showError(qsTr("主机") + AppUtils.getStateStringBystate(model.state))
                                        return
                                    }
                                    openClean(model?.ip ?? "")
                                }
                            }

                            TextButton{
                                text: qsTr("删除")
                                textColor: "white"
                                backgroundColor: "#f06969"
                                // Layout.preferredWidth: 100
                                visible: model.state === "offline"
                                onClicked: {
                                    if(model.state !== "offline"){
                                        showError(qsTr("主机") + AppUtils.getStateStringBystate(model.state))
                                        return
                                    }
                                    openDelete(model?.hostId ?? "")
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}
