TEMPLATE = app

DEFINES += ENGINIO_SAMPLE_NAME=\\\"files\\\"

# for file dialogs we want widgets

QT += quick qml enginio widgets
SOURCES += main.cpp

mac: CONFIG -= app_bundle

OTHER_FILES += *.qml *.js

RESOURCES += \
    ../qml.qrc \
    files.qrc
