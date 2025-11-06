#include "levelproxymodel.h"
#include "treemodel.h" // For ItemType enum and roles
#include <QDebug>

LevelProxyModel::LevelProxyModel(QObject* parent)
    : QAbstractProxyModel(parent)
{
}

int LevelProxyModel::level() const
{
    return m_level;
}

void LevelProxyModel::setLevel(int level)
{
    if (m_level == level)
        return;

    m_level = level;
    emit levelChanged();
    rebuildIndexMap();
}

QString LevelProxyModel::filterText() const
{
    return m_filterText;
}

void LevelProxyModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    emit filterTextChanged();
    rebuildIndexMap();
}

QString LevelProxyModel::filterState() const
{
    return m_filterState;
}

void LevelProxyModel::setFilterState(const QString &state)
{
    if (m_filterState == state)
        return;
    m_filterState = state;
    emit filterStateChanged();
    rebuildIndexMap();
}


void LevelProxyModel::setSourceModel(QAbstractItemModel *newSourceModel)
{
    beginResetModel();
    if (sourceModel()) {
        disconnect(sourceModel(), &QAbstractItemModel::modelReset, this, &LevelProxyModel::rebuildIndexMap);
        disconnect(sourceModel(), SIGNAL(rowsInserted(QModelIndex,int,int)), this, SLOT(rebuildIndexMap()));
        disconnect(sourceModel(), SIGNAL(rowsRemoved(QModelIndex,int,int)), this, SLOT(rebuildIndexMap()));
        disconnect(sourceModel(), &QAbstractItemModel::dataChanged, this, &LevelProxyModel::onSourceDataChanged);
    }
    QAbstractProxyModel::setSourceModel(newSourceModel);
    if (sourceModel()) {
        connect(sourceModel(), &QAbstractItemModel::modelReset, this, &LevelProxyModel::rebuildIndexMap);
        connect(sourceModel(), SIGNAL(rowsInserted(QModelIndex,int,int)), this, SLOT(rebuildIndexMap()));
        connect(sourceModel(), SIGNAL(rowsRemoved(QModelIndex,int,int)), this, SLOT(rebuildIndexMap()));
        connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &LevelProxyModel::onSourceDataChanged);
        rebuildIndexMap();
    } else {
        rebuildIndexMap();
    }
    endResetModel();
}

bool LevelProxyModel::filterAcceptsIndex(const QModelIndex& sourceIndex) const
{
    if (!sourceIndex.isValid()) {
        return false;
    }

    if (m_level == 1) return true;

    if (m_level == 2 || m_level == 3) {
        const QVariant stateData = sourceModel()->data(sourceIndex, DeviceRoles::StateRole);
        const bool stateFilterActive = !m_filterState.isEmpty() && m_filterState.compare("", Qt::CaseInsensitive) != 0;
        if (stateFilterActive && stateData.toString().compare(m_filterState, Qt::CaseInsensitive) != 0) {
            return false;
        }

        const QVariant hostIdData = sourceModel()->data(sourceIndex, DeviceRoles::HostIdRole);
        const QVariant ipData = sourceModel()->data(sourceIndex, DeviceRoles::IpRole);
        const bool textFilterActive = !m_filterText.isEmpty();
        if (textFilterActive) {
            if (!hostIdData.toString().contains(m_filterText, Qt::CaseInsensitive) &&
                !ipData.toString().contains(m_filterText, Qt::CaseInsensitive)) {
                return false;
            }
        }
    }

    return true;
}

void LevelProxyModel::rebuildIndexMap()
{
    beginResetModel();
    m_sourceToProxyRowMap.clear();
    m_proxyRowToSourceMap.clear();
    if (!sourceModel()) {
        endResetModel();
        return;
    }

    auto addItem = [&](const QModelIndex& itemIndex) {
        int newRow = m_proxyRowToSourceMap.count();
        QPersistentModelIndex persistentIndex(itemIndex);
        m_proxyRowToSourceMap.append(persistentIndex);
        m_sourceToProxyRowMap.insert(persistentIndex, newRow);
    };

    if (m_level == 1) { // Groups
        int groupCount = sourceModel()->rowCount(QModelIndex());
        for (int g = 0; g < groupCount; ++g) {
            QModelIndex groupIndex = sourceModel()->index(g, 0, QModelIndex());
            if (groupIndex.isValid() && sourceModel()->data(groupIndex, DeviceRoles::ItemTypeRole) == TreeModel::TypeGroup) {
                if (filterAcceptsIndex(groupIndex)) {
                    addItem(groupIndex);
                }
            }
        }
    } else if (m_level == 2) { // Hosts
        int groupCount = sourceModel()->rowCount(QModelIndex());
        for (int g = 0; g < groupCount; ++g) {
            QModelIndex groupIndex = sourceModel()->index(g, 0, QModelIndex());
            int hostCount = sourceModel()->rowCount(groupIndex);
            for (int h = 0; h < hostCount; ++h) {
                QModelIndex hostIndex = sourceModel()->index(h, 0, groupIndex);
                if (hostIndex.isValid() && sourceModel()->data(hostIndex, DeviceRoles::ItemTypeRole) == TreeModel::TypeHost) {
                    if (filterAcceptsIndex(hostIndex)) {
                        addItem(hostIndex);
                    }
                }
            }
        }
    } else if (m_level == 3) { // Devices
        int groupCount = sourceModel()->rowCount(QModelIndex());
        for (int g = 0; g < groupCount; ++g) {
            QModelIndex groupIndex = sourceModel()->index(g, 0, QModelIndex());
            int hostCount = sourceModel()->rowCount(groupIndex);
            for (int h = 0; h < hostCount; ++h) {
                QModelIndex hostIndex = sourceModel()->index(h, 0, groupIndex);
                int deviceCount = sourceModel()->rowCount(hostIndex);
                for (int d = 0; d < deviceCount; ++d) {
                    QModelIndex deviceIndex = sourceModel()->index(d, 0, hostIndex);
                    if (deviceIndex.isValid() && sourceModel()->data(deviceIndex, DeviceRoles::ItemTypeRole) == TreeModel::TypeDevice) {
                        if (filterAcceptsIndex(deviceIndex)) {
                            addItem(deviceIndex);
                        }
                    }
                }
            }
        }
    }

    endResetModel();
    updateIsSelectAll();
}

void LevelProxyModel::onSourceDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles)
{
    Q_UNUSED(bottomRight);
    if (!topLeft.isValid()) return;

    bool wasAccepted = m_sourceToProxyRowMap.contains(topLeft);
    bool isNowAccepted = filterAcceptsIndex(topLeft);

    if (wasAccepted && !isNowAccepted) {
        rebuildIndexMap();
    } else if (!wasAccepted && isNowAccepted) {
        rebuildIndexMap();
    } else if (wasAccepted && isNowAccepted) {
        int row = m_sourceToProxyRowMap.value(topLeft, -1);
        if (row != -1) {
            QModelIndex proxyTopLeft = createIndex(row, topLeft.column());
            QModelIndex proxyBottomRight = createIndex(row, bottomRight.column());
            emit dataChanged(proxyTopLeft, proxyBottomRight, roles);
        }
    }

    if (roles.isEmpty() || roles.contains(DeviceRoles::SelectedRole)) {
        updateIsSelectAll();
    }
}

QModelIndex LevelProxyModel::mapFromSource(const QModelIndex& sourceIndex) const
{
    if (!sourceIndex.isValid() || !sourceModel()) {
        return QModelIndex();
    }

    QPersistentModelIndex persistentIndex(sourceIndex);
    int row = m_sourceToProxyRowMap.value(persistentIndex, -1);
    if (row == -1) {
        return QModelIndex();
    }
    return createIndex(row, sourceIndex.column());
}

QModelIndex LevelProxyModel::mapToSource(const QModelIndex& proxyIndex) const
{
    if (!proxyIndex.isValid() || proxyIndex.row() >= m_proxyRowToSourceMap.count()) {
        return QModelIndex();
    }
    return m_proxyRowToSourceMap.at(proxyIndex.row());
}

QModelIndex LevelProxyModel::index(int row, int column, const QModelIndex& parent) const
{
    if (parent.isValid() || row < 0 || row >= rowCount() || column < 0 || column >= columnCount()) {
        return QModelIndex();
    }
    return createIndex(row, column);
}

QModelIndex LevelProxyModel::parent(const QModelIndex& child) const
{
    Q_UNUSED(child);
    return QModelIndex();
}

int LevelProxyModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_proxyRowToSourceMap.count();
}

int LevelProxyModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return sourceModel() ? sourceModel()->columnCount(QModelIndex()) : 1;
}

QVariant LevelProxyModel::data(const QModelIndex& proxyIndex, int role) const
{
    if (!proxyIndex.isValid()) {
        return QVariant();
    }
    QModelIndex sourceIndex = mapToSource(proxyIndex);
    return sourceModel()->data(sourceIndex, role);
}

bool LevelProxyModel::setData(const QModelIndex &proxyIndex, const QVariant &value, int role)
{
    if (!proxyIndex.isValid()) {
        return false;
    }
    QModelIndex sourceIndex = mapToSource(proxyIndex);
    return sourceModel()->setData(sourceIndex, value, role);
}

bool LevelProxyModel::hasChildren(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return false;
}

bool LevelProxyModel::isSelectAll() const
{
    return m_isSelectAll;
}

void LevelProxyModel::selectAll(bool selected)
{
    if (!sourceModel()) {
        return;
    }

    disconnect(sourceModel(), &QAbstractItemModel::dataChanged, this, &LevelProxyModel::onSourceDataChanged);

    for (const QPersistentModelIndex& sourceIndex : m_proxyRowToSourceMap) {
        sourceModel()->setData(sourceIndex, selected, DeviceRoles::SelectedRole);
    }

    connect(sourceModel(), &QAbstractItemModel::dataChanged, this, &LevelProxyModel::onSourceDataChanged);

    if (!m_proxyRowToSourceMap.isEmpty()) {
        emit dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1), {DeviceRoles::SelectedRole});
    }

    updateIsSelectAll();
}

void LevelProxyModel::updateIsSelectAll()
{
    if (!sourceModel()) {
        if (m_isSelectAll) {
            m_isSelectAll = false;
            emit isSelectAllChanged();
        }
        return;
    }

    bool allSelected = !m_proxyRowToSourceMap.isEmpty();
    if (allSelected) {
        for (const QPersistentModelIndex& sourceIndex : m_proxyRowToSourceMap) {
            if (!sourceModel()->data(sourceIndex, DeviceRoles::SelectedRole).toBool()) {
                allSelected = false;
                break;
            }
        }
    }

    if (m_isSelectAll != allSelected) {
        m_isSelectAll = allSelected;
        emit isSelectAllChanged();
    }
}

QVariantList LevelProxyModel::getHostList() const
{
    QVariantList hostList;
    if (!sourceModel() || m_level != 2) {
        return hostList;
    }

    for (const QPersistentModelIndex& sourceIndex : m_proxyRowToSourceMap) {
        if (sourceModel()->data(sourceIndex, DeviceRoles::SelectedRole).toBool()) {
            QVariantMap hostMap;
            hostMap["groupId"] = sourceModel()->data(sourceIndex, DeviceRoles::GroupIdRole);
            hostMap["hostId"] = sourceModel()->data(sourceIndex, DeviceRoles::HostIdRole);
            hostMap["hostName"] = sourceModel()->data(sourceIndex, DeviceRoles::HostNameRole);
            hostMap["ip"] = sourceModel()->data(sourceIndex, DeviceRoles::IpRole);
            hostMap["hostPadCount"] = sourceModel()->data(sourceIndex, DeviceRoles::HostPadCountRole);
            hostMap["updateTime"] = sourceModel()->data(sourceIndex, DeviceRoles::UpdateTimeRole);
            hostMap["state"] = sourceModel()->data(sourceIndex, DeviceRoles::StateRole);
            hostMap["selected"] = true;
            hostList.append(hostMap);
        }
    }

    return hostList;
}
