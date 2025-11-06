#include "TranslateHelper.h"

#include <QGuiApplication>
#include <QQmlEngine>

#include "SettingsHelper.h"

[[maybe_unused]] TranslateHelper::TranslateHelper(QObject *parent) : QObject(parent) {
    _languages << "en";
    _languages << "zh";

    _current = SettingsHelper::getInstance()->getLanguage();
}

TranslateHelper::~TranslateHelper() = default;

void TranslateHelper::init(QQmlEngine *engine) {
    qDebug() << "TranslateHelper::init";
    _engine = engine;
    _translator = new QTranslator(this);
    QGuiApplication::installTranslator(_translator);
    QString translatorPath = QGuiApplication::applicationDirPath() + "/i18n";
    if (_translator->load(
            QString::fromStdString("%1/language_%2.qm").arg(translatorPath, _current))) {
        _engine->retranslate();
    }
}
