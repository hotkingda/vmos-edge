#ifndef TREEITEM_H
#define TREEITEM_H

#include <QVariant>
#include <QList>
#include "structs.h"

class TreeItem
{
public:
    explicit TreeItem(TreeItem *parent = nullptr);
    virtual ~TreeItem();

    void appendChild(TreeItem *child);
    bool insertChild(int pos, TreeItem* child);
    TreeItem* takeChild(int row);
    bool removeChild(int row);
    void removeChildren();

    TreeItem *child(int row);
    int childCount() const;
    int columnCount() const;
    int row() const;
    TreeItem *parentItem();
    void setParentItem(TreeItem *parentItem);

    virtual int type() const = 0;

protected:
    QList<TreeItem*> m_children;
    TreeItem *m_parent;
};

class GroupItem : public TreeItem
{
public:
    explicit GroupItem(const GroupData &data, TreeItem *parent = nullptr);
    int type() const override;
    GroupData& groupData();
private:
    GroupData m_groupData;
};

class HostItem : public TreeItem
{
public:
    explicit HostItem(const HostData &data, TreeItem *parent = nullptr);
    int type() const override;
    HostData& hostData();
private:
    HostData m_hostData;
};

class DeviceItem : public TreeItem
{
public:
    explicit DeviceItem(const DeviceData &data, TreeItem *parent = nullptr);
    int type() const override;
    DeviceData& deviceData();

private:
    DeviceData m_deviceData;
};

// 新增：用于根节点的具体类
class RootItem : public TreeItem
{
public:
    explicit RootItem(TreeItem *parent = nullptr) : TreeItem(parent) {}
    int type() const override { return -1; } // -1 表示根节点类型
};

#endif // TREEITEM_H
