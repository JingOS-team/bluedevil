/**
 * SPDX-FileCopyrightText: 2020 Nicolas Fella <nicolas.fella@gmx.de>
 *                         2021 Wang Rui <wangrui@jingos.com>
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include <KQuickAddons/ConfigModule>
#include <QObject>

#include <BluezQt/Manager>
#include <BluezQt/Device>
#include <BluezQt/DevicesModel>

#include <BluezQt/Adapter>
#include <BluezQt/Request>
#include <BluezQt/PendingCall>
#include <BluezQt/InitManagerJob>

#include <BluezQt/Agent>
#include "bluetoothagent.h"

class Bluetooth : public KQuickAddons::ConfigModule
{
    Q_OBJECT

public:
    Q_PROPERTY(QString localDeviceName READ localDeviceName NOTIFY localDeviceNameChanged)
    Bluetooth(QObject *parent, const QVariantList &args);
    ~Bluetooth();
    QString localDeviceName(){ return m_localDeviceName; };
    Q_INVOKABLE void runWizard();
    Q_INVOKABLE void runSendFile(const QString &ubi);
    Q_INVOKABLE void checkNetworkConnection(const QStringList &uuids, const QString &address);
    Q_INVOKABLE void setupNetworkConnection(const QString &service, const QString &address, const QString &deviceName);
    Q_INVOKABLE void requestParingConnection(const QString connAddress, const QString address);
    Q_INVOKABLE void confirmMatchButton(const bool match);
    Q_INVOKABLE void deviceDisconnect(const QString address, const bool isRequestConnect);
    Q_INVOKABLE void deviceRemoved(const QString address);
    Q_INVOKABLE void setName(const QString address,const QString name);
    Q_INVOKABLE void connectToDevice(const QString  connAddress, const QString address);
    Q_INVOKABLE void setAdatporCoverable(const bool visible);
    Q_INVOKABLE QString getLocalDeviceName();
    Q_INVOKABLE void setLocalDeviceName(const QString localName);
    Q_INVOKABLE void stopMediaPlayer(const QString address);
    Q_INVOKABLE void setBluetoothEnabled(const bool isEnable);
    

Q_SIGNALS:
    void networkAvailable(const QString &service, bool available);
    void showPairDialog(const QString name,const QString pin,const bool visible);
    void showKeyboardPairDialog(const QString name, const QString pin,const bool visible);
    void showPariErrorDialog(const QString name, const int errorCode, const int deviceType);
    void connectSuccess(const QString connectedAddress);
    void connectFailed(const QString name, const int deviceType);
    void localDeviceNameChanged(const QString localDeviceName);
    void connectedStateChangedToQml(bool connected,QString address);
    void removeDeviceFinishedToQml();
    void disconnectDeviceFinishedToQml();

private Q_SLOTS:
    void initJobResult(BluezQt::InitManagerJob *job);
    void operationalChanged(bool operational);
    void usableAdapterChanged(BluezQt::AdapterPtr adapter);
    void connectFinished(BluezQt::PendingCall *call);
    void pairingFinished(BluezQt::PendingCall *call);
    void disconnectFromDeviceFinished(BluezQt::PendingCall *call);
    void mediaPlayerStopFinish(BluezQt::PendingCall *call);
    void powerOnCall(BluezQt::PendingCall *call);
    void pairingSuccess();
    void pairingFailed(const int errorCode);
    void pinRequested(const QString &pin);
    void confirmationRequested(const QString &passkey, const BluezQt::Request<> &req);
    void bluetoothBlockedChanged(bool blocked);
    void connectedStateChanged(bool connected);
    void removeDeviceFinished(BluezQt::PendingCall *call);
    

private:
    void checkNetworkInternal(const QString &service, const QString &address);
    BluezQt::Manager *m_manager;
    BluezQt::AdapterPtr m_adapter;
    BluetoothAgent *m_agent;
    BluezQt::DevicePtr m_device;
    BluezQt::Request<> m_req;
    BluezQt::InitManagerJob *initJob;
    QString m_type;
    QString m_address;
    QString m_localDeviceName;
    bool m_cancel;
};

#endif // BLUETOOTHKCM_H
