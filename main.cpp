#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QSurfaceFormat>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QSurfaceFormat format;
    format.setAlphaBufferSize(0);
    format.setRedBufferSize(8);
    format.setSamples(16);
    format.setRenderableType(QSurfaceFormat::OpenGLES);
    QSurfaceFormat::setDefaultFormat(format);

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/");
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
