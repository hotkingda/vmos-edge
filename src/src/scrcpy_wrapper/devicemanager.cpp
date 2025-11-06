#include "devicemanager.h"
#include <QCoreApplication>
#include <QDebug>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <QDir>

DeviceManager::DeviceManager(QObject *parent)
    : QObject(parent)
    , m_deviceManage(qsc::IDeviceManage::getInstance())
{
    connect(&m_deviceManage, &qsc::IDeviceManage::deviceConnected, this, &DeviceManager::onDeviceConnected);
    connect(&m_deviceManage, &qsc::IDeviceManage::deviceDisconnected, this, &DeviceManager::onDeviceDisconnected);
}

DeviceManager::~DeviceManager()
{
}

void DeviceManager::connectDevice(const QString &serial)
{
    qsc::DeviceParams params;
    params.serial = serial;

    // QtScrcpyCore's CMakeLists copies scrcpy-server to the application directory.
    params.serverLocalPath = QCoreApplication::applicationDirPath() + "/scrcpy-server";

    // FIX: Set a random, non-negative scid to ensure socket names match
    params.scid = QRandomGenerator::global()->bounded(1, 10000) & 0x7FFFFFFF;

    // Set recordPath to user Pictures directory / vmosedge
    QString picturesPath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    params.recordPath = picturesPath + "/vmosedge/";

    // Set some default parameters
    params.maxSize = 0;
    params.bitRate = 4000000;
    // params.maxFps = 60;
    params.logLevel = "warn";
    params.useReverse = true; // Use adb reverse by default
    params.stayAwake = false;
    params.closeScreen = false;
    qInfo() << "Connecting to device:" << serial << "with scid:" << params.scid;
    // 字符串参数 (QString/QByteArray)
    qDebug() << "serial:" << params.serial;
    qDebug() << "recordPath:" << params.recordPath;
    qDebug() << "recordFileFormat:" << params.recordFileFormat;
    qDebug() << "serverLocalPath:" << params.serverLocalPath;
    qDebug() << "serverRemotePath:" << params.serverRemotePath;
    qDebug() << "pushFilePath:" << params.pushFilePath;
    qDebug() << "gameScript:" << params.gameScript;
    qDebug() << "serverVersion:" << params.serverVersion;
    qDebug() << "logLevel:" << params.logLevel;
    qDebug() << "codecOptions:" << params.codecOptions;
    qDebug() << "codecName:" << params.codecName;

    // 数值参数 (int/quint32/qint32)
    qDebug() << "maxSize:" << params.maxSize;
    qDebug() << "bitRate:" << params.bitRate;
    qDebug() << "maxFps:" << params.maxFps;
    qDebug() << "captureOrientationLock:" << params.captureOrientationLock;
    qDebug() << "captureOrientation:" << params.captureOrientation;
    qDebug() << "scid (Session ID):" << params.scid;

    // 布尔值参数 (bool)
    qDebug() << "closeScreen:" << (params.closeScreen ? "true" : "false");
    qDebug() << "useReverse:" << (params.useReverse ? "true" : "false");
    qDebug() << "display:" << (params.display ? "true" : "false");
    qDebug() << "renderExpiredFrames:" << (params.renderExpiredFrames ? "true" : "false");
    qDebug() << "stayAwake:" << (params.stayAwake ? "true" : "false");
    qDebug() << "recordFile:" << (params.recordFile ? "true" : "false");

    qDebug() << "--- [End Parameters Log] ---";
    m_deviceManage.connectDevice(params);
}

void DeviceManager::disconnectDevice(const QString &serial)
{
    qInfo() << "Disconnecting from device:" << serial;
    m_deviceManage.disconnectDevice(serial);
}

QPointer<qsc::IDevice> DeviceManager::getDevice(const QString &serial)
{
    return m_deviceManage.getDevice(serial);
}

void DeviceManager::onDeviceConnected(bool success, const QString &serial, const QString &deviceName, const QSize &size)
{
    if (success) {
        qInfo() << "Device connected:" << deviceName << size;
        emit deviceConnected(serial, deviceName, size);
    } else {
        qWarning() << "Device connect failed:" << serial;
        emit deviceConnectFailed(serial);
    }
}

void DeviceManager::onDeviceDisconnected(const QString &serial)
{
    qInfo() << "Device disconnected:" << serial;
    emit deviceDisconnected(serial);
}
