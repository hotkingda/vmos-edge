#pragma once

#include <memory>

namespace armcloud {
class VideoFrame;
class VideoRenderSink {
public:
	virtual ~VideoRenderSink() = default;
	virtual void onFrame(std::shared_ptr<armcloud::VideoFrame>& frame) = 0;
};
} // namespace armcloud
