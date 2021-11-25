/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Liu Bangguo <liubangguo@jingos.com>
 *
 */

 
import QtQuick 2.0
import QtQuick.Controls 2.5
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Layouts 1.11
import jingos.display 1.0

Rectangle {
    id: detail

    property var address
    property var name
    property bool isConnected
    property bool isRemoving: false
    property bool isDisconnecting: false
    property var deviceType
    property bool supportDisconnect: deviceType == 0 | deviceType == 2 | deviceType == 5

    anchors.fill: parent

    color: settingMinorBackground

    Connections {
        target: kcm

        onRemoveDeviceFinishedToQml: {
            isRemoving = false
            popView()
        }

        onDisconnectDeviceFinishedToQml: {
            isDisconnecting = false
            popView()
        }
    }

    Item {
        id: tile

        anchors {
            left: parent.left
            leftMargin: 20 * appScaleSize
            right: parent.right
            rightMargin:  20 * appScaleSize
            top: parent.top
            topMargin:  JDisplay.statusBarHeight
        }

        width: parent.width //childrenRect.width
        height: 62 * appScaleSize
        Item {
            width: parent.width
            height: icon_back.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 6 * appScaleSize
            Kirigami.JIconButton {
                id: icon_back

                width: (22 + 8) * appScaleSize
                height: (22 + 8) * appScaleSize

                source: isDarkTheme ? Qt.resolvedUrl("../image/icon_back_dark.png") : Qt.resolvedUrl("../image/icon_back.png")

                onClicked: {
                    popView()
                }
            }

            Text {
                anchors.left: icon_back.right
                anchors.leftMargin: 10 * appScaleSize
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true

                font.pixelSize: 20 * appFontSize
                text: detail.name
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                color: majorForeground
            }
        }
    }

    Rectangle {
        id: nameRect

        anchors {
            top: tile.bottom
            left: parent.left
            right: parent.right
            leftMargin: 20 * appScaleSize
            rightMargin: 20 * appScaleSize
            topMargin: 11 * appScaleSize
        }

        height: 45 * appScaleSize
        radius: 10 * appScaleSize

        color: cardBackground

        Item {
            anchors.left: parent.left
            anchors.right: parent.right

            width: parent.width
            height: 45 * appScaleSize

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScaleSize
                }

                text: i18n("Name")
                font.pixelSize: 14 * appFontSize
                color: majorForeground
            }

            Text {
                anchors {
                    right: edit_name.left
                    verticalCenter: parent.verticalCenter
                    rightMargin: 25 * appScaleSize
                }

                width: parent.width / 3

                text: detail.name
                font.pixelSize: 14 * appFontSize
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                color: isDarkTheme ? "#8CF7F7F7" : "#99000000"
            }

            Image {
                id: edit_name

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 20 * appScaleSize
                }

                width: 22 * appScaleSize
                height: 22 * appScaleSize

                source: "../image/edit_name.png"

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        inputDialog.inputText = detail.name
                        inputDialog.visible = true
                        inputDialog.forceActiveFocus()
                    }
                }
            }
        }
    }

    Rectangle {
        anchors {
            top: nameRect.bottom
            left: parent.left
            right: parent.right
            topMargin: 24 * appScaleSize
            leftMargin: 20 * appScaleSize
            rightMargin: 20 * appScaleSize
        }

        height: isConnected && supportDisconnect ? 90 * appScaleSize : 45 * appScaleSize

        radius: 10 * appScaleSize
        color: cardBackground

        Item {
            id: state

            width: parent.width
            height: isConnected && supportDisconnect ? 45 * appScaleSize : 0

            visible: isConnected && supportDisconnect

            Text {
                id: disconnectText

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScaleSize
                }

                text: i18n("Disconnect")
                color: highlightColor
                font.pixelSize: 14 * appFontSize
            }

            Image {
                id: disconnectingState

                anchors {
                    left: disconnectText.right
                    leftMargin: 10 * appScaleSize
                    verticalCenter: parent.verticalCenter
                }

                width: 22 * appScaleSize
                height: 22 * appScaleSize

                visible: isDisconnecting
                source: "../image/scan.png"

                RotationAnimation {
                    target: disconnectingState
                    loops: Animation.Infinite
                    running: true
                    from: 0
                    to: 360
                    duration: 3000
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 20 * appScaleSize
                    rightMargin: 20 * appScaleSize
                    bottom: parent.bottom
                }

                width: parent.width
                height: 1

                color: dividerForeground
                visible: isConnected
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    devicesProxyModel.removeConnectedName()
                    bt_root.connectedAdress = ""
                    isDisconnecting = true
                    kcm.deviceDisconnect(address, false)
                }
            }
        }

        Item {
            anchors.top: state.bottom

            width: parent.width
            height: 45 * appScaleSize

            Text {
                id: removeText

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScaleSize
                }

                text: i18n("Forget This Device")
                color: highlightColor
                font.pixelSize: 14 * appFontSize
            }

            Image {
                id: removingState

                anchors {
                    left: removeText.right
                    leftMargin: 10 * appScaleSize
                    verticalCenter: parent.verticalCenter
                }

                width: 22 * appScaleSize
                height: 22 * appScaleSize

                visible: isRemoving
                source: "../image/scan.png"

                RotationAnimation {
                    target: removingState
                    loops: Animation.Infinite
                    running: true
                    from: 0
                    to: 360
                    duration: 3000
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    deleteDialog.visible = true
                }
            }
        }
    }


    /*JInputDialog{
        id:inputDialog

        focus: true
        title: i18n("Name")
        echoMode: TextInput.Normal

        onCancelButtonClicked: {
            inputDialog.visible = false
        }


        onOkButtonClicked: {
            kcm.setName(address,inputDialog.inputText)
            detail.name = inputDialog.inputText
            inputDialog.visible = false
        }
        onEnteredClick: {
            kcm.setName(address,inputDialog.inputText)
            detail.name = inputDialog.inputText
            inputDialog.visible = false
        }
    }*/

    Kirigami.JDialog {
        id: inputDialog

        title: i18n("Rename")
        inputEnable: true
        text: "blank"
        showPassword: false
        leftButtonText: i18n("Cancel")
        rightButtonText: i18n("OK")
        textItem: textItem

        onInputTextChanged:{
            if(inputText.length > 32){
                inputDialog.inputText = inputText.substring(0,32)
            }
        }
        
        onRightButtonClicked: {
            if (inputDialog.inputText.length != 0) {
                kcm.setName(address, inputDialog.inputText)
                detail.name = inputDialog.inputText
            }
            inputDialog.visible = false
        }

        onLeftButtonClicked: {
            inputDialog.visible = false
        }
    }

    Component {
        id: textItem

        Item {
            width: 1
            height: 15
        }
    }

    Kirigami.JDialog {
        id: deleteDialog

        title: i18n("Forget Device")
        inputEnable: false
        text: i18n("Are you sure you want to Forget this Device?")
        leftButtonText: i18n("Cancel")
        rightButtonText: i18n("Forget")
        rightButtonTextColor: "#FF3C4BE8"

        onRightButtonClicked: {
            isRemoving = true
            devicesProxyModel.removeConnectedName()
            bt_root.connectedAdress = ""
            kcm.deviceRemoved(address)
            bt_root.connectedName = ""
            deleteDialog.visible = false
        }

        onLeftButtonClicked: {
            deleteDialog.visible = false
        }
    }
}
