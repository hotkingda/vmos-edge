#include "scrcpy_controller.h"
#include "../sdk_wrapper/video_frame.h"
#include <QDebug>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QKeyEvent>
#include <QVariantMap>
#include <libyuv.h>

ScrcpyController::ScrcpyController(QObject *parent)
    : QObject(parent)
    , m_isFirstFrame(false)
{
}

ScrcpyController::~ScrcpyController()
{
    if (m_device) {
        m_device->deRegisterDeviceObserver(this);
    }
}

void ScrcpyController::initialize(QPointer<qsc::IDevice> device, armcloud::VideoRenderSink* sink)
{
    if (!device || !sink) {
        qWarning() << "ScrcpyController::initialize - device or sink is null";
        return;
    }
    m_device = device;
    m_sink = sink;
    m_device->registerDeviceObserver(this);

    connect(m_device, &qsc::IDevice::deviceConnected, this, [this](bool success, const QString& serial, const QString& deviceName, const QSize& size){
        if (success) {
            emit connectionEstablished();
        }
    });
    connect(m_device, &qsc::IDevice::deviceDisconnected, this, [this](const QString& serial){
        emit connectionLost();
    });
}

void ScrcpyController::onFrame(int width, int height, uint8_t* dataY, uint8_t* dataU, uint8_t* dataV, int linesizeY, int linesizeU, int linesizeV)
{
    if (!m_sink) {
        return;
    }

    if(!m_isFirstFrame){
        m_isFirstFrame = true;
        emit screenInfo(width, height);
    }

    m_frameSize = QSize(width, height);

    // Create an ARGB VideoFrame, which is what the existing rendering pipeline expects.
    auto videoFrame = std::make_shared<armcloud::VideoFrame>(width, height, armcloud::PixelFormat::ARGB);

    // Use libyuv to convert from I420 (YUV420P) to ARGB.
    libyuv::I420ToARGB(dataY, linesizeY,
                       dataU, linesizeU,
                       dataV, linesizeV,
                       videoFrame->buffer(0), videoFrame->stride(0),
                       width, height);

    // Call the sink's onFrame method (which is implemented by VideoRenderItem)
    m_sink->onFrame(videoFrame);
}

void ScrcpyController::updateFPS(quint32 fps)
{
    emit fpsUpdated(fps);
}

void ScrcpyController::grabCursor(bool grab)
{
    emit grabCursorChanged(grab);
}

// --- Input Event Handling --- //

void ScrcpyController::sendMouseEvent(const QVariant& event, int viewWidth, int viewHeight)
{
    if (!m_device || m_frameSize.isEmpty()) return;

    QVariantMap map = event.toMap();
    QPointF pos(map["x"].toReal(), map["y"].toReal());
    Qt::MouseButtons buttons = static_cast<Qt::MouseButtons>(map["buttons"].toInt());
    Qt::MouseButton button = static_cast<Qt::MouseButton>(map["button"].toInt());
    QEvent::Type type = static_cast<QEvent::Type>(map["type"].toInt());

    QMouseEvent mouseEvent(type, pos, button, buttons, Qt::NoModifier);

    m_device->mouseEvent(&mouseEvent, m_frameSize, QSize(viewWidth, viewHeight));
}

void ScrcpyController::sendWheelEvent(const QVariant& event, int viewWidth, int viewHeight)
{
    if (!m_device || m_frameSize.isEmpty()) return;

    QVariantMap map = event.toMap();
    QPointF pos(map["x"].toReal(), map["y"].toReal());
    QPoint angleDelta = map["angleDelta"].toPoint();
    Qt::MouseButtons buttons = static_cast<Qt::MouseButtons>(map["buttons"].toInt());
    Qt::KeyboardModifiers modifiers = static_cast<Qt::KeyboardModifiers>(map["modifiers"].toInt());

    // Use the more complete Qt 6 constructor, filling unused arguments with defaults.
    QWheelEvent wheelEvent(pos, pos, QPoint(), angleDelta, buttons, modifiers, Qt::ScrollUpdate, false);

    m_device->wheelEvent(&wheelEvent, m_frameSize, QSize(viewWidth, viewHeight));
}

void ScrcpyController::sendKeyEvent(const QVariant& event)
{
    if (!m_device || m_frameSize.isEmpty()) return;

    QVariantMap map = event.toMap();
    QEvent::Type type = static_cast<QEvent::Type>(map["type"].toInt());
    int key = map["key"].toInt();
    Qt::KeyboardModifiers modifiers = static_cast<Qt::KeyboardModifiers>(map["modifiers"].toInt());
    QString text = map["text"].toString();

    QKeyEvent keyEvent(type, key, modifiers, text);

    m_device->keyEvent(&keyEvent, m_frameSize, m_frameSize);
}

// --- Device Control Implementations --- //

void ScrcpyController::sendGoBack() {
    if (m_device) {
        m_device->postGoBack();
    }
}

void ScrcpyController::sendGoHome() {
    if (m_device){
        m_device->postGoHome();
    }
}

void ScrcpyController::sendGoMenu() {
    if (m_device) {
        m_device->postGoMenu();
    }
}

void ScrcpyController::sendAppSwitch() {
    if (m_device) {
        m_device->postAppSwitch();
    }
}

void ScrcpyController::sendPower() {
    if (m_device) {
        m_device->postPower();
    }
}

void ScrcpyController::sendVolumeUp() {
    if (m_device) {
        m_device->postVolumeUp();
    }
}

void ScrcpyController::sendVolumeDown() {
    if (m_device) {
        m_device->postVolumeDown();
    }
}

// void ScrcpyController::setDisplayPower(bool on) {
//     if (m_device) {
//         m_device->setDisplayPower(on);
//     }
// }

// void ScrcpyController::expandNotificationPanel() {
//     if (m_device) {
//         m_device->expandNotificationPanel();
//     }
// }

// void ScrcpyController::collapsePanel() {
//     if (m_device) {
//         m_device->collapsePanel();
//     }
// }

// void ScrcpyController::clipboardPaste() {
//     if (m_device) {
//         m_device->clipboardPaste();
//     }
// }

// void ScrcpyController::showTouch(bool show) {
//     if (m_device){
//         m_device->showTouch(show);
//     }
// }

void ScrcpyController::sendTextInput(const QString& text)
{
    if (m_device) {
        QString nonConstText = text;
        m_device->postTextInput(nonConstText);
    }
}

void ScrcpyController::localScreenshot()
{
    if (m_device) {
        m_device->screenshot();
    }
}

void ScrcpyController::sendPushFileRequest(const QString& file, const QString& devicePath)
{
    if (m_device) {
        m_device->pushFileRequest(file, devicePath);
    }
}

void ScrcpyController::sendInstallApkRequest(const QString& apkFile)
{
    if (m_device) {
        m_device->installApkRequest(apkFile);
    }
}
