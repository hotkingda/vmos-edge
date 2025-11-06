#include "SettingsHelper.h"

#include <QDataStream>
#include <QStandardPaths>

SettingsHelper::SettingsHelper(QObject *parent) : QObject(parent) {
}

SettingsHelper::~SettingsHelper() = default;

void SettingsHelper::save(const QString &key, const QVariant& val) {
    if (m_cache.contains(key) && m_cache[key] == val) {
        return;
    }

    m_settings->setValue(key, val);

    m_cache.insert(key, val);
}


QVariant SettingsHelper::get(const QString &key, const QVariant& def) {
    if(m_cache.contains(key)){
        return m_cache[key];
    }

    QVariant value  = m_settings->value(key, def);

    m_cache.insert(key, value);

    return value;
}

void SettingsHelper::init(char *argv[]) {
    QString applicationPath = QString::fromStdString(argv[0]);
    const QFileInfo fileInfo(applicationPath);
    const QString iniFileName = fileInfo.completeBaseName() + ".ini";
    const QString iniFilePath = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/vmosedge/" + iniFileName;
    qDebug() << "name" << iniFileName << "appdata" << QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) << "settings path" << iniFilePath;
    m_settings.reset(new QSettings(iniFilePath, QSettings::IniFormat));
}
