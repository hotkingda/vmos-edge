#ifndef KEYMAPPERMODEL_H
#define KEYMAPPERMODEL_H

#include <QObject>
#include <QAbstractListModel>

struct KeyMapperItem {
    QString key;
    qreal px;
    qreal py;
    int cx;
    int cy;
    int left;
    int top;
    int type;
};

class KeyMapperModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum KeyMapperRoles {
        KeyRole = Qt::UserRole + 1,
        PxRole,
        PyRole,
        CxRole,
        CyRole,
        LeftRole,
        TopRole,
        TypeRole
    };
    explicit KeyMapperModel(QObject* parent = nullptr);
    ~KeyMapperModel() override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    Q_INVOKABLE QVariantMap get(int index);
    Q_INVOKABLE void addItem(int type, const QString& key);
    Q_INVOKABLE void deleteItem(const QString& key);
    Q_INVOKABLE void saveConfig();
    Q_INVOKABLE void loadConfig();

private:
    QList<KeyMapperItem> m_items;
    QString m_filePath;
};

#endif // KEYMAPPERMODEL_H
