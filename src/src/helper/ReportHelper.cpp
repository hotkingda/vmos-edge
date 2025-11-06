#include "ReportHelper.h"
#include "utils.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>


ReportHelper::ReportHelper(QObject* parent)
    : QObject(parent)
    , manager(new QNetworkAccessManager(this))
    , m_deviceKey(Utils::getInstance()->getMachineId())
{

}

ReportHelper::~ReportHelper()
{

}

void ReportHelper::init(const QString& url, const QString& appId, const QString& channel, const QString& versionName, int64_t versionCode){
}

void ReportHelper::setParam(const QVariantMap& param){

}

void ReportHelper::reportLog(const QString& eventId, const QVariantMap& map)
{

}

void ReportHelper::reportLog(const QString& eventId, const QString& podId, const QVariantMap& map)
{

}

void ReportHelper::updateUserInfo()
{

}

void ReportHelper::post_protobuf(const QString& url, const QByteArray& data)
{

}

void ReportHelper::onReplyFinished(QNetworkReply *reply)
{
    bool success = (reply->error() == QNetworkReply::NoError);
    if(!success){
        qDebug() << "report log result" << reply->error();
    }
    reply->deleteLater();
}


