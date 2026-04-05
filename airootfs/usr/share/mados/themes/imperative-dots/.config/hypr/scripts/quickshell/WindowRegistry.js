.pragma library

// Centralized registry for all widget dimensions and positional mathematics.
function getLayout(name, mx, my, mw, mh) {
    let base = {
        // Right-aligned: pinned 20px from the right edge dynamically
        "battery":   { w: 480, h: 760, rx: mw - 500, ry: 70, comp: "battery/BatteryPopup.qml" },
        "volume":    { w: 480, h: 760, rx: mw - 500, ry: 70, comp: "volume/VolumePopup.qml" },
        
        // Centered horizontally dynamically based on current screen width
        "calendar":  { w: 1450, h: 750, rx: Math.floor((mw/2)-(1450/2)), ry: 70, comp: "calendar/CalendarPopup.qml" },
        
        // Left-aligned: pinned 12px from the left edge
        "music":     { w: 700, h: 620, rx: 12, ry: 70, comp: "music/MusicPopup.qml" },
        
        // Right-aligned: pinned 20px from the right edge dynamically
        "network":   { w: 900, h: 700, rx: mw - 920, ry: 70, comp: "network/NetworkPopup.qml" },
        
        // Centered both horizontally and vertically
        "stewart":   { w: 800, h: 600, rx: Math.floor((mw/2)-(800/2)), ry: Math.floor((mh/2)-(600/2)), comp: "stewart/stewart.qml" },
        "monitors":  { w: 850, h: 580, rx: Math.floor((mw/2)-(850/2)), ry: Math.floor((mh/2)-(580/2)), comp: "monitors/MonitorPopup.qml" },
        "focustime": { w: 900, h: 720, rx: Math.floor((mw/2)-(900/2)), ry: Math.floor((mh/2)-(720/2)), comp: "focustime/FocusTimePopup.qml" },
        
        // Guide Popup (Centered) - Widened to 1200px to fix keybind cutoffs
        "guide":     { w: 1200, h: 750, rx: Math.floor((mw/2)-(1200/2)), ry: Math.floor((mh/2)-(750/2)), comp: "guide/GuidePopup.qml" },

        // Full width, centered vertically
        "wallpaper": { w: mw, h: 650, rx: 0, ry: Math.floor((mh/2)-(650/2)), comp: "wallpaper/WallpaperPicker.qml" },
        
        "hidden":    { w: 1, h: 1, rx: -5000 - mx, ry: -5000 - my, comp: "" } 
    };

    if (!base[name]) return null;
    
    let t = base[name];
    // Calculate final absolute coordinates based on active monitor offset
    t.x = mx + t.rx;
    t.y = my + t.ry;
    
    return t;
}
