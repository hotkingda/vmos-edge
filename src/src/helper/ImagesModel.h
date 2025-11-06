#ifndef IMAGESMODEL_H
#define IMAGESMODEL_H

#include <QObject>
#include <QAbstractListModel>

struct ImageItem {
    QString name;
    QString path;
    QString fileName;
    QString version;
    QString fileSize;
    QString createTime;
};

class ImagesModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum RecordRoles {
        ContentRole = Qt::UserRole + 1,
        NameRole,
        PathRole,
        FileNameRole,
        VersionRole,
        FileSizeRole,
        CreateTimeRole
    };
    Q_ENUM(RecordRoles)
    explicit ImagesModel(QObject* parent = nullptr);
    ~ImagesModel() override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role) override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    Q_INVOKABLE void addItem(const QString& path, const QString& name, const QString& fileName, const QString& version, const QString& fileSize);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void saveConfig();

private:
    void loadConfig();

private:
    QList<ImageItem> m_items;
    QString m_filePath;
};

#endif // IMAGESMODEL_H
