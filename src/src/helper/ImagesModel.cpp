#include "ImagesModel.h"
#include "FileCopyManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <QStandardPaths>

ImagesModel::ImagesModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_filePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/images.json";
    loadConfig();
}

ImagesModel::~ImagesModel()
{
    saveConfig();
}

int ImagesModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;

    return m_items.size();
}

QVariant ImagesModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return QVariant();

    const ImageItem& item = m_items.at(index.row());

    switch (role) {
    case NameRole:
        return item.name;
    case PathRole:
        return item.path;
    case FileNameRole:
        return item.fileName;
    case VersionRole:
        return item.version;
    case FileSizeRole:
        return item.fileSize;
    case CreateTimeRole:
        return item.createTime;
    default:
        return QVariant();
    }
}

bool ImagesModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return false;

    ImageItem& item = m_items[index.row()];

    switch (role) {
    case NameRole:
        item.name = value.toString();
        break;
    case PathRole:
        item.path = value.toString();
        break;
    case FileNameRole:
        item.fileName = value.toString();
        break;
    case VersionRole:
        item.version = value.toString();
        break;
    case FileSizeRole:
        item.fileSize = value.toString();
        break;
    case CreateTimeRole:
        item.createTime = value.toString();
        break;
    default:
        return false;
    }

    emit dataChanged(index, index, {role});
    return true;
}

QHash<int, QByteArray> ImagesModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[FileNameRole] = "fileName";
    roles[VersionRole] = "version";
    roles[FileSizeRole] = "fileSize";
    roles[CreateTimeRole] = "createTime";
    return roles;

}

Qt::ItemFlags ImagesModel::flags(const QModelIndex& index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

void ImagesModel::addItem(const QString& path, const QString& name, const QString& fileName, const QString& version, const QString& fileSize)
{
    // 由于原函数参数与ImageItem不匹配，这里需要调整
    // 创建一个新的ImageItem并添加到模型中
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());

    ImageItem newItem;
    newItem.name = name;
    newItem.path = path; // 根据需要设置默认值
    newItem.fileName = fileName; // 根据需要设置默认值
    newItem.version = version; // 默认版本
    newItem.fileSize = fileSize; // 默认文件大小
    newItem.createTime = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

    m_items.append(newItem);
    endInsertRows();

    saveConfig();
}

void ImagesModel::remove(int index)
{
    if (index < 0 || index >= m_items.size())
        return;

    // 删除实际的镜像文件（异步操作，在后台线程执行）
    const ImageItem& item = m_items.at(index);
    if (!item.path.isEmpty()) {
        FileCopyManager::instance()->startDelete(item.path);
    }

    // 立即从模型中移除（不等待文件删除完成）
    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    endRemoveRows();

    saveConfig();
}

void ImagesModel::saveConfig()
{
    QJsonArray jsonArray;

    for (const ImageItem& item : m_items) {
        QJsonObject jsonObj;
        jsonObj["name"] = item.name;
        jsonObj["path"] = item.path;
        jsonObj["fileName"] = item.fileName;
        jsonObj["version"] = item.version;
        jsonObj["fileSize"] = item.fileSize;
        jsonObj["createTime"] = item.createTime;

        jsonArray.append(jsonObj);
    }

    QJsonDocument doc(jsonArray);
    QFile file(m_filePath);

    if (file.open(QIODevice::WriteOnly)) {
        file.write(doc.toJson());
        file.close();
    }
}

void ImagesModel::loadConfig()
{
    QFile file(m_filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray())
        return;

    QJsonArray jsonArray = doc.array();

    beginResetModel();
    m_items.clear();

    for (const QJsonValue& value : jsonArray) {
        QJsonObject jsonObj = value.toObject();

        ImageItem item;
        item.name = jsonObj["name"].toString();
        item.path = jsonObj["path"].toString();
        item.fileName = jsonObj["fileName"].toString();
        item.version = jsonObj["version"].toString();
        item.fileSize = jsonObj["fileSize"].toString();
        item.createTime = jsonObj["createTime"].toString();

        m_items.append(item);
    }

    endResetModel();
}
