#ifndef FILECOPYMANAGER_H
#define FILECOPYMANAGER_H

#include <QObject>

class FileCopyManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qint64 totalSize READ totalSize NOTIFY totalSizeChanged)
    Q_PROPERTY(qint64 copiedSize READ copiedSize NOTIFY progressChanged)
    Q_PROPERTY(int progressPercent READ progressPercent NOTIFY progressChanged)
    Q_PROPERTY(bool isCopying READ isCopying NOTIFY isCopyingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    static FileCopyManager *instance();

    Q_INVOKABLE bool startCopy(const QString &source, const QString &destination, const QString &tempDirToCleanup = QString());
    Q_INVOKABLE bool startDelete(const QString &filePath);
    Q_INVOKABLE qint64 getFileSize(const QString &filePath);
    Q_INVOKABLE qint64 getAvailableSpace(const QString &path);
    Q_INVOKABLE bool startImageValidation(const QString &imagePath);
    Q_INVOKABLE bool startImageInfoExtraction(const QString &imagePath);
    Q_INVOKABLE bool startImageInfoAndValidation(const QString &imagePath);
    Q_INVOKABLE void cleanupTempDirectory(const QString &tempDir);

    qint64 totalSize() const { return m_totalSize; }
    qint64 copiedSize() const { return m_copiedSize; }
    int progressPercent() const;
    bool isCopying() const { return m_isCopying; }
    QString status() const { return m_status; }

signals:
    void progressChanged();
    void totalSizeChanged();
    void isCopyingChanged();
    void statusChanged();

    // Signals for explicit completion notification
    void copySucceeded();
    void copyFailed(const QString &reason);
    void deleteSucceeded(const QString &filePath);
    void deleteFailed(const QString &reason);
    
    // Image validation signals
    void validationProgress(const QString &step, int progress);
    void validationSucceeded(const QString &imageName, const QString &tarFilePath);
    void validationFailed(const QString &reason);
    
    // Image info extraction signals
    void imageInfoExtracted(bool success, const QString &imageName, const QString &androidVersion, const QString &errorMessage = QString());
    
    // Combined image info and validation signals
    void imageInfoAndValidationCompleted(bool success, const QString &message, const QString &imageName, const QString &androidVersion, const QString &tarFilePath = QString());

private slots:
    void onCopyProgress(qint64 copiedSize, qint64 totalSize);
    void onCopyFinished(bool success, const QString &message);
    void onDeleteFinished(bool success, const QString &message);
    void onValidationFinished(bool success, const QString &message, const QString &imageName, const QString &tarFilePath);
    void onImageInfoExtracted(bool success, const QString &imageName, const QString &androidVersion, const QString &errorMessage);
    void onImageInfoAndValidationCompleted(bool success, const QString &message, const QString &imageName, const QString &androidVersion, const QString &tarFilePath);

private:
    explicit FileCopyManager(QObject *parent = nullptr);
    ~FileCopyManager() = default;
    FileCopyManager(const FileCopyManager&) = delete;
    FileCopyManager& operator=(const FileCopyManager&) = delete;

    qint64 m_totalSize = 0;
    qint64 m_copiedSize = 0;
    bool m_isCopying = false;
    QString m_status = "Ready";
    QString m_deletingFilePath;
    QString m_tempDirToCleanup;  // 存储需要清理的临时目录路径
};

#endif // FILECOPYMANAGER_H