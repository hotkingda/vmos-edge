import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Templates as T
import FluentUI

T.CheckBox {
    id: control
    property int fontSize: 12
    property color textColor: ThemeUI.primaryColor
    property string selectedImage: ThemeUI.loadRes("common/checkbox_selected.png")
    property string unselectedImag: ThemeUI.loadRes("common/checkbox_unselected.png")
    property string partialSelectedImage: ThemeUI.loadRes("common/checkbox_part_selected.png")
    property string tooltip: ""
    // 可选：最大内容宽度，若未指定则按实际宽度裁剪
    property int maxWidth: -1
    spacing: 5
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    implicitWidth: indicatorImg.width + spacing + label.implicitWidth
    implicitHeight: Math.max(indicator.height, label.implicitHeight)

    // 关闭模板默认的指示器，使用自定义的图片指示器
    indicator: Item { width: 0; height: 0; visible: false }

    contentItem: Item {
        id: contentRoot
        // 让“勾选框+文本”整体在控件内水平/垂直居中
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // 固定使用控件可用宽度，内部再决定文本占用，防止名字过长将外层撑破
        width: (control.maxWidth >= 0 ? control.maxWidth : control.width)
        height: Math.max(indicatorImg.height, label.implicitHeight)

        Row {
            id: row
            spacing: control.spacing
            anchors.centerIn: parent

            Image {
                id: indicatorImg
                width: 16
                height: 16
                source: control.checkState === Qt.Checked
                        ? selectedImage
                        : (control.checkState === Qt.PartiallyChecked
                           ? partialSelectedImage
                           : unselectedImag)
            }

            FluText {
                id: label
                text: control.text
                font.pixelSize: control.fontSize
                elide: Text.ElideRight
                // 固定与勾选框的间距后，剩余宽度用来显示文本
                width: Math.max(0, Math.min(label.implicitWidth, contentRoot.width - indicatorImg.width - row.spacing))
                clip: true
                color: control.textColor
            }
        }

        FluTooltip{
            visible: control.tooltip && control.hovered
            text: control.tooltip
            delay: 1000
        }
    }
}


