import QtQuick 2.0
import QtQuick.Controls 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import "../code/timeCalculations.js" as TimeCalc

WallpaperItem {
    id: root

    property string scheduleJson: wallpaper.configuration.ScheduleJson || "{\"00:00\":\"images/11-Mid-Night.png\",\"04:00\":\"images/12-Late-Night.png\",\"06:00\":\"images/01-Early-Morning.png\",\"08:00\":\"images/02-Mid-Morning.png\",\"10:00\":\"images/03-Late-Morning.png\",\"12:00\":\"images/04-Early-Afternoon.png\",\"14:00\":\"images/05-Mid-Afternoon.png\",\"16:00\":\"images/06-Late-Afternoon.png\",\"18:00\":\"images/07-Early-Evening.png\",\"19:30\":\"images/08-Mid-Evening.png\",\"21:00\":\"images/09-Late-Evening.png\",\"22:30\":\"images/10-Early-Night.png\"}"
    property string heicFilePath: ""
    property bool processingHeic: false

    property int updateInterval: wallpaper.configuration.UpdateInterval || 5

    property int fillModeIndex: wallpaper.configuration.FillMode !== undefined ? wallpaper.configuration.FillMode : 2

    Connections {
        target: wallpaper.configuration
        function onFillModeChanged() {
            fillModeIndex = wallpaper.configuration.FillMode
        }
        function onScheduleJsonChanged() {
            scheduleJson = wallpaper.configuration.ScheduleJson
            checkForHeicFile()
            updateWallpaper()
        }
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: {
            const stdout = data["stdout"]
            if (stdout && heicFilePath) {
                try {
                    const parsed = JSON.parse(stdout)
                    if (Array.isArray(parsed)) {
                        scheduleJson = stdout
                        processingHeic = false
                        console.log("Kuallpapers: Loaded HEIC schedule with", parsed.length, "entries")
                    }
                } catch (e) {
                    console.error("Kuallpapers: Error parsing HEIC output:", e)
                    processingHeic = false
                }
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
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

    function checkForHeicFile() {
        if (TimeCalc.isHeicFile(scheduleJson)) {
            heicFilePath = scheduleJson

            // Try to load cached schedule first
            const cached = TimeCalc.loadHeicSchedule(heicFilePath)
            if (cached) {
                scheduleJson = JSON.stringify(cached)
                console.log("Kuallpapers: Loaded cached HEIC schedule")
                return
            }

            // If no cache, process the HEIC file
            processHeicFile(heicFilePath)
        } else {
            heicFilePath = ""
        }
    }

    function processHeicFile(filePath) {
        if (processingHeic) return

        processingHeic = true
        const pythonScript = Qt.resolvedUrl("../code/heic_parser.py").toString().replace("file://", "")
        let normalizedPath = filePath

        if (normalizedPath.startsWith("file://")) {
            normalizedPath = normalizedPath.substring(7)
        }

        // Try python3 first, then python
        const cmd = `python3 "${pythonScript}" "${normalizedPath}" 2>&1 || python "${pythonScript}" "${normalizedPath}" 2>&1`
        console.log("Kuallpapers: Processing HEIC file:", normalizedPath)
        executable.exec(cmd)
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
        checkForHeicFile()
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
