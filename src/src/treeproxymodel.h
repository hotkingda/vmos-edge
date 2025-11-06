#ifndef TREEPROXYMODEL_H
#define TREEPROXYMODEL_H

#include <QObject>
#include <QSortFilterProxyModel>
#include <QCollator>

class TreeProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString searchFilter READ searchFilter WRITE setSearchFilter NOTIFY searchFilterChanged)

public:
    TreeProxyModel(QObject *parent = nullptr);

    // 过滤属性
    QString searchFilter() const;
    void setSearchFilter(const QString &filter);

signals:
    void searchFilterChanged();

protected:
    // 核心筛选逻辑
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

private:
    QCollator collator; // 可以提升为类成员或 static 局部，避免频繁构造
    
    // 过滤条件
    QString m_searchFilter;
    
    // 辅助方法
    bool matchesSearchFilter(const QModelIndex &sourceIndex) const;
    bool hasMatchingChildren(const QModelIndex &parent) const;
    void autoCheckMatchingDevices();
    void clearAllDeviceChecks();
};

#endif // TREEPROXYMODEL_H
