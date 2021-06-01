/**
 * SPDX-FileCopyrightText: 2021 Wang Rui <wangrui@jingos.com>
 *                         
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.10
import QtQuick.Window 2.2

import org.kde.kirigami 2.15 as Kirigami
import org.kde.kcm 1.2

import org.kde.bluezqt 1.0 as BluezQt
import QtBluetooth 5.2
import org.kde.plasma.private.bluetooth 1.0

Item {

    id: root

    property int appFontSize: theme.defaultFont.pointSize
    property bool isBluetoothOn: !BluezQt.Manager.bluetoothBlocked
    property QtObject manager: BluezQt.Manager
    property int devicesCount: manager.devices.length
    property int adaptersCount: manager.adapters.length
    property BluetoothService currentService

    function setBluetoothEnabled(enabled) {
        BluezQt.Manager.bluetoothBlocked = !enabled
        for (var i = 0; i < BluezQt.Manager.adapters.length; ++i) {
            var adapter = BluezQt.Manager.adapters[i]
            adapter.powered = enabled
        }
        if (enabled) {
            //scanner.startScaner()
        }
    }

    Connections {
        target: kcm

        onLocalDeviceNameChanged: {
            recent_tags.text = localDeviceName
        }
    }

    Component.onCompleted: {
    }

    Rectangle {
        anchors.fill: parent

        color: "#FFF6F9FF"

        Text {
            id: blue_title

            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 20 * appScale
                topMargin: 48 * appScale
            }

            width: 360
            height: 20 * appScale
            
            text: i18n("Bluetooth")
            font.pixelSize: 20
            font.bold: true
        }

        Rectangle {
            id: blue_switch_area

            anchors {
                left: parent.left
                top: blue_title.bottom
                leftMargin: 20 * appScale
                right: parent.right
                rightMargin: 20 * appScale
                topMargin: 18 * appScale
            }

            width: parent.width - 40 * appScale
            height: !bt_switch.checked ? 45 * appScale : 2 * 45 * appScale

            color: "white"
            radius: 10 * appScale

            Rectangle {
                id: bt_switch_item

                width: parent.width
                height: 45 * appScale //parent.height

                color: "transparent"

                Text {
                    id: bt_title

                    anchors {
                        left: parent.left
                        leftMargin: 20 * appScale
                        verticalCenter: parent.verticalCenter
                    }

                    text: i18n("Bluetooth")
                    font.pixelSize: 14
                }

                Kirigami.JSwitch {
                    id: bt_switch

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: 20 * appScale
                    }

                    checked: isBluetoothOn
                    checkable: true

                    onCheckedChanged: {
                        if (!checked && BluezQt.Manager.bluetoothOperational) {
                            bt_root.connectedAdress = ""
                            root.setBluetoothEnabled(false)
                            devicesProxyModel.removeConnectedName()
                        }

                        if (checked && BluezQt.Manager.operational
                                && !BluezQt.Manager.bluetoothOperational) {
                            root.setBluetoothEnabled(true)
                            if (checked
                                    && devicesProxyModel.connectedAdress != "") {

                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                id: sepatatooLine

                anchors {
                    top: bt_switch_item.bottom
                    left: parent.left
                    right: parent.right
                    rightMargin: 20 * appScale
                    leftMargin: 20 * appScale
                }

                width: parent.width
                height: 1

                visible: bt_switch.checked
                color: "#FFE5E5EA"
            }

            Rectangle {
                id: recent_title_layout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: sepatatooLine.bottom
                }

                height: 45 * appScale

                visible: bt_switch.checked
                color: "transparent"

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 20 * appScale
                        verticalCenter: parent.verticalCenter
                    }

                    text: i18n("Device Name")
                    font.pixelSize: 14
                    color: "black"
                }

                Text {
                    id: recent_tags

                    anchors {
                        right: image_edit.left
                        rightMargin: 9 * appScale
                        verticalCenter: parent.verticalCenter
                    }

                    width: parent.width / 3

                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    text: kcm.localDeviceName
                    font.pointSize: appFontSize + 2
                    color: "black"
                }

                Image {
                    id: image_edit

                    anchors {
                        right: parent.right
                        rightMargin: 17 * appScale
                        verticalCenter: parent.verticalCenter
                    }

                    width: 22 * appScale
                    height: 22 * appScale

                    source: "../image/edit_name.png"
                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            editDialog.inputText = recent_tags.text
                            editDialog.visible = true
                            editDialog.forceActiveFocus()
                            editDialog.focus = true
                        }
                    }
                }
            }
        }

        Rectangle {
            id: device_list_layout

            height: scanner.lvHeight - 1
            width: parent.width

            radius: 10 * appScale
            visible: isBluetoothOn

            anchors {
                top: blue_switch_area.bottom
                topMargin: 24 * appScale
                left: blue_switch_area.left
                right: blue_switch_area.right
            }

            JScanner {
                id: scanner
            }
        }
    }

    Kirigami.JDialog {
        id: editDialog

        title: i18n("Device Name")
        text: i18n("Other devices will see this name when you use Bluetooth,WLAN Direct,Personal hotspot and USB.")
        inputEnable: true
        showPassword: false
        leftButtonText: i18n("Cancel")
        rightButtonText: i18n("Ok")

        onRightButtonClicked: {
            if (editDialog.inputText.length != 0) {
                kcm.setLocalDeviceName(editDialog.inputText)
            }
            editDialog.visible = false
        }
        
        onLeftButtonClicked: {
            editDialog.visible = false
        }
    }
}
