#include "proxytester.h"
#include <QNetworkProxy>
#include <QNetworkRequest>
#include <QUrl>
#include <QDebug>
#include <QByteArray>

ProxyTester::ProxyTester(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_timeoutTimer(new QTimer(this))
{
    // 设置超时时间为10秒
    m_timeoutTimer->setSingleShot(true);
    m_timeoutTimer->setInterval(10000);
    
    connect(m_timeoutTimer, &QTimer::timeout, this, &ProxyTester::onRequestTimeout);
}

void ProxyTester::testProxy(const QString &serverAddress, 
                           int port, 
                           const QString &username, 
                           const QString &password, 
                           const QString &protocol,
                           const QString &testUrl)
{
    emit testProgress("正在设置代理...");
    
    // 清理之前的连接
    cleanup();
    
    // 创建代理对象
    QNetworkProxy proxy;
    setupProxy(proxy, serverAddress, port, username, password, protocol);
    
    // 设置网络管理器使用代理
    m_networkManager->setProxy(proxy);
    
    emit testProgress("正在连接代理服务器...");
    
    // 开始计时
    m_elapsedTimer.start();
    
    // 创建网络请求
    QNetworkRequest request;
    request.setUrl(QUrl(testUrl));
    request.setRawHeader(QByteArray("User-Agent"), QByteArray("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"));
    
    // 发送请求
    m_currentReply = m_networkManager->get(request);
    
    // 连接信号
    connect(m_currentReply, &QNetworkReply::finished, this, &ProxyTester::onRequestFinished);
    
    // 启动超时定时器
    m_timeoutTimer->start();
}

void ProxyTester::setupProxy(QNetworkProxy &proxy, const QString &serverAddress, int port, 
                            const QString &username, const QString &password, const QString &protocol)
{
    // 设置代理类型
    if (protocol.toLower() == "socks5") {
        proxy.setType(QNetworkProxy::Socks5Proxy);
    } else if (protocol.toLower() == "http" || protocol.toLower() == "https") {
        proxy.setType(QNetworkProxy::HttpProxy);
    } else {
        proxy.setType(QNetworkProxy::HttpProxy); // 默认使用HTTP代理
    }
    
    // 设置代理服务器地址和端口
    proxy.setHostName(serverAddress);
    proxy.setPort(port);
    
    // 设置认证信息
    if (!username.isEmpty() && !password.isEmpty()) {
        proxy.setUser(username);
        proxy.setPassword(password);
    }
}

void ProxyTester::onRequestFinished()
{
    m_timeoutTimer->stop();
    
    if (!m_currentReply) {
        return;
    }
    
    int latency = m_elapsedTimer.elapsed();
    
    if (m_currentReply->error() == QNetworkReply::NoError) {
        // 请求成功
        emit testCompleted(true, QString("代理连接成功！延迟: %1ms").arg(latency), latency);
    } else {
        // 请求失败
        QString errorMessage = QString("网络检测失败，请检查数据是否正确！");
        emit testCompleted(false, errorMessage, latency);
    }
    
    cleanup();
}

void ProxyTester::onRequestTimeout()
{
    if (m_currentReply) {
        m_currentReply->abort();
        int latency = m_elapsedTimer.elapsed();
        // emit testCompleted(false, "代理连接超时", latency);
        cleanup();
    }
}

void ProxyTester::cleanup()
{
    if (m_currentReply) {
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }
    
    m_timeoutTimer->stop();
    
    // 重置网络管理器代理设置
    m_networkManager->setProxy(QNetworkProxy::NoProxy);
}
