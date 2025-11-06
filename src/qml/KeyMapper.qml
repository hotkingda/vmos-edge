pragma Singleton
import QtQuick

QtObject {
    // 定义 Windows 到 Android 的键值映射表
    readonly property var keyMapping: {
        // 控制键
        16777219: 67,   // VK_BACK -> KEYCODE_DEL
        // 0x09: 61,   // VK_TAB -> KEYCODE_TAB
        16777220 : 66,   // VK_RETURN -> KEYCODE_ENTER
        // 0x10: 59,   // VK_SHIFT -> KEYCODE_SHIFT_LEFT
        // 0x11: 113,  // VK_CONTROL -> KEYCODE_CTRL_LEFT
        // 0x12: 57,   // VK_MENU (Alt) -> KEYCODE_ALT_LEFT
        // 0x20: 62,   // VK_SPACE -> KEYCODE_SPACE

        // 方向键
        16777234: 21,   // VK_LEFT -> KEYCODE_DPAD_LEFT
        16777235: 19,   // VK_UP -> KEYCODE_DPAD_UP
        16777236: 22,   // VK_RIGHT -> KEYCODE_DPAD_RIGHT
        16777237: 20,   // VK_DOWN -> KEYCODE_DPAD_DOWN

        // 数字键（直接映射）
        // 0x30: 7,  // 0 -> KEYCODE_0
        // 0x31: 8,  // 1 -> KEYCODE_1
        // 0x32: 9,  // 2 -> KEYCODE_2
        // 0x33: 10, // 3 -> KEYCODE_3
        // 0x34: 11, // 4 -> KEYCODE_4
        // 0x35: 12, // 5 -> KEYCODE_5
        // 0x36: 13, // 6 -> KEYCODE_6
        // 0x37: 14, // 7 -> KEYCODE_7
        // 0x38: 15, // 8 -> KEYCODE_8
        // 0x39: 16, // 9 -> KEYCODE_9

        // 字母键（A-Z 直接映射）
        0x41: 29, // A -> KEYCODE_A
        0x42: 30, // B -> KEYCODE_B
        0x43: 31, // C -> KEYCODE_C
        0x44: 32, // D -> KEYCODE_D
        0x45: 33, // E -> KEYCODE_E
        0x46: 34, // F -> KEYCODE_F
        0x47: 35, // G -> KEYCODE_G
        0x48: 36, // H -> KEYCODE_H
        0x49: 37, // I -> KEYCODE_I
        0x4A: 38, // J -> KEYCODE_J
        0x4B: 39, // K -> KEYCODE_K
        0x4C: 40, // L -> KEYCODE_L
        0x4D: 41, // M -> KEYCODE_M
        0x4E: 42, // N -> KEYCODE_N
        0x4F: 43, // O -> KEYCODE_O
        0x50: 44, // P -> KEYCODE_P
        0x51: 45, // Q -> KEYCODE_Q
        0x52: 46, // R -> KEYCODE_R
        0x53: 47, // S -> KEYCODE_S
        0x54: 48, // T -> KEYCODE_T
        0x55: 49, // U -> KEYCODE_U
        0x56: 50, // V -> KEYCODE_V
        0x57: 51, // W -> KEYCODE_W
        0x58: 52, // X -> KEYCODE_X
        0x59: 53, // Y -> KEYCODE_Y
        0x5A: 54  // Z -> KEYCODE_Z

    }

    // 转换方法（支持直接传入 Qt.Key_XXX 常量）
    function getAndroidKeyCode(winKeyCode) {
        // 处理 Qt 的跨平台键值差异
        const adjustedCode = adjustPlatformKeyCode(winKeyCode)

        // 查找映射表
        const androidCode = keyMapping[adjustedCode]

        // 返回结果或默认值
        return androidCode !== undefined ? androidCode : -1
    }

    // 处理 Qt 键值与原生键值的差异
    function adjustPlatformKeyCode(code) {
        // 示例：Qt 的 Key_Back 对应不同平台的原始值
        if (code === Qt.Key_Back) {
            return 0x08 // 强制映射到 VK_BACK
        }
        return code
    }
}
