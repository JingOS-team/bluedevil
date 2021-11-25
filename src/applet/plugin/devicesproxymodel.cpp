/*
    SPDX-FileCopyrightText: 2014-2015 David Rosca <nowrep@gmail.com>
    SPDX-FileCopyrightText: 2021 Liu Bangguo <liubangguo@jingos.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

#include "devicesproxymodel.h"

#include <BluezQt/Adapter>
#include <BluezQt/Device>
#include <QDebug>
#include <KLocalizedString>
#include <QDBusConnection>

class DevicesProxyModel;
DevicesProxyModel::DevicesProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    sort(0, Qt::DescendingOrder);
    m_manager = new BluezQt::Manager(this);
    connect(m_manager, &BluezQt::Manager::bluetoothBlockedChanged, this, &DevicesProxyModel::bluetoothBlockedChanged);
    QDBusConnection::sessionBus().connect(QString(), QString("/org/kde/jingos/kcm_bluetooth"), "org.kde.jingos.kcm_bluetooth",
                                                        "deviceRemove", this, SLOT(deviceRemoved()));
}

void  DevicesProxyModel::deviceRemoved()
{
    m_connectedName = "";
    emit connectedNameChanged(m_connectedName);
}

void DevicesProxyModel::bluetoothBlockedChanged(bool blocked)
{
    if(blocked){
        m_connectedName = "";
        emit connectedNameChanged(m_connectedName);
    }    
}

void DevicesProxyModel::removeConnectedName()
{
    m_connectedName = "";
    m_connectedAdress = "";
    emit connectedNameChanged(m_connectedName);
    emit connectedAdressChanged(m_connectedAdress);
}

QHash<int, QByteArray> DevicesProxyModel::roleNames() const
{
    QHash<int, QByteArray> roles = QSortFilterProxyModel::roleNames();
    roles[SectionRole] = QByteArrayLiteral("Section");
    roles[DeviceFullNameRole] = QByteArrayLiteral("DeviceFullName");
    roles[ConnectionStateRole] = QByteArrayLiteral("ConnectionState");
    return roles;
}

QVariant DevicesProxyModel::data(const QModelIndex &index, int role) const
{
    switch (role) {
        case ConnectionStateRole:
        if (index.data(BluezQt::DevicesModel::PairedRole).toBool()) {
            return i18n("My devices");
        }
        return i18n("Other devices");
    case SectionRole:
        if (index.data(BluezQt::DevicesModel::ConnectedRole).toBool()) {
            return QStringLiteral("Connected");
        }
        return QStringLiteral("Available");

    case DeviceFullNameRole:
        if (duplicateIndexAddress(index)) {
            const QString &name = QSortFilterProxyModel::data(index, BluezQt::DevicesModel::NameRole).toString();
            const QString &ubi = QSortFilterProxyModel::data(index, BluezQt::DevicesModel::UbiRole).toString();
            const QString &hci = adapterHciString(ubi);

            if (!hci.isEmpty()) {
                return QStringLiteral("%1 - %2").arg(name, hci);
            }
        }
        return QSortFilterProxyModel::data(index, BluezQt::DevicesModel::NameRole);

    default:
        return QSortFilterProxyModel::data(index, role);
    }
}

void DevicesProxyModel::resetData()
{
    beginResetModel();
    endResetModel();
}

bool DevicesProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    bool leftPaired = left.data(BluezQt::DevicesModel::PairedRole).toBool();
    bool rightPaired= right.data(BluezQt::DevicesModel::PairedRole).toBool();
    // bool leftConnected = left.data(BluezQt::DevicesModel::ConnectedRole).toBool();
    // bool rightConnected = right.data(BluezQt::DevicesModel::ConnectedRole).toBool();

    const QString &leftName = left.data(BluezQt::DevicesModel::NameRole).toString();
    const QString &rightName = right.data(BluezQt::DevicesModel::NameRole).toString();

    const int &leftType = left.data(BluezQt::DevicesModel::TypeRole).toInt();
    const int &rightType = right.data(BluezQt::DevicesModel::TypeRole).toInt();

    qint16 leftRssi = left.data(BluezQt::DevicesModel::RssiRole).toInt();
    qint16 rightRssi = right.data(BluezQt::DevicesModel::RssiRole).toInt();
    
    if (leftPaired < rightPaired) {
        return true;
    } else if (leftPaired > rightPaired) {
        return false;
    }

    if(leftType != 18 && rightType != 18){
        if(leftRssi < rightRssi){
            return true;
        }else if(leftRssi > rightRssi){
            return false;
        }
    }
    
    if (leftType > rightType) {
        return true;
    } else if (leftType < rightType) {
        return false;
    }

    // if (leftConnected < rightConnected) {
    //     return true;
    // } else if (leftConnected > rightConnected) {
    //     return false;
    // }
    
    if(!leftPaired && leftRssi < rightRssi){
        return true;
    }else if(!leftPaired && leftRssi > rightRssi){
        return false;
    }

    return QString::localeAwareCompare(leftName, rightName) > 0;
}

// Returns "hciX" part from UBI "/org/bluez/hciX/dev_xx_xx_xx_xx_xx_xx"
QString DevicesProxyModel::adapterHciString(const QString &ubi) const
{
    int startIndex = ubi.indexOf(QLatin1String("/hci")) + 1;

    if (startIndex < 1) {
        return QString();
    }

    int endIndex = ubi.indexOf(QLatin1Char('/'), startIndex);

    if (endIndex == -1) {
        return ubi.mid(startIndex);
    }
    return ubi.mid(startIndex, endIndex - startIndex);
}

bool DevicesProxyModel::duplicateIndexAddress(const QModelIndex &idx) const
{
    const QModelIndexList &list = match(index(0, 0),
                                        BluezQt::DevicesModel::AddressRole,
                                        idx.data(BluezQt::DevicesModel::AddressRole).toString(),
                                        2,
                                        Qt::MatchExactly);
    return list.size() > 1;
}

bool DevicesProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    const QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    if(index.data(BluezQt::DevicesModel::ConnectedRole).toBool() && index.data(BluezQt::DevicesModel::PairedRole).toBool()){
        m_connectedName = index.data(BluezQt::DevicesModel::NameRole).toString();
        m_connectedAdress = index.data(BluezQt::DevicesModel::AddressRole).toString();
        emit connectedNameChanged(m_connectedName);
        emit connectedAdressChanged(m_connectedAdress);
    }
    // if(index.data(BluezQt::DevicesModel::NameRole).toString().replace("-","") == 
    //     index.data(BluezQt::DevicesModel::AddressRole).toString().replace(":","")){
    //     return false;
    // }
    if(!index.data(BluezQt::DevicesModel::PairedRole).toBool() && index.data(BluezQt::DevicesModel::RssiRole).toInt() == -32768){
        return false;
    }
    // if(index.data(BluezQt::DevicesModel::RssiRole).toInt() == -32768){
    //     return false;
    // }
    // Only show paired devices in the KCM and applet
    // return index.data(BluezQt::DevicesModel::PairedRole).toBool();
    bool adapterPowered = index.data(BluezQt::DevicesModel::AdapterPoweredRole).toBool();
    bool adapterPairable = index.data(BluezQt::DevicesModel::AdapterPairableRole).toBool();
    BluezQt::Device::Type type = index.data(BluezQt::DevicesModel::TypeRole).value<BluezQt::Device::Type>();
    return adapterPowered && adapterPairable && type!=BluezQt::Device::Type::Uncategorized;
}
