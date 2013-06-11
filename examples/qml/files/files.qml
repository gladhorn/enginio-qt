import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0

import Enginio 1.0
import "qrc:///config.js" as AppConfig

ApplicationWindow {

    width: 600
    height: 600
    visible: true

    Component.onCompleted: console.log("hello")

    // Enginio client specifies the backend to be used
    Enginio {
        id: client
        backendId: AppConfig.backendData.id
        backendSecret: AppConfig.backendData.secret
        apiUrl: AppConfig.backendData.apiUrl
        onError: console.log("Enginio error " + reply.errorCode + ": " + reply.errorString)
        onFinished: console.log(JSON.stringify(reply))
    }

    EnginioModel {
        id: enginioModel
        enginio: client
        query: { // query for all objects of type "objects.image" and include references to files
            "objectType": "objects.files",
            "include": {"file": {}},
        }
    }

    ColumnLayout {
        anchors.fill: parent

        TableView {
            id: listView
            model: enginioModel
            TableViewColumn {
                title: "Name"
                role: "name"
            }
            TableViewColumn {
                title: "Size"
                role: "size"
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Button {
            text: "Upload file"
            onClicked: fileDialog.visible = true
        }
    }

    // File dialog for selecting image file from local file system
    FileDialog {
        id: fileDialog
        title: "Select file to upload"
        nameFilters: [ "All files (*)" ]

        onSelectionAccepted: {
            var pathParts = fileUrl.toString().split("/");
            var fileName = pathParts[pathParts.length - 1];
            var fileObject = {
                objectType: "objects.files",
                name: fileName,
                localPath: fileUrl
            }
            var reply = client.create(fileObject);
            reply.finished.connect(function() {
                var uploadData = {
                    file: { fileName: fileName },
                    targetFileProperty: {
                        objectType: "objects.files",
                        id: reply.data.id,
                        propertyName: "file"
                    },
                };
                console.log("data: " + reply.data + " id: " + reply.data.id)
                var uploadReply = client.uploadFile(uploadData, fileUrl)
                uploadReply.finished.connect(function() { var tmp = enginioModel.query; enginioModel.query = {}; enginioModel.query = tmp; })
            })
            console.log("File selected: " + fileUrl);
        }
    }
}
