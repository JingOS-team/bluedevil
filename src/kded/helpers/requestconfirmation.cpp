/*
 *   SPDX-FileCopyrightText: 2010 Alejandro Fiestas Olivares <alex@eyeos.org>
 *   SPDX-FileCopyrightText: 2010 Eduardo Robles Elvira <edulix@gmail.com>
 *   SPDX-FileCopyrightText: 2010 UFO Coders <info@ufocoders.com>
 *   SPDX-FileCopyrightText: 2014-2015 David Rosca <nowrep@gmail.com>
 *   SPDX-FileCopyrightText: 2021 Liu Bangguo <liubangguo@jingos.com>
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "requestconfirmation.h"
#include "debug_p.h"

#include <KLocalizedString>
#include <KNotification>

RequestConfirmation::RequestConfirmation(BluezQt::DevicePtr device, const QString &pin, QObject *parent)
    : QObject(parent)
    , m_device(device)
    , m_pin(pin)
{
    KNotification *notification = new KNotification(QStringLiteral("RequestConfirmation"), KNotification::Persistent, this);

    notification->setComponentName(QStringLiteral("bluedevil"));
    notification->setTitle(QStringLiteral("%1 (%2)").arg(m_device->name().toHtmlEscaped(), m_device->address()));
    notification->setText(
        i18nc("The text is shown in a notification to know if the PIN is correct,"
              "%1 is the remote bluetooth device and %2 is the pin",
              "%1 is asking if the PIN is correct: %2",
              m_device->name().toHtmlEscaped(),
              m_pin));

    notification->setActions({i18n("Pair"), i18n("Cancel")});
    connect(notification, &KNotification::action1Activated, this, &RequestConfirmation::pinCorrect);
    connect(notification, &KNotification::action2Activated, this, &RequestConfirmation::pinWrong);
    connect(parent, SIGNAL(agentCanceled()), this, SLOT(pinWrong()));
    notification->sendEvent();
}

void RequestConfirmation::pinCorrect()
{
    qCDebug(BLUEDAEMON) << "PIN correct:" << m_device->name() << m_device->address();

    deleteLater();
    Q_EMIT done(Accept);
}

void RequestConfirmation::pinWrong()
{
    qCDebug(BLUEDAEMON) << "PIN wrong:" << m_device->name() << m_device->address();

    deleteLater();
    Q_EMIT done(Deny);
}
