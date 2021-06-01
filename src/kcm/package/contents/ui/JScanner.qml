/**
 * SPDX-FileCopyrightText: 2021 Wang Rui <wangrui@jingos.com>
 *                         
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.0
import QtBluetooth 5.2
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.12
import org.kde.kirigami 2.15 as Kirigami
import org.kde.bluezqt 1.0 as BluezQt

import org.kde.plasma.private.bluetooth 1.0

Item {
    id: top

    property bool isdiscovering
    property var currentItem
    property var lvHeight:  mainList.height

    width: parent.width
    height: lvHeight
    
    Connections {
        target: kcm

        onShowPairDialog:{
            if(visible){
                pairDialog.visible = true
                var tip = i18n("\"%1\" would like to pair with your pad,Confirm that this code is shown on\"%1\".Do not enter this code on any accessory.",name)
                pairDialog.text = tip
                pairDialog.msgText = pin
            }else{
                pairDialog.visible = false
                currentItem.isConnectting = false
            }
            
        }

        onShowPariErrorDialog:{
            var tip
            if(deviceType == 0 | deviceType == 2){
                tip = i18n("Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }else{
                tip = i18n("Pairing took too long.Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }

            pairDialog.visible = false
            pairErrorDialog.visible = true
            pairErrorDialog.text = tip
            currentItem.isConnectting = false

            if(pairDialog.visible == true){
                pairDialog.visible = false
            }
        }

        onShowKeyboardPairDialog:{
            if(!visible){
                 keyboardPairDialog.visible = false
            }else{
                var tip = i18n("\"%2\" would like to pair with your iPad. Enter the code \"%1\" on \"%2\"",pin,name)
                keyboardPairDialog.text = tip
                keyboardPairDialog.visible = true
            }
        }
        
        onConnectSuccess:{
            bt_root.connectedAdress = connectedAddress
            currentItem.isConnectting = false
        }

        onConnectFailed:{
            currentItem.isConnectting = false
            var tip
            if(deviceType == 0 | deviceType == 2){
                tip = i18n("Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }else{
                tip = i18n("Pairing took too long.Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }
            connectFailedDialog.text = tip
            connectFailedDialog.visible = true
        }
        
        onConnectedStateChangedToQml:{
            if(connected){
                bt_root.connectedAdress = address
            }else{
                bt_root.connectedAdress = ""
                devicesProxyModel.removeConnectedName();
            }
        }

    }
    
    Component {
        id: sectionHeading

        Rectangle {
            required property string section

            anchors{
                left: parent.left
            }
            
            width: mainList.width
            height: 37 * appScale

            color: "transparent"

            Text {
                id:headData
                
                anchors.bottom: parent.bottom

                text: i18n(parent.section)
                font.pixelSize: 12
                color:"#4D000000"
            }

            Image {
                id: scanIcon

                anchors{
                    left: headData.right
                    leftMargin: width/2
                    verticalCenter:parent.verticalCenter
                }

                width: 22 * appScale
                height: width

                visible: isdiscovering & parent.height === 100
                source: "../image/scan.png";

                RotationAnimation{
                 id:scanAnim

                 target: scanIcon
                 loops:Animation.Infinite
                 running: scanIcon.visible
                 from: 0
                 to:360
                 duration: 1000
                }
            }
        }
    }

    ListView {
        id: mainList

        anchors.left:parent.left
        anchors.leftMargin: 20 * appScale
        anchors.right:parent.right
        anchors.rightMargin: 20 * appScale
        anchors.top: parent.top

        width: parent.width
        height:  mainList.count < 9 ? childrenRect.height : 420 * appScale
        
        clip: true
        focus: true
        model:BluezQt.Manager.bluetoothOperational ? devicesProxyModel : []
        section.property: "ConnectionState"
        section.criteria: ViewSection.FullString
        section.delegate: sectionHeading

        delegate: Rectangle {
            id: btDelegate

            property bool isConnectting: false

            width: mainList.width
            height: 45 * appScale

            color: "transparent"
            clip: true

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if(currentItem == btDelegate && isConnectting){
                        return;
                    }

                    if(currentItem){
                        currentItem.isConnectting = false
                    }

                    if(model.Connected && model.Paired){
                         gotoPage("detail_view",{"address":model.Address,"name":model.Name,"isConnected":model.Connected})
                         return ;
                    }

                    if(model.Paired){
                        isConnectting = true
                        currentItem = btDelegate
                        kcm.connectToDevice(bt_root.connectedAdress,model.Address)
                    }else{
                        isConnectting = true
                        currentItem = btDelegate
                        kcm.requestParingConnection("",model.Address)
                    }
                }
            }

            Text {
                id: bttext

                anchors{
                    verticalCenter: parent.verticalCenter
                }

                width : parent.width / 2

                text:model.Name
                font.pixelSize: 14
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                color: model.Connected && model.Paired ? "#FF3C4BE8" : "#000000"
            }

            Text {
                id: tipText

                anchors{
                    right: itemScanIcon.visible ? itemScanIcon.left : infoImage.left
                    rightMargin: infoImage.width / 3
                    verticalCenter: parent.verticalCenter
                }

                visible:isConnectting ? true : model.Paired
                text: isConnectting ? i18n("On Connection") :  Connected ? i18n("Connected") : i18n("Not Connected")
                font.pixelSize: 14
                color: "#99000000"
            }

            Image {
                id: itemScanIcon

                anchors{
                    right: infoImage.left
                    rightMargin:  width/3
                    verticalCenter:parent.verticalCenter
                }

                width: 22
                height: width

                visible: isConnectting 
                source: "../image/scan.png"

                RotationAnimation{
                 id:scanAnim

                 target: itemScanIcon
                 loops:Animation.Infinite
                 running: itemScanIcon.visible
                 from: 0
                 to:360
                 duration: 1000
                }
            }

            Image {
                id: infoImage

                anchors{
                    right: parent.right
                    verticalCenter:parent.verticalCenter
                }

                width: 22 * appScale
                height: width

                visible: isConnectting ? true : model.Paired
                source: "../image/info.png";

                MouseArea{
                    anchors.fill: parent

                    onClicked: {
                        gotoPage("detail_view",{"address":model.Address,"name":model.Name,"isConnected":model.Connected})
                    }
                }
            }

            Kirigami.Separator {
                id: my_separator

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                height: 1 * appScale

                color: "#f0f0f0"
                visible: index != mainList.count - 1

            }
        }
    }

    Kirigami.JDialog {
        id: keyboardPairDialog

        title: i18n("Bluetooth Pairing Request")
        centerButtonText: i18n("Cancel")
        onCenterButtonClicked: {
            keyboardPairDialog.visible = false
        }
    }

    Kirigami.JDialog {
        id: pairDialog

        title:i18n("Bluetooth Pairing Request")
        inputEnable: false
        leftButtonText: i18n("Cancel")
        rightButtonText: i18n("Pair")

        onRightButtonClicked: {
            kcm.confirmMatchButton(true);
            pairDialog.close()
        }
        onLeftButtonClicked: {
            kcm.confirmMatchButton(false);
            pairDialog.close()
        }
    }

    Kirigami.JDialog {
        id: pairErrorDialog

        title: i18n("Pairing Unsuccessful")
        inputEnable: false
        centerButtonText: i18n("Ok")
        
        onCenterButtonClicked: {
            pairErrorDialog.visible = false
        }
    }

    Kirigami.JDialog {
        id: connectFailedDialog

        title: i18n("Connecting Unsuccessful")
        inputEnable: false
        centerButtonText: i18n("Ok")

        onCenterButtonClicked: {
            connectFailedDialog.visible = false
        }
    }
}
