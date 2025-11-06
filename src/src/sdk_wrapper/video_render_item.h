#pragma once

#include <QQuickPaintedItem>
#include <QImage>
#include <QMutex>
#include <memory>
#include "video_render_sink.h"


class VideoRenderItem : public QQuickPaintedItem, public armcloud::VideoRenderSink {
    Q_OBJECT

    Q_PROPERTY(qreal rotation READ rotation WRITE setRotation)
    Q_PROPERTY(bool hasVideo READ hasVideo WRITE setHasVideo NOTIFY hasVideoChanged FINAL)
public:
    explicit VideoRenderItem(QQuickItem* parent = nullptr);
    ~VideoRenderItem() override;

    void onFrame(std::shared_ptr<armcloud::VideoFrame>& frame) override;
    void paint(QPainter* painter) override;

    qreal rotation() const { return m_angle; }
    void setRotation(qreal angle);

    bool hasVideo() const { return m_hasVideo; }
    void setHasVideo(bool value);

signals:
    void hasVideoChanged();
private:
    QImage m_image;
    QMutex m_mutex;
    qreal m_angle = 0.0;
    bool m_hasVideo = false;
};
