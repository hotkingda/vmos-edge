#include "video_render_item.h"
#include "video_frame.h"
#include <QPainter>

VideoRenderItem::VideoRenderItem(QQuickItem* parent)
    : QQuickPaintedItem(parent)
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject); // 可选提高性能
    setAntialiasing(false);
}

VideoRenderItem::~VideoRenderItem() = default;


void VideoRenderItem::onFrame(std::shared_ptr<armcloud::VideoFrame>& frame) {
    if (!frame) return;

    setHasVideo(true);
    // // 创建临时 QImage，使用原始数据指针（只要确保 frame 生命周期有效即可）
    QImage image(frame->buffer(0), frame->width(), frame->height(), frame->width() * 4, QImage::Format_ARGB32);

    {
        QMutexLocker locker(&m_mutex);
        m_image = image.copy(); // 拷贝数据，避免悬空引用
    }

    // update(); // 通知 Qt 重绘
    QMetaObject::invokeMethod(this, [this]() {
        update();
    }, Qt::QueuedConnection);
}

void VideoRenderItem::paint(QPainter* painter) {
    QMutexLocker locker(&m_mutex);
    if (!m_image.isNull()) {
        painter->setRenderHint(QPainter::SmoothPixmapTransform, true);

        // 原始图像尺寸
        QSizeF imageSize(m_image.width(), m_image.height());

        qreal currentRotation = rotation() - (imageSize.height() > imageSize.width() ? 0.0 : 270.0);

        // 判断是否需要交换宽高（90°或270°旋转）
        bool isVertical = !qFuzzyCompare(fmod(qAbs(currentRotation), 180.0), 0.0);

        // 计算目标绘制区域
        QRectF destRect = boundingRect();
        QSizeF targetSize = isVertical ? QSizeF(destRect.height(), destRect.width())
                                       : destRect.size();

        // 计算缩放比例，保持图像比例
        qreal scale = qMin(targetSize.width() / imageSize.width(),
                           targetSize.height() / imageSize.height());
        QSizeF scaledSize = imageSize * scale;

        // 计算居中位置
        QPointF centerOffset((targetSize.width() - scaledSize.width()) / 2,
                             (targetSize.height() - scaledSize.height()) / 2);

        painter->save();

        // 将坐标系移到Item中心
        painter->translate(destRect.center());

        // 应用旋转
        painter->rotate(currentRotation);

        // 绘制图像（考虑缩放和居中）
        painter->translate(-scaledSize.width()/2, -scaledSize.height()/2);
        painter->drawImage(QRectF(QPointF(0, 0), scaledSize), m_image,
                           QRectF(QPointF(0, 0), imageSize));

        painter->restore();
    }
}


void VideoRenderItem::setRotation(qreal angle){
    if (qFuzzyCompare(m_angle, angle))
        return;

    m_angle = angle;

    update();
}

void VideoRenderItem::setHasVideo(bool value) {
    if (m_hasVideo == value)
        return;
    m_hasVideo = value;
    emit hasVideoChanged();
}

