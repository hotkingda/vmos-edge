#ifndef WINDOWSIZEHELPER_H
#define WINDOWSIZEHELPER_H

#include <QObject>
#include <QSettings>

class WindowSizeHelper : public QObject
{
    Q_OBJECT
public:
    explicit WindowSizeHelper(QObject *parent = nullptr);
    virtual ~WindowSizeHelper() = default;

    Q_INVOKABLE void save(const QString& group, const QString &key, const QVariant& val);
    Q_INVOKABLE QVariant get(const QString& group, const QString &key, const QVariant& def = {});
private:
    QHash<QString, QVariant> m_cache;
    QScopedPointer<QSettings> m_settings;
};

#endif // WINDOWSIZEHELPER_H
