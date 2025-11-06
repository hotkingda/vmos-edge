#pragma once

#include "../singleton.h"
#include <QObject>
#include <QString>
#include <QByteArray>
#include <QMap>

class QNetworkReply;
class QNetworkAccessManager;
class ReportHelper : public QObject {
    Q_OBJECT
public:
    ReportHelper(QObject* parent = nullptr);
    ~ReportHelper() override;
    SINGLETON(ReportHelper)

public:
    Q_INVOKABLE void reportLog(const QString& eventId, const QVariantMap& map = {});
    Q_INVOKABLE void reportLog(const QString& eventId, const QString& podId, const QVariantMap& map = {});
    Q_INVOKABLE void updateUserInfo();
    Q_INVOKABLE void init(const QString& url, const QString& appId, const QString& channel, const QString& versionName, int64_t versionCode);
    Q_INVOKABLE void setParam(const QVariantMap& param);

private:
    void post_protobuf(const QString& url, const QByteArray& data);

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    QString m_url;
    int64_t m_versionCode;
    QString m_appId;
    QString m_versionName;
    QString m_channel;
    QString m_deviceKey;
    QMap<QString, QString> m_globalMap;

    QNetworkAccessManager *manager;
};
