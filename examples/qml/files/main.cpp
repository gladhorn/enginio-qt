#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDir>

int main(int argc, char* argv[])
{
    QApplication app(argc,argv);
    QQmlApplicationEngine engine(QUrl("qrc:///" ENGINIO_SAMPLE_NAME ".qml"));
    return app.exec();
}
