#include "treeitem.h"
#include "treemodel.h" // Include for role definitions
#include "structs.h"


// TreeItem implementation
TreeItem::TreeItem(TreeItem *parent) : m_parent(parent) {}

TreeItem::~TreeItem()
{
    qDeleteAll(m_children);
}

void TreeItem::appendChild(TreeItem *child)
{
    m_children.append(child);
}

bool TreeItem::insertChild(int pos, TreeItem *child)
{
    if (pos < 0 || pos > m_children.size()) return false;
    m_children.insert(pos, child);
    return true;
}

TreeItem* TreeItem::takeChild(int row)
{
    if (row < 0 || row >= m_children.size()) return nullptr;
    return m_children.takeAt(row);
}

bool TreeItem::removeChild(int row)
{
    TreeItem* item = takeChild(row);
    if (item) {
        delete item;
        return true;
    }
    return false;
}

TreeItem *TreeItem::child(int row)
{
    if (row < 0 || row >= m_children.size()) return nullptr;
    return m_children.at(row);
}

int TreeItem::childCount() const
{
    return m_children.count();
}

int TreeItem::columnCount() const
{
    return 1;
}

int TreeItem::row() const
{
    if (m_parent && !m_parent->m_children.isEmpty()) {
        int index = m_parent->m_children.indexOf(const_cast<TreeItem*>(this));
        return index >= 0 ? index : 0;
    }
    return 0;
}

TreeItem *TreeItem::parentItem()
{
    return m_parent;
}

void TreeItem::setParentItem(TreeItem *parentItem)
{
    m_parent = parentItem;
}

void TreeItem::removeChildren()
{
    qDeleteAll(m_children);
    m_children.clear();
}

// GroupItem implementation
GroupItem::GroupItem(const GroupData &data, TreeItem *parent) : TreeItem(parent), m_groupData(data) {}

int GroupItem::type() const
{
    return TreeModel::TypeGroup;
}

GroupData& GroupItem::groupData()
{
    return m_groupData;
}

// HostItem implementation
HostItem::HostItem(const HostData &data, TreeItem *parent) : TreeItem(parent), m_hostData(data) {}



int HostItem::type() const
{
    return TreeModel::TypeHost;
}

HostData& HostItem::hostData()
{
    return m_hostData;
}

// DeviceItem implementation
DeviceItem::DeviceItem(const DeviceData &data, TreeItem *parent) : TreeItem(parent), m_deviceData(data) {}

int DeviceItem::type() const
{
    return TreeModel::TypeDevice;
}

DeviceData& DeviceItem::deviceData()
{
    return m_deviceData;
}
