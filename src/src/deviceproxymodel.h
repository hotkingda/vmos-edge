#ifndef DEVICEPROXYMODEL_H
#define DEVICEPROXYMODEL_H

#include <QSortFilterProxyModel>
#include <QString>
#include <QCollator>
#include <QJsonArray>


class DeviceProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
    Q_PROPERTY(int checkedCount READ checkedCount NOTIFY checkedCountChanged FINAL)
    Q_PROPERTY(bool isSelectAll READ isSelectAll NOTIFY isSelectAllChanged FINAL)
public:
    explicit DeviceProxyModel(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList getAllPadCodeList() const;
    Q_INVOKABLE QVariantList getCheckedIDList() const;
    Q_INVOKABLE QVariantList getPadList() const;

    Q_INVOKABLE void selectAll(bool checked);
    Q_INVOKABLE void invertSelection();
    Q_INVOKABLE void multiSelect(int count);
    // 仅选择/反选代理模型的一个区间 [start, end)，用于“当前页全选”
    Q_INVOKABLE void selectRange(int start, int end, bool checked);
    Q_INVOKABLE void invertRange(int start, int end);
    Q_INVOKABLE int checkedCountInRange(int start, int end) const;
    Q_INVOKABLE bool isAllCheckedInRange(int start, int end) const;

    QString filterString() const;
    Q_INVOKABLE void setFilterString(const QString &newFilterString);

    int checkedCount() const;
    bool isSelectAll() const;

protected:
    // 核心筛选逻辑
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex& left, const QModelIndex& right) const override;

signals:
    void checkedCountChanged();
    void isSelectAllChanged();
    void filterStringChanged();

private:
    QString m_filterString;
    QCollator collator;
};

#endif // DEVICEPROXYMODEL_H
