#include "treeproxymodel.h"
#include "structs.h"
#include "treemodel.h"

TreeProxyModel::TreeProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    collator.setLocale(QLocale::system());  // 使用系统语言
    collator.setNumericMode(true);          // 开启数字感知：名字(2) < 名字(11)
    collator.setCaseSensitivity(Qt::CaseInsensitive);
}

bool TreeProxyModel::lessThan(const QModelIndex& left, const QModelIndex& right) const {
    QModelIndex leftParent = left.parent();
    QModelIndex rightParent = right.parent();

    // 只比较相同 parent 的子项
    if (leftParent != rightParent)
        return false;

    QVariant leftData, rightData;
    int itemType = sourceModel()->data(left, DeviceRoles::ItemTypeRole).toInt();

    switch(itemType){
    case TreeModel::TypeGroup:
        leftData = sourceModel()->data(left, DeviceRoles::GroupNameRole);
        rightData = sourceModel()->data(right, DeviceRoles::GroupNameRole);
        break;
    case TreeModel::TypeHost:
        leftData = sourceModel()->data(left, DeviceRoles::IpRole);
        rightData = sourceModel()->data(right, DeviceRoles::IpRole);
        break;
    case TreeModel::TypeDevice:
        leftData = sourceModel()->data(left, DeviceRoles::DisplayNameRole);
        rightData = sourceModel()->data(right, DeviceRoles::DisplayNameRole);
        break;
    default:
        return false;
    }

    return collator.compare(leftData.toString(), rightData.toString()) < 0;
}

// 过滤属性实现
QString TreeProxyModel::searchFilter() const {
    return m_searchFilter;
}

void TreeProxyModel::setSearchFilter(const QString &filter) {
    if (m_searchFilter != filter) {
        m_searchFilter = filter;
        emit searchFilterChanged();
        
        // 根据搜索条件处理设备勾选状态
        if (!m_searchFilter.isEmpty()) {
            // 有搜索条件时，只勾选匹配的设备
            autoCheckMatchingDevices();
        } else {
            // 搜索条件为空时，取消所有设备的勾选状态
            clearAllDeviceChecks();
        }
        
        invalidateFilter();
    }
}

// 核心筛选逻辑
bool TreeProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const {
    QModelIndex sourceIndex = sourceModel()->index(source_row, 0, source_parent);
    
    if (!sourceIndex.isValid()) {
        return false;
    }
    
    // 如果搜索条件为空，显示所有项目
    if (m_searchFilter.isEmpty()) {
        return true;
    }
    
    // 获取项目类型
    int itemType = sourceModel()->data(sourceIndex, DeviceRoles::ItemTypeRole).toInt();
    
    // 根据项目类型进行过滤
    switch (itemType) {
    case TreeModel::TypeGroup:
        // 组节点：如果组内有匹配的设备，则显示组
        return hasMatchingChildren(sourceIndex);
        
    case TreeModel::TypeHost:
        // 主机节点：如果主机下有匹配的设备，则显示主机
        return hasMatchingChildren(sourceIndex);
        
    case TreeModel::TypeDevice:
        // 设备节点：检查设备名称匹配
        return matchesSearchFilter(sourceIndex);
        
    default:
        return true;
    }
}

// 检查是否有匹配的子项
bool TreeProxyModel::hasMatchingChildren(const QModelIndex &parent) const {
    int rowCount = sourceModel()->rowCount(parent);
    for (int i = 0; i < rowCount; ++i) {
        QModelIndex child = sourceModel()->index(i, 0, parent);
        if (filterAcceptsRow(i, parent)) {
            return true;
        }
    }
    return false;
}

// 统一搜索过滤匹配（只匹配设备节点）
bool TreeProxyModel::matchesSearchFilter(const QModelIndex &sourceIndex) const {
    if (m_searchFilter.isEmpty()) {
        return true;
    }
    
    // 只对设备节点进行名称匹配
    QString displayName = sourceModel()->data(sourceIndex, DeviceRoles::DisplayNameRole).toString();
    QString hostIp = sourceModel()->data(sourceIndex, DeviceRoles::HostIpRole).toString();
    return displayName.contains(m_searchFilter, Qt::CaseInsensitive) || hostIp.contains(m_searchFilter, Qt::CaseInsensitive);
}

// 自动勾选匹配搜索条件的设备，取消勾选不匹配的设备
void TreeProxyModel::autoCheckMatchingDevices() {
    if (!sourceModel()) return;
    
    // 遍历所有设备，根据匹配情况设置勾选状态
    for (int i = 0; i < sourceModel()->rowCount(QModelIndex()); ++i) { // Groups
        QModelIndex groupIndex = sourceModel()->index(i, 0, QModelIndex());
        for (int j = 0; j < sourceModel()->rowCount(groupIndex); ++j) { // Hosts
            QModelIndex hostIndex = sourceModel()->index(j, 0, groupIndex);
            for (int k = 0; k < sourceModel()->rowCount(hostIndex); ++k) { // Devices
                QModelIndex deviceIndex = sourceModel()->index(k, 0, hostIndex);
                if (sourceModel()->data(deviceIndex, DeviceRoles::ItemTypeRole) == TreeModel::TypeDevice) {
                    // 检查设备是否匹配搜索条件
                    QString displayName = sourceModel()->data(deviceIndex, DeviceRoles::DisplayNameRole).toString();
                    QString hostIp = sourceModel()->data(deviceIndex, DeviceRoles::HostIpRole).toString();
                    bool matches = displayName.contains(m_searchFilter, Qt::CaseInsensitive) || 
                                  hostIp.contains(m_searchFilter, Qt::CaseInsensitive);
                    
                    // 根据匹配情况设置勾选状态
                    sourceModel()->setData(deviceIndex, matches, DeviceRoles::CheckedRole);
                }
            }
        }
    }
}

// 取消所有设备的勾选状态
void TreeProxyModel::clearAllDeviceChecks() {
    if (!sourceModel()) return;
    
    // 遍历所有设备，取消勾选状态
    for (int i = 0; i < sourceModel()->rowCount(QModelIndex()); ++i) { // Groups
        QModelIndex groupIndex = sourceModel()->index(i, 0, QModelIndex());
        for (int j = 0; j < sourceModel()->rowCount(groupIndex); ++j) { // Hosts
            QModelIndex hostIndex = sourceModel()->index(j, 0, groupIndex);
            for (int k = 0; k < sourceModel()->rowCount(hostIndex); ++k) { // Devices
                QModelIndex deviceIndex = sourceModel()->index(k, 0, hostIndex);
                if (sourceModel()->data(deviceIndex, DeviceRoles::ItemTypeRole) == TreeModel::TypeDevice) {
                    // 取消勾选所有设备
                    sourceModel()->setData(deviceIndex, false, DeviceRoles::CheckedRole);
                }
            }
        }
    }
}