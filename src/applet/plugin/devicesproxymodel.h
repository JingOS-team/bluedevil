/*
    SPDX-FileCopyrightText: 2014 David Rosca <nowrep@gmail.com>
    SPDX-FileCopyrightText: 2021 Liu Bangguo <liubangguo@jingos.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

#ifndef DEVICESPROXYMODEL_H
#define DEVICESPROXYMODEL_H

#include <BluezQt/DevicesModel>
#include <QSortFilterProxyModel>
#include <BluezQt/Manager>
// #include "bluetoothagent.h"

class DevicesProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    Q_PROPERTY(QString connectedName READ connectedName NOTIFY connectedNameChanged)
    Q_PROPERTY(QString connectedAdress READ connectedAdress NOTIFY connectedAdressChanged)

    enum AdditionalRoles {
        SectionRole = BluezQt::DevicesModel::LastRole + 10,
        DeviceFullNameRole = BluezQt::DevicesModel::LastRole + 11,
        ConnectionStateRole = BluezQt::DevicesModel::LastRole + 12,
    };

    explicit DevicesProxyModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

    Q_INVOKABLE QString adapterHciString(const QString &ubi) const;
    QString connectedName(){ return m_connectedName; };
    QString connectedAdress(){ return m_connectedAdress; };

    Q_INVOKABLE void removeConnectedName();
    Q_INVOKABLE void resetData();

signals:
    void connectedNameChanged(const QString connectedName) const;
    void connectedAdressChanged(const QString connectedAddress) const;
    
private Q_SLOTS:
    void bluetoothBlockedChanged(bool blocked);
    void deviceRemoved();
private:
    bool duplicateIndexAddress(const QModelIndex &idx) const;
    mutable QString m_connectedName = "";
    mutable QString m_connectedAdress = "";
    BluezQt::Manager *m_manager;
};

#endif // DEVICESPROXYMODEL_H
