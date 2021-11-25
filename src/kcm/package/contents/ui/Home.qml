/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Liu Bangguo <liubangguo@jingos.com>
 *
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
import jingos.display 1.0
Item {
    id: root

    property bool isBluetoothOn: !BluezQt.Manager.bluetoothBlocked && isAdapterPowered()
    property QtObject manager: BluezQt.Manager
    property int devicesCount: manager.devices.length
    property int adaptersCount: manager.adapters.length
    property BluetoothService currentService
    property var isCurrentConnectting: false
    property bool bluetoothOffMask: false

    function isAdapterPowered() {
        var adapter = BluezQt.Manager.adapters[0]
        var isPowered = adapter.powered
        return isPowered;
    }

    function setBluetoothEnabled(enabled) {
        //BluezQt.Manager.bluetoothBlocked = !enabled
        if(enabled && BluezQt.Manager.bluetoothBlocked){
            BluezQt.Manager.bluetoothBlocked = false
        }
        if(!enabled){
            //isCurrentConnectting = true
            bluetoothOffMask = true
        }

        for (var i = 0; i < BluezQt.Manager.adapters.length; ++i) {
            var adapter = BluezQt.Manager.adapters[i]
            adapter.powered = enabled
        }
        //if (enabled) {
        //    //scanner.startScaner()
        //    timer.running = true
        //}
    }

    Connections {
        target: kcm

        onCurrentIndexChanged:{
            if(index == 1){
                recent_tags.text = kcm.getLocalDeviceName();
                bt_root.popAllView();
            }
        }
    }

    onVisibleChanged: {
        kcm.setAdatporDiscovery(visible);
        kcm.setAdatporCoverable(visible);
    }




    Timer {
        id: timer

        interval: 500
        repeat: false
        running: false

        onTriggered: {
           //kcm.setAdatporCoverable(true)
        }
    }

    Connections {
        target: kcm

        onLocalDeviceNameChanged: {
            recent_tags.text = localDeviceName
        }
        onPoweredChangedToQml: {
            if(!powered){

            }
            bluetoothOffMask = false
            //isCurrentConnectting = false

            if(powered){
                kcm.setAdatporCoverable(true);
            }
        }
    }

    Component.onCompleted: {
    }

    Rectangle {
        anchors.fill: parent

        color: settingMinorBackground

        Item {
            id: blue_title
            anchors {
                left: parent.left
                leftMargin: 20 * appScaleSize
                right: parent.right
                rightMargin: 20 * appScaleSize
                top: parent.top
                topMargin:  JDisplay.statusBarHeight
            }

            height: 62 * appScaleSize

            Text {
                text: i18n("Bluetooth")
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 6 * appScaleSize
                font.pixelSize: 20 * appFontSize
                font.bold: true
                color: majorForeground
                MouseArea {
                    anchors.fill:parent
                    onClicked:{
                         
                    }
                }
            }
        }

        Rectangle {
            id: blue_switch_area

            width: parent.width - 40 * appScaleSize
            height: !bt_switch.checked ? 45 * appScaleSize : 2 * 45 * appScaleSize
            anchors {
                left: parent.left
                top: blue_title.bottom
                leftMargin: 20 * appScaleSize
                right: parent.right
                rightMargin: 20 * appScaleSize
            }

            color: cardBackground
            radius: 10 * appScaleSize

            Item {
                id: bt_switch_item

                width: parent.width
                height: 45 * appScaleSize //parent.height

                Text {
                    id: bt_title

                    anchors {
                        left: parent.left
                        leftMargin: 20 * appScaleSize
                        verticalCenter: parent.verticalCenter
                    }

                    text: i18n("Bluetooth")
                    font.pixelSize: 14 * appFontSize
                    color: majorForeground
                }

                Kirigami.JSwitch {
                    id: bt_switch

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: 20 * appScaleSize
                    }

                    implicitWidth: 43 * appScaleSize
                    implicitHeight: 26 * appScaleSize

                    checked: isBluetoothOn
                    checkable: !isCurrentConnectting

                    onClicked: {
                        if(isCurrentConnectting){
                           showToast(i18n("Do not turn off Bluetooth during the connection"))
                        }
                    }

                    onToggled: {
                        
                        if (!bt_switch.checked && BluezQt.Manager.bluetoothOperational) {
                            bt_root.connectedAdress = ""
                            root.setBluetoothEnabled(false)
                            devicesProxyModel.removeConnectedName()
                            return
                        }
                        root.setBluetoothEnabled(true)
                    }
                }
            }

            Kirigami.Separator {
                id: sepatatooLine

                    anchors {
                        bottom: bt_switch_item.bottom
                        left: parent.left
                        right: parent.right
                        rightMargin: 20 * appScaleSize
                        leftMargin: 20 * appScaleSize
                    }

                    height: 1

                    visible: bt_switch.checked
                    color: dividerForeground
            }

            Item {
                id: recent_title_layout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: bt_switch_item.bottom
                }

                height: 45 * appScaleSize

                visible: bt_switch.checked

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 20 * appScaleSize
                        verticalCenter: parent.verticalCenter
                    }

                    text: i18n("Device Name")
                    font.pixelSize: 14 * appFontSize
                    color: majorForeground
                }

                Text {
                    id: recent_tags

                    anchors {
                        right: image_edit.left
                        rightMargin: 9 * appScaleSize
                        verticalCenter: parent.verticalCenter
                    }

                    width: parent.width / 3

                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    text: kcm.getLocalDeviceName()
                    font.pixelSize: 14 * appFontSize
                    color: Kirigami.JTheme.minorForeground
                }

                Kirigami.Icon {
                    id: image_edit

                    anchors {
                        right: parent.right
                        rightMargin: 17 * appScaleSize
                        verticalCenter: parent.verticalCenter
                    }

                    width: 22 * appScaleSize
                    height: 22 * appScaleSize

                    source: Qt.resolvedUrl("../image/edit_name.png")
                    color:Kirigami.JTheme.minorForeground

                }
                MouseArea {
                    anchors.fill: image_edit

                    onClicked: {
                        editDialog.open()
                        editDialog.forceActiveFocus()
                        editDialog.focus = true
                        editDialog.inputText = recent_tags.text
                    }
                }
            }
        }

        Rectangle {
            id: device_list_layout

            height: scanner.lvHeight - 1
            width: parent.width

            radius: 10 * appScaleSize
            visible: bt_switch.checked
            color: cardBackground

            anchors {
                top: blue_switch_area.bottom
                topMargin: 24 * appScaleSize
                left: blue_switch_area.left
                right: blue_switch_area.right
            }

            JScanner {
                id: scanner

                onConnectedUpdate:{
                    isCurrentConnectting = isConnectting
                }
            }
        }
    }

    Kirigami.JDialog {
        id: editDialog

        title: i18n("Device Name")
        text: i18n("Other devices will see this name when you use Bluetooth and USB.")
        inputEnable: true
        showPassword: false
        leftButtonText: i18n("Cancel")
        rightButtonText: i18n("OK")

        onInputTextChanged: {
            if (inputText.length > 32) {
                editDialog.inputText = inputText.substring(0, 32)
            }
            if (inputText.length < 1) {
                rightButtonEnable = false
            } else {
                rightButtonEnable = true
            }
        }

        onRightButtonClicked: {
            if (!rightButtonEnable) {
                return;
            }
            if (editDialog.inputText.length != 0) {
                kcm.setLocalDeviceName(editDialog.inputText)
            }
            editDialog.close()
        }

        onLeftButtonClicked: {
            //clear inputText when cancel
            editDialog.inputText = ""
            editDialog.close()
        }
    }

    ToastView {
        id: toastView
    }

    function showToast(tips)
    {
        toastView.toastContent = tips
        toastView.x = (root.width - toastView.width - 200) / 2
        toastView.y = root.width - toastView.height - 36
        toastView.visible = true
    }
}
