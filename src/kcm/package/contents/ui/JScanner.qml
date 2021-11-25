/*
 * Copyright (C) 2021 Beijing Jingling Information System Technology Co., Ltd. All rights reserved.
 *
 * Authors:
 * Liu Bangguo <liubangguo@jingos.com>
 *
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

    property bool isdiscovering: true
    property var currentItem
    property var lvHeight:  mainList.height
    property bool isConnecttingState: false
    signal connectedUpdate(bool isConnectting)
    property var currentAddress

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

                isConnecttingState = true
            }else{
                pairDialog.visible = false
                if(currentItem){
                    currentItem.isConnectting = false
                }
                isConnecttingState = false
                currentAddress = ""
                connectedUpdate(false)
            }
            
        }

        onShowPariErrorDialog:{
            var tip
            if(deviceType == 0 | deviceType == 2){
                tip = i18n("Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }else{
                tip = i18n("Pairing took too long.Make sure\"%1\" is turned on,in range,and is ready to pair.",name)
            }
            if(!isConnecttingState) return;

            pairDialog.visible = false
            if(pairErrorDialog.visible == false){
                pairErrorDialog.visible = true
            }
            pairErrorDialog.text = tip
            if(currentItem){
                currentItem.isConnectting = false
            }
            isConnecttingState = false
            currentAddress = ""
            connectedUpdate(false)

            if(pairDialog.visible == true){
                pairDialog.visible = false
            }
            if(keyboardPairDialog.visible == true)
            {
                keyboardPairDialog.visible = false
            }
        }

        onShowKeyboardPairDialog:{
            if(!visible){
                 keyboardPairDialog.visible = false
                isConnecttingState = false
            }else{
                var tip = i18n("\"%2\" would like to pair with your iPad. Enter the code \"%1\" on \"%2\"",pin,name)
                if(pairErrorDialog.visible = true){
                    pairErrorDialog.visible = false
                }
                keyboardPairDialog.text = tip
                keyboardPairDialog.visible = true

                isConnecttingState = true
            }
        }
        
        onConnectSuccess:{
            bt_root.connectedAdress = connectedAddress
            if(currentItem){
                currentItem.isConnectting = false
            }
            isConnecttingState = false
            currentAddress = ""
            connectedUpdate(false)
        }

        onConnectFailed:{
            if(pairDialog.visible){
                pairDialog.visible = false
            }
            if(currentItem){
                currentItem.isConnectting = false
            }
            isConnecttingState = false
            currentAddress = ""
            connectedUpdate(false)
            
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
            height: 37 * appScaleSize

            color: "transparent"

            Text {
                id:headData
                
                anchors.bottom: parent.bottom
                anchors.bottomMargin: (scanIcon.height - headData.height) / 2

                text: i18n(parent.section)
                font.pixelSize: 12 * appFontSize
                color: minorForeground
            }

            Image {
                id: scanIcon

                anchors{
                    left: headData.right
                    leftMargin: width/2
                    bottom: parent.bottom
                }

                width: 22 * appScaleSize
                height: width

                visible: parent.section == "Other devices"
                source: "../image/scan.png";

                RotationAnimation{
                 id:scanAnim

                 target: scanIcon
                 loops:Animation.Infinite
                 running: scanIcon.visible
                 from: 0
                 to:360
                 duration: 3000
                }
            }
        }
    }
    ListView {
        id: mainList

        property int contentYOnFlickStarted

        anchors.left:parent.left
        anchors.leftMargin: 20 * appScaleSize
        anchors.right:parent.right
        anchors.rightMargin: 20 * appScaleSize
        anchors.top: parent.top

        width: parent.width
        height:  {
            if(mainList.count<1) return 0
            if(mainList.count < 7)
                    return (mainList.count*45+45)*appScaleSize
            return bt_root.height - 235 *appScaleSize
            }
        
        clip: true
        focus: true
        model:BluezQt.Manager.bluetoothOperational ? devicesProxyModel : []
        section.property: "ConnectionState"
        section.criteria: ViewSection.FullString
        section.delegate: sectionHeading
        property bool refreshFlag: false;

        /*onFlickStarted: {
            contentYOnFlickStarted = contentY
        }

        onFlickEnded: {
            if (contentYOnFlickStarted < 0) {
                kcm.refreshDiscovery()
                mainList.currentIndex = -1
            }
        }*/

        onContentYChanged: {
            if((contentY - originY) < -220){
                if(!refreshFlag){
                    refreshFlag = true
                }
            }
        }
        
        onMovementEnded: {
            if(refreshFlag){
                refreshFlag = false
                kcm.refreshDiscovery()
                mainList.currentIndex = -1
            }
        }


        onCurrentItemChanged:{
            top.currentItem = currentItem
        }

        delegate: Rectangle {
            id: btDelegate

            property bool isConnectting: false
            property bool connectionStatus: model.Connected

            width: mainList.width
            height: 45 * appScaleSize

            color: "transparent"
            clip: true

            onConnectionStatusChanged:{
                kcm.connectionStateChange(connectionStatus);
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if((currentAddress == model.Address) | isConnecttingState){
                        return;
                    }

                    if(currentItem){
                        currentItem.isConnectting = false
                        isConnecttingState = false
                        connectedUpdate(false)
                        currentAddress = ""
                        mainList.currentIndex = index
                    }

                    if(model.Connected && model.Paired){
                         gotoPage("detail_view",{"address":model.Address,"name":model.Name,"isConnected":model.Connected,"deviceType":model.Type})
                         return ;
                    }
                    isConnecttingState = true
                    if(model.Paired){
                        isConnectting = true
                        connectedUpdate(true)
                        currentItem = btDelegate
                        kcm.connectToDevice(bt_root.connectedAdress,model.Address)
                        mainList.currentIndex = index
                        currentAddress = model.Address
                    }else{
                        isConnectting = true
                        connectedUpdate(true)
                        currentItem = btDelegate
                        kcm.requestParingConnection("",model.Address)
                        mainList.currentIndex = index
                        currentAddress = model.Address
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
                font.pixelSize: 14 * appFontSize
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                color: model.Connected && model.Paired ? highlightColor : majorForeground
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
                font.pixelSize: 14 * appFontSize
                color: isDarkTheme ? "#8CF7F7F7" : "#99000000"
            }

            Image {
                id: itemScanIcon

                anchors{
                    right: infoImage.left
                    rightMargin:  width/3
                    verticalCenter:parent.verticalCenter
                }

                width: 22 * appScaleSize
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
                    rightMargin: -2
                    verticalCenter:parent.verticalCenter
                }

                width: 22 * appScaleSize
                height: width

                visible: isConnectting ? true : model.Paired
                source: "../image/info.png";

                MouseArea{
                    anchors.fill: parent

                    onClicked: {
                        gotoPage("detail_view",{"address":model.Address,"name":model.Name,"isConnected":model.Connected,"deviceType":model.Type})
                    }
                }
            }

            Kirigami.Separator {
                id: my_separator

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                height: 1

                color: dividerForeground
                visible: index != mainList.count - 1

            }
        }
        
        Component.onCompleted:{
             mainList.currentIndex = -1
        }
    }

    Kirigami.JDialog {
        id: keyboardPairDialog

        title: i18n("Bluetooth Pairing Request")
        centerButtonText: i18n("Cancel")
        onCenterButtonClicked: {
            keyboardPairDialog.visible = false
            kcm.cancelAgent()
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
            isConnecttingState = false
        }
        onLeftButtonClicked: {
            kcm.confirmMatchButton(false);
            pairDialog.close()
            isConnecttingState = false
        }
    }

    Kirigami.JDialog {
        id: pairErrorDialog

        title: i18n("Pairing Unsuccessful")
        inputEnable: false
        centerButtonText: i18n("OK")
        centerButtonTextColor: "#000000"
        
        onCenterButtonClicked: {
            pairErrorDialog.visible = false
        }
    }

    Kirigami.JDialog {
        id: connectFailedDialog

        title: i18n("Connecting Unsuccessful")
        inputEnable: false
        centerButtonText: i18n("OK")

        onCenterButtonClicked: {
            connectFailedDialog.visible = false
        }
    }

}
