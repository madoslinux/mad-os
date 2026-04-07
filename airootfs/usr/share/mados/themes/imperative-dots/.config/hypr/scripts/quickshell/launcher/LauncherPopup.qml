import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    property string searchText: ""
    property string sourceFilter: "all"
    property var rawApps: []
    property int selectedIndex: -1
    property int scrollAccum: 0
    property bool loading: false
    property var freqData: ({})
    property var configData: defaultConfig()

    readonly property string launcherScriptPath: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/launcher/list_apps.py"
    readonly property string frequencyScriptPath: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/launcher/record_frequency.py"
    readonly property string stateScriptPath: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/launcher/update_state.py"
    readonly property string launcherConfigPath: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/launcher/config.json"
    readonly property string hiddenAppsConfigPath: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/launcher/hidden-apps.json"
    readonly property string launcherCacheDir: Quickshell.env("HOME") + "/.cache/quickshell/launcher"
    readonly property string frequencyFilePath: launcherCacheDir + "/freq.json"
    readonly property string stateFilePath: launcherCacheDir + "/state.json"
    readonly property int compactCardWidth: Math.max(120, Math.round(toNumber(cfg("ui", "compactCardWidth", 176), 176)))
    readonly property int expandedCardWidth: Math.max(220, Math.round(toNumber(cfg("ui", "expandedCardWidth", 360), 360)))
    readonly property bool showBadges: toBool(cfg("ui", "showBadges", true), true)
    readonly property bool showSteamHeroBackground: toBool(cfg("ui", "showSteamHeroBackground", true), true)
    readonly property var defaultHiddenDesktopFiles: toLookup(hiddenConfigData.desktopFiles)
    readonly property var defaultHiddenAppNames: toLookup(hiddenConfigData.appNames)
    readonly property var defaultHiddenExecHeads: toLookup(hiddenConfigData.execHeads)
    property var stateData: ({ "favorites": {}, "hidden": {} })
    property var hiddenConfigData: defaultHiddenConfig()
    property string contextAppId: ""
    property bool contextFavorite: false
    property bool contextHidden: false

    function defaultState() {
        return { "favorites": {}, "hidden": {} };
    }

    function normalizeState(rawState) {
        let normalized = defaultState();
        if (!rawState || typeof rawState !== "object")
            return normalized;

        if (rawState.favorites && typeof rawState.favorites === "object")
            normalized.favorites = rawState.favorites;

        if (rawState.hidden && typeof rawState.hidden === "object")
            normalized.hidden = rawState.hidden;

        return normalized;
    }

    function isFavorite(appId) {
        let key = appKey(appId);
        if (key === "")
            return false;

        let bucket = stateData.favorites;
        return bucket && typeof bucket === "object" && bucket[key] === true;
    }

    function isHidden(appId) {
        let key = appKey(appId);
        if (key === "")
            return false;

        let bucket = stateData.hidden;
        return bucket && typeof bucket === "object" && bucket[key] === true;
    }

    function isDefaultHidden(app) {
        if (!app || typeof app !== "object")
            return false;

        let desktopFile = String(app.desktopFile || "").toLowerCase();
        if (desktopFile !== "" && defaultHiddenDesktopFiles[desktopFile] === true)
            return true;

        let name = String(app.name || "").toLowerCase().trim();
        if (name !== "" && defaultHiddenAppNames[name] === true)
            return true;

        let execHead = String(app.execHead || "").toLowerCase().trim();
        if (execHead !== "" && defaultHiddenExecHeads[execHead] === true)
            return true;

        return false;
    }

    function persistState(action, appId, enabled) {
        let key = appKey(appId);
        if (key === "")
            return;

        Quickshell.execDetached([
            "python3",
            stateScriptPath,
            stateFilePath,
            action,
            key,
            enabled ? "1" : "0"
        ]);
    }

    function setFavorite(appId, enabled) {
        let key = appKey(appId);
        if (key === "")
            return;

        let nextFavorites = Object.assign({}, stateData.favorites || {});
        let nextHidden = Object.assign({}, stateData.hidden || {});
        if (enabled)
            nextFavorites[key] = true;
        else
            delete nextFavorites[key];

        stateData = { "favorites": nextFavorites, "hidden": nextHidden };
        persistState("favorite", key, enabled);
    }

    function setHidden(appId, enabled) {
        let key = appKey(appId);
        if (key === "")
            return;

        let nextFavorites = Object.assign({}, stateData.favorites || {});
        let nextHidden = Object.assign({}, stateData.hidden || {});
        if (enabled)
            nextHidden[key] = true;
        else
            delete nextHidden[key];

        stateData = { "favorites": nextFavorites, "hidden": nextHidden };
        persistState("hidden", key, enabled);
        hideContextMenu();
    }

    function toggleFavorite(appId) {
        setFavorite(appId, !isFavorite(appId));
    }

    function toggleHidden(appId) {
        setHidden(appId, !isHidden(appId));
    }

    function loadStateData() {
        if (!stateReadProcess.running)
            stateReadProcess.running = true;
    }

    function appAcronym(name) {
        let value = String(name || "").trim();
        if (value === "")
            return "APP";

        let words = value.split(/[^A-Za-z0-9]+/).filter(w => w.length > 0);
        if (words.length <= 0)
            words = [value];

        let ignored = {
            "de": true,
            "del": true,
            "la": true,
            "las": true,
            "los": true,
            "the": true,
            "and": true,
            "of": true,
            "for": true,
            "to": true
        };

        let filtered = words.filter(w => !ignored[String(w).toLowerCase()]);
        if (filtered.length <= 0)
            filtered = words;

        if (filtered.length >= 3)
            return (filtered[0][0] + filtered[1][0] + filtered[2][0]).toUpperCase();

        if (filtered.length === 2)
            return (filtered[0][0] + filtered[1][0]).toUpperCase();

        return filtered[0].slice(0, 3).toUpperCase();
    }

    function openContextMenu(appId, mouseX, mouseY) {
        contextAppId = appId;
        contextFavorite = isFavorite(appId);
        contextHidden = isHidden(appId);

        let menuW = contextMenu.width;
        let menuH = contextMenu.height;
        let maxX = Math.max(0, cardSurface.width - menuW - 12);
        let maxY = Math.max(0, cardSurface.height - menuH - 12);

        contextMenu.x = Math.max(12, Math.min(mouseX, maxX));
        contextMenu.y = Math.max(12, Math.min(mouseY, maxY));
        contextMenu.visible = true;
    }

    function hideContextMenu() {
        contextMenu.visible = false;
        contextAppId = "";
        contextFavorite = false;
        contextHidden = false;
    }

    function defaultConfig() {
        return {
            "ranking": {
                "frequencyWeight": 0.72,
                "recencyWeight": 0.28,
                "recencyHalfLifeSeconds": 604800,
                "minQueryLength": 1
            },
            "behavior": {
                "frequencyRefreshMs": 1500
            },
            "ui": {
                "compactCardWidth": 176,
                "expandedCardWidth": 360,
                "showBadges": true,
                "showSteamHeroBackground": true
            }
        };
    }

    function defaultHiddenConfig() {
        return {
            "desktopFiles": [
                "nm-connection-editor.desktop",
                "bssh.desktop",
                "avahi-discover.desktop",
                "bvnc.desktop",
                "blueman-adapters.desktop",
                "blueman-manager.desktop",
                "lxappearance.desktop",
                "lstopo.desktop",
                "libreoffice-startcenter.desktop",
                "libreoffice-base.desktop",
                "libreoffice-draw.desktop",
                "easyeffects.desktop",
                "htop.desktop",
                "btop.desktop",
                "libreoffice-math.desktop",
                "mados-launcher.desktop",
                "mados-equalizer.desktop",
                "qt5ct.desktop",
                "qt6ct.desktop",
                "vim.desktop",
                "exo-preferred-applications.desktop",
                "pavucontrol.desktop"
            ],
            "appNames": [
                "advanced network configuration",
                "avahi ssh server browser",
                "avahi zeroconf browser",
                "avahi vnc server browser",
                "bluetooth adapters",
                "bluetooth manager",
                "customize look and feel",
                "easy effects",
                "easyeffects",
                "hardware locality lstopo",
                "libreoffice",
                "libreoffice base",
                "libreoffice draw",
                "htop",
                "btop",
                "libreoffice math",
                "mados equalizer",
                "mados-equalizer",
                "mados launcher",
                "preferred applications",
                "qt5 settings",
                "qt6 settings",
                "vim",
                "volume control",
                "pulseaudio volume control"
            ],
            "execHeads": [
                "mados-launcher",
                "mados-equalizer",
                "vim"
            ]
        };
    }

    function cfg(section, key, fallback) {
        let sectionObj = configData[section];
        if (!sectionObj || typeof sectionObj !== "object")
            return fallback;

        if (sectionObj[key] === undefined || sectionObj[key] === null)
            return fallback;

        return sectionObj[key];
    }

    function toNumber(value, fallback) {
        let n = Number(value);
        if (!isFinite(n))
            return fallback;

        return n;
    }

    function toBool(value, fallback) {
        if (typeof value === "boolean")
            return value;

        return fallback;
    }

    function normalizeLookupKey(value) {
        return String(value || "").toLowerCase().trim();
    }

    function toLookup(value) {
        let output = {};
        if (Array.isArray(value)) {
            for (let i = 0; i < value.length; i++) {
                let key = normalizeLookupKey(value[i]);
                if (key !== "")
                    output[key] = true;
            }
            return output;
        }

        if (value && typeof value === "object") {
            let keys = Object.keys(value);
            for (let j = 0; j < keys.length; j++) {
                let key = normalizeLookupKey(keys[j]);
                if (key !== "" && value[keys[j]] === true)
                    output[key] = true;
            }
        }

        return output;
    }

    function applyConfig(rawConfig) {
        let merged = defaultConfig();
        if (!rawConfig || typeof rawConfig !== "object") {
            configData = merged;
            return;
        }

        let sections = ["ranking", "behavior", "ui"];
        for (let i = 0; i < sections.length; i++) {
            let name = sections[i];
            let incoming = rawConfig[name];
            if (!incoming || typeof incoming !== "object")
                continue;

            let keys = Object.keys(incoming);
            for (let j = 0; j < keys.length; j++) {
                let key = keys[j];
                merged[name][key] = incoming[key];
            }
        }

        configData = merged;
    }

    function applyHiddenConfig(rawConfig) {
        let merged = defaultHiddenConfig();
        if (!rawConfig || typeof rawConfig !== "object") {
            hiddenConfigData = merged;
            return;
        }

        let sections = ["desktopFiles", "appNames", "execHeads"];
        for (let i = 0; i < sections.length; i++) {
            let name = sections[i];
            let incoming = rawConfig[name];
            if (Array.isArray(incoming))
                merged[name] = incoming;
        }

        hiddenConfigData = merged;
    }

    function loadLauncherConfig() {
        if (!configReadProcess.running)
            configReadProcess.running = true;
    }

    function loadHiddenConfig() {
        if (!hiddenConfigReadProcess.running)
            hiddenConfigReadProcess.running = true;
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\"'\"'") + "'";
    }

    function appKey(name) {
        return String(name || "").toLowerCase();
    }

    function currentQuery() {
        return String(searchText || "").toLowerCase().trim();
    }

    function normalizeFrequencyValue(value) {
        if (typeof value === "number") {
            return {
                "count": Number(value),
                "last": 0
            };
        }

        if (value && typeof value === "object") {
            return {
                "count": toNumber(value.count, 0),
                "last": toNumber(value.last, 0)
            };
        }

        return {
            "count": 0,
            "last": 0
        };
    }

    function frequencyStats(appId, appName, query) {
        let q = String(query || "").toLowerCase().trim();
        let key = appKey(appId);
        let legacyKey = appKey(appName);
        if (q === "" || key === "")
            return { "count": 0, "last": 0 };

        let bucket = freqData[q];
        if (!bucket)
            return { "count": 0, "last": 0 };

        let value = bucket[key];
        if (value === undefined && legacyKey !== "")
            value = bucket[legacyKey];

        return normalizeFrequencyValue(value);
    }

    function combinedScore(count, last, query) {
        let minQueryLength = Math.max(0, Math.round(toNumber(cfg("ranking", "minQueryLength", 1), 1)));
        let q = String(query || "").toLowerCase().trim();
        if (q.length < minQueryLength)
            return 0;

        let frequencyWeight = toNumber(cfg("ranking", "frequencyWeight", 0.72), 0.72);
        let recencyWeight = toNumber(cfg("ranking", "recencyWeight", 0.28), 0.28);
        let halfLife = Math.max(3600, toNumber(cfg("ranking", "recencyHalfLifeSeconds", 604800), 604800));

        let frequencyPart = Math.log(Math.max(0, count) + 1);
        let recencyPart = 0;
        if (last > 0) {
            let nowEpoch = Math.floor(Date.now() / 1000);
            let age = Math.max(0, nowEpoch - Math.floor(last));
            recencyPart = Math.exp(-age / halfLife);
        }

        return (frequencyPart * frequencyWeight) + (recencyPart * recencyWeight);
    }

    function loadFrequencyData() {
        if (!freqReadProcess.running)
            freqReadProcess.running = true;
    }

    function refreshApps() {
        if (loadAppsProcess.running)
            return;

        loading = true;
        loadAppsProcess.running = true;
    }

    function applyFilter() {
        let query = currentQuery();
        let minQueryLength = Math.max(0, Math.round(toNumber(cfg("ranking", "minQueryLength", 1), 1)));
        let oldKey = "";
        if (selectedIndex >= 0 && selectedIndex < filteredModel.count)
            oldKey = appKey(filteredModel.get(selectedIndex).id || filteredModel.get(selectedIndex).name);

        let candidates = [];
        for (let i = 0; i < rawApps.length; i++) {
            let app = rawApps[i];
            let appId = String(app.id || app.name || "");
            let name = String(app.name || "");
            let iconName = String(app.icon || "");
            let categories = String(app.categories || "");
            let tags = String(app.tags || "");
            let displayCategory = String(app.displayCategory || "App");
            let displayTagsText = String(app.displayTagsText || "");
            let source = String(app.source || "desktop").toLowerCase();
            let thumbPath = String(app.thumbPath || "");
            let heroPath = String(app.heroPath || "");
            let desktopFile = String(app.desktopFile || "").toLowerCase();
            let execHead = String(app.execHead || "").toLowerCase();
            let isGame = app.isGame === true;
            let hidden = isHidden(appId) || isDefaultHidden(app);
            let favorite = isFavorite(appId);
            let sourceLabel = source === "steam" ? "steam" : "app";
            let haystack = (name + " " + categories + " " + tags + " " + displayCategory + " " + displayTagsText + " " + sourceLabel).toLowerCase();

            if (query !== "" && haystack.indexOf(query) === -1)
                continue;

            if (sourceFilter === "apps" && isGame)
                continue;

            if (sourceFilter === "games" && !isGame)
                continue;

            if (sourceFilter === "hidden") {
                if (!hidden)
                    continue;
            } else if (hidden) {
                continue;
            }

            let stats = frequencyStats(appId, name, query);
            let score = combinedScore(stats.count, stats.last, query);
            candidates.push({
                "id": appId,
                "name": name,
                "exec": String(app.exec || ""),
                "iconName": iconName,
                "iconPath": String(app.iconPath || ""),
                "thumbPath": thumbPath,
                "heroPath": heroPath,
                "categories": categories,
                "tags": tags,
                "displayCategory": displayCategory,
                "displayTagsText": displayTagsText,
                "isGame": isGame,
                "terminal": app.terminal === true,
                "source": source,
                "desktopFile": desktopFile,
                "execHead": execHead,
                "favorite": favorite,
                "hidden": hidden,
                "score": score,
                "frequencyCount": stats.count,
                "lastUsed": stats.last
            });
        }

        candidates.sort((a, b) => {
            if (a.favorite !== b.favorite)
                return a.favorite ? -1 : 1;

            if (query.length >= minQueryLength && b.score !== a.score)
                return b.score - a.score;

            return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        });

        filteredModel.clear();
        for (let j = 0; j < candidates.length; j++)
            filteredModel.append(candidates[j]);

        if (filteredModel.count <= 0) {
            selectedIndex = -1;
            listView.currentIndex = -1;
            return;
        }

        let nextIndex = -1;
        if (oldKey !== "") {
            for (let k = 0; k < filteredModel.count; k++) {
                if (appKey(filteredModel.get(k).id || filteredModel.get(k).name) === oldKey) {
                    nextIndex = k;
                    break;
                }
            }
        }

        if (nextIndex === -1)
            nextIndex = 0;

        selectedIndex = Math.max(0, Math.min(nextIndex, filteredModel.count - 1));
        listView.currentIndex = selectedIndex;
        listView.positionViewAtIndex(selectedIndex, ListView.Center);
    }

    function moveSelection(step) {
        if (filteredModel.count <= 0)
            return;

        let index = selectedIndex;
        if (index < 0)
            index = 0;

        index = (index + step + filteredModel.count) % filteredModel.count;
        selectedIndex = index;
        listView.currentIndex = index;
        listView.positionViewAtIndex(index, ListView.Center);
    }

    function closeLauncher() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    function recordSelection(appId, appName) {
        let query = currentQuery();
        let key = appKey(appId || appName);
        if (query.length < 2 || key === "")
            return;

        Quickshell.execDetached([
            "python3",
            frequencyScriptPath,
            frequencyFilePath,
            query,
            key
        ]);
    }

    function launchSelected() {
        if (selectedIndex < 0 || selectedIndex >= filteredModel.count)
            return;

        let app = filteredModel.get(selectedIndex);
        let command = String(app.exec || "").trim();
        if (command === "")
            return;

        recordSelection(app.id, app.name);

        if (app.terminal === true)
            command = "${TERMINAL:-kitty} -e bash -lc " + shellQuote(command);

        Quickshell.execDetached(["bash", "-lc", "setsid -f " + command + " >/dev/null 2>&1"]);
        closeLauncher();
    }

    onSearchTextChanged: applyFilter()
    onSourceFilterChanged: applyFilter()
    onConfigDataChanged: applyFilter()
    onHiddenConfigDataChanged: applyFilter()
    onFreqDataChanged: applyFilter()
    onStateDataChanged: applyFilter()

    Component.onCompleted: {
        loadLauncherConfig();
        loadHiddenConfig();
        loadFrequencyData();
        loadStateData();
        refreshApps();
        focusTimer.start();
    }

    Keys.onEscapePressed: {
        if (contextMenu.visible)
            hideContextMenu();
        else
            closeLauncher();
        event.accepted = true;
    }

    Keys.onLeftPressed: {
        moveSelection(-1);
        event.accepted = true;
    }

    Keys.onRightPressed: {
        moveSelection(1);
        event.accepted = true;
    }

    Keys.onTabPressed: {
        moveSelection(1);
        event.accepted = true;
    }

    Keys.onBacktabPressed: {
        moveSelection(-1);
        event.accepted = true;
    }

    Keys.onReturnPressed: {
        launchSelected();
        event.accepted = true;
    }

    Keys.onEnterPressed: {
        launchSelected();
        event.accepted = true;
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: searchInput.forceActiveFocus()
    }

    Process {
        id: configReadProcess
        command: ["bash", "-lc", "if [ -f " + shellQuote(root.launcherConfigPath) + " ]; then cat " + shellQuote(root.launcherConfigPath) + "; else printf '{}' ; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = {};
                try {
                    parsed = JSON.parse(this.text.trim());
                } catch (e) {
                    parsed = {};
                }

                root.applyConfig(parsed);
            }
        }
    }

    Process {
        id: hiddenConfigReadProcess
        command: ["bash", "-lc", "if [ -f " + shellQuote(root.hiddenAppsConfigPath) + " ]; then cat " + shellQuote(root.hiddenAppsConfigPath) + "; else printf '{}' ; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = {};
                try {
                    parsed = JSON.parse(this.text.trim());
                } catch (e) {
                    parsed = {};
                }

                root.applyHiddenConfig(parsed);
            }
        }
    }

    Process {
        id: freqReadProcess
        command: ["bash", "-lc", "if [ -f " + shellQuote(root.frequencyFilePath) + " ]; then cat " + shellQuote(root.frequencyFilePath) + "; else printf '{}' ; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = {};
                try {
                    parsed = JSON.parse(this.text.trim());
                } catch (e) {
                    parsed = {};
                }

                if (parsed && typeof parsed === "object")
                    root.freqData = parsed;
                else
                    root.freqData = {};
            }
        }
    }

    Process {
        id: stateReadProcess
        command: ["bash", "-lc", "if [ -f " + shellQuote(root.stateFilePath) + " ]; then cat " + shellQuote(root.stateFilePath) + "; else printf '{\"favorites\":{},\"hidden\":{}}' ; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = root.defaultState();
                try {
                    parsed = JSON.parse(this.text.trim());
                } catch (e) {
                    parsed = root.defaultState();
                }

                root.stateData = root.normalizeState(parsed);
            }
        }
    }

    Process {
        id: loadAppsProcess
        command: ["python3", root.launcherScriptPath]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = [];
                try {
                    parsed = JSON.parse(this.text.trim());
                } catch (e) {
                    parsed = [];
                }

                if (!Array.isArray(parsed))
                    parsed = [];

                root.rawApps = parsed;
                root.loading = false;
                root.applyFilter();
            }
        }

        onExited: root.loading = false
    }

    ListModel {
        id: filteredModel
    }

    MatugenColors {
        id: theme
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: filteredModel.count + " apps"
                font.family: "Michroma"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: theme.subtext0
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: loading ? "loading..." : "Tab/arrows to switch, Enter to launch"
                font.family: "Michroma"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: theme.subtext1
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 14
            color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.85)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Repeater {
                    model: [
                        { "id": "all", "icon": "󰄶", "label": "All" },
                        { "id": "apps", "icon": "󰀻", "label": "Apps" },
                        { "id": "games", "icon": "󰊗", "label": "Games" },
                        { "id": "hidden", "icon": "󰈉", "label": "Hidden" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        property bool active: root.sourceFilter === modelData.id
                        width: 74
                        height: 24
                        radius: 6
                        color: active ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.9) : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.75)
                        border.width: 1
                        border.color: active ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 1.0) : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 4

                            Text {
                                text: modelData.icon
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 13
                                color: active ? theme.base : theme.text
                            }

                            Text {
                                text: modelData.label
                                font.family: "Michroma"
                                font.pixelSize: 8
                                font.weight: Font.Bold
                                color: active ? theme.base : theme.text
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sourceFilter = modelData.id
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 20
                    color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.75)
                }

                Text {
                    text: "󰍉"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: theme.blue
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    text: root.searchText
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: theme.text
                    clip: true
                    selectByMouse: true
                    selectionColor: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.45)
                    selectedTextColor: theme.base

                    onTextChanged: {
                        if (root.searchText !== text)
                            root.searchText = text;
                    }

                    Keys.onEscapePressed: {
                        root.closeLauncher();
                        event.accepted = true;
                    }

                    Keys.onLeftPressed: {
                        if (cursorPosition === 0 || root.searchText === "") {
                            root.moveSelection(-1);
                            event.accepted = true;
                        }
                    }

                    Keys.onRightPressed: {
                        if (cursorPosition === text.length || root.searchText === "") {
                            root.moveSelection(1);
                            event.accepted = true;
                        }
                    }

                    Keys.onTabPressed: {
                        root.moveSelection(1);
                        event.accepted = true;
                    }

                    Keys.onBacktabPressed: {
                        root.moveSelection(-1);
                        event.accepted = true;
                    }

                    Keys.onReturnPressed: {
                        root.launchSelected();
                        event.accepted = true;
                    }

                    Keys.onEnterPressed: {
                        root.launchSelected();
                        event.accepted = true;
                    }
                }

                Text {
                    visible: searchInput.text === ""
                    text: "search apps..."
                    font.family: "Michroma"
                    font.pixelSize: 10
                    color: Qt.rgba(theme.subtext1.r, theme.subtext1.g, theme.subtext1.b, 0.7)
                }
            }
        }

        Rectangle {
            id: cardSurface
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.84)
            border.width: 1
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.85)

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 14
                orientation: ListView.Horizontal
                spacing: -18
                clip: true
                interactive: false

                model: filteredModel
                currentIndex: root.selectedIndex

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: Math.max(0, (width - root.expandedCardWidth) / 2)
                preferredHighlightEnd: Math.max(0, (width + root.expandedCardWidth) / 2)
                highlightMoveDuration: 220
                highlightFollowsCurrentItem: true

                header: Item {
                    width: Math.max(0, (listView.width - root.expandedCardWidth) / 2)
                    height: 1
                }

                footer: Item {
                    width: Math.max(0, (listView.width - root.expandedCardWidth) / 2)
                    height: 1
                }

                onCurrentIndexChanged: {
                    if (currentIndex !== root.selectedIndex)
                        root.selectedIndex = currentIndex;
                }

                delegate: Item {
                    id: card
                    required property int index
                    required property var model

                    readonly property bool current: ListView.isCurrentItem
                    readonly property int skewOffset: 26
                    readonly property bool showStarControl: current || cardMouse.containsMouse

                    width: current ? root.expandedCardWidth : root.compactCardWidth
                    height: listView.height
                    z: current ? 40 : (index >= listView.currentIndex ? 30 - (index - listView.currentIndex) : 20)

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Shape {
                        anchors.fill: parent
                        anchors.margins: 1
                        antialiasing: true
                        preferredRendererType: Shape.GeometryRenderer
                        layer.enabled: true
                        layer.smooth: true
                        layer.samples: 4

                        ShapePath {
                            joinStyle: ShapePath.RoundJoin
                            capStyle: ShapePath.RoundCap
                            fillColor: card.current ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.95) : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.74)
                            strokeColor: card.current ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 1.0) : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8)
                            strokeWidth: 1
                            startX: card.skewOffset + 1.5
                            startY: 1.5
                            PathLine { x: card.width - 1.5; y: 1.5 }
                            PathLine { x: card.width - card.skewOffset - 1.5; y: card.height - 1.5 }
                            PathLine { x: 1.5; y: card.height - 1.5 }
                            PathLine { x: card.skewOffset + 1.5; y: 1.5 }
                        }
                    }

                    Item {
                        id: visualStage
                        readonly property bool hasMedia: String(model.thumbPath || "") !== "" || (root.showSteamHeroBackground && String(model.heroPath || "") !== "")
                        readonly property bool thumbReady: thumbImage.status === Image.Ready
                        readonly property int iconSize: hasMedia ? (card.current ? 112 : 76) : (card.current ? 152 : 106)

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        anchors.leftMargin: 24
                        height: 220

                        Rectangle {
                            id: previewArea
                            anchors.fill: parent
                            visible: visualStage.hasMedia
                            radius: 12
                            color: (root.showSteamHeroBackground && model.heroPath !== "") ? Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.7) : Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.95)
                            border.width: 1
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)

                            Image {
                                id: heroImage
                                anchors.fill: parent
                                source: (root.showSteamHeroBackground && model.heroPath !== "") ? ("file://" + model.heroPath) : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                visible: source !== ""
                                clip: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: heroImage.visible
                                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, card.current ? 0.36 : 0.54)
                            }

                            Image {
                                id: thumbImage
                                anchors.fill: parent
                                anchors.margins: 14
                                source: model.thumbPath !== "" ? ("file://" + model.thumbPath) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: source !== ""
                            }
                        }

                        Image {
                            id: iconImage
                            anchors.centerIn: parent
                            width: visualStage.iconSize
                            height: width
                            source: String(model.iconPath || "") !== "" ? ("file://" + String(model.iconPath || "")) : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            sourceSize: Qt.size(visualStage.iconSize, visualStage.iconSize)
                            visible: !visualStage.thumbReady && source !== "" && status === Image.Ready
                        }

                        Image {
                            id: themeIconImage
                            anchors.centerIn: parent
                            width: visualStage.iconSize
                            height: width
                            source: (String(model.iconName || "") !== "" && !String(model.iconName || "").startsWith("/")) ? ("image://icon/" + String(model.iconName || "")) : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            sourceSize: Qt.size(visualStage.iconSize, visualStage.iconSize)
                            visible: !visualStage.thumbReady && iconImage.status !== Image.Ready && source !== "" && status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.appAcronym(model.name || "")
                            font.family: "Michroma"
                            font.pixelSize: card.current ? 56 : 42
                            font.weight: Font.Black
                            color: card.current ? theme.blue : theme.subtext0
                            visible: !visualStage.thumbReady && iconImage.status !== Image.Ready && themeIconImage.status !== Image.Ready
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 9
                            anchors.rightMargin: 8
                            text: model.favorite ? "★" : "☆"
                            font.family: "Michroma"
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: model.favorite ? theme.yellow : theme.subtext1
                            visible: card.showStarControl
                        }

                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 24
                        anchors.rightMargin: 16
                        anchors.bottomMargin: 14
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: (model.name || "App").toUpperCase()
                            font.family: "Michroma"
                            font.pixelSize: 11
                            font.weight: Font.Black
                            color: card.current ? theme.blue : theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.displayCategory || "App"
                            font.family: "Michroma"
                            font.pixelSize: 9
                            color: theme.subtext0
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: (model.displayTagsText || "") !== ""
                            text: model.displayTagsText || ""
                            font.family: "Michroma"
                            font.pixelSize: 8
                            color: theme.overlay1
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                visible: root.showBadges && model.source === "steam"
                                width: steamText.implicitWidth + 12
                                height: 18
                                radius: 6
                                color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.9)

                                Text {
                                    id: steamText
                                    anchors.centerIn: parent
                                    text: "STEAM"
                                    font.family: "Michroma"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: theme.base
                                }
                            }

                            Rectangle {
                                visible: root.showBadges && model.terminal === true
                                width: terminalText.implicitWidth + 12
                                height: 18
                                radius: 6
                                color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.86)

                                Text {
                                    id: terminalText
                                    anchors.centerIn: parent
                                    text: "TERMINAL"
                                    font.family: "Michroma"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: theme.base
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: root.showBadges && Number(model.score || 0) > 0
                                width: scoreText.implicitWidth + 10
                                height: 18
                                radius: 6
                                color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.86)

                                Text {
                                    id: scoreText
                                    anchors.centerIn: parent
                                    text: "HOT " + Number(model.frequencyCount || 0)
                                    font.family: "Michroma"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: theme.base
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                let pos = card.mapToItem(cardSurface, mouse.x, mouse.y);
                                root.openContextMenu(model.id, pos.x, pos.y);
                                mouse.accepted = true;
                                return;
                            }

                            root.hideContextMenu();
                            if (card.current)
                                root.launchSelected();
                            else {
                                root.selectedIndex = index;
                                listView.currentIndex = index;
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: contextMenu.visible
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.ArrowCursor
                onClicked: {
                    root.hideContextMenu();
                    mouse.accepted = true;
                }
                z: 100
            }

            Rectangle {
                id: contextMenu
                width: 196
                height: 84
                visible: false
                radius: 10
                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.97)
                border.width: 1
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.95)
                z: 101

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.82)
                        border.width: 1
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.78)

                        Text {
                            anchors.centerIn: parent
                            text: root.contextFavorite ? "Remove favorite" : "Add favorite"
                            font.family: "Michroma"
                            font.pixelSize: 9
                            color: theme.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.setFavorite(root.contextAppId, !root.contextFavorite);
                                root.hideContextMenu();
                                mouse.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.82)
                        border.width: 1
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.78)

                        Text {
                            anchors.centerIn: parent
                            text: root.contextHidden ? "Unhide app" : "Hide app"
                            font.family: "Michroma"
                            font.pixelSize: 9
                            color: root.contextHidden ? theme.green : theme.peach
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.setHidden(root.contextAppId, !root.contextHidden);
                                mouse.accepted = true;
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    let dx = wheel.angleDelta.x;
                    let dy = wheel.angleDelta.y;
                    let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;
                    root.scrollAccum += delta;

                    if (Math.abs(root.scrollAccum) >= 120) {
                        root.moveSelection(root.scrollAccum > 0 ? -1 : 1);
                        root.scrollAccum = 0;
                    }

                    wheel.accepted = true;
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.loading && filteredModel.count === 0
                text: root.searchText === "" ? "NO APPS FOUND" : "NO RESULTS"
                font.family: "Michroma"
                font.pixelSize: 18
                font.weight: Font.Black
                color: theme.overlay1
            }

            Text {
                anchors.centerIn: parent
                visible: root.loading
                text: "LOADING APPS..."
                font.family: "Michroma"
                font.pixelSize: 14
                font.weight: Font.Black
                color: theme.overlay1
            }
        }
    }
}
