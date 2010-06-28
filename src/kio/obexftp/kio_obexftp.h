/*  This file is part of the KDE libraries

    Copyright (c) 2010 Eduardo Robles Elvira <edulix@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/
#ifndef KIO_OBEXFTP_H
#define KIO_OBEXFTP_H

#include <QObject>
#include <kio/slavebase.h>

class KioObexFtpPrivate;

/**
 * @short Kioslave that browses through the ftp service of bluetooth devices.
 */
class KioObexFtp : public QObject, public KIO::SlaveBase
{
  Q_OBJECT

public:
    /**
     * Constructor
     */
    KioObexFtp(const QByteArray &pool, const QByteArray &app);

    /**
     * Destructor
     */
    virtual ~KioObexFtp();

    /**
     * Retrieves a file from the remote device.
     * 
     * Overrides virtual SlaveBase::get()
     */
    void get(const KUrl &url);

    /**
     * List a remote directory. There are two types of directories in this kio:
     *
     * 1. The root dir, obexftp://. This directory is empty.
     * 2. Remote device directory (something like bluetoth:/00_12_34_56_6d_34/path/to/dir). This is
     *    used when the setHost function has been called, and lists directories inside a remote
     *    bluetooth device ftp service.
     * 
     * Overrides virtual SlaveBase::listDir()
     */
    void listDir(const KUrl &url);

    /**
     * Sets the remote bluetooth device to which the kio will be connected to, the device that will
     * be used for listing and managing files and directories.
     *
     * Overrides virtual SlaveBase::setHost()
     */
    void setHost(const QString &constHostname, quint16 port, const QString &user,
      const QString &pass);

    /**
     * Calls to slaveStatus().
     *
     * Overrides virtual SlaveBase::slave_status()
     */
    void slave_status();

    /**
     * Overrides virtual SlaveBase::stat()
     */
    void stat(const KUrl &url);

    /**
     * Overrides virtual SlaveBase::del()
     */
    void del(const KUrl &url, bool isfile);

    /**
     * Overrides virtual SlaveBase::url()
     */
    void mkdir(const KUrl&url, int permissions);

private:
    KioObexFtpPrivate *d;
};

#endif // KIO_OBEXFTP_H