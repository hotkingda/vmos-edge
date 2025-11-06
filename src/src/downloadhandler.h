#ifndef DOWNLOADHANDLER_H
#define DOWNLOADHANDLER_H

#include <QObject>

class QWebEngineDownloadRequest;

class DownloadHandler : public QObject
{
    Q_OBJECT
public:
    explicit DownloadHandler(QObject *parent = nullptr);

public slots:
    // 用于连接 QWebEngineProfile::downloadRequested 信号
    void handleDownload(QWebEngineDownloadRequest *download);
};

#endif // DOWNLOADHANDLER_H