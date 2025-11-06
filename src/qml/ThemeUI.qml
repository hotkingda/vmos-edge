pragma Singleton
import QtQuick

QtObject  {
    property color primary: "#596380"
    property color grayLine: "#b8bdcc"
    property color leftText: "#26304d"
    property color bkcolor: "#007aff"
    property color blueColor: "#007aff"
    property color blackColor: "black"
    property color grayColor: "#e5e5e5"
    property color primaryColor: AppConfig.projectName == "vsphone" ?  "#F4AE22" : "#007aff"
    property color textColor: AppConfig.projectName == "vsphone" ? "black" : "white"
    property color backgroundColor: AppConfig.projectName == "vsphone" ? "#262626" : "#d6e6ff"
    property color selectColor: AppConfig.projectName == "vsphone" ? "#F4AE22" : "#c4dcfe"
    property color titleColor: AppConfig.projectName == "vsphone" ? "#F4AE22" : "white"
    property color listTextColor: AppConfig.projectName == "vsphone" ? "#B2FFFFFF" : "#26304d"

    function loadRes(src){
        const prefix = AppConfig.projectName == "vsphone" ? "/vsphone/" : "/"
        return "qrc:/res" + prefix + src
    }
}
