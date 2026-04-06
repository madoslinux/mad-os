.pragma library

const DEFAULT_SCALE = 0.75;

function s(v, scale) {
    return Math.max(1, Math.round(v * scale));
}

// Centralized registry for all widget dimensions and positional mathematics.
function getLayout(name, mx, my, mw, mh, scale) {
    const ui = scale || DEFAULT_SCALE;
    const calendarW = s(1450, ui);
    const calendarH = s(750, ui);
    const stewartW = s(800, ui);
    const stewartH = s(600, ui);
    const monitorsW = s(850, ui);
    const monitorsH = s(580, ui);
    const focustimeW = s(900, ui);
    const focustimeH = s(720, ui);
    const guideW = s(1200, ui);
    const guideH = s(750, ui);
    const wallpaperW = Math.max(1, Math.round(mw * ui));
    const wallpaperH = s(650, ui);
    const launcherW = Math.max(1, Math.round(mw * 0.9));
    const launcherH = s(690, ui);

    let base = {
        // Right-aligned: pinned 20px from the right edge dynamically
        "battery":   { w: s(480, ui), h: s(760, ui), rx: mw - s(500, ui), ry: s(70, ui), comp: "battery/BatteryPopup.qml" },
        "volume":    { w: s(480, ui), h: s(760, ui), rx: mw - s(500, ui), ry: s(70, ui), comp: "volume/VolumePopup.qml" },
        
        // Centered horizontally dynamically based on current screen width
        "calendar":  { w: calendarW, h: calendarH, rx: Math.floor((mw / 2) - (calendarW / 2)), ry: s(70, ui), comp: "calendar/CalendarPopup.qml" },
        
        // Left-aligned: pinned 12px from the left edge
        "music":     { w: s(700, ui), h: s(620, ui), rx: s(12, ui), ry: s(70, ui), comp: "music/MusicPopup.qml" },
        
        // Right-aligned: pinned 20px from the right edge dynamically
        "network":   { w: s(900, ui), h: s(700, ui), rx: mw - s(920, ui), ry: s(70, ui), comp: "network/NetworkPopup.qml" },
        
        // Centered both horizontally and vertically
        "stewart":   { w: stewartW, h: stewartH, rx: Math.floor((mw / 2) - (stewartW / 2)), ry: Math.floor((mh / 2) - (stewartH / 2)), comp: "stewart/stewart.qml" },
        "monitors":  { w: monitorsW, h: monitorsH, rx: Math.floor((mw / 2) - (monitorsW / 2)), ry: Math.floor((mh / 2) - (monitorsH / 2)), comp: "monitors/MonitorPopup.qml" },
        "focustime": { w: focustimeW, h: focustimeH, rx: Math.floor((mw / 2) - (focustimeW / 2)), ry: Math.floor((mh / 2) - (focustimeH / 2)), comp: "focustime/FocusTimePopup.qml" },
        
        // Guide Popup (Centered) - Widened to 1200px to fix keybind cutoffs
        "guide":     { w: guideW, h: guideH, rx: Math.floor((mw / 2) - (guideW / 2)), ry: Math.floor((mh / 2) - (guideH / 2)), comp: "guide/GuidePopup.qml" },

        // Full width, centered vertically
        "wallpaper": { w: wallpaperW, h: wallpaperH, rx: Math.floor((mw - wallpaperW) / 2), ry: Math.floor((mh / 2) - (wallpaperH / 2)), comp: "wallpaper/WallpaperPicker.qml" },

        // SKWD-inspired app launcher (90% monitor width)
        "launcher":  { w: launcherW, h: launcherH, rx: Math.floor((mw - launcherW) / 2), ry: Math.floor((mh / 2) - (launcherH / 2)), comp: "launcher/LauncherPopup.qml" },

        // Alt-Tab switcher style card
        "switcher":  { w: s(1700, ui), h: s(620, ui), rx: Math.floor((mw - s(1700, ui)) / 2), ry: Math.floor((mh / 2) - (s(620, ui) / 2)), comp: "switcher/WindowSwitcher.qml" },
        
        "hidden":    { w: 1, h: 1, rx: -5000 - mx, ry: -5000 - my, comp: "" } 
    };

    if (!base[name]) return null;
    
    let t = base[name];
    // Calculate final absolute coordinates based on active monitor offset
    t.x = mx + t.rx;
    t.y = my + t.ry;
    
    return t;
}
