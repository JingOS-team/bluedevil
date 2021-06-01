/**
 * SPDX-FileCopyrightText: 2020 Nicolas Fella <nicolas.fella@gmx.de>
 *                         2021 Wang Rui <wangrui@jingos.com>
 * 
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "bluetooth.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

#include <KAboutData>
#include <KLocalizedString>
#include <KPluginFactory>

#include <BluezQt/Manager>
#include <BluezQt/Device>
#include <BluezQt/Adapter>
#include <BluezQt/Services>
#include <BluezQt/Agent>
#include <BluezQt/DevicesModel>
#include <KNotification>
#include <QTimer>
#include <BluezQt/MediaPlayer>

K_PLUGIN_CLASS_WITH_JSON(Bluetooth, "metadata.json")

Bluetooth::Bluetooth(QObject *parent, const QVariantList &args)
    : KQuickAddons::ConfigModule(parent, args)
    ,m_agent(new BluetoothAgent(parent))
{
    KLocalizedString::setApplicationDomain("kcm_bluetooth");
    KAboutData *about = new KAboutData("kcm_bluetooth", i18n("Bluetooth"), "1.0", QString(), KAboutLicense::GPL);
    
    about->addAuthor(i18n("Nicolas Fella"), QString(), "nicolas.fella@gmx.de");
    setAboutData(about);
    setButtons(KQuickAddons::ConfigModule::NoAdditionalButton);

    m_manager = new BluezQt::Manager(this);
    BluezQt::InitManagerJob *initJob = m_manager->init();
    initJob->start();
    connect(initJob, &BluezQt::InitManagerJob::result, this, &Bluetooth::initJobResult);
    connect(m_manager, &BluezQt::Manager::bluetoothBlockedChanged, this, &Bluetooth::bluetoothBlockedChanged);
    connect(m_agent, &BluetoothAgent::pinRequested, this, &Bluetooth::pinRequested);
    connect(m_agent, &BluetoothAgent::confirmationRequested, this, &Bluetooth::confirmationRequested);
}

Bluetooth::~Bluetooth() 
{
    if (m_manager != nullptr && m_agent != nullptr) 
    {
        m_manager->unregisterAgent(m_agent);
        delete m_agent;
        delete m_manager;
    }
}

void Bluetooth::bluetoothBlockedChanged(bool blocked)
{
    if(!blocked){
        BluezQt::AdapterPtr adaptor = m_manager->adapters().at(0);
        if(adaptor){
            m_localDeviceName = adaptor->name();
            Q_EMIT localDeviceNameChanged(m_localDeviceName);
            if(adaptor->isDiscoverable() == false){
                qDebug()<<"setAdatporCoverable ::: "<<true;
                adaptor->setDiscoverable(true);
            }
        }
    }
}

void Bluetooth::runWizard()
{
    QProcess::startDetached(QStringLiteral("bluedevil-wizard"), QStringList());
}

void Bluetooth::runSendFile(const QString &ubi)
{
    QProcess::startDetached(QStringLiteral("bluedevil-sendfile"), {QStringLiteral("-u"), ubi});
}

void Bluetooth::checkNetworkConnection(const QStringList &uuids, const QString &address)
{
    if (uuids.contains(BluezQt::Services::Nap)) {
        checkNetworkInternal(QStringLiteral("nap"), address);
    }

    if (uuids.contains(BluezQt::Services::DialupNetworking)) {
        checkNetworkInternal(QStringLiteral("dun"), address);
    }
}

void Bluetooth::checkNetworkInternal(const QString &service, const QString &address)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.plasmanetworkmanagement"),
                                                      QStringLiteral("/org/kde/plasmanetworkmanagement"),
                                                      QStringLiteral("org.kde.plasmanetworkmanagement"),
                                                      QStringLiteral("bluetoothConnectionExists"));

    msg << address;
    msg << service;

    QDBusPendingCallWatcher *call = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(msg));
    connect(call, &QDBusPendingCallWatcher::finished, this, [this, service, call]() {
        QDBusPendingReply<bool> reply = *call;
        if (reply.isError()) {
            return;
        }

        Q_EMIT networkAvailable(service, reply.value());
    });
}

void Bluetooth::setupNetworkConnection(const QString &service, const QString &address, const QString &deviceName)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.plasmanetworkmanagement"),
                                                      QStringLiteral("/org/kde/plasmanetworkmanagement"),
                                                      QStringLiteral("org.kde.plasmanetworkmanagement"),
                                                      QStringLiteral("addBluetoothConnection"));

    msg << address;
    msg << service;
    msg << i18nc("DeviceName Network (Service)", "%1 Network (%2)", deviceName, service);

    QDBusConnection::sessionBus().call(msg, QDBus::NoBlock);
}

void Bluetooth::initJobResult(BluezQt::InitManagerJob *job)
{
    if (job->error()) {
        qApp->exit(1);
        return;
    }

    // Make sure to register agent when bluetoothd starts
    operationalChanged(m_manager->isOperational());
    connect(m_manager, &BluezQt::Manager::operationalChanged, this, &Bluetooth::operationalChanged);
    m_adapter = m_manager->usableAdapter();
    if(m_adapter){
        m_localDeviceName = m_adapter->name();
        if(m_adapter->name() == "localhost.localdomain"){
            m_localDeviceName = "JingOS";
            setLocalDeviceName("JingOS");
        }
        Q_EMIT localDeviceNameChanged(m_localDeviceName);
    }
    if (m_adapter && !m_adapter->isDiscovering()) {
        m_adapter->startDiscovery();
    }
     connect(m_manager, &BluezQt::Manager::usableAdapterChanged, this, &Bluetooth::usableAdapterChanged);
}

void Bluetooth::operationalChanged(bool operational)
{
    if (operational) {
        if(!m_manager->isBluetoothBlocked()){
            setAdatporCoverable(true);
        }
        m_manager->registerAgent(m_agent);
    } else {
        // Attempt to start bluetoothd
        BluezQt::Manager::startService();
    }
}

void Bluetooth::usableAdapterChanged(BluezQt::AdapterPtr adapter)
{
    m_adapter = adapter;

    if (m_adapter && !m_adapter->isDiscovering()) {
        m_adapter->startDiscovery();
    }
}

void Bluetooth::connectFinished(BluezQt::PendingCall *call)
{
    if(call->error()){
      qDebug() <<"code : "<<call->error()<< "\t errorText : " << call->errorText();  
    }

    if(!call->error()){
        KNotification *notification = new KNotification(QStringLiteral("SetupFinished"),
                                                        KNotification::CloseOnTimeout, this);
        notification->setComponentName(QStringLiteral("bluedevil"));
        notification->setTitle(i18n("Setup Finished"));
        if (m_device->name().isEmpty()) {
            notification->setText(i18n("The device has been set up and can now be used."));
        } else {
            notification->setText(i18nc("Placeholder is device name",
                                        "The device '%1' has been set up and can now be used.", m_device->name()));
        }
        // Mark as response to explicit user action ("pairing the device")
        notification->setHint(QStringLiteral("x-kde-user-action-feedback"), true);
        notification->sendEvent();
        Q_EMIT connectSuccess(m_device->address());
    }else{
        //Q_EMIT showPariErrorDialog(m_device->name(),16);
        Q_EMIT connectFailed(m_device->name(), m_device->type());
    }
}

void Bluetooth::pinRequested(const QString &pin)
{
    Q_EMIT showKeyboardPairDialog(m_device->name(),pin,true);
}

void Bluetooth::confirmationRequested(const QString &passkey, const BluezQt::Request<> &req)
{
    m_req = req;
    Q_EMIT showPairDialog(m_device->name(),passkey,true);
    m_cancel = false;
}

void Bluetooth::confirmMatchButton(const bool match)
{
    if(match){
        m_req.accept();
    }else{
        m_cancel = true;
        m_req.reject();
    }
}

void Bluetooth::pairingFinished(BluezQt::PendingCall *call)
{
    if(call->error()){
      qDebug() <<"code : "<<call->error()<< "\t errorText : " << call->errorText();  
    }

    if(m_device->type() == 7){
        Q_EMIT showKeyboardPairDialog(m_device->name(),"",false);
    }

    if(!call->error()){
        pairingSuccess();
    }else{
        if(m_device->type() == 7){
            pairingFailed(call->error());
        }
        if(call->error() == 98){
            Q_EMIT showPairDialog(m_device->name(),"",false);
        }else{
            if(m_cancel){
                Q_EMIT showPairDialog(m_device->name(),"",false);
            }else{
                pairingFailed(call->error());
            }
        }
    }
}

void Bluetooth::pairingSuccess()
{   
    BluezQt::PendingCall *call = m_device->connectToDevice();
    connect(call, &BluezQt::PendingCall::finished, this, &Bluetooth::connectFinished);
}

void Bluetooth::pairingFailed(const int errorCode)
{
    Q_EMIT showPariErrorDialog(m_device->name(),errorCode,m_device->type());
}

void Bluetooth::connectToDevice(const QString connAddress, const QString address)
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    m_device = device;
    device->setTrusted(true);
    BluezQt::PendingCall *call = m_device->connectToDevice();
    connect(call, &BluezQt::PendingCall::finished, this, &Bluetooth::connectFinished);
    connect(m_device.data(), &BluezQt::Device::connectedChanged, this, &Bluetooth::connectedStateChanged);
}

void Bluetooth::connectedStateChanged (bool connected)
{
    Q_EMIT connectedStateChangedToQml(connected,m_device->address());
}

void Bluetooth::requestParingConnection(const QString connAddress, const QString address)
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    m_device = device;
    m_address =  address;
    BluezQt::PendingCall *pairCall = m_device->pair();
    connect(pairCall, &BluezQt::PendingCall::finished, this, &Bluetooth::pairingFinished); 
}

void Bluetooth::deviceDisconnect(const QString address, const bool isRequestConnect)
{
    stopMediaPlayer(address);
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    BluezQt::PendingCall *pairCall = device->disconnectFromDevice();
    connect(pairCall, &BluezQt::PendingCall::finished, this, &Bluetooth::disconnectFromDeviceFinished); 
}

void Bluetooth::disconnectFromDeviceFinished(BluezQt::PendingCall *call)
{
    if(call->error()){
      qDebug() <<"code : "<<call->error()<< "\t errorText : " << call->errorText();  
    }else{
        Q_EMIT disconnectDeviceFinishedToQml();
    }
}

void Bluetooth::deviceRemoved(const QString address)
{
    stopMediaPlayer(address);
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    BluezQt::PendingCall *removeCall = adaptor->removeDevice(device);
    connect(removeCall, &BluezQt::PendingCall::finished, this, &Bluetooth::removeDeviceFinished); 

}

void Bluetooth::removeDeviceFinished(BluezQt::PendingCall *call)
{
    Q_EMIT removeDeviceFinishedToQml();
}

void Bluetooth::setName(const QString address,const QString name)
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    device->setName(name);
}

void Bluetooth::setAdatporCoverable(const bool visible)
{
    BluezQt::AdapterPtr adaptor = m_manager->adapters().at(0);
    if(adaptor && adaptor->isDiscoverable() != visible){
        qDebug()<<"setAdatporCoverable ::: "<<visible;
        adaptor->setDiscoverable(visible);
    }
}

QString Bluetooth::getLocalDeviceName()
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    if(adaptor){
       return adaptor->name(); 
    }
    return "";
}

void Bluetooth::setLocalDeviceName(const QString localName)
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    adaptor->setName(localName);
    m_localDeviceName = localName;
    Q_EMIT localDeviceNameChanged(m_localDeviceName);
}

void Bluetooth::stopMediaPlayer(const QString address)
{
    BluezQt::AdapterPtr adaptor = m_manager->usableAdapter();
    BluezQt::DevicePtr device = adaptor->deviceForAddress(address); 
    BluezQt::MediaPlayerPtr mediaPlayer = device->mediaPlayer();
    if(mediaPlayer){
        BluezQt::PendingCall *pairCall = mediaPlayer->stop();
        connect(pairCall, &BluezQt::PendingCall::finished, this, &Bluetooth::mediaPlayerStopFinish); 
    }
    
}
void Bluetooth::mediaPlayerStopFinish(BluezQt::PendingCall *call)
{
    if(call->error()){
      qDebug() <<"code : "<<call->error()<< "\t errorText : " << call->errorText();  
    }
}

void Bluetooth::setBluetoothEnabled(const bool isEnable)
{
    m_manager->setBluetoothBlocked(isEnable);
    BluezQt::AdapterPtr adaptor = m_manager->adapters().at(0);  
    m_adapter = adaptor; 
    if(isEnable){
        BluezQt::PendingCall *powerOnCall =  adaptor->setPowered(true);
        connect(powerOnCall, &BluezQt::PendingCall::finished, this, &Bluetooth::powerOnCall); 
    }else{
        adaptor->setPowered(false);
    }

}

void Bluetooth::powerOnCall(BluezQt::PendingCall *call)
{
    if(call->error()){
      qDebug() <<"code : "<<call->error()<< "\t errorText : " << call->errorText();  
    }else{
         m_adapter->setDiscoverable(true);
    }
}

#include "bluetooth.moc"
