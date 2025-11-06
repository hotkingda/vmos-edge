#pragma once

#include <QQuickPaintedItem>
#include <QImage>
#include <QMutex>
#include <memory>
#include <QtNetwork/QNetworkAccessManager> // 新增：用于网络请求
#include <QtNetwork/QNetworkReply>       // 新增：用于网络回复
#include "video_render_sink.h"


class ScreenshotRenderItem : public QQuickPaintedItem {
    Q_OBJECT

    // 现有属性：旋转
    Q_PROPERTY(qreal rotation READ rotation WRITE setRotation NOTIFY rotationChanged)
    // 新增属性：图片 URL
    Q_PROPERTY(QUrl imageUrl READ imageUrl WRITE setImageUrl NOTIFY imageUrlChanged)
    Q_PROPERTY(bool hasVideo READ hasVideo WRITE setHasVideo NOTIFY hasVideoChanged FINAL)
public:
    explicit ScreenshotRenderItem(QQuickItem* parent = nullptr);
    ~ScreenshotRenderItem() override;

    void onFrame(std::shared_ptr<armcloud::VideoFrame>& frame);
    void paint(QPainter* painter) override;

    // rotation 属性的 getter 和 setter
    qreal rotation() const { return m_rotation; }
    void setRotation(qreal angle);

    // imageUrl 属性的 getter 和 setter
    QUrl imageUrl() const { return m_imageUrl; }
    void setImageUrl(const QUrl& url);
    bool hasVideo() const { return m_hasVideo; }
    void setHasVideo(bool value);
private:
    void postImageRequest(const QUrl &url, const QByteArray &postData, const QString &requestId);
signals:
    // 旋转属性改变时发出信号
    void rotationChanged();
    // 图片 URL 属性改变时发出信号
    void imageUrlChanged();

    void hasVideoChanged();
private slots:
    // 处理图片下载完成的槽函数
    void onImageDownloaded(QNetworkReply* reply);

private:
    QImage m_image;
    QMutex m_mutex;
    qreal m_angle = 0.0;
    qreal m_rotation = 0.0;
    QUrl m_imageUrl; // 存储图片 URL
    bool m_hasVideo = false;
    QNetworkAccessManager* m_networkManager; // 网络访问管理器
};
