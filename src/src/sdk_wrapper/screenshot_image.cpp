#include "screenshot_image.h"
#include "video_frame.h"
#include <QPainter>
#include <QtNetwork/QNetworkRequest>
#include <QBuffer>

#include "libyuv.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

ScreenshotRenderItem::ScreenshotRenderItem(QQuickItem* parent)
    : QQuickPaintedItem(parent)
    , m_networkManager(new QNetworkAccessManager(this)) // 初始化网络管理器
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject); // 可选：提高性能
    setAntialiasing(false);

    // 连接网络管理器的 finished 信号到我们的槽函数
    connect(m_networkManager, &QNetworkAccessManager::finished, this, &ScreenshotRenderItem::onImageDownloaded);
}

ScreenshotRenderItem::~ScreenshotRenderItem() = default;

void ScreenshotRenderItem::onFrame(std::shared_ptr<armcloud::VideoFrame>& frame) {
    if (!frame) return;

    setHasVideo(true);
    // 创建临时 QImage，使用原始数据指针（只要确保 frame 生命周期有效即可）
    QImage image(frame->buffer(0), frame->width(), frame->height(), frame->width() * 4, QImage::Format_ARGB32);

    {
        QMutexLocker locker(&m_mutex);
        m_image = image.copy(); // 拷贝数据，避免悬空引用
    }

    // 通知 Qt 在 GUI 线程上重绘
    QMetaObject::invokeMethod(this, [this]() {
        update();
    }, Qt::QueuedConnection);
}

void ScreenshotRenderItem::paint(QPainter* painter) {
    QMutexLocker locker(&m_mutex);
    if (!m_image.isNull()) {
        painter->setRenderHint(QPainter::SmoothPixmapTransform, true);

        // 原始图像尺寸
        QSizeF imageSize(m_image.width(), m_image.height());

        if(rotation() == 0){
            // 竖屏
            if(imageSize.width() < imageSize.height()){
                m_angle = 0;
            }else{
                m_angle = 90;
            }
        }else{
            // 横屏
            if(imageSize.width() < imageSize.height()){
                m_angle = -90;
            }else{
                m_angle = 0;
            }
        }
        // 判断是否需要交换宽高（90°或270°旋转）
        bool isVertical = !qFuzzyCompare(fmod(qAbs(m_angle), 180.0), 0.0);

        // 计算目标绘制区域
        QRectF destRect = boundingRect();
        QSizeF targetSize = isVertical ? QSizeF(destRect.height(), destRect.width())
                                       : destRect.size();

        // 计算缩放比例，保持图像比例
        qreal scale = qMin(targetSize.width() / imageSize.width(),
                           targetSize.height() / imageSize.height());
        QSizeF scaledSize = imageSize * scale;

        painter->save();
        // 先绘制背景色填充，避免黑边
        painter->fillRect(destRect, QColor("#F3F3F3"));

        // 将坐标系移到 Item 中心
        painter->translate(destRect.center());

        // 应用旋转
        painter->rotate(m_angle);

        // 绘制图像（考虑缩放和居中）
        painter->translate(-scaledSize.width()/2, -scaledSize.height()/2);
        painter->drawImage(QRectF(QPointF(0, 0), scaledSize), m_image,
                           QRectF(QPointF(0, 0), imageSize));

        painter->restore();
    }
}

void ScreenshotRenderItem::setRotation(qreal rotation){
    if (qFuzzyCompare(m_rotation, rotation))
        return;

    m_rotation = rotation;
    emit rotationChanged(); // 属性改变时发出信号
    update();
}

void ScreenshotRenderItem::setImageUrl(const QUrl& url) {
    if (m_imageUrl != url){
        m_imageUrl = url;
        emit imageUrlChanged(); // 属性改变时发出信号
    }
    
    if (m_imageUrl.isValid()) {
        // 添加请求标识，避免串图
        QString requestId = QString::number(QDateTime::currentMSecsSinceEpoch()) + "_" + QString::number(reinterpret_cast<quintptr>(this));
        // qDebug() << "ScreenshotRenderItem::setImageUrl - Request ID:" << requestId << "URL:" << url.toString();
        
        QByteArray data;
        postImageRequest(m_imageUrl, data, requestId);
    }else{
        // 无效不做任何处理
    }
}

void ScreenshotRenderItem::postImageRequest(const QUrl& url, const QByteArray& postData, const QString& requestId) {
    if (!url.isValid()) {
        qWarning() << "postImageRequest: Invalid URL provided.";
        return;
    }

    QNetworkRequest request(url);
    // 添加请求标识头，避免缓存和串图
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("X-Request-ID", requestId.toUtf8());
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    
    // qDebug() << "ScreenshotRenderItem: POST request sent to" << url << "with Request ID:" << requestId;
    m_networkManager->get(request);
}

void ScreenshotRenderItem::setHasVideo(bool value)
{
    if (m_hasVideo == value)
        return;
    m_hasVideo = value;
    emit hasVideoChanged();
}

void ScreenshotRenderItem::onImageDownloaded(QNetworkReply* reply) {
    // 获取请求标识用于调试
    QString requestId = reply->request().rawHeader("X-Request-ID");
    
    if (reply->error() == QNetworkReply::NoError) {
        // 读取所有可用的数据
        QByteArray imageData = reply->readAll();
        
        if (imageData.isEmpty()) {
            qWarning() << "ScreenshotRenderItem: Empty image data received for Request ID:" << requestId;
            reply->deleteLater();
            return;
        }

        int channels;
        int width = 0;
        int height = 0;
        unsigned char* rgba = stbi_load_from_memory((const uint8_t*)imageData.data(), imageData.size(), &width, &height, &channels, 4); // force RGBA
        if (!rgba) {
            // qWarning() << "ScreenshotRenderItem: Failed to decode image data for Request ID:" << requestId;
            reply->deleteLater();
            return;
        }

        // qDebug() << "ScreenshotRenderItem: Successfully decoded image" << width << "x" << height << "for Request ID:" << requestId;
        
        auto videoFrame = std::make_shared<armcloud::VideoFrame>(width, height, armcloud::PixelFormat::ARGB);
        libyuv::ABGRToARGB(rgba, width * 4, videoFrame->buffer(0), width * 4, width, height);
        stbi_image_free(rgba);

        onFrame(videoFrame);
    } else {
        qWarning() << "ScreenshotRenderItem: Image download error for Request ID:" << requestId << "Error:" << reply->errorString();
        setHasVideo(false);
    }
    reply->deleteLater(); // 释放 QNetworkReply 资源
}
