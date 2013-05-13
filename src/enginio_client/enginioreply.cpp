/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://qt.digia.com/contact-us
**
** This file is part of the Enginio Qt Client Library.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia. For licensing terms and
** conditions see http://qt.digia.com/licensing. For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights. These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file. Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
****************************************************************************/

#include <QtCore/qstring.h>
#include <QtCore/qjsonobject.h>
#include <QtCore/qjsondocument.h>
#include <QtNetwork/qnetworkreply.h>

#include "enginioreply.h"
#include "enginioclient.h"
#include "enginioclient_p.h"

class EnginioReplyPrivate {
    QNetworkReply *_nreply;
    mutable QJsonObject _data;

public:
    EnginioReplyPrivate(QNetworkReply *reply)
        : _nreply(reply)
    {
        Q_ASSERT(reply);
    }

    QNetworkReply::NetworkError errorCode() const
    {
        return _nreply->error();
    }

    QString errorString() const
    {
        return _nreply->errorString();
    }

    QJsonObject data() const
    {
        if (_data.isEmpty())
            _data = QJsonDocument::fromJson(_nreply->readAll()).object();
        return _data;
    }
};

EnginioReply::EnginioReply(EnginioClientPrivate *p, QNetworkReply *reply)
    : QObject(p->q_ptr)
    , d(new EnginioReplyPrivate(reply))
{
    p->registerReply(reply, this);
}

EnginioReply::~EnginioReply()
{
    delete d;
}

QNetworkReply::NetworkError EnginioReply::errorCode() const
{
    return d->errorCode();
}

QString EnginioReply::errorString() const
{
    return d->errorString();
}

QJsonObject EnginioReply::data() const
{
    return d->data();
}

#ifndef QT_NO_DEBUG_STREAM
QDebug operator<<(QDebug d, const EnginioReply *reply)
{
    if (!reply) {
        d << "EnginioReply(null)";
        return d;
    }
    d.nospace();
    d << "EnginioReply(" << hex << (void *) reply << dec;

    if (reply->errorCode() == 0) {
        d << " success data=" << reply->data();
    } else {
        d << " errorCode=" << reply->errorCode() << " ";
        d << " errorString=" << reply->errorString() << " ";
        d << " errorData=" << reply->data() << " ";
    }
    d << ")";
    return d.space();
}
#endif