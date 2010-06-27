/*
    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#ifndef BLUEWIZARD_H
#define BLUEWIZARD_H

#include <QObject>
#include <QWizard>
#include <kservice.h>

class WizardAgent;
class BlueWizard : public QWizard
{
Q_OBJECT

public:
    BlueWizard();
    virtual ~BlueWizard();

    QByteArray deviceAddress() const;
    void setDeviceAddress(const QByteArray& address);

    QByteArray pin() const;
    void setPin(const QByteArray& pin);

    bool manualPin() const;
    void setManualPin(bool);

    WizardAgent* agent() const;

    KService::List services() const;

    void setService(const KService *);
    enum { Introduction, Discover, Pin, Pairing, ManualPin, Services};

public Q_SLOTS:
    virtual void done(int result);

private:
    QByteArray m_deviceAddress;
    QByteArray m_pin;
    WizardAgent *m_agent;
    KService::List m_services;
    const KService *m_service;

    bool m_manualPin;
};

#endif // BLUEWIZARD_H