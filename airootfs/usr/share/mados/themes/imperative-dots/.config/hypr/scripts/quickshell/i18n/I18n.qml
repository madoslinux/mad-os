pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: i18n

    readonly property var supportedLanguages: ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"]

    readonly property var _strings: ({
        "Help": {
            "es": "Ayuda", "en": "Help", "fr": "Aide", "de": "Hilfe", "it": "Aiuto", "pt": "Ajuda", "ru": "Pomoshch", "ja": "Help", "zh": "Help"
        },
        "On": {
            "es": "Encendido", "en": "On", "fr": "Active", "de": "An", "it": "Attivo", "pt": "Ligado", "ru": "Vkl", "ja": "On", "zh": "On"
        },
        "Off": {
            "es": "Apagado", "en": "Off", "fr": "Desactive", "de": "Aus", "it": "Disattivato", "pt": "Desligado", "ru": "VykL", "ja": "Off", "zh": "Off"
        },
        "All": {
            "es": "Todo", "en": "All", "fr": "Tout", "de": "Alle", "it": "Tutto", "pt": "Tudo", "ru": "Vse", "ja": "All", "zh": "All"
        },
        "Apps": {
            "es": "Apps", "en": "Apps", "fr": "Apps", "de": "Apps", "it": "App", "pt": "Apps", "ru": "Apps", "ja": "Apps", "zh": "Apps"
        },
        "Games": {
            "es": "Juegos", "en": "Games", "fr": "Jeux", "de": "Spiele", "it": "Giochi", "pt": "Jogos", "ru": "Igry", "ja": "Games", "zh": "Games"
        },
        "Hidden": {
            "es": "Ocultas", "en": "Hidden", "fr": "Caches", "de": "Versteckt", "it": "Nascoste", "pt": "Ocultas", "ru": "Skrytye", "ja": "Hidden", "zh": "Hidden"
        },
        "search apps...": {
            "es": "buscar apps...", "en": "search apps...", "fr": "chercher des apps...", "de": "apps suchen...", "it": "cerca app...", "pt": "buscar apps...", "ru": "poisk prilozhenii...", "ja": "search apps...", "zh": "search apps..."
        },
        "STEAM": {
            "es": "STEAM", "en": "STEAM", "fr": "STEAM", "de": "STEAM", "it": "STEAM", "pt": "STEAM", "ru": "STEAM", "ja": "STEAM", "zh": "STEAM"
        },
        "TERMINAL": {
            "es": "TERMINAL", "en": "TERMINAL", "fr": "TERMINAL", "de": "TERMINAL", "it": "TERMINAL", "pt": "TERMINAL", "ru": "TERMINAL", "ja": "TERMINAL", "zh": "TERMINAL"
        },
        "HOT": {
            "es": "TOP", "en": "HOT", "fr": "HOT", "de": "HOT", "it": "HOT", "pt": "HOT", "ru": "HOT", "ja": "HOT", "zh": "HOT"
        },
        "Remove favorite": {
            "es": "Quitar favorito", "en": "Remove favorite", "fr": "Retirer favori", "de": "Favorit entfernen", "it": "Rimuovi preferito", "pt": "Remover favorito", "ru": "Ubrat iz izbrannogo", "ja": "Remove favorite", "zh": "Remove favorite"
        },
        "Add favorite": {
            "es": "Agregar favorito", "en": "Add favorite", "fr": "Ajouter favori", "de": "Zu Favoriten", "it": "Aggiungi preferito", "pt": "Adicionar favorito", "ru": "Dobavit v izbrannoe", "ja": "Add favorite", "zh": "Add favorite"
        },
        "Unhide app": {
            "es": "Mostrar app", "en": "Unhide app", "fr": "Afficher app", "de": "App einblenden", "it": "Mostra app", "pt": "Mostrar app", "ru": "Pokazat prilozhenie", "ja": "Unhide app", "zh": "Unhide app"
        },
        "Hide app": {
            "es": "Ocultar app", "en": "Hide app", "fr": "Masquer app", "de": "App ausblenden", "it": "Nascondi app", "pt": "Ocultar app", "ru": "Skryt prilozhenie", "ja": "Hide app", "zh": "Hide app"
        },
        "NO APPS FOUND": {
            "es": "NO SE ENCONTRARON APPS", "en": "NO APPS FOUND", "fr": "AUCUNE APP TROUVEE", "de": "KEINE APPS GEFUNDEN", "it": "NESSUNA APP TROVATA", "pt": "NENHUM APP ENCONTRADO", "ru": "PRILOZHENIYA NE NAIDENY", "ja": "NO APPS FOUND", "zh": "NO APPS FOUND"
        },
        "NO RESULTS": {
            "es": "SIN RESULTADOS", "en": "NO RESULTS", "fr": "AUCUN RESULTAT", "de": "KEINE ERGEBNISSE", "it": "NESSUN RISULTATO", "pt": "SEM RESULTADOS", "ru": "NET REZULTATOV", "ja": "NO RESULTS", "zh": "NO RESULTS"
        },
        "LOADING APPS...": {
            "es": "CARGANDO APPS...", "en": "LOADING APPS...", "fr": "CHARGEMENT APPS...", "de": "APPS WERDEN GELADEN...", "it": "CARICAMENTO APP...", "pt": "CARREGANDO APPS...", "ru": "ZAGRUZKA PRILOZHENII...", "ja": "LOADING APPS...", "zh": "LOADING APPS..."
        },
        "loading...": {
            "es": "cargando...", "en": "loading...", "fr": "chargement...", "de": "laden...", "it": "caricamento...", "pt": "carregando...", "ru": "zagruzka...", "ja": "loading...", "zh": "loading..."
        },
        "apps": {
            "es": "apps", "en": "apps", "fr": "apps", "de": "apps", "it": "app", "pt": "apps", "ru": "prilozhenii", "ja": "apps", "zh": "apps"
        },
        "Tab/arrows to switch, Enter to launch": {
            "es": "Tab/flechas para cambiar, Enter para abrir", "en": "Tab/arrows to switch, Enter to launch", "fr": "Tab/fleches pour changer, Entree pour lancer", "de": "Tab/Pfeile zum Wechseln, Enter zum Starten", "it": "Tab/frecce per cambiare, Invio per avviare", "pt": "Tab/setas para mudar, Enter para abrir", "ru": "Tab/strelki dlya perekhoda, Enter dlya zapuska", "ja": "Tab/arrows to switch, Enter to launch", "zh": "Tab/arrows to switch, Enter to launch"
        },
        "Downloading wallpaper...": {
            "es": "Descargando fondo...", "en": "Downloading wallpaper...", "fr": "Telechargement du fond...", "de": "Hintergrund wird heruntergeladen...", "it": "Download sfondo...", "pt": "Baixando papel de parede...", "ru": "Zagruzka oboev...", "ja": "Downloading wallpaper...", "zh": "Downloading wallpaper..."
        },
        "Type something to search...": {
            "es": "Escribe algo para buscar...", "en": "Type something to search...", "fr": "Tapez quelque chose pour chercher...", "de": "Tippe etwas zum Suchen...", "it": "Scrivi qualcosa da cercare...", "pt": "Digite algo para pesquisar...", "ru": "Vvedite chto-nibud dlya poiska...", "ja": "Type something to search...", "zh": "Type something to search..."
        },
        "Search Paused": {
            "es": "Busqueda en pausa", "en": "Search Paused", "fr": "Recherche en pause", "de": "Suche pausiert", "it": "Ricerca in pausa", "pt": "Busca pausada", "ru": "Poisk na pauze", "ja": "Search Paused", "zh": "Search Paused"
        },
        "Searching DDG (FHD+)...": {
            "es": "Buscando en DDG (FHD+)...", "en": "Searching DDG (FHD+)...", "fr": "Recherche DDG (FHD+)...", "de": "Suche in DDG (FHD+)...", "it": "Ricerca DDG (FHD+)...", "pt": "Buscando no DDG (FHD+)...", "ru": "Poisk v DDG (FHD+)...", "ja": "Searching DDG (FHD+)...", "zh": "Searching DDG (FHD+)..."
        },
        "Generating thumbnails...": {
            "es": "Generando miniaturas...", "en": "Generating thumbnails...", "fr": "Generation des miniatures...", "de": "Vorschaubilder werden erzeugt...", "it": "Generazione miniature...", "pt": "Gerando miniaturas...", "ru": "Sozdanie miniatyur...", "ja": "Generating thumbnails...", "zh": "Generating thumbnails..."
        },
        "No wallpapers found": {
            "es": "No se encontraron fondos", "en": "No wallpapers found", "fr": "Aucun fond trouve", "de": "Keine Hintergrunde gefunden", "it": "Nessuno sfondo trovato", "pt": "Nenhum papel de parede encontrado", "ru": "Oboi ne naideny", "ja": "No wallpapers found", "zh": "No wallpapers found"
        },
        "About": {
            "es": "About", "en": "About", "fr": "About", "de": "About", "it": "About", "pt": "About", "ru": "About", "ja": "About", "zh": "About"
        },
        "Adjust Brightness": {
            "es": "Adjust Brightness", "en": "Adjust Brightness", "fr": "Adjust Brightness", "de": "Adjust Brightness", "it": "Adjust Brightness", "pt": "Adjust Brightness", "ru": "Adjust Brightness", "ja": "Adjust Brightness", "zh": "Adjust Brightness"
        },
        "Adjust Volume": {
            "es": "Adjust Volume", "en": "Adjust Volume", "fr": "Adjust Volume", "de": "Adjust Volume", "it": "Adjust Volume", "pt": "Adjust Volume", "ru": "Adjust Volume", "ja": "Adjust Volume", "zh": "Adjust Volume"
        },
        "App Launcher": {
            "es": "App Launcher", "en": "App Launcher", "fr": "App Launcher", "de": "App Launcher", "it": "App Launcher", "pt": "App Launcher", "ru": "App Launcher", "ja": "App Launcher", "zh": "App Launcher"
        },

        "Caps Lock OSD": {
            "es": "Caps Lock OSD", "en": "Caps Lock OSD", "fr": "Caps Lock OSD", "de": "Caps Lock OSD", "it": "Caps Lock OSD", "pt": "Caps Lock OSD", "ru": "Caps Lock OSD", "ja": "Caps Lock OSD", "zh": "Caps Lock OSD"
        },
        "Click any card to toggle the live module overlay.": {
            "es": "Click any card to toggle the live module overlay.", "en": "Click any card to toggle the live module overlay.", "fr": "Click any card to toggle the live module overlay.", "de": "Click any card to toggle the live module overlay.", "it": "Click any card to toggle the live module overlay.", "pt": "Click any card to toggle the live module overlay.", "ru": "Click any card to toggle the live module overlay.", "ja": "Click any card to toggle the live module overlay.", "zh": "Click any card to toggle the live module overlay."
        },
        "Click any row below to instantly execute the keybind command.": {
            "es": "Click any row below to instantly execute the keybind command.", "en": "Click any row below to instantly execute the keybind command.", "fr": "Click any row below to instantly execute the keybind command.", "de": "Click any row below to instantly execute the keybind command.", "it": "Click any row below to instantly execute the keybind command.", "pt": "Click any row below to instantly execute the keybind command.", "ru": "Click any row below to instantly execute the keybind command.", "ja": "Click any row below to instantly execute the keybind command.", "zh": "Click any row below to instantly execute the keybind command."
        },
        "Clipboard History": {
            "es": "Clipboard History", "en": "Clipboard History", "fr": "Clipboard History", "de": "Clipboard History", "it": "Clipboard History", "pt": "Clipboard History", "ru": "Clipboard History", "ja": "Clipboard History", "zh": "Clipboard History"
        },
        "Close Active Window/Widget": {
            "es": "Close Active Window/Widget", "en": "Close Active Window/Widget", "fr": "Close Active Window/Widget", "de": "Close Active Window/Widget", "it": "Close Active Window/Widget", "pt": "Close Active Window/Widget", "ru": "Close Active Window/Widget", "ja": "Close Active Window/Widget", "zh": "Close Active Window/Widget"
        },
        "Imperative": {
            "es": "Imperative", "en": "Imperative", "fr": "Imperative", "de": "Imperative", "it": "Imperative", "pt": "Imperative", "ru": "Imperative", "ja": "Imperative", "zh": "Imperative"
        },
        "Imperative System Theme": {
            "es": "Imperative System Theme", "en": "Imperative System Theme", "fr": "Imperative System Theme", "de": "Imperative System Theme", "it": "Imperative System Theme", "pt": "Imperative System Theme", "ru": "Imperative System Theme", "ja": "Imperative System Theme", "zh": "Imperative System Theme"
        },
        "Interactive Modules": {
            "es": "Interactive Modules", "en": "Interactive Modules", "fr": "Interactive Modules", "de": "Interactive Modules", "it": "Interactive Modules", "pt": "Interactive Modules", "ru": "Interactive Modules", "ja": "Interactive Modules", "zh": "Interactive Modules"
        },
        "Keybinds": {
            "es": "Keybinds", "en": "Keybinds", "fr": "Keybinds", "de": "Keybinds", "it": "Keybinds", "pt": "Keybinds", "ru": "Keybinds", "ja": "Keybinds", "zh": "Keybinds"
        },
        "Lock Screen": {
            "es": "Lock Screen", "en": "Lock Screen", "fr": "Lock Screen", "de": "Lock Screen", "it": "Lock Screen", "pt": "Lock Screen", "ru": "Lock Screen", "ja": "Lock Screen", "zh": "Lock Screen"
        },
        "Matugen": {
            "es": "Matugen", "en": "Matugen", "fr": "Matugen", "de": "Matugen", "it": "Matugen", "pt": "Matugen", "ru": "Matugen", "ja": "Matugen", "zh": "Matugen"
        },
        "Matugen Core": {
            "es": "Matugen Core", "en": "Matugen Core", "fr": "Matugen Core", "de": "Matugen Core", "it": "Matugen Core", "pt": "Matugen Core", "ru": "Matugen Core", "ja": "Matugen Core", "zh": "Matugen Core"
        },
        "Modules": {
            "es": "Modules", "en": "Modules", "fr": "Modules", "de": "Modules", "it": "Modules", "pt": "Modules", "ru": "Modules", "ja": "Modules", "zh": "Modules"
        },
        "Move Focus": {
            "es": "Move Focus", "en": "Move Focus", "fr": "Move Focus", "de": "Move Focus", "it": "Move Focus", "pt": "Move Focus", "ru": "Move Focus", "ja": "Move Focus", "zh": "Move Focus"
        },
        "Move Window": {
            "es": "Move Window", "en": "Move Window", "fr": "Move Window", "de": "Move Window", "it": "Move Window", "pt": "Move Window", "ru": "Move Window", "ja": "Move Window", "zh": "Move Window"
        },
        "Mute Microphone": {
            "es": "Mute Microphone", "en": "Mute Microphone", "fr": "Mute Microphone", "de": "Mute Microphone", "it": "Mute Microphone", "pt": "Mute Microphone", "ru": "Mute Microphone", "ja": "Mute Microphone", "zh": "Mute Microphone"
        },
        "Mute Volume": {
            "es": "Mute Volume", "en": "Mute Volume", "fr": "Mute Volume", "de": "Mute Volume", "it": "Mute Volume", "pt": "Mute Volume", "ru": "Mute Volume", "ja": "Mute Volume", "zh": "Mute Volume"
        },
        "Navigation & Control": {
            "es": "Navigation & Control", "en": "Navigation & Control", "fr": "Navigation & Control", "de": "Navigation & Control", "it": "Navigation & Control", "pt": "Navigation & Control", "ru": "Navigation & Control", "ja": "Navigation & Control", "zh": "Navigation & Control"
        },
        "Open Firefox": {
            "es": "Open Firefox", "en": "Open Firefox", "fr": "Open Firefox", "de": "Open Firefox", "it": "Open Firefox", "pt": "Open Firefox", "ru": "Open Firefox", "ja": "Open Firefox", "zh": "Open Firefox"
        },
        "Open Nautilus": {
            "es": "Open Nautilus", "en": "Open Nautilus", "fr": "Open Nautilus", "de": "Open Nautilus", "it": "Open Nautilus", "pt": "Open Nautilus", "ru": "Open Nautilus", "ja": "Open Nautilus", "zh": "Open Nautilus"
        },
        "Open Terminal (Kitty)": {
            "es": "Open Terminal (Kitty)", "en": "Open Terminal (Kitty)", "fr": "Open Terminal (Kitty)", "de": "Open Terminal (Kitty)", "it": "Open Terminal (Kitty)", "pt": "Open Terminal (Kitty)", "ru": "Open Terminal (Kitty)", "ja": "Open Terminal (Kitty)", "zh": "Open Terminal (Kitty)"
        },
        "Play/Pause Media": {
            "es": "Play/Pause Media", "en": "Play/Pause Media", "fr": "Play/Pause Media", "de": "Play/Pause Media", "it": "Play/Pause Media", "pt": "Play/Pause Media", "ru": "Play/Pause Media", "ja": "Play/Pause Media", "zh": "Play/Pause Media"
        },
        "Resize Window": {
            "es": "Resize Window", "en": "Resize Window", "fr": "Resize Window", "de": "Resize Window", "it": "Resize Window", "pt": "Resize Window", "ru": "Resize Window", "ja": "Resize Window", "zh": "Resize Window"
        },
        "SKWD Shell and Wallpaper manager": {
            "es": "SKWD Shell and Wallpaper manager", "en": "SKWD Shell and Wallpaper manager", "fr": "SKWD Shell and Wallpaper manager", "de": "SKWD Shell and Wallpaper manager", "it": "SKWD Shell and Wallpaper manager", "pt": "SKWD Shell and Wallpaper manager", "ru": "SKWD Shell and Wallpaper manager", "ja": "SKWD Shell and Wallpaper manager", "zh": "SKWD Shell and Wallpaper manager"
        },
        "Screenshot": {
            "es": "Screenshot", "en": "Screenshot", "fr": "Screenshot", "de": "Screenshot", "it": "Screenshot", "pt": "Screenshot", "ru": "Screenshot", "ja": "Screenshot", "zh": "Screenshot"
        },
        "Screenshot (Edit)": {
            "es": "Screenshot (Edit)", "en": "Screenshot (Edit)", "fr": "Screenshot (Edit)", "de": "Screenshot (Edit)", "it": "Screenshot (Edit)", "pt": "Screenshot (Edit)", "ru": "Screenshot (Edit)", "ja": "Screenshot (Edit)", "zh": "Screenshot (Edit)"
        },
        "Search": {
            "es": "Search", "en": "Search", "fr": "Search", "de": "Search", "it": "Search", "pt": "Search", "ru": "Search", "ja": "Search", "zh": "Search"
        },
        "Search Wallpapers on Web": {
            "es": "Search Wallpapers on Web", "en": "Search Wallpapers on Web", "fr": "Search Wallpapers on Web", "de": "Search Wallpapers on Web", "it": "Search Wallpapers on Web", "pt": "Search Wallpapers on Web", "ru": "Search Wallpapers on Web", "ja": "Search Wallpapers on Web", "zh": "Search Wallpapers on Web"
        },
        "Switch Keyboard Layout": {
            "es": "Switch Keyboard Layout", "en": "Switch Keyboard Layout", "fr": "Switch Keyboard Layout", "de": "Switch Keyboard Layout", "it": "Switch Keyboard Layout", "pt": "Switch Keyboard Layout", "ru": "Switch Keyboard Layout", "ja": "Switch Keyboard Layout", "zh": "Switch Keyboard Layout"
        },
        "System Architecture": {
            "es": "System Architecture", "en": "System Architecture", "fr": "System Architecture", "de": "System Architecture", "it": "System Architecture", "pt": "System Architecture", "ru": "System Architecture", "ja": "System Architecture", "zh": "System Architecture"
        },
        "Templates": {
            "es": "Templates", "en": "Templates", "fr": "Templates", "de": "Templates", "it": "Templates", "pt": "Templates", "ru": "Templates", "ja": "Templates", "zh": "Templates"
        },
        "Theming Engine": {
            "es": "Theming Engine", "en": "Theming Engine", "fr": "Theming Engine", "de": "Theming Engine", "it": "Theming Engine", "pt": "Theming Engine", "ru": "Theming Engine", "ja": "Theming Engine", "zh": "Theming Engine"
        },
        "Toggle Battery Widget": {
            "es": "Toggle Battery Widget", "en": "Toggle Battery Widget", "fr": "Toggle Battery Widget", "de": "Toggle Battery Widget", "it": "Toggle Battery Widget", "pt": "Toggle Battery Widget", "ru": "Toggle Battery Widget", "ja": "Toggle Battery Widget", "zh": "Toggle Battery Widget"
        },
        "Toggle Calendar Widget": {
            "es": "Toggle Calendar Widget", "en": "Toggle Calendar Widget", "fr": "Toggle Calendar Widget", "de": "Toggle Calendar Widget", "it": "Toggle Calendar Widget", "pt": "Toggle Calendar Widget", "ru": "Toggle Calendar Widget", "ja": "Toggle Calendar Widget", "zh": "Toggle Calendar Widget"
        },
        "Toggle Floating": {
            "es": "Toggle Floating", "en": "Toggle Floating", "fr": "Toggle Floating", "de": "Toggle Floating", "it": "Toggle Floating", "pt": "Toggle Floating", "ru": "Toggle Floating", "ja": "Toggle Floating", "zh": "Toggle Floating"
        },
        "Toggle FocusTime": {
            "es": "Toggle FocusTime", "en": "Toggle FocusTime", "fr": "Toggle FocusTime", "de": "Toggle FocusTime", "it": "Toggle FocusTime", "pt": "Toggle FocusTime", "ru": "Toggle FocusTime", "ja": "Toggle FocusTime", "zh": "Toggle FocusTime"
        },
        "Toggle Monitors Widget": {
            "es": "Toggle Monitors Widget", "en": "Toggle Monitors Widget", "fr": "Toggle Monitors Widget", "de": "Toggle Monitors Widget", "it": "Toggle Monitors Widget", "pt": "Toggle Monitors Widget", "ru": "Toggle Monitors Widget", "ja": "Toggle Monitors Widget", "zh": "Toggle Monitors Widget"
        },
        "Toggle Music Widget": {
            "es": "Toggle Music Widget", "en": "Toggle Music Widget", "fr": "Toggle Music Widget", "de": "Toggle Music Widget", "it": "Toggle Music Widget", "pt": "Toggle Music Widget", "ru": "Toggle Music Widget", "ja": "Toggle Music Widget", "zh": "Toggle Music Widget"
        },
        "Toggle Network Widget": {
            "es": "Toggle Network Widget", "en": "Toggle Network Widget", "fr": "Toggle Network Widget", "de": "Toggle Network Widget", "it": "Toggle Network Widget", "pt": "Toggle Network Widget", "ru": "Toggle Network Widget", "ja": "Toggle Network Widget", "zh": "Toggle Network Widget"
        },
        "Toggle Notifications": {
            "es": "Toggle Notifications", "en": "Toggle Notifications", "fr": "Toggle Notifications", "de": "Toggle Notifications", "it": "Toggle Notifications", "pt": "Toggle Notifications", "ru": "Toggle Notifications", "ja": "Toggle Notifications", "zh": "Toggle Notifications"
        },
        "Toggle Stewart AI": {
            "es": "Toggle Stewart AI", "en": "Toggle Stewart AI", "fr": "Toggle Stewart AI", "de": "Toggle Stewart AI", "it": "Toggle Stewart AI", "pt": "Toggle Stewart AI", "ru": "Toggle Stewart AI", "ja": "Toggle Stewart AI", "zh": "Toggle Stewart AI"
        },
        "Toggle Volume Widget": {
            "es": "Toggle Volume Widget", "en": "Toggle Volume Widget", "fr": "Toggle Volume Widget", "de": "Toggle Volume Widget", "it": "Toggle Volume Widget", "pt": "Toggle Volume Widget", "ru": "Toggle Volume Widget", "ja": "Toggle Volume Widget", "zh": "Toggle Volume Widget"
        },
        "Toggle Wallpaper Picker": {
            "es": "Toggle Wallpaper Picker", "en": "Toggle Wallpaper Picker", "fr": "Toggle Wallpaper Picker", "de": "Toggle Wallpaper Picker", "it": "Toggle Wallpaper Picker", "pt": "Toggle Wallpaper Picker", "ru": "Toggle Wallpaper Picker", "ja": "Toggle Wallpaper Picker", "zh": "Toggle Wallpaper Picker"
        },
        "Wallpaper": {
            "es": "Wallpaper", "en": "Wallpaper", "fr": "Wallpaper", "de": "Wallpaper", "it": "Wallpaper", "pt": "Wallpaper", "ru": "Wallpaper", "ja": "Wallpaper", "zh": "Wallpaper"
        },
        "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:": {
            "es": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "en": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "fr": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "de": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "it": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "pt": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "ru": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "ja": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:", "zh": "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:"
        },
        "Window Switcher": {
            "es": "Window Switcher", "en": "Window Switcher", "fr": "Window Switcher", "de": "Window Switcher", "it": "Window Switcher", "pt": "Window Switcher", "ru": "Window Switcher", "ja": "Window Switcher", "zh": "Window Switcher"
        },
        "Workspaces (SUPER + 1-9)": {
            "es": "Workspaces (SUPER + 1-9)", "en": "Workspaces (SUPER + 1-9)", "fr": "Workspaces (SUPER + 1-9)", "de": "Workspaces (SUPER + 1-9)", "it": "Workspaces (SUPER + 1-9)", "pt": "Workspaces (SUPER + 1-9)", "ru": "Workspaces (SUPER + 1-9)", "ja": "Workspaces (SUPER + 1-9)", "zh": "Workspaces (SUPER + 1-9)"
        },
        "madOS Distro Author": {
            "es": "madOS Distro Author", "en": "madOS Distro Author", "fr": "madOS Distro Author", "de": "madOS Distro Author", "it": "madOS Distro Author", "pt": "madOS Distro Author", "ru": "madOS Distro Author", "ja": "madOS Distro Author", "zh": "madOS Distro Author"
        },
        "Battery & Power": {
            "es": "Bateria y Energia", "en": "Battery & Power", "fr": "Battery & Power", "de": "Battery & Power", "it": "Battery & Power", "pt": "Battery & Power", "ru": "Battery & Power", "ja": "Battery & Power", "zh": "Battery & Power"
        },
        "Built-in Pomodoro timer daemon \nwith session tracking.": {
            "es": "Temporizador Pomodoro integrado \ncon seguimiento de sesiones.", "en": "Built-in Pomodoro timer daemon \nwith session tracking.", "fr": "Built-in Pomodoro timer daemon \nwith session tracking.", "de": "Built-in Pomodoro timer daemon \nwith session tracking.", "it": "Built-in Pomodoro timer daemon \nwith session tracking.", "pt": "Built-in Pomodoro timer daemon \nwith session tracking.", "ru": "Built-in Pomodoro timer daemon \nwith session tracking.", "ja": "Built-in Pomodoro timer daemon \nwith session tracking.", "zh": "Built-in Pomodoro timer daemon \nwith session tracking."
        },
        "Calendar & Weather": {
            "es": "Calendario y Clima", "en": "Calendar & Weather", "fr": "Calendar & Weather", "de": "Calendar & Weather", "it": "Calendar & Weather", "pt": "Calendar & Weather", "ru": "Calendar & Weather", "ja": "Calendar & Weather", "zh": "Calendar & Weather"
        },
        "Dual-sync calendar with live \nOpenWeatherMap integration.": {
            "es": "Calendario de doble sincronizacion con \nintegracion de OpenWeatherMap en vivo.", "en": "Dual-sync calendar with live \nOpenWeatherMap integration.", "fr": "Dual-sync calendar with live \nOpenWeatherMap integration.", "de": "Dual-sync calendar with live \nOpenWeatherMap integration.", "it": "Dual-sync calendar with live \nOpenWeatherMap integration.", "pt": "Dual-sync calendar with live \nOpenWeatherMap integration.", "ru": "Dual-sync calendar with live \nOpenWeatherMap integration.", "ja": "Dual-sync calendar with live \nOpenWeatherMap integration.", "zh": "Dual-sync calendar with live \nOpenWeatherMap integration."
        },
        "Media & Lyrics": {
            "es": "Media y Letras", "en": "Media & Lyrics", "fr": "Media & Lyrics", "de": "Media & Lyrics", "it": "Media & Lyrics", "pt": "Media & Lyrics", "ru": "Media & Lyrics", "ja": "Media & Lyrics", "zh": "Media & Lyrics"
        },
        "Monitors": {
            "es": "Monitores", "en": "Monitors", "fr": "Monitors", "de": "Monitors", "it": "Monitors", "pt": "Monitors", "ru": "Monitors", "ja": "Monitors", "zh": "Monitors"
        },
        "Network Hub": {
            "es": "Centro de Red", "en": "Network Hub", "fr": "Network Hub", "de": "Network Hub", "it": "Network Hub", "pt": "Network Hub", "ru": "Network Hub", "ja": "Network Hub", "zh": "Network Hub"
        },
        "Overlays & Notifs": {
            "es": "Superposiciones y Notifs", "en": "Overlays & Notifs", "fr": "Overlays & Notifs", "de": "Overlays & Notifs", "it": "Overlays & Notifs", "pt": "Overlays & Notifs", "ru": "Overlays & Notifs", "ja": "Overlays & Notifs", "zh": "Overlays & Notifs"
        },
        "PlayerCtl integration, Cava \nvisualizer, and live lyrics.": {
            "es": "Integracion con PlayerCtl, visualizador \nCava y letras en vivo.", "en": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "fr": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "de": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "it": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "pt": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "ru": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "ja": "PlayerCtl integration, Cava \nvisualizer, and live lyrics.", "zh": "PlayerCtl integration, Cava \nvisualizer, and live lyrics."
        },
        "Quick display management.": {
            "es": "Gestion rapida de pantallas.", "en": "Quick display management.", "fr": "Quick display management.", "de": "Quick display management.", "it": "Quick display management.", "pt": "Quick display management.", "ru": "Quick display management.", "ja": "Quick display management.", "zh": "Quick display management."
        },
        "Stewart AI": {
            "es": "Stewart AI", "en": "Stewart AI", "fr": "Stewart AI", "de": "Stewart AI", "it": "Stewart AI", "pt": "Stewart AI", "ru": "Stewart AI", "ja": "Stewart AI", "zh": "Stewart AI"
        },
        "Theme Engine": {
            "es": "Motor de Temas", "en": "Theme Engine", "fr": "Theme Engine", "de": "Theme Engine", "it": "Theme Engine", "pt": "Theme Engine", "ru": "Theme Engine", "ja": "Theme Engine", "zh": "Theme Engine"
        },
        "Terminal Emulator": {
            "es": "Emulador de Terminal", "en": "Terminal Emulator", "fr": "Terminal Emulator", "de": "Terminal Emulator", "it": "Terminal Emulator", "pt": "Terminal Emulator", "ru": "Terminal Emulator", "ja": "Terminal Emulator", "zh": "Terminal Emulator"
        },
        "Uptime tracking, power profiles, \nand battery health metrics.": {
            "es": "Seguimiento de actividad, perfiles de energia \ny metricas de salud de bateria.", "en": "Uptime tracking, power profiles, \nand battery health metrics.", "fr": "Uptime tracking, power profiles, \nand battery health metrics.", "de": "Uptime tracking, power profiles, \nand battery health metrics.", "it": "Uptime tracking, power profiles, \nand battery health metrics.", "pt": "Uptime tracking, power profiles, \nand battery health metrics.", "ru": "Uptime tracking, power profiles, \nand battery health metrics.", "ja": "Uptime tracking, power profiles, \nand battery health metrics.", "zh": "Uptime tracking, power profiles, \nand battery health metrics."
        },
        "Voice assistant integration.\n(Reserved for future, currently disabled)": {
            "es": "Integracion de asistente de voz.\n(Reservado para el futuro, deshabilitado por ahora)", "en": "Voice assistant integration.\n(Reserved for future, currently disabled)", "fr": "Voice assistant integration.\n(Reserved for future, currently disabled)", "de": "Voice assistant integration.\n(Reserved for future, currently disabled)", "it": "Voice assistant integration.\n(Reserved for future, currently disabled)", "pt": "Voice assistant integration.\n(Reserved for future, currently disabled)", "ru": "Voice assistant integration.\n(Reserved for future, currently disabled)", "ja": "Voice assistant integration.\n(Reserved for future, currently disabled)", "zh": "Voice assistant integration.\n(Reserved for future, currently disabled)"
        },
        "Volume Mixer": {
            "es": "Mezclador de Volumen", "en": "Volume Mixer", "fr": "Volume Mixer", "de": "Volume Mixer", "it": "Volume Mixer", "pt": "Volume Mixer", "ru": "Volume Mixer", "ja": "Volume Mixer", "zh": "Volume Mixer"
        },
        "Wallpaper Picker": {
            "es": "Selector de Fondos", "en": "Wallpaper Picker", "fr": "Wallpaper Picker", "de": "Wallpaper Picker", "it": "Wallpaper Picker", "pt": "Wallpaper Picker", "ru": "Wallpaper Picker", "ja": "Wallpaper Picker", "zh": "Wallpaper Picker"
        },
        "Wayland Compositor": {
            "es": "Compositor Wayland", "en": "Wayland Compositor", "fr": "Wayland Compositor", "de": "Wayland Compositor", "it": "Wayland Compositor", "pt": "Wayland Compositor", "ru": "Wayland Compositor", "ja": "Wayland Compositor", "zh": "Wayland Compositor"
        },
        "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.": {
            "es": "Gestion de conexiones Wi-Fi y Bluetooth \nmediante nmcli/bluez.", "en": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "fr": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "de": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "it": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "pt": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "ru": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "ja": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez.", "zh": "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez."
        },
        "FocusTime": {
            "es": "FocusTime", "en": "FocusTime", "fr": "FocusTime", "de": "FocusTime", "it": "FocusTime", "pt": "FocusTime", "ru": "FocusTime", "ja": "FocusTime", "zh": "FocusTime"
        },
        "SKWD Launcher": {
            "es": "SKWD Launcher", "en": "SKWD Launcher", "fr": "SKWD Launcher", "de": "SKWD Launcher", "it": "SKWD Launcher", "pt": "SKWD Launcher", "ru": "SKWD Launcher", "ja": "SKWD Launcher", "zh": "SKWD Launcher"
        },
        "UI Framework": {
            "es": "Framework de UI", "en": "UI Framework", "fr": "UI Framework", "de": "UI Framework", "it": "UI Framework", "pt": "UI Framework", "ru": "UI Framework", "ja": "UI Framework", "zh": "UI Framework"
        },
        "Pipewire integration for I/O \nvolume and stream routing.": {
            "es": "Integracion de Pipewire para I/O \nvolumen y ruteo de audio.", "en": "Pipewire integration for I/O \nvolume and stream routing.", "fr": "Pipewire integration for I/O \nvolume and stream routing.", "de": "Pipewire integration for I/O \nvolume and stream routing.", "it": "Pipewire integration for I/O \nvolume and stream routing.", "pt": "Pipewire integration for I/O \nvolume and stream routing.", "ru": "Pipewire integration for I/O \nvolume and stream routing.", "ja": "Pipewire integration for I/O \nvolume and stream routing.", "zh": "Pipewire integration for I/O \nvolume and stream routing."
        },
        "Parallelogram app launcher \nwith frequency + recency ranking.": {
            "es": "Lanzador en paralelogramo \ncon ranking por frecuencia + recencia.", "en": "Parallelogram app launcher \nwith frequency + recency ranking.", "fr": "Parallelogram app launcher \nwith frequency + recency ranking.", "de": "Parallelogram app launcher \nwith frequency + recency ranking.", "it": "Parallelogram app launcher \nwith frequency + recency ranking.", "pt": "Parallelogram app launcher \nwith frequency + recency ranking.", "ru": "Parallelogram app launcher \nwith frequency + recency ranking.", "ja": "Parallelogram app launcher \nwith frequency + recency ranking.", "zh": "Parallelogram app launcher \nwith frequency + recency ranking."
        },
        "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.": {
            "es": "Selector de skwd-wall con awww,\nMatugen y Wallhaven.cc.", "en": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "fr": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "de": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "it": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "pt": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "ru": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "ja": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc.", "zh": "skwd-wall selector with awww,\nMatugen, and Wallhaven.cc."
        },
        "WINDOW SWITCHER": {
            "es": "CAMBIADOR DE VENTANAS", "en": "WINDOW SWITCHER", "fr": "WINDOW SWITCHER", "de": "WINDOW SWITCHER", "it": "WINDOW SWITCHER", "pt": "WINDOW SWITCHER", "ru": "WINDOW SWITCHER", "ja": "WINDOW SWITCHER", "zh": "WINDOW SWITCHER"
        },
        "windows": {
            "es": "ventanas", "en": "windows", "fr": "windows", "de": "windows", "it": "windows", "pt": "windows", "ru": "windows", "ja": "windows", "zh": "windows"
        },
        "App": {
            "es": "App", "en": "App", "fr": "App", "de": "App", "it": "App", "pt": "App", "ru": "App", "ja": "App", "zh": "App"
        },
        "Untitled": {
            "es": "Sin titulo", "en": "Untitled", "fr": "Untitled", "de": "Untitled", "it": "Untitled", "pt": "Untitled", "ru": "Untitled", "ja": "Untitled", "zh": "Untitled"
        },
        "WS": {
            "es": "WS", "en": "WS", "fr": "WS", "de": "WS", "it": "WS", "pt": "WS", "ru": "WS", "ja": "WS", "zh": "WS"
        },
        "FOCUSED": {
            "es": "EN FOCO", "en": "FOCUSED", "fr": "FOCUSED", "de": "FOCUSED", "it": "FOCUSED", "pt": "FOCUSED", "ru": "FOCUSED", "ja": "FOCUSED", "zh": "FOCUSED"
        },
        "NO WINDOWS": {
            "es": "SIN VENTANAS", "en": "NO WINDOWS", "fr": "NO WINDOWS", "de": "NO WINDOWS", "it": "NO WINDOWS", "pt": "NO WINDOWS", "ru": "NO WINDOWS", "ja": "NO WINDOWS", "zh": "NO WINDOWS"
        },
        "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel": {
            "es": "Tab/Shift+Tab para cambiar, Enter para enfocar, Esc para cancelar", "en": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "fr": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "de": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "it": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "pt": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "ru": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "ja": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel", "zh": "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel"
        },
        "NOTIFICATIONS": {
            "es": "NOTIFICACIONES", "en": "NOTIFICATIONS", "fr": "NOTIFICATIONS", "de": "NOTIFICATIONS", "it": "NOTIFICATIONS", "pt": "NOTIFICATIONS", "ru": "NOTIFICATIONS", "ja": "NOTIFICATIONS", "zh": "NOTIFICATIONS"
        },
        "CLEAR": {
            "es": "LIMPIAR", "en": "CLEAR", "fr": "CLEAR", "de": "CLEAR", "it": "CLEAR", "pt": "CLEAR", "ru": "CLEAR", "ja": "CLEAR", "zh": "CLEAR"
        },
        "NO NOTIFICATIONS": {
            "es": "SIN NOTIFICACIONES", "en": "NO NOTIFICATIONS", "fr": "NO NOTIFICATIONS", "de": "NO NOTIFICATIONS", "it": "NO NOTIFICATIONS", "pt": "NO NOTIFICATIONS", "ru": "NO NOTIFICATIONS", "ja": "NO NOTIFICATIONS", "zh": "NO NOTIFICATIONS"
        },
        "Notification": {
            "es": "Notificacion", "en": "Notification", "fr": "Notification", "de": "Notification", "it": "Notification", "pt": "Notification", "ru": "Notification", "ja": "Notification", "zh": "Notification"
        },
        "Action": {
            "es": "Accion", "en": "Action", "fr": "Action", "de": "Action", "it": "Action", "pt": "Action", "ru": "Action", "ja": "Action", "zh": "Action"
        },
        "No Device": {
            "es": "Sin dispositivo", "en": "No Device", "fr": "No Device", "de": "No Device", "it": "No Device", "pt": "No Device", "ru": "No Device", "ja": "No Device", "zh": "No Device"
        },
        "MUTE": {
            "es": "MUDO", "en": "MUTE", "fr": "MUTE", "de": "MUTE", "it": "MUTE", "pt": "MUTE", "ru": "MUTE", "ja": "MUTE", "zh": "MUTE"
        },
        "Master Output Volume": {
            "es": "Volumen maestro de salida", "en": "Master Output Volume", "fr": "Master Output Volume", "de": "Master Output Volume", "it": "Master Output Volume", "pt": "Master Output Volume", "ru": "Master Output Volume", "ja": "Master Output Volume", "zh": "Master Output Volume"
        },
        "Outputs": {
            "es": "Salidas", "en": "Outputs", "fr": "Outputs", "de": "Outputs", "it": "Outputs", "pt": "Outputs", "ru": "Outputs", "ja": "Outputs", "zh": "Outputs"
        },
        "Inputs": {
            "es": "Entradas", "en": "Inputs", "fr": "Inputs", "de": "Inputs", "it": "Inputs", "pt": "Inputs", "ru": "Inputs", "ja": "Inputs", "zh": "Inputs"
        },
        "Streams": {
            "es": "Flujos", "en": "Streams", "fr": "Streams", "de": "Streams", "it": "Streams", "pt": "Streams", "ru": "Streams", "ja": "Streams", "zh": "Streams"
        },
        "No active streams": {
            "es": "Sin flujos activos", "en": "No active streams", "fr": "No active streams", "de": "No active streams", "it": "No active streams", "pt": "No active streams", "ru": "No active streams", "ja": "No active streams", "zh": "No active streams"
        },
        "Active Default": {
            "es": "Activo por defecto", "en": "Active Default", "fr": "Active Default", "de": "Active Default", "it": "Active Default", "pt": "Active Default", "ru": "Active Default", "ja": "Active Default", "zh": "Active Default"
        },
        "Powering On...": {
            "es": "Encendiendo...", "en": "Powering On...", "fr": "Powering On...", "de": "Powering On...", "it": "Powering On...", "pt": "Powering On...", "ru": "Powering On...", "ja": "Powering On...", "zh": "Powering On..."
        },
        "Powering Off...": {
            "es": "Apagando...", "en": "Powering Off...", "fr": "Powering Off...", "de": "Powering Off...", "it": "Powering Off...", "pt": "Powering Off...", "ru": "Powering Off...", "ja": "Powering Off...", "zh": "Powering Off..."
        },
        "Radio Offline": {
            "es": "Radio apagada", "en": "Radio Offline", "fr": "Radio Offline", "de": "Radio Offline", "it": "Radio Offline", "pt": "Radio Offline", "ru": "Radio Offline", "ja": "Radio Offline", "zh": "Radio Offline"
        },
        "Scanning...": {
            "es": "Escaneando...", "en": "Scanning...", "fr": "Scanning...", "de": "Scanning...", "it": "Scanning...", "pt": "Scanning...", "ru": "Scanning...", "ja": "Scanning...", "zh": "Scanning..."
        },
        "Disconnecting...": {
            "es": "Desconectando...", "en": "Disconnecting...", "fr": "Disconnecting...", "de": "Disconnecting...", "it": "Disconnecting...", "pt": "Disconnecting...", "ru": "Disconnecting...", "ja": "Disconnecting...", "zh": "Disconnecting..."
        },
        "Hold...": {
            "es": "Manten...", "en": "Hold...", "fr": "Hold...", "de": "Hold...", "it": "Hold...", "pt": "Hold...", "ru": "Hold...", "ja": "Hold...", "zh": "Hold..."
        },
        "Connected": {
            "es": "Conectado", "en": "Connected", "fr": "Connected", "de": "Connected", "it": "Connected", "pt": "Connected", "ru": "Connected", "ja": "Connected", "zh": "Connected"
        },
        "Connecting...": {
            "es": "Conectando...", "en": "Connecting...", "fr": "Connecting...", "de": "Connecting...", "it": "Connecting...", "pt": "Connecting...", "ru": "Connecting...", "ja": "Connecting...", "zh": "Connecting..."
        },
        "Wi-Fi": {
            "es": "Wi-Fi", "en": "Wi-Fi", "fr": "Wi-Fi", "de": "Wi-Fi", "it": "Wi-Fi", "pt": "Wi-Fi", "ru": "Wi-Fi", "ja": "Wi-Fi", "zh": "Wi-Fi"
        },
        "Bluetooth": {
            "es": "Bluetooth", "en": "Bluetooth", "fr": "Bluetooth", "de": "Bluetooth", "it": "Bluetooth", "pt": "Bluetooth", "ru": "Bluetooth", "ja": "Bluetooth", "zh": "Bluetooth"
        },
        "Signal Strength": {
            "es": "Senal", "en": "Signal Strength", "fr": "Signal Strength", "de": "Signal Strength", "it": "Signal Strength", "pt": "Signal Strength", "ru": "Signal Strength", "ja": "Signal Strength", "zh": "Signal Strength"
        },
        "Security": {
            "es": "Seguridad", "en": "Security", "fr": "Security", "de": "Security", "it": "Security", "pt": "Security", "ru": "Security", "ja": "Security", "zh": "Security"
        },
        "Open": {
            "es": "Abierta", "en": "Open", "fr": "Open", "de": "Open", "it": "Open", "pt": "Open", "ru": "Open", "ja": "Open", "zh": "Open"
        },
        "IP Address": {
            "es": "Direccion IP", "en": "IP Address", "fr": "IP Address", "de": "IP Address", "it": "IP Address", "pt": "IP Address", "ru": "IP Address", "ja": "IP Address", "zh": "IP Address"
        },
        "Band": {
            "es": "Banda", "en": "Band", "fr": "Band", "de": "Band", "it": "Band", "pt": "Band", "ru": "Band", "ja": "Band", "zh": "Band"
        },
        "Battery": {
            "es": "Bateria", "en": "Battery", "fr": "Battery", "de": "Battery", "it": "Battery", "pt": "Battery", "ru": "Battery", "ja": "Battery", "zh": "Battery"
        },
        "Audio Profile": {
            "es": "Perfil de audio", "en": "Audio Profile", "fr": "Audio Profile", "de": "Audio Profile", "it": "Audio Profile", "pt": "Audio Profile", "ru": "Audio Profile", "ja": "Audio Profile", "zh": "Audio Profile"
        },
        "Unknown": {
            "es": "Desconocido", "en": "Unknown", "fr": "Inconnu", "de": "Unbekannt", "it": "Sconosciuto", "pt": "Desconhecido", "ru": "Неизвестно", "ja": "不明", "zh": "未知"
        },
        "MAC Address": {
            "es": "Direccion MAC", "en": "MAC Address", "fr": "MAC Address", "de": "MAC Address", "it": "MAC Address", "pt": "MAC Address", "ru": "MAC Address", "ja": "MAC Address", "zh": "MAC Address"
        },
        "Scan Devices": {
            "es": "Escanear dispositivos", "en": "Scan Devices", "fr": "Scan Devices", "de": "Scan Devices", "it": "Scan Devices", "pt": "Scan Devices", "ru": "Scan Devices", "ja": "Scan Devices", "zh": "Scan Devices"
        },
        "Switch View": {
            "es": "Cambiar vista", "en": "Switch View", "fr": "Switch View", "de": "Switch View", "it": "Switch View", "pt": "Switch View", "ru": "Switch View", "ja": "Switch View", "zh": "Switch View"
        },
        "Current Device": {
            "es": "Dispositivo actual", "en": "Current Device", "fr": "Current Device", "de": "Current Device", "it": "Current Device", "pt": "Current Device", "ru": "Current Device", "ja": "Current Device", "zh": "Current Device"
        },
        "View Info": {
            "es": "Ver info", "en": "View Info", "fr": "View Info", "de": "View Info", "it": "View Info", "pt": "View Info", "ru": "View Info", "ja": "View Info", "zh": "View Info"
        },
        "Connect": {
            "es": "Conectar", "en": "Connect", "fr": "Connect", "de": "Connect", "it": "Connect", "pt": "Connect", "ru": "Connect", "ja": "Connect", "zh": "Connect"
        },
        "Pair": {
            "es": "Emparejar", "en": "Pair", "fr": "Pair", "de": "Pair", "it": "Pair", "pt": "Pair", "ru": "Pair", "ja": "Pair", "zh": "Pair"
        },
        "Calculating...": {
            "es": "Calculando...", "en": "Calculating...", "fr": "Calculating...", "de": "Calculating...", "it": "Calculating...", "pt": "Calculating...", "ru": "Calculating...", "ja": "Calculating...", "zh": "Calculating..."
        },
        "Hi-Fi (A2DP)": {
            "es": "Hi-Fi (A2DP)", "en": "Hi-Fi (A2DP)", "fr": "Hi-Fi (A2DP)", "de": "Hi-Fi (A2DP)", "it": "Hi-Fi (A2DP)", "pt": "Hi-Fi (A2DP)", "ru": "Hi-Fi (A2DP)", "ja": "Hi-Fi (A2DP)", "zh": "Hi-Fi (A2DP)"
        },
        "Headset (HFP)": {
            "es": "Headset (HFP)", "en": "Headset (HFP)", "fr": "Headset (HFP)", "de": "Headset (HFP)", "it": "Headset (HFP)", "pt": "Headset (HFP)", "ru": "Headset (HFP)", "ja": "Headset (HFP)", "zh": "Headset (HFP)"
        },
        "None": {
            "es": "Ninguno", "en": "None", "fr": "None", "de": "None", "it": "None", "pt": "None", "ru": "None", "ja": "None", "zh": "None"
        },
        "Loading...": {
            "es": "Cargando...", "en": "Loading...", "fr": "Loading...", "de": "Loading...", "it": "Loading...", "pt": "Loading...", "ru": "Loading...", "ja": "Loading...", "zh": "Loading..."
        },
        "BY": {
            "es": "POR", "en": "BY", "fr": "BY", "de": "BY", "it": "BY", "pt": "BY", "ru": "BY", "ja": "BY", "zh": "BY"
        },
        "VIA": {
            "es": "VIA", "en": "VIA", "fr": "VIA", "de": "VIA", "it": "VIA", "pt": "VIA", "ru": "VIA", "ja": "VIA", "zh": "VIA"
        },
        "Offline": {
            "es": "Sin conexion", "en": "Offline", "fr": "Offline", "de": "Offline", "it": "Offline", "pt": "Offline", "ru": "Offline", "ja": "Offline", "zh": "Offline"
        },
        "Speaker": {
            "es": "Altavoz", "en": "Speaker", "fr": "Speaker", "de": "Speaker", "it": "Speaker", "pt": "Speaker", "ru": "Speaker", "ja": "Speaker", "zh": "Speaker"
        },
        "Equalizer": {
            "es": "Ecualizador", "en": "Equalizer", "fr": "Equalizer", "de": "Equalizer", "it": "Equalizer", "pt": "Equalizer", "ru": "Equalizer", "ja": "Equalizer", "zh": "Equalizer"
        },
        "Apply": {
            "es": "Aplicar", "en": "Apply", "fr": "Apply", "de": "Apply", "it": "Apply", "pt": "Apply", "ru": "Apply", "ja": "Apply", "zh": "Apply"
        },
        "Saved": {
            "es": "Guardado", "en": "Saved", "fr": "Saved", "de": "Saved", "it": "Saved", "pt": "Saved", "ru": "Saved", "ja": "Saved", "zh": "Saved"
        },
        "Desktop": {
            "es": "Escritorio", "en": "Desktop", "fr": "Desktop", "de": "Desktop", "it": "Desktop", "pt": "Desktop", "ru": "Desktop", "ja": "Desktop", "zh": "Desktop"
        },
        "N/A": {
            "es": "N/A", "en": "N/A", "fr": "N/A", "de": "N/A", "it": "N/A", "pt": "N/A", "ru": "N/A", "ja": "N/A", "zh": "N/A"
        },
        "Today": {
            "es": "Hoy", "en": "Today", "fr": "Today", "de": "Today", "it": "Today", "pt": "Today", "ru": "Today", "ja": "Today", "zh": "Today"
        },
        "Week Overview": {
            "es": "Resumen semanal", "en": "Week Overview", "fr": "Week Overview", "de": "Week Overview", "it": "Week Overview", "pt": "Week Overview", "ru": "Week Overview", "ja": "Week Overview", "zh": "Week Overview"
        },
        "Daily average": {
            "es": "Promedio diario", "en": "Daily average", "fr": "Daily average", "de": "Daily average", "it": "Daily average", "pt": "Daily average", "ru": "Daily average", "ja": "Daily average", "zh": "Daily average"
        },
        "No data": {
            "es": "Sin datos", "en": "No data", "fr": "No data", "de": "No data", "it": "No data", "pt": "No data", "ru": "No data", "ja": "No data", "zh": "No data"
        },
        "Same time": {
            "es": "Mismo tiempo", "en": "Same time", "fr": "Same time", "de": "Same time", "it": "Same time", "pt": "Same time", "ru": "Same time", "ja": "Same time", "zh": "Same time"
        },
        "Daily usage": {
            "es": "Uso diario", "en": "Daily usage", "fr": "Daily usage", "de": "Daily usage", "it": "Daily usage", "pt": "Daily usage", "ru": "Daily usage", "ja": "Daily usage", "zh": "Daily usage"
        },
        "Peak hours": {
            "es": "Horas pico", "en": "Peak hours", "fr": "Peak hours", "de": "Peak hours", "it": "Peak hours", "pt": "Peak hours", "ru": "Peak hours", "ja": "Peak hours", "zh": "Peak hours"
        },
        "Monday": {
            "es": "Lunes", "en": "Monday", "fr": "Lundi", "de": "Montag", "it": "Lunedì", "pt": "Segunda-feira", "ru": "Понедельник", "ja": "月曜日", "zh": "星期一"
        },
        "Tuesday": {
            "es": "Martes", "en": "Tuesday", "fr": "Mardi", "de": "Dienstag", "it": "Martedì", "pt": "Terça-feira", "ru": "Вторник", "ja": "火曜日", "zh": "星期二"
        },
        "Wednesday": {
            "es": "Miércoles", "en": "Wednesday", "fr": "Mercredi", "de": "Mittwoch", "it": "Mercoledì", "pt": "Quarta-feira", "ru": "Среда", "ja": "水曜日", "zh": "星期三"
        },
        "Thursday": {
            "es": "Jueves", "en": "Thursday", "fr": "Jeudi", "de": "Donnerstag", "it": "Giovedì", "pt": "Quinta-feira", "ru": "Четверг", "ja": "木曜日", "zh": "星期四"
        },
        "Friday": {
            "es": "Viernes", "en": "Friday", "fr": "Vendredi", "de": "Freitag", "it": "Venerdì", "pt": "Sexta-feira", "ru": "Пятница", "ja": "金曜日", "zh": "星期五"
        },
        "Saturday": {
            "es": "Sábado", "en": "Saturday", "fr": "Samedi", "de": "Samstag", "it": "Sabato", "pt": "Sábado", "ru": "Суббота", "ja": "土曜日", "zh": "星期六"
        },
        "Sunday": {
            "es": "Domingo", "en": "Sunday", "fr": "Dimanche", "de": "Sonntag", "it": "Domenica", "pt": "Domingo", "ru": "Воскресенье", "ja": "日曜日", "zh": "星期日"
        },
        "January": {
            "es": "Enero", "en": "January", "fr": "Janvier", "de": "Januar", "it": "Gennaio", "pt": "Janeiro", "ru": "Январь", "ja": "1月", "zh": "一月"
        },
        "February": {
            "es": "Febrero", "en": "February", "fr": "Février", "de": "Februar", "it": "Febbraio", "pt": "Fevereiro", "ru": "Февраль", "ja": "2月", "zh": "二月"
        },
        "March": {
            "es": "Marzo", "en": "March", "fr": "Mars", "de": "März", "it": "Marzo", "pt": "Março", "ru": "Март", "ja": "3月", "zh": "三月"
        },
        "April": {
            "es": "Abril", "en": "April", "fr": "Avril", "de": "April", "it": "Aprile", "pt": "Abril", "ru": "Апрель", "ja": "4月", "zh": "四月"
        },
        "May": {
            "es": "Mayo", "en": "May", "fr": "Mai", "de": "Mai", "it": "Maggio", "pt": "Maio", "ru": "Май", "ja": "5月", "zh": "五月"
        },
        "June": {
            "es": "Junio", "en": "June", "fr": "Juin", "de": "Juni", "it": "Giugno", "pt": "Junho", "ru": "Июнь", "ja": "6月", "zh": "六月"
        },
        "July": {
            "es": "Julio", "en": "July", "fr": "Juillet", "de": "Juli", "it": "Luglio", "pt": "Julho", "ru": "Июль", "ja": "7月", "zh": "七月"
        },
        "August": {
            "es": "Agosto", "en": "August", "fr": "Août", "de": "August", "it": "Agosto", "pt": "Agosto", "ru": "Август", "ja": "8月", "zh": "八月"
        },
        "September": {
            "es": "Septiembre", "en": "September", "fr": "Septembre", "de": "September", "it": "Settembre", "pt": "Setembro", "ru": "Сентябрь", "ja": "9月", "zh": "九月"
        },
        "October": {
            "es": "Octubre", "en": "October", "fr": "Octobre", "de": "Oktober", "it": "Ottobre", "pt": "Outubro", "ru": "Октябрь", "ja": "10月", "zh": "十月"
        },
        "November": {
            "es": "Noviembre", "en": "November", "fr": "Novembre", "de": "November", "it": "Novembre", "pt": "Novembro", "ru": "Ноябрь", "ja": "11月", "zh": "十一月"
        },
        "December": {
            "es": "Diciembre", "en": "December", "fr": "Décembre", "de": "Dezember", "it": "Dicembre", "pt": "Dezembro", "ru": "Декабрь", "ja": "12月", "zh": "十二月"
        },
        "00:00": {
            "es": "00:00", "en": "00:00", "fr": "00:00", "de": "00:00", "it": "00:00", "pt": "00:00", "ru": "00:00", "ja": "00:00", "zh": "00:00"
        },
        "06:00": {
            "es": "06:00", "en": "06:00", "fr": "06:00", "de": "06:00", "it": "06:00", "pt": "06:00", "ru": "06:00", "ja": "06:00", "zh": "06:00"
        },
        "12:00": {
            "es": "12:00", "en": "12:00", "fr": "12:00", "de": "12:00", "it": "12:00", "pt": "12:00", "ru": "12:00", "ja": "12:00", "zh": "12:00"
        },
        "18:00": {
            "es": "18:00", "en": "18:00", "fr": "18:00", "de": "18:00", "it": "18:00", "pt": "18:00", "ru": "18:00", "ja": "18:00", "zh": "18:00"
        },
        "23:00": {
            "es": "23:00", "en": "23:00", "fr": "23:00", "de": "23:00", "it": "23:00", "pt": "23:00", "ru": "23:00", "ja": "23:00", "zh": "23:00"
        },
        "LOADING...": {
            "es": "CARGANDO...", "en": "LOADING...", "fr": "CHARGEMENT...", "de": "LADEN...", "it": "CARICAMENTO...", "pt": "CARREGANDO...", "ru": "ЗАГРУЗКА...", "ja": "読み込み中...", "zh": "加载中..."
        },
        "Weather API Setup": {
            "es": "Configurar API del clima", "en": "Weather API Setup", "fr": "Configuration de l'API météo", "de": "Weather-API einrichten", "it": "Configura API meteo", "pt": "Configurar API do clima", "ru": "Настройка API погоды", "ja": "天気API設定", "zh": "天气 API 设置"
        },
        "OpenWeatherMap API Key": {
            "es": "Clave API de OpenWeatherMap", "en": "OpenWeatherMap API Key", "fr": "Clé API OpenWeatherMap", "de": "OpenWeatherMap-API-Schlüssel", "it": "Chiave API OpenWeatherMap", "pt": "Chave da API OpenWeatherMap", "ru": "Ключ API OpenWeatherMap", "ja": "OpenWeatherMap APIキー", "zh": "OpenWeatherMap API 密钥"
        },
        "Paste your API key": {
            "es": "Pega tu clave API", "en": "Paste your API key", "fr": "Collez votre clé API", "de": "API-Schlüssel einfügen", "it": "Incolla la tua chiave API", "pt": "Cole sua chave de API", "ru": "Вставьте ключ API", "ja": "APIキーを貼り付け", "zh": "粘贴你的 API 密钥"
        },
        "City ID": {
            "es": "ID de ciudad", "en": "City ID", "fr": "ID de ville", "de": "Stadt-ID", "it": "ID città", "pt": "ID da cidade", "ru": "ID города", "ja": "都市ID", "zh": "城市 ID"
        },
        "Example: 2643743": {
            "es": "Ejemplo: 2643743", "en": "Example: 2643743", "fr": "Exemple : 2643743", "de": "Beispiel: 2643743", "it": "Esempio: 2643743", "pt": "Exemplo: 2643743", "ru": "Пример: 2643743", "ja": "例: 2643743", "zh": "示例：2643743"
        },
        "Units": {
            "es": "Unidades", "en": "Units", "fr": "Unités", "de": "Einheiten", "it": "Unità", "pt": "Unidades", "ru": "Единицы", "ja": "単位", "zh": "单位"
        },
        "metric": {
            "es": "métrico", "en": "metric", "fr": "métrique", "de": "metrisch", "it": "metrico", "pt": "métrico", "ru": "метрическая", "ja": "メートル法", "zh": "公制"
        },
        "imperial": {
            "es": "imperial", "en": "imperial", "fr": "impérial", "de": "imperial", "it": "imperiale", "pt": "imperial", "ru": "имперская", "ja": "ヤード・ポンド法", "zh": "英制"
        },
        "Cancel": {
            "es": "Cancelar", "en": "Cancel", "fr": "Annuler", "de": "Abbrechen", "it": "Annulla", "pt": "Cancelar", "ru": "Отмена", "ja": "キャンセル", "zh": "取消"
        },
        "Save": {
            "es": "Guardar", "en": "Save", "fr": "Enregistrer", "de": "Speichern", "it": "Salva", "pt": "Salvar", "ru": "Сохранить", "ja": "保存", "zh": "保存"
        },
        "Validating...": {
            "es": "Validando...", "en": "Validating...", "fr": "Validation...", "de": "Wird geprüft...", "it": "Verifica in corso...", "pt": "Validando...", "ru": "Проверка...", "ja": "検証中...", "zh": "正在验证..."
        },
        "Saved. Refreshing weather...": {
            "es": "Guardado. Actualizando clima...", "en": "Saved. Refreshing weather...", "fr": "Enregistré. Actualisation de la météo...", "de": "Gespeichert. Wetter wird aktualisiert...", "it": "Salvato. Aggiornamento meteo...", "pt": "Salvo. Atualizando clima...", "ru": "Сохранено. Обновление погоды...", "ja": "保存しました。天気を更新中...", "zh": "已保存。正在刷新天气..."
        },
        "Invalid API key or city id": {
            "es": "API key o city id inválido", "en": "Invalid API key or city id", "fr": "Clé API ou ID de ville invalide", "de": "Ungültiger API-Schlüssel oder Stadt-ID", "it": "Chiave API o ID città non valido", "pt": "Chave API ou ID da cidade inválido", "ru": "Неверный API-ключ или ID города", "ja": "APIキーまたは都市IDが無効です", "zh": "API 密钥或城市 ID 无效"
        },
        "Validation failed": {
            "es": "Validación fallida", "en": "Validation failed", "fr": "Échec de validation", "de": "Validierung fehlgeschlagen", "it": "Convalida fallita", "pt": "Falha na validação", "ru": "Ошибка проверки", "ja": "検証に失敗しました", "zh": "验证失败"
        },
        "Mo": {
            "es": "Lu", "en": "Mo", "fr": "Lu", "de": "Mo", "it": "Lu", "pt": "Seg", "ru": "Пн", "ja": "月", "zh": "周一"
        },
        "Tu": {
            "es": "Ma", "en": "Tu", "fr": "Ma", "de": "Di", "it": "Ma", "pt": "Ter", "ru": "Вт", "ja": "火", "zh": "周二"
        },
        "We": {
            "es": "Mi", "en": "We", "fr": "Me", "de": "Mi", "it": "Me", "pt": "Qua", "ru": "Ср", "ja": "水", "zh": "周三"
        },
        "Th": {
            "es": "Ju", "en": "Th", "fr": "Je", "de": "Do", "it": "Gi", "pt": "Qui", "ru": "Чт", "ja": "木", "zh": "周四"
        },
        "Fr": {
            "es": "Vi", "en": "Fr", "fr": "Ve", "de": "Fr", "it": "Ve", "pt": "Sex", "ru": "Пт", "ja": "金", "zh": "周五"
        },
        "Sa": {
            "es": "Sá", "en": "Sa", "fr": "Sa", "de": "Sa", "it": "Sa", "pt": "Sáb", "ru": "Сб", "ja": "土", "zh": "周六"
        },
        "Su": {
            "es": "Do", "en": "Su", "fr": "Di", "de": "So", "it": "Do", "pt": "Dom", "ru": "Вс", "ja": "日", "zh": "周日"
        },
        "WIND": {
            "es": "VIENTO", "en": "WIND", "fr": "VENT", "de": "WIND", "it": "VENTO", "pt": "VENTO", "ru": "ВЕТЕР", "ja": "風", "zh": "风"
        },
        "HUMID": {
            "es": "HUMEDAD", "en": "HUMID", "fr": "HUMIDITÉ", "de": "FEUCHTE", "it": "UMIDITÀ", "pt": "UMIDADE", "ru": "ВЛАЖН.", "ja": "湿度", "zh": "湿度"
        },
        "RAIN": {
            "es": "LLUVIA", "en": "RAIN", "fr": "PLUIE", "de": "REGEN", "it": "PIOGGIA", "pt": "CHUVA", "ru": "ДОЖДЬ", "ja": "雨", "zh": "降雨"
        },
        "FEELS": {
            "es": "SENSAC.", "en": "FEELS", "fr": "RESSENTI", "de": "GEFÜHLT", "it": "PERCEPITA", "pt": "SENSAÇÃO", "ru": "ОЩУЩ.", "ja": "体感", "zh": "体感"
        },
        "No API Key": {
            "es": "Sin clave API", "en": "No API Key", "fr": "Aucune clé API", "de": "Kein API-Schlüssel", "it": "Nessuna chiave API", "pt": "Sem chave de API", "ru": "Нет API-ключа", "ja": "APIキー未設定", "zh": "未设置 API 密钥"
        },
        "Missing API key or city id": {
            "es": "Falta API key o city id", "en": "Missing API key or city id", "fr": "Clé API ou ID de ville manquant", "de": "API-Schlüssel oder Stadt-ID fehlt", "it": "Manca la chiave API o l'ID città", "pt": "Falta a chave API ou o ID da cidade", "ru": "Отсутствует API-ключ или ID города", "ja": "APIキーまたは都市IDがありません", "zh": "缺少 API 密钥或城市 ID"
        },
        "OpenWeather request failed": {
            "es": "Fallo en solicitud a OpenWeather", "en": "OpenWeather request failed", "fr": "Échec de la requête OpenWeather", "de": "OpenWeather-Anfrage fehlgeschlagen", "it": "Richiesta OpenWeather non riuscita", "pt": "Falha na requisição ao OpenWeather", "ru": "Ошибка запроса OpenWeather", "ja": "OpenWeather リクエストに失敗しました", "zh": "OpenWeather 请求失败"
        },
        "OpenWeather validation failed": {
            "es": "Validación de OpenWeather fallida", "en": "OpenWeather validation failed", "fr": "Validation OpenWeather échouée", "de": "OpenWeather-Validierung fehlgeschlagen", "it": "Convalida OpenWeather fallita", "pt": "Falha na validação do OpenWeather", "ru": "Ошибка проверки OpenWeather", "ja": "OpenWeather の検証に失敗しました", "zh": "OpenWeather 验证失败"
        },
        "Mist": {
            "es": "Niebla", "en": "Mist", "fr": "Brume", "de": "Nebel", "it": "Nebbia", "pt": "Névoa", "ru": "Туман", "ja": "霧", "zh": "薄雾"
        },
        "Sunny": {
            "es": "Soleado", "en": "Sunny", "fr": "Ensoleillé", "de": "Sonnig", "it": "Soleggiato", "pt": "Ensolarado", "ru": "Солнечно", "ja": "晴れ", "zh": "晴朗"
        },
        "Clear": {
            "es": "Despejado", "en": "Clear", "fr": "Dégagé", "de": "Klar", "it": "Sereno", "pt": "Céu limpo", "ru": "Ясно", "ja": "快晴", "zh": "晴"
        },
        "Cloudy": {
            "es": "Nublado", "en": "Cloudy", "fr": "Nuageux", "de": "Bewölkt", "it": "Nuvoloso", "pt": "Nublado", "ru": "Облачно", "ja": "くもり", "zh": "多云"
        },
        "Rainy": {
            "es": "Lluvioso", "en": "Rainy", "fr": "Pluvieux", "de": "Regnerisch", "it": "Piovoso", "pt": "Chuvoso", "ru": "Дождливо", "ja": "雨", "zh": "有雨"
        },
        "Storm": {
            "es": "Tormenta", "en": "Storm", "fr": "Orage", "de": "Sturm", "it": "Tempesta", "pt": "Tempestade", "ru": "Гроза", "ja": "嵐", "zh": "暴风雨"
        },
        "Snow": {
            "es": "Nieve", "en": "Snow", "fr": "Neige", "de": "Schnee", "it": "Neve", "pt": "Neve", "ru": "Снег", "ja": "雪", "zh": "雪"
        },
        "HR": {
            "es": "HR", "en": "HR", "fr": "HR", "de": "HR", "it": "HR", "pt": "HR", "ru": "HR", "ja": "HR", "zh": "HR"
        },
        "MIN": {
            "es": "MIN", "en": "MIN", "fr": "MIN", "de": "MIN", "it": "MIN", "pt": "MIN", "ru": "MIN", "ja": "MIN", "zh": "MIN"
        },
        "CPU LOAD": {
            "es": "CARGA CPU", "en": "CPU LOAD", "fr": "CPU LOAD", "de": "CPU LOAD", "it": "CPU LOAD", "pt": "CPU LOAD", "ru": "CPU LOAD", "ja": "CPU LOAD", "zh": "CPU LOAD"
        },
        "MEMORY": {
            "es": "MEMORIA", "en": "MEMORY", "fr": "MEMORY", "de": "MEMORY", "it": "MEMORY", "pt": "MEMORY", "ru": "MEMORY", "ja": "MEMORY", "zh": "MEMORY"
        },
        "STORAGE": {
            "es": "ALMACENAMIENTO", "en": "STORAGE", "fr": "STORAGE", "de": "STORAGE", "it": "STORAGE", "pt": "STORAGE", "ru": "STORAGE", "ja": "STORAGE", "zh": "STORAGE"
        },
        "SYSTEM TEMP": {
            "es": "TEMP SISTEMA", "en": "SYSTEM TEMP", "fr": "SYSTEM TEMP", "de": "SYSTEM TEMP", "it": "SYSTEM TEMP", "pt": "SYSTEM TEMP", "ru": "SYSTEM TEMP", "ja": "SYSTEM TEMP", "zh": "SYSTEM TEMP"
        },
        "Perform": {
            "es": "Rendimiento", "en": "Perform", "fr": "Perform", "de": "Perform", "it": "Perform", "pt": "Perform", "ru": "Perform", "ja": "Perform", "zh": "Perform"
        },
        "Balance": {
            "es": "Balance", "en": "Balance", "fr": "Balance", "de": "Balance", "it": "Balance", "pt": "Balance", "ru": "Balance", "ja": "Balance", "zh": "Balance"
        },
        "Saver": {
            "es": "Ahorro", "en": "Saver", "fr": "Saver", "de": "Saver", "it": "Saver", "pt": "Saver", "ru": "Saver", "ja": "Saver", "zh": "Saver"
        },
        "Locked": {
            "es": "Bloqueado", "en": "Locked", "fr": "Locked", "de": "Locked", "it": "Locked", "pt": "Locked", "ru": "Locked", "ja": "Locked", "zh": "Locked"
        },
        "Access Denied": {
            "es": "Acceso denegado", "en": "Access Denied", "fr": "Access Denied", "de": "Access Denied", "it": "Access Denied", "pt": "Access Denied", "ru": "Access Denied", "ja": "Access Denied", "zh": "Access Denied"
        },
        "Authenticating...": {
            "es": "Autenticando...", "en": "Authenticating...", "fr": "Authenticating...", "de": "Authenticating...", "it": "Authenticating...", "pt": "Authenticating...", "ru": "Authenticating...", "ja": "Authenticating...", "zh": "Authenticating..."
        },
        "Enter PIN": {
            "es": "Ingresa PIN", "en": "Enter PIN", "fr": "Enter PIN", "de": "Enter PIN", "it": "Enter PIN", "pt": "Enter PIN", "ru": "Enter PIN", "ja": "Enter PIN", "zh": "Enter PIN"
        },
        "SETTINGS": {
            "es": "AJUSTES", "en": "SETTINGS", "fr": "SETTINGS", "de": "SETTINGS", "it": "SETTINGS", "pt": "SETTINGS", "ru": "SETTINGS", "ja": "SETTINGS", "zh": "SETTINGS"
        },
        "Hide password": {
            "es": "Ocultar contrasena", "en": "Hide password", "fr": "Hide password", "de": "Hide password", "it": "Hide password", "pt": "Hide password", "ru": "Hide password", "ja": "Hide password", "zh": "Hide password"
        },
        "Reveal delay": {
            "es": "Retraso de muestra", "en": "Reveal delay", "fr": "Reveal delay", "de": "Reveal delay", "it": "Reveal delay", "pt": "Reveal delay", "ru": "Reveal delay", "ja": "Reveal delay", "zh": "Reveal delay"
        },
        "SYSTEM": {
            "es": "SISTEMA", "en": "SYSTEM", "fr": "SYSTEM", "de": "SYSTEM", "it": "SYSTEM", "pt": "SYSTEM", "ru": "SYSTEM", "ja": "SYSTEM", "zh": "SYSTEM"
        },
        "Reboot": {
            "es": "Reiniciar", "en": "Reboot", "fr": "Reboot", "de": "Reboot", "it": "Reboot", "pt": "Reboot", "ru": "Reboot", "ja": "Reboot", "zh": "Reboot"
        },
        "Suspend": {
            "es": "Suspender", "en": "Suspend", "fr": "Suspend", "de": "Suspend", "it": "Suspend", "pt": "Suspend", "ru": "Suspend", "ja": "Suspend", "zh": "Suspend"
        },
        "Power Off": {
            "es": "Apagar", "en": "Power Off", "fr": "Power Off", "de": "Power Off", "it": "Power Off", "pt": "Power Off", "ru": "Power Off", "ja": "Power Off", "zh": "Power Off"
        },
        "Apply": {
            "es": "Aplicar", "en": "Apply", "fr": "Apply", "de": "Apply", "it": "Apply", "pt": "Apply", "ru": "Apply", "ja": "Apply", "zh": "Apply"
        },
        "Apply All": {
            "es": "Aplicar todo", "en": "Apply All", "fr": "Apply All", "de": "Apply All", "it": "Apply All", "pt": "Apply All", "ru": "Apply All", "ja": "Apply All", "zh": "Apply All"
        },
        "Display Update": {
            "es": "Actualizacion de pantalla", "en": "Display Update", "fr": "Display Update", "de": "Display Update", "it": "Display Update", "pt": "Display Update", "ru": "Display Update", "ja": "Display Update", "zh": "Display Update"
        },
        "Applied:": {
            "es": "Aplicado:", "en": "Applied:", "fr": "Applied:", "de": "Applied:", "it": "Applied:", "pt": "Applied:", "ru": "Applied:", "ja": "Applied:", "zh": "Applied:"
        },
        "Applied layout for:": {
            "es": "Distribucion aplicada para:", "en": "Applied layout for:", "fr": "Applied layout for:", "de": "Applied layout for:", "it": "Applied layout for:", "pt": "Applied layout for:", "ru": "Applied layout for:", "ja": "Applied layout for:", "zh": "Applied layout for:"
        },
        "Videos": {
            "es": "Videos", "en": "Videos", "fr": "Videos", "de": "Videos", "it": "Video", "pt": "Videos", "ru": "Video", "ja": "Videos", "zh": "Videos"
        }
    })

    readonly property string language: _detectLanguage()

    function _normalizeLanguage(value) {
        var lowered = String(value || "").toLowerCase().trim()
        if (!lowered)
            return "en"

        lowered = lowered.replace(/-/g, "_")
        if (lowered.indexOf("@") >= 0)
            lowered = lowered.split("@")[0]
        if (lowered.indexOf(".") >= 0)
            lowered = lowered.split(".")[0]

        var alias = {
            "c": "en",
            "posix": "en",
            "en_us": "en",
            "en_gb": "en",
            "es_es": "es",
            "es_mx": "es",
            "fr_fr": "fr",
            "de_de": "de",
            "it_it": "it",
            "pt_br": "pt",
            "pt_pt": "pt",
            "ru_ru": "ru",
            "ja_jp": "ja",
            "zh_cn": "zh",
            "zh_sg": "zh",
            "zh_tw": "zh",
            "zh_hk": "zh"
        }

        if (alias[lowered])
            lowered = alias[lowered]

        if (supportedLanguages.indexOf(lowered) >= 0)
            return lowered

        var shortCode = lowered.split("_")[0]
        if (supportedLanguages.indexOf(shortCode) >= 0)
            return shortCode

        return "en"
    }

    function _detectLanguage() {
        var envCandidates = [
            Quickshell.env("LC_ALL"),
            Quickshell.env("LC_MESSAGES"),
            Quickshell.env("LANG")
        ]

        for (var i = 0; i < envCandidates.length; i++) {
            var candidate = String(envCandidates[i] || "").trim()
            if (!candidate)
                continue
            return _normalizeLanguage(candidate)
        }

        return "en"
    }

    function s(text) {
        var dict = _strings[text]
        if (!dict || typeof dict !== "object")
            return text
        var out = dict[language]
        if (typeof out === "string" && out !== "")
            return out
        out = dict["en"]
        if (typeof out === "string" && out !== "")
            return out
        return text
    }
}
