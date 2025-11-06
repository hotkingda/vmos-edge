#ifndef ACCOUNT_MODEL_H
#define ACCOUNT_MODEL_H

#include <QObject>
#include <QAbstractListModel>

struct AccountItem {
    QString account;
    QString token;
    QString name;
};

class AccountModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum AccountRoles {
        AccountRole = Qt::UserRole + 1,
        TokenRole,
        NameRole
    };
    explicit AccountModel(QObject* parent = nullptr);
    ~AccountModel() override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    Q_INVOKABLE void addItem(const QString& account, const QString& token, const QString& name);
    Q_INVOKABLE void removeItem(const QString& account);
    Q_INVOKABLE void saveConfig();

private:
    void loadConfig();

private:
    QList<AccountItem> m_items;
    QString m_filePath;
};

#endif // ACCOUNT_MODEL_H
