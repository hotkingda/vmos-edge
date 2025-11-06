#ifndef FILECOPYWORKER_H
#define FILECOPYWORKER_H

#include <QObject>
#include <QString>

class FileCopyWorker : public QObject
{
    Q_OBJECT

public:
    explicit FileCopyWorker(QObject *parent = nullptr);

public slots:
    void doCopy(const QString &source, const QString &destination);
    void doDelete(const QString &filePath);
    void doValidateImage(const QString &imagePath);
    void doExtractImageInfo(const QString &imagePath);
    void doExtractAndValidateImage(const QString &imagePath);

signals:
    void progress(qint64 copiedSize, qint64 totalSize);
    void finished(bool success, const QString &message);
    void deleteFinished(bool success, const QString &message);
    void validationProgress(const QString &step, int progress);
    void validationFinished(bool success, const QString &message, const QString &imageName, const QString &tarFilePath = QString());
    void imageInfoExtracted(bool success, const QString &imageName, const QString &androidVersion, const QString &errorMessage = QString());
    void imageInfoAndValidationCompleted(bool success, const QString &message, const QString &imageName, const QString &androidVersion, const QString &tarFilePath = QString());

private:
    bool validateSignature(const QString &signature, const QString &tempDir);
    bool decompressZstd(const QString &inputPath, const QString &outputPath);
    bool extractTar(const QString &inputPath, const QString &outputDir);
    int copy_data(struct archive *ar, struct archive *aw);
    bool verifySignatureWithRsaPss(const QString &signature, const QString &message, const QByteArray &pemData);
    bool validateSignatureAlternative(const QString &signature, const QString &tempDir);
    bool verifySignatureSimple(const QString &signature, const QString &message, const QByteArray &pemData);
    QString calculateFileMd5(const QString &filePath);
    void cleanupTempDirectory(const QString &tempDir);
    QString copyValidatedTarGzFile(const QString &tempDir, const QString &imageName, const QString &targetDir);
};

#endif // FILECOPYWORKER_H
