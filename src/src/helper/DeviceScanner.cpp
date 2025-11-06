
#include "DeviceScanner.h"
#include <QNetworkAddressEntry>
#include <QDateTime>

DeviceScanner::DeviceScanner(QObject *parent)
    : QObject(parent),
      m_udpSocket(new QUdpSocket(this)),
      m_scanTimer(new QTimer(this)),
      m_scanning(false)
{
    // 连接UDP套接字的readyRead信号，当有数据可读时触发
    connect(m_udpSocket, &QUdpSocket::readyRead, this, &DeviceScanner::onReadyRead);
    
    // 连接定时器的timeout信号，当扫描超时时触发
    connect(m_scanTimer, &QTimer::timeout, this, &DeviceScanner::onScanTimeout);
}

bool DeviceScanner::scanning() const
{
    return m_scanning;
}

QVariantList DeviceScanner::discoveredDevices() const
{
    return m_discoveredDevices;
}

void DeviceScanner::startDiscovery(int timeout)
{
    if (m_scanning) {
        return;
    }

    emit discoveryStarted();

    // 1. 清理上一次的扫描结果
    m_discoveredDevices.clear();
    m_foundDeviceIds.clear();
    emit discoveredDevicesChanged();

    // 2. 更新状态并绑定端口
    m_scanning = true;
    emit scanningChanged();
    m_udpSocket->bind(QHostAddress::AnyIPv4); // 绑定到任意IPv4地址以接收响应

    // 3. 遍历所有网段并发送探测包
    QList<QHostAddress> targets = getTargetHosts();
    QByteArray probeData = "lgcloud";
    for (const QHostAddress &host : targets) {
        m_udpSocket->writeDatagram(probeData, host, 7678);
    }

    // 4. 启动超时定时器
    m_scanTimer->start(timeout);
}

void DeviceScanner::startDiscoveryWithIps(const QString& ipList, int timeout)
{
    if (m_scanning) {
        return;
    }

    emit discoveryStarted();

    // 1. 清理上一次的扫描结果
    m_discoveredDevices.clear();
    m_foundDeviceIds.clear();
    m_pendingIps.clear();
    emit discoveredDevicesChanged();

    // 2. 更新状态并绑定端口
    m_scanning = true;
    emit scanningChanged();
    m_udpSocket->bind(QHostAddress::AnyIPv4); // 绑定到任意IPv4地址以接收响应

    // 3. 解析IP列表并发送探测包
    QStringList ips = ipList.split(',', Qt::SkipEmptyParts);
    if (ips.isEmpty()) {
        stopDiscovery();
        return;
    }
    QByteArray probeData = "lgcloud";
    for (const QString &ipString : ips) {
        QString trimmedIp = ipString.trimmed();
        QHostAddress host(trimmedIp);
        if (!host.isNull() && host.protocol() == QAbstractSocket::IPv4Protocol) {
            m_udpSocket->writeDatagram(probeData, host, 7678);
            m_pendingIps.insert(trimmedIp);
        } else {
            qWarning() << "DeviceScanner: Invalid IP address in list:" << ipString;
        }
    }

    // If no valid IPs were found to scan, stop immediately.
    if (m_pendingIps.isEmpty()) {
        stopDiscovery();
        return;
    }

    // 4. 启动超时定时器
    m_scanTimer->start(timeout);
}

void DeviceScanner::stopDiscovery()
{
    if (!m_scanning) {
        return;
    }

    m_scanTimer->stop();
    m_pendingIps.clear();
    m_udpSocket->close(); // close()会解绑端口，下次启动需要重新bind
    m_scanning = false;
    emit scanningChanged();
    emit discoveryFinished();
}

void DeviceScanner::onScanTimeout()
{
    if (!m_pendingIps.isEmpty()) {
        emit discoveryFailed(m_pendingIps.values());
    }
    stopDiscovery();
}

void DeviceScanner::onReadyRead()
{
    while (m_udpSocket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(m_udpSocket->pendingDatagramSize());
        QHostAddress senderIp;
        quint16 senderPort;

        m_udpSocket->readDatagram(datagram.data(), datagram.size(), &senderIp, &senderPort);
        m_pendingIps.remove(senderIp.toString());

        QString response = QString::fromUtf8(datagram).trimmed();
        qDebug() << "host" << response;
        if (response.startsWith("CBS:")) {
            QStringList parts = response.split(':');
            if (parts.size() >= 3) {
                QString deviceId = parts[1];
                
                // 如果设备ID已存在，则忽略，实现去重
                if (m_foundDeviceIds.contains(deviceId)) {
                    continue;
                }

                m_foundDeviceIds.insert(deviceId);

                QVariantMap device;
                device["ip"] = senderIp.toString();
                device["id"] = deviceId;
                device["name"] = parts[2];
                device["type"] = parts[0];
                device["last_scan"] = QDateTime::currentDateTime().toString(Qt::ISODate);

                m_discoveredDevices.append(device);
                emit discoveredDevicesChanged();
                emit deviceFound(device);
            }
        }
    }

    if (m_scanning && m_pendingIps.isEmpty()) {
        stopDiscovery();
    }
}

QList<QHostAddress> DeviceScanner::getTargetHosts()
{
    QList<QHostAddress> hosts;
    // 遍历所有网络接口
    for (const QNetworkInterface &iface : QNetworkInterface::allInterfaces()) {
        // 只处理活动的、非回环的接口
        if (!(iface.flags() & QNetworkInterface::IsUp) || (iface.flags() & QNetworkInterface::IsLoopBack)) {
            continue;
        }

        // 遍历接口上的所有IP地址条目
        for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
            // 只处理IPv4
            if (entry.ip().protocol() == QAbstractSocket::IPv4Protocol) {
                quint32 ip = entry.ip().toIPv4Address();
                quint32 netmask = entry.netmask().toIPv4Address();
                quint32 networkAddr = ip & netmask;
                quint32 broadcastAddr = networkAddr | (~netmask);

                // 从网络地址+1到广播地址-1，都是有效的主机地址
                for (quint32 i = networkAddr + 1; i < broadcastAddr; ++i) {
                    hosts.append(QHostAddress(i));
                }
            }
        }
    }
    return hosts;
}

