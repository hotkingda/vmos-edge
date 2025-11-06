#include "downloadhandler.h"
#include <QWebEngineDownloadRequest>
#include <QFileDialog>
#include <QStandardPaths>
#include <QFileInfo>

DownloadHandler::DownloadHandler(QObject *parent) : QObject(parent)
{
}

void DownloadHandler::handleDownload(QWebEngineDownloadRequest *download)
{
    // 使用 QStandardPaths 获取默认的下载目录
    QString defaultPath = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    QString defaultFilePath = QFileInfo(defaultPath, download->downloadFileName()).absoluteFilePath();

    // 弹出系统原生文件对话框，这是一个阻塞操作
    QString filePath = QFileDialog::getSaveFileName(nullptr, QObject::tr("保存文件"), defaultFilePath);

    // 如果用户点击了取消，filePath 会为空，下载请求会自动销毁，我们什么都不用做
    if (filePath.isEmpty()) {
        return;
    }

    // 如果用户选择了路径，我们设置路径并接受下载
    download->setDownloadDirectory(QFileInfo(filePath).path());
    download->setDownloadFileName(QFileInfo(filePath).fileName());
    download->accept();
}
