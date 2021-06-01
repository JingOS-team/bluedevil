/**
 * SPDX-FileCopyrightText: 2021 Wang Rui <wangrui@jingos.com>
 *                         
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */
 
import QtQuick 2.0
import QtQuick.Controls 2.5
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Layouts 1.11

Rectangle {
    id: detail

    property var address
    property var name
    property bool isConnected
    property bool isRemoving: false
    property bool isDisconnecting: false

    anchors.fill: parent

    color: "#FFF6F9FF"

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
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 48 * appScale
            leftMargin: 14 * appScale
            rightMargin: 20 * appScale
        }

        width: parent.width
        height: 20 * appScale

        Image {
            id: icon_back
            
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            width: 22 * appScale
            height: 22 * appScale

            source: "../image/icon_back.png"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    popView()
                }
            }
        }

        Text {
            anchors.left: icon_back.right
            anchors.leftMargin: 10 * appScale
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width / 2

            font.bold: true
            font.pixelSize: 20
            text: detail.name
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
        }
    }

    Rectangle {
        id: nameRect

        anchors {
            top: tile.bottom
            left: parent.left
            right: parent.right
            leftMargin: 20 * appScale
            rightMargin: 20 * appScale
            topMargin: 18 * appScale
        }

        height: 45 * appScale
        radius: 10 * appScale

        color: "white"

        Item {
            anchors.left: parent.left
            anchors.right: parent.right

            width: parent.width
            height: 45 * appScale

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScale
                }

                text: i18n("Name")
                font.pixelSize: 14
            }

            Text {
                anchors {
                    right: edit_name.left
                    verticalCenter: parent.verticalCenter
                    rightMargin: 25 * appScale
                }

                width: parent.width / 3

                text: detail.name
                font.pixelSize: 14
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }

            Image {
                id: edit_name

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 20 * appScale
                }

                width: 22 * appScale
                height: 22 * appScale

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
            topMargin: 24 * appScale
            leftMargin: 20 * appScale
            rightMargin: 20 * appScale
        }

        height: isConnected ? 90 * appScale : 45 * appScale

        radius: 10 * appScale
        color: "white"

        Item {
            id: state

            width: parent.width
            height: isConnected ? 45 * appScale : 0

            visible: isConnected

            Text {
                id: disconnectText

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScale
                }

                text: i18n("Disconnect")
                color: "#FF3C4BE8"
                font.pixelSize: 14
            }

            Image {
                id: disconnectingState

                anchors {
                    left: disconnectText.right
                    leftMargin: 10 * appScale
                    verticalCenter: parent.verticalCenter
                }

                width: 22 * appScale
                height: 22 * appScale

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
                    leftMargin: 20 * appScale
                    rightMargin: 20 * appScale
                    bottom: parent.bottom
                }

                width: parent.width
                height: 1

                color: "#FFE5E5EA"
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
            height: 45 * appScale

            Text {
                id: removeText

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20 * appScale
                }

                text: i18n("Forget This Device")
                color: "#FF3C4BE8"
                font.pixelSize: 14
            }

            Image {
                id: removingState

                anchors {
                    left: removeText.right
                    leftMargin: 10 * appScale
                    verticalCenter: parent.verticalCenter
                }

                width: 22 * appScale
                height: 22 * appScale

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
        rightButtonText: i18n("Ok")
        textItem: textItem

        onRightButtonClicked: {
            if (inputDialog.inputText.length != 0) {
                kcm.setName(address, inputDialog.inputText)
                detail.name = inputDialog.inputText
                inputDialog.visible = false
            }
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
