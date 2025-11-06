pragma Singleton

import QtQuick
import FluentUI

QtObject  {
    // 版本标识符，用于强制刷新缓存
    property string version: "2.0"

    function getStateStringBystate(status){
        if (status === "restarting") {
            return qsTr("重启中")
        }
        else if (status === "removing") {
            return qsTr("删除中")
        }
        else if (status === "created") {
            return qsTr("创建中")
        }
        else if (status === "creating") {
            return qsTr("创建中")
        }
        else if (status === "exited" || status === "stopped") {
            return qsTr("已关机")
        }
        else if (status === "paused") {
            return qsTr("已暂停")
        }
        else if (status === "dead") {
            return qsTr("异常")
        }
        else if(status === "running"){
            return qsTr("运行中")
        }
        else if(status === "online"){
            return qsTr("在线")
        }
        else if(status === "offline"){
            return qsTr("离线")
        }
        else if(status === "deleting"){
            return qsTr("删除中")
        }
        else if(status === "starting"){
            return qsTr("启动中")
        }
        else if(status === "stopping"){
            return qsTr("关机中")
        }
        else if(status === "rebooting"){
            return qsTr("重启中")
        }
        else if(status === "rebuilding"){
            return qsTr("重置中")
        }
        else if(status === "upgrading"){
            return qsTr("修改镜像中")
        }
        else if(status === "renewing"){
            return qsTr("一键新机中")
        }
        else if(status === "failed"){
            return qsTr("任务失败")
        }

        return qsTr("未知状态") + "(" + status + ")"
    }

    function getStateColorBystate(status){
        if (status === "restarting") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if (status === "removing") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if (status === "created") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if (status === "creating") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if (status === "exited" || status === "stopped") {
            return {text:"#B8B8B8", bg:"#F5F5F5", border:"#D9D9D9"}
        }
        else if (status === "paused") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if (status === "dead") {
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if(status === "running" || status === "online"){
            return {text:"#52C41A", bg:"#F6FFED", border:"#B7EB8F"}
        }
        else if(status === "offline"){
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if(status === "deleting"){
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }
        else if(status === "upgrading"){
            return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
        }

        return {text:"#FF3F42", bg:"#FFF0F1", border:"#FF9294"}
    }

    function mbToGB(mb) {
        if (typeof mb !== 'number' || isNaN(mb) || mb < 0) {
            return "0.00";
        }
        var gb = mb / 1024.0;
        return gb.toFixed(2);
    }

    function isValidIp(ip) {
        var regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
        return regex.test(ip);
    }

    function isValidDomain(domain) {
        // 允许域名以点号结尾，但最好在校验前去除 (例如：'example.com.' -> 'example.com')
        if (domain.endsWith('.')) {
            domain = domain.slice(0, -1);
        }

        // 检查总长度：域名总长不能超过 253 个字符 (包括点号)
        if (domain.length > 253) {
            return false;
        }

        // 简化的正则表达式，避免使用QML可能不支持的负向断言
        // 基本格式：子域名.子域名.顶级域名
        var domainRegex = /^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9](\.[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9])*\.[A-Za-z0-9]{2,63}$/;
        
        // 特殊情况：单字符域名段
        var singleCharRegex = /^[A-Za-z0-9](\.[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9])*\.[A-Za-z0-9]{2,63}$/;
        
        return domainRegex.test(domain) || singleCharRegex.test(domain);
    }
}
