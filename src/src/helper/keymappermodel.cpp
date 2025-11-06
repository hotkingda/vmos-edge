#include "keymappermodel.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>


KeyMapperModel::KeyMapperModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_filePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/keymap.json";
    loadConfig();
}

KeyMapperModel::~KeyMapperModel(){
    saveConfig();
}

void KeyMapperModel::loadConfig(){

    QFile file(m_filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data = file.readAll();
    file.close();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray())
        return;

    beginResetModel();
    m_items.clear();

    QJsonArray arr = doc.array();
    for (const QJsonValue& val : arr) {
        QJsonObject obj = val.toObject();
        KeyMapperItem item;
        item.key = obj["key"].toString();
        item.px = obj["px"].toDouble();
        item.py = obj["py"].toDouble();
        item.cx = obj["cx"].toInt(0);
        item.cy = obj["cy"].toInt(0);
        item.left = obj["left"].toInt(0);
        item.top = obj["top"].toInt(0);
        item.type = obj["type"].toInt(0);

        m_items.append(item);
    }

    endResetModel();
}

void KeyMapperModel::saveConfig(){
    QJsonArray array;
    for (const KeyMapperItem& item : std::as_const(m_items)) {
        QJsonObject obj;
        obj["key"] = item.key;
        obj["px"] = item.px;
        obj["py"] = item.py;
        obj["cx"] = item.cx;
        obj["cy"] = item.cy;
        obj["left"] = item.left;
        obj["top"] = item.top;
        obj["type"] = item.type;
        array.append(obj);
    }

    QJsonDocument doc(array);
    QFile file(m_filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(doc.toJson(QJsonDocument::Indented));
        file.close();
    }
}

int KeyMapperModel::rowCount(const QModelIndex&) const {
    return m_items.count();
}

QVariant KeyMapperModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_items.count())
        return {};

    const KeyMapperItem& item = m_items.at(index.row());

    switch (role) {
    case KeyRole: return item.key;
    case PxRole: return item.px;
    case PyRole: return item.py;
    case CxRole: return item.cx;
    case CyRole: return item.cy;
    case LeftRole: return item.left;
    case TopRole: return item.top;
    case TypeRole: return item.type;
    default: return {};
    }
}

bool KeyMapperModel::setData(const QModelIndex& index, const QVariant& value, int role) {
    if (!index.isValid() || index.row() >= m_items.size())
        return false;

    qDebug() << "setData" << index << value << role;
    KeyMapperItem& item = m_items[index.row()];
    if (role == KeyRole) {
        item.key = value.toString();
    } else if (role == PxRole) {
        item.px = value.toDouble();
    } else if (role == PyRole) {
        item.py = value.toDouble();
    } else if (role == CxRole) {
        item.cx = value.toInt(0);
    } else if (role == CyRole) {
        item.cy = value.toInt(0);
    } else if (role == LeftRole) {
        item.left = value.toInt(0);
    } else if (role == TopRole) {
        item.top = value.toInt(0);
    } else if (role == TypeRole) {
        item.type = value.toInt(0);
    } else {
        return false;
    }

    emit dataChanged(index, index, { role });
    return true;
}

QHash<int, QByteArray> KeyMapperModel::roleNames() const {
    return {
        { KeyRole, "key" },
        { PxRole, "px" },
        { PyRole, "py" },
        { CxRole, "cx" },
        { CyRole, "cy" },
        { LeftRole, "left" },
        { TopRole, "top" },
        { TypeRole, "type" }
    };
}

Qt::ItemFlags KeyMapperModel::flags(const QModelIndex& index) const {
    if (!index.isValid()) return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

QVariantMap KeyMapperModel::get(int index){
    QVariantMap obj;
    if (index < 0 || index >= rowCount()){
        return obj;
    }
    const auto &item = m_items.at(index);

    obj["key"] = item.key;
    obj["px"] = item.px;
    obj["py"] = item.py;
    obj["cx"] = item.cx;
    obj["cy"] = item.cy;
    obj["left"] = item.left;
    obj["top"] = item.top;
    obj["type"] = item.type;

    return obj;
}

void KeyMapperModel::addItem(int type, const QString& key){
    beginResetModel();
    KeyMapperItem item;
    item.key = key;
    item.px = 0.5;
    item.py = 0.5;
    item.cx = (type == 1 ? 100 : 30);
    item.cy = (type == 1 ? 100 : 30);
    item.left = 0;
    item.top = 0;
    item.type = type;
    m_items.prepend(item);
    endResetModel();
}

void KeyMapperModel::deleteItem(const QString& key){
    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items.at(i).key == key) {
            beginRemoveRows(QModelIndex(), i, i);
            m_items.removeAt(i);
            endRemoveRows();
            break;
        }
    }
}

