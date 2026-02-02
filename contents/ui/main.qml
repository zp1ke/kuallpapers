import QtQuick 2.0
import QtQuick.Controls 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import "../code/timeCalculations.js" as TimeCalc

WallpaperItem {
    id: root

    property string scheduleJson: wallpaper.configuration.ScheduleJson || TimeCalc.getDefaultScheduleJson()

    property int updateInterval: wallpaper.configuration.UpdateInterval || 5

    property int fillModeIndex: wallpaper.configuration.FillMode !== undefined ? wallpaper.configuration.FillMode : 2

    Connections {
        target: wallpaper.configuration
        function onFillModeChanged() {
            fillModeIndex = wallpaper.configuration.FillMode
        }
        function onScheduleJsonChanged() {
            scheduleJson = wallpaper.configuration.ScheduleJson
            updateWallpaper()
        }
    }

    function getFillMode() {
        switch(fillModeIndex) {
            case 0: return Image.PreserveAspectCrop  // Scaled and Cropped
            case 1: return Image.Stretch             // Scaled
            case 2: return Image.PreserveAspectFit   // Scaled, Keep Proportions
            case 3: return Image.Pad                 // Centered
            case 4: return Image.Tile                // Tiled
            default: return Image.PreserveAspectCrop
        }
    }

    function getFillModeName() {
        switch(fillModeIndex) {
            case 0: return "PreserveAspectCrop"
            case 1: return "Stretch"
            case 2: return "PreserveAspectFit"
            case 3: return "Pad"
            case 4: return "Tile"
            default: return "PreserveAspectCrop"
        }
    }

    onFillModeIndexChanged: {
        backgroundImage.fillMode = getFillMode()
        foregroundImage.fillMode = getFillMode()
    }

    property string currentImage: ""
    property string pendingImage: ""

    function resolveImageSource(pathOrUrl) {
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

    function imageFileName(pathOrUrl) {
        if (!pathOrUrl) return "none";
        let normalized = pathOrUrl;
        if (normalized.startsWith("file://")) {
            normalized = normalized.replace("file://", "");
        }
        return normalized.split("/").pop();
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: resolveImageSource(currentImage)
        fillMode: getFillMode()
        asynchronous: true
        cache: false
    }

    Image {
        id: foregroundImage
        anchors.fill: parent
        fillMode: getFillMode()
        asynchronous: true
        cache: false
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }

        onOpacityChanged: {
            if (opacity === 1) {
                backgroundImage.source = foregroundImage.source
                currentImage = pendingImage
                pendingImage = ""
                foregroundImage.opacity = 0
            }
        }

        onStatusChanged: {
            if (status === Image.Error) {
                console.log("Kuallpapers: image error", source)
            }
        }
    }

    onScheduleJsonChanged: updateWallpaper()

    Timer {
        id: updateTimer
        interval: updateInterval * 60 * 1000
        running: true
        repeat: true
        onTriggered: updateWallpaper()
    }

    Timer {
        id: preciseTimer
        running: false
        repeat: false
        onTriggered: {
            updateWallpaper()
            updateTimer.restart()
        }
    }

    Component.onCompleted: {
        updateWallpaper()
    }

    function updateWallpaper() {
        let newImage = TimeCalc.getWallpaperForSchedule(scheduleJson)

        if (newImage !== currentImage) {
            if (!currentImage) {
                currentImage = newImage
                backgroundImage.source = resolveImageSource(newImage)
            } else {
                pendingImage = newImage
                foregroundImage.source = resolveImageSource(newImage)
                foregroundImage.opacity = 1
            }
        }

        let nextUpdateMs = TimeCalc.getNextUpdateTimeSchedule(scheduleJson)
        if (nextUpdateMs < updateTimer.interval) {
            preciseTimer.interval = nextUpdateMs
            preciseTimer.start()
        }
    }

    // Debug overlay
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: debugText.width + 20
        height: debugText.height + 20
        color: "black"
        opacity: 0.7
        visible: wallpaper.configuration.ShowDebug !== undefined ? wallpaper.configuration.ShowDebug : true

        Text {
            id: debugText
            anchors.centerIn: parent
            color: "white"
            font.pointSize: 10
            text: ""

            Timer {
                interval: 1000
                running: parent.parent.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const now = new Date()
                    const timeStr = now.toLocaleTimeString()
                    const imageFile = imageFileName(root.currentImage)
                    const scheduleEntries = TimeCalc.parseScheduleInput(root.scheduleJson).length
                    debugText.text = `Time: ${timeStr}\nImage: ${imageFile}\nSchedule entries: ${scheduleEntries}`
                }
            }
        }
    }
}
