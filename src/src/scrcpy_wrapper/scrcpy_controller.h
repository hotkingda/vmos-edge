#pragma once

#include <QObject>
#include <QPointer>
#include <QSize>
#include "QtScrcpyCore.h"
#include "../sdk_wrapper/video_render_sink.h"

// Forward declarations for input events
class QMouseEvent;
class QWheelEvent;
class QKeyEvent;

class ScrcpyController : public QObject, public qsc::DeviceObserver
{
    Q_OBJECT
public:
    explicit ScrcpyController(QObject *parent = nullptr);
    ~ScrcpyController() override;

    /**
     * @brief Initializes the controller and connects it to the device and the sink.
     * @param device The device object from QtScrcpyCore, obtained via DeviceManager.
     * @param sink The UI render item (your VideoRenderItem) which implements armcloud::VideoRenderSink.
     */
    Q_INVOKABLE void initialize(QPointer<qsc::IDevice> device, armcloud::VideoRenderSink* sink);

    // --- Input Handling Slots --- //
    Q_INVOKABLE void sendMouseEvent(const QVariant& event, int viewWidth, int viewHeight);
    Q_INVOKABLE void sendWheelEvent(const QVariant& event, int viewWidth, int viewHeight);
    Q_INVOKABLE void sendKeyEvent(const QVariant& event);

    // --- Device Control Slots --- //
    Q_INVOKABLE void sendGoBack();
    Q_INVOKABLE void sendGoHome();
    Q_INVOKABLE void sendGoMenu();
    Q_INVOKABLE void sendAppSwitch();
    Q_INVOKABLE void sendPower();
    Q_INVOKABLE void sendVolumeUp();
    Q_INVOKABLE void sendVolumeDown();
    // Q_INVOKABLE void setDisplayPower(bool on);
    // Q_INVOKABLE void expandNotificationPanel();
    // Q_INVOKABLE void collapsePanel();
    Q_INVOKABLE void sendTextInput(const QString& text);
    // Q_INVOKABLE void clipboardPaste();
    Q_INVOKABLE void localScreenshot();
    Q_INVOKABLE void sendPushFileRequest(const QString& file, const QString& devicePath = "");
    Q_INVOKABLE void sendInstallApkRequest(const QString& apkFile);
    // Q_INVOKABLE void showTouch(bool show);

signals:
    void newFrame(const QImage &frame);
    void fpsUpdated(int fps);
    void grabCursorChanged(bool grab);
    void screenInfo(int width, int height);
    void connectionEstablished();
    void connectionLost();

protected:
    // Override from qsc::DeviceObserver
    void onFrame(int width, int height, uint8_t* dataY, uint8_t* dataU, uint8_t* dataV, int linesizeY, int linesizeU, int linesizeV) override;
    void updateFPS(quint32 fps) override;
    void grabCursor(bool grab) override;

private:
    QPointer<qsc::IDevice> m_device;
    armcloud::VideoRenderSink* m_sink = nullptr;
    QSize m_frameSize;
    bool m_isFirstFrame;
};
