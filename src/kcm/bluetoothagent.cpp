/*
 *   SPDX-FileCopyrightText: 2010 Alex Fiestas <alex@eyeos.org>
 *   SPDX-FileCopyrightText: 2010 UFO Coders <info@ufocoders.com>
 *   SPDX-FileCopyrightText: 2021 Liu Bangguo <liubangguo@jingos.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "bluetoothagent.h"

#include <QDBusObjectPath>
#include <QFile>
#include <QStandardPaths>
#include <QXmlStreamReader>

#include <KLocalizedString>
#include <KRandom>

#include <BluezQt/Device>
#include <QDebug>

BluetoothAgent::BluetoothAgent(QObject *parent)
    : BluezQt::Agent(parent)
    , m_fromDatabase(false)
{
}

QString BluetoothAgent::pin()
{
    return m_pin;
}

void BluetoothAgent::setPin(const QString &pin)
{
    m_pin = pin;
    m_fromDatabase = false;
}

bool BluetoothAgent::isFromDatabase()
{
    return m_fromDatabase;
}

QString BluetoothAgent::getPin(BluezQt::DevicePtr device)
{
    m_fromDatabase = false;
    m_pin = QString::number(KRandom::random());
    m_pin = m_pin.left(6);

    const QString &xmlPath = QStandardPaths::locate(QStandardPaths::AppDataLocation, QStringLiteral("pin-code-database.xml"));

    QFile file(xmlPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Can't open the pin-code-database.xml";
        return m_pin;
    }

    QXmlStreamReader xml(&file);

    QString deviceType = BluezQt::Device::typeToString(device->type());
    if (deviceType == QLatin1String("audiovideo")) {
        deviceType = QStringLiteral("audio");
    }

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.name() != QLatin1String("device")) {
            continue;
        }
        QXmlStreamAttributes attr = xml.attributes();

        if (attr.count() == 0) {
            continue;
        }

        if (attr.hasAttribute(QLatin1String("type")) && attr.value(QLatin1String("type")) != QLatin1String("any")) {
            if (deviceType != attr.value(QLatin1String("type")).toString()) {
                continue;
            }
        }

        if (attr.hasAttribute(QLatin1String("oui"))) {
            if (!device->address().startsWith(attr.value(QLatin1String("oui")).toString())) {
                continue;
            }
        }

        if (attr.hasAttribute(QLatin1String("name"))) {
            if (device->name() != attr.value(QLatin1String("name")).toString()) {
                continue;
            }
        }

        m_pin = attr.value(QLatin1String("pin")).toString();
        m_fromDatabase = true;
        if (m_pin.startsWith(QLatin1String("max:"))) {
            m_fromDatabase = false;
            int num = m_pin.rightRef(m_pin.length() - 4).toInt();
            m_pin = QString::number(KRandom::random()).left(num);
        }

        qDebug() << "PIN: " << m_pin;
        return m_pin;
    }

    return m_pin;
}

QDBusObjectPath BluetoothAgent::objectPath() const
{
    return QDBusObjectPath(QStringLiteral("/agent"));
}

void BluetoothAgent::requestPinCode(BluezQt::DevicePtr device, const BluezQt::Request<QString> &req)
{
    qDebug() << "AGENT-RequestPinCode" << device->ubi();

    Q_EMIT pinRequested(device,m_pin);
    req.accept(m_pin);
}

void BluetoothAgent::displayPinCode(BluezQt::DevicePtr device, const QString &pinCode)
{
    qDebug() << "AGENT-DisplayPinCode" << device->ubi() << pinCode;

    Q_EMIT pinRequested(device,pinCode);
}

void BluetoothAgent::requestPasskey(BluezQt::DevicePtr device, const BluezQt::Request<quint32> &req)
{
    qDebug() << "AGENT-RequestPasskey" << device->ubi();

    Q_EMIT pinRequested(device,m_pin);
    req.accept(m_pin.toUInt());
}

void BluetoothAgent::displayPasskey(BluezQt::DevicePtr device, const QString &passkey, const QString &entered)
{
    Q_UNUSED(entered);

    qDebug() << "AGENT-DisplayPasskey" << device->ubi() << passkey;

    Q_EMIT pinRequested(device,passkey);
}

void BluetoothAgent::requestConfirmation(BluezQt::DevicePtr device, const QString &passkey, const BluezQt::Request<> &req)
{
    
    qDebug() << "AGENT-RequestConfirmation " << device->ubi() << passkey;

    Q_EMIT confirmationRequested(device, passkey, req);
}

void BluetoothAgent::requestAuthorization(BluezQt::DevicePtr device, const BluezQt::Request<> &request)
{
    qDebug() << "AGENT-RequestAuthorization";
    // request.accept();
}

void BluetoothAgent::authorizeService(BluezQt::DevicePtr device, const QString &uuid, const BluezQt::Request<> &request)
{
    // TODO: Show user the Service UUID
    qDebug() << "AGENT-AuthorizeService" << device->name() << "Service:" << uuid;
    request.accept();
}
void BluetoothAgent::release()
{
    qDebug() << "AGENT-Release";

    Q_EMIT agentReleased();
}

void BluetoothAgent::cancel()
{
    qDebug() << "AGENT-Cancel";

    Q_EMIT agentCanceled();
}
