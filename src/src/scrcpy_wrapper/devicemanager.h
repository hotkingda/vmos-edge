#pragma once

#include <QObject>
#include <QSize>
#include "QtScrcpyCore.h"

class DeviceManager : public QObject
{
    Q_OBJECT
public:
    explicit DeviceManager(QObject *parent = nullptr);
    ~DeviceManager();

    Q_INVOKABLE void connectDevice(const QString &serial);
    Q_INVOKABLE void disconnectDevice(const QString &serial);
    Q_INVOKABLE QPointer<qsc::IDevice> getDevice(const QString &serial);

signals:
    void deviceConnected(const QString &serial, const QString &deviceName, const QSize &size);
    void deviceDisconnected(const QString &serial);
    void deviceConnectFailed(const QString &serial);

private slots:
    void onDeviceConnected(bool success, const QString& serial, const QString& deviceName, const QSize& size);
    void onDeviceDisconnected(const QString& serial);

private:
    qsc::IDeviceManage& m_deviceManage;
};
