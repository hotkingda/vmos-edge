#include "windowsizehelper.h"
#include <QStandardPaths>

WindowSizeHelper::WindowSizeHelper(QObject *parent)
    : QObject(parent)
{
    auto filePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/config.ini";
    qDebug() << "settings path" << filePath;
    m_settings.reset(new QSettings(filePath, QSettings::IniFormat));
}

void WindowSizeHelper::save(const QString& group, const QString &key, const QVariant& val) {
    auto cacheKey = group + "-" + key;
    if (m_cache.contains(cacheKey) && m_cache[cacheKey] == val) {
        return;
    }

    m_settings->beginGroup(group);
    m_settings->setValue(key, val);
    m_settings->endGroup();

    m_cache.insert(cacheKey, val);
}


QVariant WindowSizeHelper::get(const QString& group, const QString &key, const QVariant& def) {
    auto cacheKey = group + "-" + key;
    if(m_cache.contains(cacheKey)){
        return m_cache[cacheKey];
    }

    m_settings->beginGroup(group);
    QVariant value  = m_settings->value(key, def);
    m_settings->endGroup();

    m_cache.insert(cacheKey, value);

    return value;
}
