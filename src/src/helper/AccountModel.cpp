#include "AccountModel.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>


AccountModel::AccountModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_filePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/account.json";
    loadConfig();
}

AccountModel::~AccountModel(){
    saveConfig();
}

void AccountModel::loadConfig(){

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
        AccountItem item;
        item.account = obj["account"].toString();
        item.token = obj["token"].toString();
        item.name = obj["name"].toString();
        m_items.append(item);
    }

    endResetModel();
}
void AccountModel::saveConfig(){
    QJsonArray array;
    for (const AccountItem& item : std::as_const(m_items)) {
        QJsonObject obj;
        obj["account"] = item.account;
        obj["token"] = item.token;
        obj["name"] = item.name;
        array.append(obj);
    }

    QJsonDocument doc(array);
    QFile file(m_filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(doc.toJson(QJsonDocument::Indented));
        file.close();
    }
}

int AccountModel::rowCount(const QModelIndex&) const {
    return m_items.count();
}

QVariant AccountModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_items.count())
        return {};

    const AccountItem& item = m_items.at(index.row());

    switch (role) {
    case AccountRole: return item.account;
    case TokenRole: return item.token;
    case NameRole: return item.name;
    default: return {};
    }
}

bool AccountModel::setData(const QModelIndex& index, const QVariant& value, int role) {
    if (!index.isValid() || index.row() >= m_items.size())
        return false;

    qDebug() << "setData" << index << value << role;
    AccountItem& item = m_items[index.row()];
    if (role == AccountRole) {
        item.account = value.toString();
    } else if (role == TokenRole) {
        item.token = value.toString();
    } else if (role == NameRole) {
        item.name = value.toString();
    } else {
        return false;
    }

    emit dataChanged(index, index, { role });
    return true;
}

QHash<int, QByteArray> AccountModel::roleNames() const {
    return {
        { AccountRole, "account" },
        { TokenRole, "token" },
        { NameRole, "name" }
    };
}

Qt::ItemFlags AccountModel::flags(const QModelIndex& index) const {
    if (!index.isValid()) return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

void AccountModel::addItem(const QString& account, const QString& token, const QString& name){
    // Check for duplicate account
    for (const AccountItem& existingItem : std::as_const(m_items)) {
        if (existingItem.account == account) {
            return; // Account already exists, do not add
        }
    }

    beginResetModel();
    // 插入到最前面
    AccountItem item;
    item.account = account;
    item.token = token;
    item.name = name;
    m_items.prepend(item);

    // 保留前10条（忽略 isLock）
    while (m_items.size() > 10)
        m_items.removeLast();

    endResetModel();
}

void AccountModel::removeItem(const QString &account)
{
    for (int i = 0; i < m_items.count(); ++i) {
        if (m_items.at(i).account == account) {
            beginRemoveRows(QModelIndex(), i, i);
            m_items.removeAt(i);
            endRemoveRows();
            break;
        }
    }
}
