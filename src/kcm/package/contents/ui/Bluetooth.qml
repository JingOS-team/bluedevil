
/**
 * SPDX-FileCopyrightText: 2020 Nicolas Fella <nicolas.fella@gmx.de>
 *                         2021 Wang Rui <wangrui@jingos.com>
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.5
import QtQuick.Controls 2.10 as QQC2

import org.kde.kirigami 2.15 as Kirigami
import org.kde.kcm 1.2

import org.kde.bluezqt 1.0 as BluezQt

import org.kde.plasma.private.bluetooth 1.0
import jingos.display 1.0

Item {

    id: bt_root

    property real appScaleSize: JDisplay.dp(1.0)
    property real appFontSize: JDisplay.sp(1.0)
    property var connectedName: devicesProxyModel.connectedName
    property var connectedAdress: devicesProxyModel.connectedAdress
    
    property var majorForeground: Kirigami.JTheme.majorForeground
    property var minorForeground: Kirigami.JTheme.minorForeground
    property var settingMinorBackground: Kirigami.JTheme.settingMinorBackground
    property var cardBackground: Kirigami.JTheme.cardBackground
    property var highlightColor: Kirigami.JTheme.highlightColor
    property var dividerForeground: Kirigami.JTheme.dividerForeground
    property bool isDarkTheme: Kirigami.JTheme.colorScheme === "jingosDark"

    anchors.fill: parent

    DevicesProxyModel {
        id: devicesProxyModel
        sourceModel: devicesModel
    }

    Connections {
        target: parent

        onPause: {
            kcm.setAdatporDiscovery(false);
            kcm.setAdatporCoverable(false);
        }

        onResume: {
            kcm.setAdatporDiscovery(true);
            kcm.setAdatporCoverable(true);
        }
    }

    BluezQt.DevicesModel {
        id: devicesModel
    }

    Component {
        id: home_view
        Home {}
    }

    Component {
        id: detail_view
        BluetoothDetail {}
    }

    function gotoPage(name, json) {
        if (name == "home_view") {
            stack.push(home_view)
        } else if (name == "detail_view") {
            stack.push(detail_view, json)
        }
    }

    StackView {
        id: stack

        anchors.fill: parent

        Component.onCompleted: {
            stack.push(home_view)
        }
    }

    function popView() {
        stack.pop()
    }

    function popAllView() {
        while (stack.depth > 1) {
            stack.pop()
        }
    }

    Timer {
        id: scanTimer

        interval: 10000
        repeat: true
        running: false
    }
}
