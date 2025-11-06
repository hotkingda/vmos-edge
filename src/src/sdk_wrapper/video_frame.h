#pragma once

#include <stdint.h>
#include <algorithm> // For std::min
#include <cstring>   // For memcpy

namespace armcloud {

enum class PixelFormat{
    RGBA,
    ARGB,
    YUV420P
};

class VideoFrame {
public:
    explicit VideoFrame(uint32_t width, uint32_t height, PixelFormat format)
        : m_width(width)
        , m_height(height)
        , m_format(format)
    {
        if(PixelFormat::ARGB == format || PixelFormat::RGBA == format){
            m_stride[0] = width * 4;
            m_size[0] = m_stride[0] * height;
            m_buffer[0] = new uint8_t[m_size[0]];
        }else if(PixelFormat::YUV420P == format){
            m_stride[0] = width;
            m_stride[1] = width / 2;
            m_stride[2] = width / 2;
            m_size[0] = m_stride[0] * height;
            m_size[1] = m_stride[1] * (height / 2);
            m_size[2] = m_stride[2] * (height / 2);
            m_buffer[0] = new uint8_t[m_size[0]];
            m_buffer[1] = new uint8_t[m_size[1]];
            m_buffer[2] = new uint8_t[m_size[2]];
        }
	}

    explicit VideoFrame(uint32_t width, uint32_t height, uint32_t stridey, uint32_t strideu, uint32_t stridev)
        : m_width(width)
        , m_height(height)
        , m_format(PixelFormat::YUV420P)
    {
        m_stride[0] = stridey;
        m_stride[1] = strideu;
        m_stride[2] = stridev;
        m_size[0] = m_stride[0] * height;
        m_size[1] = m_stride[1] * (height / 2);
        m_size[2] = m_stride[2] * (height / 2);
        m_buffer[0] = new uint8_t[m_size[0]];
        m_buffer[1] = new uint8_t[m_size[1]];
        m_buffer[2] = new uint8_t[m_size[2]];
    }

	virtual ~VideoFrame() {
        if(PixelFormat::ARGB == m_format || PixelFormat::RGBA == m_format){
            if(m_buffer[0]) delete[] m_buffer[0];
        }else if(PixelFormat::YUV420P == m_format){
            if(m_buffer[0]) delete[] m_buffer[0];
            if(m_buffer[1]) delete[] m_buffer[1];
            if(m_buffer[2]) delete[] m_buffer[2];
        }
	}

    inline uint32_t width() const {
		return m_width;
	}

    inline uint32_t height() const {
		return m_height;
	}

    inline uint8_t* buffer(int planes) const {
        return m_buffer[planes];
	}

    inline uint32_t stride(int planes) const {
        return m_stride[planes];
    }

    inline uint32_t size(int planes) const {
        return m_size[planes];
	}

    inline PixelFormat format() const {
        return m_format;
    }

private:
	uint32_t m_width;
	uint32_t m_height;
    uint8_t* m_buffer[4] = {nullptr};
    uint32_t m_stride[4] = {0};
    uint32_t m_size[4] = {0};
    PixelFormat m_format;
};
} // namespace armcloud
