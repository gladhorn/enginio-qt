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

    // Enginio client specifies the backend to be used
    Enginio {
        id: client
        backendId: AppConfig.backendData.id
        backendSecret: AppConfig.backendData.secret
        onError: console.log("Enginio finished " + reply.errorCode + ": " + reply.errorString)
        onFinished: console.log(JSON.stringify(reply))
    }

    EnginioModel {
        id: enginioModel
        enginio: client
        query: { // query for all objects of type "objects.image" and include references to files
            "objectType": "objects.files",
            "include": {"file": {}},
            "sort": [{"sortBy": "name", "direction": "asc"}],
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
                title: "Type"
                delegate: typeDelegate
            }
            TableViewColumn {
                title: "Size"
                delegate: sizeDelegate
            }
            TableViewColumn {
                title: "Status"
                delegate: statusDelegate
            }
            Layout.fillWidth: true
            Layout.fillHeight: true

            onClicked: console.log("Clicked")
            onActivated: {
                console.log("Activated: " + row + JSON.stringify(model.rowData(row)["file"]))
                downloadFile(model.rowData(row)["file"]["id"], model.rowData(row)["file"]["fileName"])
            }
        }

        RowLayout {
            Button {
                text: "Upload file"
                onClicked: fileDialog.visible = true
            }
            Button {
                id: downloadButton
                enabled: listView.currentRow >= 0
                text: "Download selected"
                onClicked: downloadFile(enginioModel.rowData(listView.currentRow)["file"]["id"],
                                        enginioModel.rowData(listView.currentRow)["file"]["fileName"])
            }
            Button {
                id: deleteButton
                enabled: listView.currentRow >= 0
                text: "Delete selected"
                onClicked: enginioModel.remove(listView.currentRow)
            }

            ProgressBar {
                id: uploadProgress
                maximumValue: 1.0
                visible: false
                Layout.fillWidth: true
                Text {
                    id: progressText
                    anchors.centerIn: parent
                }
            }
        }
    }

    function sizeString(size) {
        if (size > 1024 * 1024)
            return (size / 1024 / 1024).toFixed(1).toString() + " MiB"
        if (size > 1024)
            return (size / 1024).toFixed(1).toString() + " KiB"
        return size.toString() + " B"
    }

    Component {
        id: sizeDelegate
        Text {
            id: label
            text: sizeString(model.rowData(styleData.row)["file"]["fileSize"])
            width: parent.width
            anchors.margins: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Qt.AlignRight
            font: styleitem.font
            color: styleData.textColor
            renderType: Text.NativeRendering
        }
    }
    Component {
        id: typeDelegate
        Text {
            id: label
            text: sizeString(model.rowData(styleData.row)["file"]["contentType"])
            width: parent.width
            anchors.margins: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Qt.AlignLeft
            font: styleitem.font
            color: styleData.textColor
            renderType: Text.NativeRendering
        }
    }
    Component {
        id: statusDelegate
        Text {
            text: (model.rowData(styleData.row)["file"] !== undefined
                && model.rowData(styleData.row)["file"]["fileSize"] !== undefined) ?
                      "Complete" : "Incomplete"
            anchors.left: parent.left
            anchors.margins: 8
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    FileDialog {
        id: saveDialog
        property string fileId
        property string fileName
        onSelectionAccepted: {
            console.log("download to : " + fileUrl.toString() + "/" + fileName)
            var downReply = client.downloadFile({"id":fileId}, fileUrl.toString() + fileName)
            downReply.finished.connect(function() {
                console.log("Download: " + JSON.stringify(downReply.data) + " to " + fileUrl)
            })
        }
    }

    function downloadFile(fileId, fileName) {
        console.log("Download " + fileId + " as " + fileName)
        saveDialog.title = "Download " + fileName
        saveDialog.fileId = fileId
        saveDialog.fileName = fileName
        saveDialog.setSelectFolder(true)
        saveDialog.visible = true
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
                uploadReply.finished.connect(function() {
                    var tmp = enginioModel.query; enginioModel.query = {}; enginioModel.query = tmp;
                    uploadProgress.visible = false
                })
                uploadReply.uploadProgress.connect(function(progress, total) {
                    console.log("Uploading: " + progress + " of " + total)
                    uploadProgress.value = progress / total
                    uploadProgress.visible = true
                    progressText.text = "Uploaded " + sizeString(progress) + " of " + sizeString(total)
                })
            })
            console.log("File selected: " + fileUrl);
        }
    }
}
