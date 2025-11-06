#ifndef PROXYTESTER_H
#define PROXYTESTER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QElapsedTimer>
#include <QNetworkProxy>
#include <QNetworkRequest>
#include <QUrl>

class ProxyTester : public QObject
{
    Q_OBJECT

public:
    explicit ProxyTester(QObject *parent = nullptr);
    
    // 测试代理连接
    Q_INVOKABLE void testProxy(const QString &serverAddress, 
                              int port, 
                              const QString &username, 
                              const QString &password, 
                              const QString &protocol = "socks5",
                              const QString &testUrl = "https://www.baidu.com");

signals:
    // 测试完成信号
    void testCompleted(bool success, const QString &message, int latency = -1);
    // 测试进度信号
    void testProgress(const QString &message);

private slots:
    void onRequestFinished();
    void onRequestTimeout();

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    QTimer *m_timeoutTimer;
    QElapsedTimer m_elapsedTimer;
    
    void setupProxy(QNetworkProxy &proxy, const QString &serverAddress, int port, 
                    const QString &username, const QString &password, const QString &protocol);
    void cleanup();
};

#endif // PROXYTESTER_H
