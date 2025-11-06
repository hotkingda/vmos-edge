#ifndef LEVELPROXYMODEL_H
#define LEVELPROXYMODEL_H

#include <QAbstractProxyModel>
#include <QHash>
#include <QPersistentModelIndex>

class LevelProxyModel : public QAbstractProxyModel {
    Q_OBJECT
    Q_PROPERTY(int level READ level WRITE setLevel NOTIFY levelChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(QString filterState READ filterState WRITE setFilterState NOTIFY filterStateChanged)
    Q_PROPERTY(bool isSelectAll READ isSelectAll NOTIFY isSelectAllChanged)

public:
    explicit LevelProxyModel(QObject* parent = nullptr);

    int level() const;
    void setLevel(int level);

    QString filterText() const;
    Q_INVOKABLE void setFilterText(const QString& text);

    QString filterState() const;
    Q_INVOKABLE void setFilterState(const QString& state);

    bool isSelectAll() const;
    Q_INVOKABLE void selectAll(bool selected);
    Q_INVOKABLE QVariantList getHostList() const;

    void setSourceModel(QAbstractItemModel *sourceModel) override;
    QModelIndex mapFromSource(const QModelIndex& sourceIndex) const override;
    QModelIndex mapToSource(const QModelIndex& proxyIndex) const override;

    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& child) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    bool hasChildren(const QModelIndex& parent = QModelIndex()) const override;

signals:
    void levelChanged();
    void filterTextChanged();
    void filterStateChanged();
    void isSelectAllChanged();

private slots:
    void rebuildIndexMap();
    void onSourceDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles = QVector<int>());

private:
    bool filterAcceptsIndex(const QModelIndex& sourceIndex) const;
    void updateIsSelectAll();

    QHash<QPersistentModelIndex, int> m_sourceToProxyRowMap;
    QList<QPersistentModelIndex> m_proxyRowToSourceMap;
    int m_level = 2; // 1: group, 2: host, 3: device
    QString m_filterText;
    QString m_filterState;
    bool m_isSelectAll = false;
};

#endif // LEVELPROXYMODEL_H
