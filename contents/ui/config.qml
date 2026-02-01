import QtQuick
import QtQuick.Controls as QtControls2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import "../code/timeCalculations.js" as TimeCalc

ColumnLayout {
    id: root

    property var configDialog
    property var wallpaperConfiguration: ({})
    property var parentLayout

    property alias cfg_UpdateInterval: updateIntervalSpinBox.value
    property alias cfg_ShowDebug: debugCheckBox.checked
    property alias cfg_FillMode: fillModeConfig.value

    property alias cfg_ScheduleJson: scheduleJsonField.text

    property bool __initializing: true

    function defaultScheduleJson() {
        return "{\"00:00\":\"images/11-Mid-Night.png\",\"04:00\":\"images/12-Late-Night.png\",\"06:00\":\"images/01-Early-Morning.png\",\"08:00\":\"images/02-Mid-Morning.png\",\"10:00\":\"images/03-Late-Morning.png\",\"12:00\":\"images/04-Early-Afternoon.png\",\"14:00\":\"images/05-Mid-Afternoon.png\",\"16:00\":\"images/06-Late-Afternoon.png\",\"18:00\":\"images/07-Early-Evening.png\",\"19:30\":\"images/08-Mid-Evening.png\",\"21:00\":\"images/09-Late-Evening.png\",\"22:30\":\"images/10-Early-Night.png\"}";
    }

    function normalizeTimeString(timeStr) {
        const parts = (timeStr || "00:00").split(":");
        const h = Math.max(0, Math.min(23, parseInt(parts[0] || 0)));
        const m = Math.max(0, Math.min(59, parseInt(parts[1] || 0)));
        return h.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0");
    }

    function loadScheduleFromConfig() {
        scheduleModel.clear()
        const raw = scheduleJsonField.text || defaultScheduleJson()
        let entries = TimeCalc.parseScheduleInput(raw)
        if (!entries.length) {
            entries = TimeCalc.parseScheduleInput(defaultScheduleJson())
        }
        for (let i = 0; i < entries.length; i++) {
            scheduleModel.append({ time: entries[i].time, image: entries[i].image })
        }
    }

    function saveScheduleToConfig() {
        const arr = []
        for (let i = 0; i < scheduleModel.count; i++) {
            const item = scheduleModel.get(i)
            arr.push({ time: normalizeTimeString(item.time), image: item.image })
        }
        scheduleJsonField.text = JSON.stringify(arr)
        if (configDialog && configDialog.changed) configDialog.changed()
    }

    function resolvePreviewSource(pathOrUrl) {
        if (!pathOrUrl) return "";
        if (pathOrUrl.startsWith("file://") || pathOrUrl.startsWith("http://") || pathOrUrl.startsWith("https://") || pathOrUrl.startsWith("qrc:")) {
            return pathOrUrl;
        }
        if (pathOrUrl.indexOf("/") === -1 && pathOrUrl.indexOf("\\") === -1) {
            return Qt.resolvedUrl("../images/" + pathOrUrl);
        }
        if (pathOrUrl.startsWith("/")) {
            return "file://" + pathOrUrl;
        }
        if (pathOrUrl.startsWith("images/")) {
            return Qt.resolvedUrl("../" + pathOrUrl);
        }
        return Qt.resolvedUrl(pathOrUrl);
    }

    ListModel { id: scheduleModel }

    QtControls2.TextField {
        id: scheduleJsonField
        visible: false
        text: defaultScheduleJson()
        onTextChanged: if (!root.__initializing) loadScheduleFromConfig()
    }

    function exportSettings() {
        const settings = {
            "ScheduleJson": scheduleJsonField.text,
            "UpdateInterval": updateIntervalSpinBox.value,
            "ShowDebug": debugCheckBox.checked,
            "FillMode": fillModeConfig.value
        }
        return JSON.stringify(settings, null, 2)
    }

    function importSettings(jsonString) {
        try {
            const settings = JSON.parse(jsonString)
            if (settings.ScheduleJson !== undefined) {
                scheduleJsonField.text = settings.ScheduleJson
            }
            if (settings.UpdateInterval !== undefined) {
                updateIntervalSpinBox.value = settings.UpdateInterval
            }
            if (settings.ShowDebug !== undefined) {
                debugCheckBox.checked = settings.ShowDebug
            }
            if (settings.FillMode !== undefined) {
                fillModeConfig.value = settings.FillMode
            }
            return true
        } catch (e) {
            console.error("Failed to import settings:", e)
            return false
        }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Separator {
            Kirigami.FormData.label: "Import / Export"
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: "Settings:"
            spacing: 8

            QtControls2.Button {
                text: "Export Settings"
                icon.name: "document-export"
                onClicked: exportDialog.open()
            }

            QtControls2.Button {
                text: "Import Settings"
                icon.name: "document-import"
                onClicked: importDialog.open()
            }
        }

        Kirigami.Separator {            Kirigami.FormData.label: "Credits"
            Kirigami.FormData.isSection: true
        }

        QtControls2.Label {
            Kirigami.FormData.label: "Artwork:"
            text: '<a href="https://www.bitday.me/">bitday.me</a> - Default wallpaper images'
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Kirigami.Separator {            Kirigami.FormData.label: "Schedule"
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: "HEIC File:"
            spacing: 8

            QtControls2.TextField {
                id: heicFileField
                Layout.fillWidth: true
                placeholderText: "Select a HEIC Dynamic Desktop file..."
                readOnly: true
            }

            QtControls2.Button {
                text: "Browse HEIC"
                icon.name: "document-open"
                onClicked: heicFileDialog.open()
            }

            QtControls2.Button {
                text: "Clear"
                icon.name: "edit-clear"
                enabled: heicFileField.text !== ""
                onClicked: {
                    heicFileField.text = ""
                    scheduleModel.clear()
                    scheduleJsonField.text = defaultScheduleJson()
                    saveScheduleToConfig()
                }
            }
        }

        QtControls2.Label {
            Kirigami.FormData.label: "Or Manual:"
            text: "Configure individual schedule entries below"
            font.italic: true
            visible: heicFileField.text === ""
        }

        ColumnLayout {
            Kirigami.FormData.label: "Entries:"
            Layout.fillWidth: true

            QtControls2.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 280

                ColumnLayout {
                    id: scheduleList
                    width: parent.width

                    Repeater {
                        model: scheduleModel
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            QtControls2.TextField {
                                id: timeField
                                text: model.time
                                inputMask: "00:00"
                                Layout.preferredWidth: 70
                                onEditingFinished: {
                                    const normalized = normalizeTimeString(text)
                                    scheduleModel.setProperty(index, "time", normalized)
                                    text = normalized
                                    saveScheduleToConfig()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 72
                                border.color: "gray"
                                border.width: 1
                                color: "transparent"
                                radius: 4

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectCrop
                                    source: resolvePreviewSource(model.image)
                                }
                            }

                            QtControls2.TextField {
                                Layout.fillWidth: true
                                text: model.image
                                placeholderText: "images/1.jpg"
                                onEditingFinished: {
                                    scheduleModel.setProperty(index, "image", text)
                                    saveScheduleToConfig()
                                }
                            }

                            QtControls2.Button {
                                text: "Browse"
                                onClicked: {
                                    scheduleImageDialog.targetIndex = index
                                    scheduleImageDialog.open()
                                }
                            }

                            QtControls2.Button {
                                text: "Remove"
                                onClicked: {
                                    scheduleModel.remove(index)
                                    saveScheduleToConfig()
                                }
                            }
                        }
                    }
                }
            }

            QtControls2.Button {
                text: "Add schedule entry"
                onClicked: {
                    scheduleModel.append({ time: "00:00", image: "images/1.jpg" })
                    saveScheduleToConfig()
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.label: "Display Settings"
            Kirigami.FormData.isSection: true
        }

        QtControls2.ComboBox {
            id: fillModeComboBox
            Kirigami.FormData.label: "Scaling:"
            model: [
                "Scaled and Cropped",
                "Scaled",
                "Scaled, Keep Proportions",
                "Centered",
                "Tiled"
            ]
            currentIndex: 2  // Default to "Scaled, Keep Proportions"
            onCurrentIndexChanged: {
                console.log("FillMode ComboBox changed to", currentIndex)
                fillModeConfig.value = currentIndex
            }
        }

        // Hidden control for fill mode
        QtControls2.SpinBox {
            id: fillModeConfig
            visible: false
            value: 2  // Default value
            onValueChanged: {
                console.log("FillMode config changed to", value)
                if (fillModeComboBox.currentIndex !== value) {
                    fillModeComboBox.currentIndex = value
                }
            }
        }



        Kirigami.Separator {
            Kirigami.FormData.label: "Update Settings"
            Kirigami.FormData.isSection: true
        }

        QtControls2.SpinBox {
            id: updateIntervalSpinBox
            Kirigami.FormData.label: "Update interval (minutes):"
            from: 1
            to: 60
            value: 5
        }

        QtControls2.CheckBox {
            id: debugCheckBox
            Kirigami.FormData.label: "Show debug info:"
            checked: false
        }
    }

    // File dialog for schedule image selection
    FileDialog {
        id: scheduleImageDialog
        property int targetIndex: -1
        title: "Select Scheduled Wallpaper"
        nameFilters: ["Image files (*.jpg *.jpeg *.png *.bmp *.gif *.tiff *.webp)", "All files (*)"]
        onAccepted: {
            const selectedPath = selectedFile.toString().replace("file://", "")
            if (targetIndex >= 0 && targetIndex < scheduleModel.count) {
                scheduleModel.setProperty(targetIndex, "image", selectedPath)
                saveScheduleToConfig()
            }
        }
    }

    // File dialog for HEIC file selection
    FileDialog {
        id: heicFileDialog
        title: "Select HEIC Dynamic Desktop File"
        nameFilters: ["HEIC files (*.heic *.heif)", "All files (*)"]
        onAccepted: {
            const selectedPath = selectedFile.toString().replace("file://", "")
            heicFileField.text = selectedPath

            // When HEIC file is selected, set it as the schedule directly
            // The main.qml will detect it's a HEIC and process it
            scheduleJsonField.text = selectedPath
            saveScheduleToConfig()

            console.log("HEIC file selected:", selectedPath)
        }
    }

    // File dialog for exporting settings
    FileDialog {
        id: exportDialog
        title: "Export Settings"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        defaultSuffix: "json"
        onAccepted: {
            const filePath = selectedFile.toString().replace("file://", "")
            const jsonContent = exportSettings()

            // Use Qt.StandardPaths to write file
            const success = TimeCalc.writeFile(filePath, jsonContent)
            if (success) {
                console.log("Settings exported to:", filePath)
            } else {
                console.error("Failed to export settings to:", filePath)
            }
        }
    }

    // File dialog for importing settings
    FileDialog {
        id: importDialog
        title: "Import Settings"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        onAccepted: {
            const filePath = selectedFile.toString().replace("file://", "")

            // Use Qt.StandardPaths to read file
            const jsonContent = TimeCalc.readFile(filePath)
            if (jsonContent !== null) {
                const success = importSettings(jsonContent)
                if (success) {
                    console.log("Settings imported from:", filePath)
                } else {
                    console.error("Failed to parse settings from:", filePath)
                }
            } else {
                console.error("Failed to read file:", filePath)
            }
        }
    }

    Component.onCompleted: {
        root.__initializing = true
        loadScheduleFromConfig()
        root.__initializing = false
    }
}
