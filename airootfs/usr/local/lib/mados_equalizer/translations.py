"""
madOS Audio Equalizer - Internationalization / Translations
===========================================================

Provides translation strings for 6 languages:
    - English
    - Espanol (Spanish)
    - Francais (French)
    - Deutsch (German)
    - Chinese (Simplified)
    - Japanese

All UI strings are accessed through the TRANSLATIONS dictionary
using language name as key and string identifier as sub-key.
"""

FREQ_60_HZ = "60 Hz"
FREQ_170_HZ = "170 Hz"
FREQ_310_HZ = "310 Hz"
FREQ_600_HZ = "600 Hz"
FREQ_1_KHZ = "1 kHz"
FREQ_3_KHZ = "3 kHz"
FREQ_6_KHZ = "6 kHz"
FREQ_12_KHZ = "12 kHz"

TRANSLATIONS = {
    "English": {
        # Application
        "title": "madOS Equalizer",
        "equalizer": "Equalizer",
        "audio_equalizer": "Audio Equalizer",
        # Enable/Disable
        "enable": "Enable",
        "disable": "Disable",
        "enabled": "Enabled",
        "disabled": "Disabled",
        "bypass": "Bypass",
        # Presets
        "preset": "Preset",
        "presets": "Presets",
        "save_preset": "Save Preset",
        "delete_preset": "Delete Preset",
        "custom_preset": "Custom Preset",
        "preset_name": "Preset Name",
        # Built-in preset names
        "flat": "Flat",
        "rock": "Rock",
        "pop": "Pop",
        "jazz": "Jazz",
        "classical": "Classical",
        "bass_boost": "Bass Boost",
        "treble_boost": "Treble Boost",
        "vocal": "Vocal",
        "electronic": "Electronic",
        "acoustic": "Acoustic",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "Gain",
        "frequency": "Frequency",
        "db": "dB",
        # Volume
        "master_volume": "Master Volume",
        "volume": "Volume",
        "mute": "Mute",
        "unmute": "Unmute",
        # Output
        "output_device": "Output Device",
        "no_device": "No Device Found",
        "active_output": "Active Output",
        # Actions
        "reset": "Reset",
        "apply": "Apply",
        # Language
        "language": "Language",
        # Dialogs
        "error": "Error",
        "success": "Success",
        "save": "Save",
        "cancel": "Cancel",
        "close": "Close",
        # Status messages
        "preset_saved": "Preset saved successfully",
        "preset_deleted": "Preset deleted successfully",
        "preset_exists": "A preset with this name already exists",
        "eq_applied": "Equalizer settings applied",
        "eq_disabled": "Equalizer disabled",
    },
    "Español": {
        # Application
        "title": "Ecualizador madOS",
        "equalizer": "Ecualizador",
        "audio_equalizer": "Ecualizador de Audio",
        # Enable/Disable
        "enable": "Activar",
        "disable": "Desactivar",
        "enabled": "Activado",
        "disabled": "Desactivado",
        "bypass": "Bypass",
        # Presets
        "preset": "Preajuste",
        "presets": "Preajustes",
        "save_preset": "Guardar Preajuste",
        "delete_preset": "Eliminar Preajuste",
        "custom_preset": "Preajuste Personalizado",
        "preset_name": "Nombre del Preajuste",
        # Built-in preset names
        "flat": "Plano",
        "rock": "Rock",
        "pop": "Pop",
        "jazz": "Jazz",
        "classical": "Clasica",
        "bass_boost": "Refuerzo de Graves",
        "treble_boost": "Refuerzo de Agudos",
        "vocal": "Vocal",
        "electronic": "Electronica",
        "acoustic": "Acustica",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "Ganancia",
        "frequency": "Frecuencia",
        "db": "dB",
        # Volume
        "master_volume": "Volumen Principal",
        "volume": "Volumen",
        "mute": "Silenciar",
        "unmute": "Activar Sonido",
        # Output
        "output_device": "Dispositivo de Salida",
        "no_device": "Dispositivo No Encontrado",
        "active_output": "Salida Activa",
        # Actions
        "reset": "Restablecer",
        "apply": "Aplicar",
        # Language
        "language": "Idioma",
        # Dialogs
        "error": "Error",
        "success": "Correcto",
        "save": "Guardar",
        "cancel": "Cancelar",
        "close": "Cerrar",
        # Status messages
        "preset_saved": "Preajuste guardado correctamente",
        "preset_deleted": "Preajuste eliminado correctamente",
        "preset_exists": "Ya existe un preajuste con este nombre",
        "eq_applied": "Ajustes del ecualizador aplicados",
        "eq_disabled": "Ecualizador desactivado",
    },
    "Français": {
        # Application
        "title": "Egaliseur madOS",
        "equalizer": "Egaliseur",
        "audio_equalizer": "Egaliseur Audio",
        # Enable/Disable
        "enable": "Activer",
        "disable": "Desactiver",
        "enabled": "Active",
        "disabled": "Desactive",
        "bypass": "Bypass",
        # Presets
        "preset": "Preselection",
        "presets": "Preselections",
        "save_preset": "Enregistrer",
        "delete_preset": "Supprimer",
        "custom_preset": "Preselection Personnalisee",
        "preset_name": "Nom de la Preselection",
        # Built-in preset names
        "flat": "Plat",
        "rock": "Rock",
        "pop": "Pop",
        "jazz": "Jazz",
        "classical": "Classique",
        "bass_boost": "Renforcement des Basses",
        "treble_boost": "Renforcement des Aigus",
        "vocal": "Vocal",
        "electronic": "Electronique",
        "acoustic": "Acoustique",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "Gain",
        "frequency": "Frequence",
        "db": "dB",
        # Volume
        "master_volume": "Volume Principal",
        "volume": "Volume",
        "mute": "Muet",
        "unmute": "Reactiver le Son",
        # Output
        "output_device": "Peripherique de Sortie",
        "no_device": "Aucun Peripherique Trouve",
        "active_output": "Sortie Active",
        # Actions
        "reset": "Reinitialiser",
        "apply": "Appliquer",
        # Language
        "language": "Langue",
        # Dialogs
        "error": "Erreur",
        "success": "Succes",
        "save": "Enregistrer",
        "cancel": "Annuler",
        "close": "Fermer",
        # Status messages
        "preset_saved": "Preselection enregistree avec succes",
        "preset_deleted": "Preselection supprimee avec succes",
        "preset_exists": "Une preselection avec ce nom existe deja",
        "eq_applied": "Parametres de l'egaliseur appliques",
        "eq_disabled": "Egaliseur desactive",
    },
    "Deutsch": {
        # Application
        "title": "madOS Equalizer",
        "equalizer": "Equalizer",
        "audio_equalizer": "Audio-Equalizer",
        # Enable/Disable
        "enable": "Aktivieren",
        "disable": "Deaktivieren",
        "enabled": "Aktiviert",
        "disabled": "Deaktiviert",
        "bypass": "Bypass",
        # Presets
        "preset": "Voreinstellung",
        "presets": "Voreinstellungen",
        "save_preset": "Speichern",
        "delete_preset": "Loeschen",
        "custom_preset": "Eigene Voreinstellung",
        "preset_name": "Name der Voreinstellung",
        # Built-in preset names
        "flat": "Flach",
        "rock": "Rock",
        "pop": "Pop",
        "jazz": "Jazz",
        "classical": "Klassik",
        "bass_boost": "Bassverstaerkung",
        "treble_boost": "Hoehenverstaerkung",
        "vocal": "Gesang",
        "electronic": "Elektronisch",
        "acoustic": "Akustisch",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "Verstaerkung",
        "frequency": "Frequenz",
        "db": "dB",
        # Volume
        "master_volume": "Hauptlautstaerke",
        "volume": "Lautstaerke",
        "mute": "Stumm",
        "unmute": "Ton An",
        # Output
        "output_device": "Ausgabegeraet",
        "no_device": "Kein Geraet Gefunden",
        "active_output": "Aktive Ausgabe",
        # Actions
        "reset": "Zuruecksetzen",
        "apply": "Anwenden",
        # Language
        "language": "Sprache",
        # Dialogs
        "error": "Fehler",
        "success": "Erfolg",
        "save": "Speichern",
        "cancel": "Abbrechen",
        "close": "Schliessen",
        # Status messages
        "preset_saved": "Voreinstellung erfolgreich gespeichert",
        "preset_deleted": "Voreinstellung erfolgreich geloescht",
        "preset_exists": "Eine Voreinstellung mit diesem Namen existiert bereits",
        "eq_applied": "Equalizer-Einstellungen angewendet",
        "eq_disabled": "Equalizer deaktiviert",
    },
    "中文": {
        # Application
        "title": "madOS 均衡器",
        "equalizer": "均衡器",
        "audio_equalizer": "音频均衡器",
        # Enable/Disable
        "enable": "启用",
        "disable": "禁用",
        "enabled": "已启用",
        "disabled": "已禁用",
        "bypass": "旁通",
        # Presets
        "preset": "预设",
        "presets": "预设列表",
        "save_preset": "保存预设",
        "delete_preset": "删除预设",
        "custom_preset": "自定义预设",
        "preset_name": "预设名称",
        # Built-in preset names
        "flat": "平坦",
        "rock": "摇滚",
        "pop": "流行",
        "jazz": "爵士",
        "classical": "古典",
        "bass_boost": "低音增强",
        "treble_boost": "高音增强",
        "vocal": "人声",
        "electronic": "电子",
        "acoustic": "原声",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "增益",
        "frequency": "频率",
        "db": "dB",
        # Volume
        "master_volume": "主音量",
        "volume": "音量",
        "mute": "静音",
        "unmute": "取消静音",
        # Output
        "output_device": "输出设备",
        "no_device": "未找到设备",
        "active_output": "活动输出",
        # Actions
        "reset": "重置",
        "apply": "应用",
        # Language
        "language": "语言",
        # Dialogs
        "error": "错误",
        "success": "成功",
        "save": "保存",
        "cancel": "取消",
        "close": "关闭",
        # Status messages
        "preset_saved": "预设保存成功",
        "preset_deleted": "预设删除成功",
        "preset_exists": "已存在同名预设",
        "eq_applied": "均衡器设置已应用",
        "eq_disabled": "均衡器已禁用",
    },
    "日本語": {
        # Application
        "title": "madOS イコライザー",
        "equalizer": "イコライザー",
        "audio_equalizer": "オーディオイコライザー",
        # Enable/Disable
        "enable": "有効",
        "disable": "無効",
        "enabled": "有効",
        "disabled": "無効",
        "bypass": "バイパス",
        # Presets
        "preset": "プリセット",
        "presets": "プリセット一覧",
        "save_preset": "プリセットを保存",
        "delete_preset": "プリセットを削除",
        "custom_preset": "カスタムプリセット",
        "preset_name": "プリセット名",
        # Built-in preset names
        "flat": "フラット",
        "rock": "ロック",
        "pop": "ポップ",
        "jazz": "ジャズ",
        "classical": "クラシック",
        "bass_boost": "低音ブースト",
        "treble_boost": "高音ブースト",
        "vocal": "ボーカル",
        "electronic": "エレクトロニック",
        "acoustic": "アコースティック",
        # Frequency bands
        "band_60": FREQ_60_HZ,
        "band_170": FREQ_170_HZ,
        "band_310": FREQ_310_HZ,
        "band_600": FREQ_600_HZ,
        "band_1k": FREQ_1_KHZ,
        "band_3k": FREQ_3_KHZ,
        "band_6k": FREQ_6_KHZ,
        "band_12k": FREQ_12_KHZ,
        # Gain and frequency
        "gain": "ゲイン",
        "frequency": "周波数",
        "db": "dB",
        # Volume
        "master_volume": "マスターボリューム",
        "volume": "音量",
        "mute": "ミュート",
        "unmute": "ミュート解除",
        # Output
        "output_device": "出力デバイス",
        "no_device": "デバイスが見つかりません",
        "active_output": "アクティブ出力",
        # Actions
        "reset": "リセット",
        "apply": "適用",
        # Language
        "language": "言語",
        # Dialogs
        "error": "エラー",
        "success": "成功",
        "save": "保存",
        "cancel": "キャンセル",
        "close": "閉じる",
        # Status messages
        "preset_saved": "プリセットが正常に保存されました",
        "preset_deleted": "プリセットが正常に削除されました",
        "preset_exists": "この名前のプリセットは既に存在します",
        "eq_applied": "イコライザー設定が適用されました",
        "eq_disabled": "イコライザーが無効になりました",
    },


    "Português": {
    "title": "madOS",
    "subtitle": "Arch Linux Orquestrado por IA | Powered by OpenCode",
    "features": [
        "Compressão ZRAM",
        "Compositor Sway",
        "Node.js + npm",
        "Chromium + VS Code",
        "Git pré-instalado",
        "Ajuste do kernel",
        "Steam Deck ready",
        "Controle Xbox",
    ],
    "language": "Idioma:",
    "start_install": "Iniciar Instalação",
    "exit": "Sair",
    "select_disk": "Selecionar Disco",
    "warning": "AVISO: TODOS OS DADOS SERÃO APAGADOS",
    "layout": "Layout:",
    "back": "← Voltar",
    "next": "Próximo →",
    "partitioning": "Esquema de Particionamento",
    "disk_info": "Disco:",
    "sep_home_radio": "Partição /home separada",
    "sep_home_title": "Partição /home separada:",
    "sep_home_pro1": "Reinstalar SO sem perder dados",
    "sep_home_pro2": "Melhor para backups",
    "sep_home_con": "Menos flexível com espaço",
    "all_root_radio": "Tudo em / (recomendado para <128GB)",
    "all_root_title": "Tudo em / (sem /home separado):",
    "all_root_pro1": "Máxima flexibilidade de espaço",
    "all_root_pro2": "Melhor para discos pequenos",
    "all_root_con": "Reinstalar requer backup",
    "efi_label": "EFI",
    "root_label": "Raiz",
    "home_label": "Home",
    "rest_label": "resto",
    "all_rest_label": "todo o resto",
    "home_dir_label": "/home como diretório",
    "create_user": "Criar Conta de Usuário",
    "username": "Usuário:",
    "pwd_label": "Senha:",
    "pwd_confirm_label": "Confirmar Senha:",
    "hostname": "Nome do computador:",
    "regional": "Configuração Regional",
    "timezone": "Fuso horário:",
    "locale_label": "Idioma do sistema:",
    "summary": "Resumo da Instalação",
    "sys_config": "Configuração do Sistema:",
    "disk": "Disco:",
    "partitions": "Partições:",
    "software": "Software Incluído:",
    "software_list": "- Compositor Wayland Sway\n- Assistente IA OpenCode\n- Chromium, VS Code, Git\n- Ferramentas de desenvolvimento (Node.js, npm)\n- Otimizado para 1.9GB RAM",
    "start_install_btn": "Iniciar Instalação",
    "installing": "Instalando madOS",
    "preparing": "Preparando instalação...",
    "success_title": "Instalação Completa!",
    "success_msg": "O sistema base madOS foi instalado!\n\n<b>No primeiro boot</b>, os pacotes e\nconfigurações restantes serão instalados automaticamente.\nIsso requer conexão com a internet.\n\nPróximos passos:\n1. Remover a mídia de instalação\n2. Reiniciar o computador\n3. Aguardar a configuração inicial terminar\n4. Fazer login com suas credenciais\n5. Digite \"opencode\" para iniciar o assistente IA",
    "reboot_now": "Reiniciar Agora",
    "exit_live": "Sair para o Sistema Live",
    "wifi_setup": "Conexão de Rede",
    "wifi_networks": "Redes Disponíveis",
    "wifi_scan": "Buscar",
    "wifi_scanning": "Buscando",
    "wifi_password": "Senha:",
    "wifi_pass_placeholder": "Digite a senha do WiFi",
    "wifi_connect": "Conectar",
    "wifi_skip": "Pular / Próximo →",
    "wifi_detecting": "Adaptador WiFi detectado",
    "wifi_no_adapter": "Nenhum adaptador WiFi detectado — conecte via Ethernet",
    "wifi_no_networks": "Nenhuma rede encontrada. Tente buscar novamente.",
    "wifi_connecting": "Conectando a",
    "wifi_connected": "Conectado a",
    "wifi_failed": "Conexão falhou. Verifique a senha e tente novamente.",
    "wifi_enter_password": "Por favor digite a senha do WiFi.",
    "show_log": "▶ Ver registro",
    "hide_log": "▼ Ocultar registro",
    },

    "Italiano": {
    "title": "madOS",
    "subtitle": "Arch Linux Orchestrato da IA | Powered by OpenCode",
    "features": [
        "Compressione ZRAM",
        "Compositore Sway",
        "Node.js + npm",
        "Chromium + VS Code",
        "Git preinstallato",
        "Ottimizzazione kernel",
        "Steam Deck ready",
        "Controller Xbox",
    ],
    "language": "Lingua:",
    "start_install": "Avvia Installazione",
    "exit": "Uscita",
    "select_disk": "Seleziona Disco",
    "warning": "ATTENZIONE: TUTTI I DATI SARANNO CANCELLATI",
    "layout": "Layout:",
    "back": "← Indietro",
    "next": "Avanti →",
    "partitioning": "Schema di Partizionamento",
    "disk_info": "Disco:",
    "sep_home_radio": "Partizione /home separata",
    "sep_home_title": "Partizione /home separata:",
    "sep_home_pro1": "Reinstallare SO senza perdere dati",
    "sep_home_pro2": "Migliore per i backup",
    "sep_home_con": "Meno flessibile con lo spazio",
    "all_root_radio": "Tutto in / (consigliato per <128GB)",
    "all_root_title": "Tutto in / (senza /home separato):",
    "all_root_pro1": "Massima flessibilità dello spazio",
    "all_root_pro2": "Migliore per dischi piccoli",
    "all_root_con": "La reinstallazione richiede backup",
    "efi_label": "EFI",
    "root_label": "Root",
    "home_label": "Home",
    "rest_label": "resto",
    "all_rest_label": "tutto il resto",
    "home_dir_label": "/home come directory",
    "create_user": "Crea Account Utente",
    "username": "Utente:",
    "pwd_label": "Password:",
    "pwd_confirm_label": "Conferma Password:",
    "hostname": "Nome host:",
    "regional": "Impostazioni Regionali",
    "timezone": "Fuso orario:",
    "locale_label": "Lingua del sistema:",
    "summary": "Riepilogo Installazione",
    "sys_config": "Configurazione Sistema:",
    "disk": "Disco:",
    "partitions": "Partizioni:",
    "software": "Software Incluso:",
    "software_list": "- Compositore Wayland Sway\n- Assistente IA OpenCode\n- Chromium, VS Code, Git\n- Strumenti sviluppo (Node.js, npm)\n- Ottimizzato per 1.9GB RAM",
    "start_install_btn": "Avvia Installazione",
    "installing": "Installazione madOS",
    "preparing": "Preparazione installazione...",
    "success_title": "Installazione Completata!",
    "success_msg": "Il sistema base madOS è stato installato!\n\n<b>Al primo avvio</b>, i pacchetti e le\nconfigurazioni rimanenti verranno installati automaticamente.\nRichiede connessione internet.\n\nProssimi passi:\n1. Rimuovere il supporto di installazione\n2. Riavviare il computer\n3. Attendere il completamento della configurazione iniziale\n4. Accedere con le tue credenziali\n5. Digita \"opencode\" per avviare l'assistente IA",
    "reboot_now": "Riavvia Ora",
    "exit_live": "Esci al Sistema Live",
    "wifi_setup": "Connessione Rete",
    "wifi_networks": "Reti Disponibili",
    "wifi_scan": "Cerca",
    "wifi_scanning": "Ricerca",
    "wifi_password": "Password:",
    "wifi_pass_placeholder": "Inserisci password WiFi",
    "wifi_connect": "Connetti",
    "wifi_skip": "Salta / Avanti →",
    "wifi_detecting": "Adattatore WiFi rilevato",
    "wifi_no_adapter": "Nessun adattatore WiFi rilevato — connetti via Ethernet",
    "wifi_no_networks": "Nessuna rete trovata. Prova a cercare di nuovo.",
    "wifi_connecting": "Connessione a",
    "wifi_connected": "Connesso a",
    "wifi_failed": "Connessione fallita. Verifica la password e riprova.",
    "wifi_enter_password": "Inserisci la password WiFi.",
    "show_log": "▶ Mostra log",
    "hide_log": "▼ Nascondi log",
    },

    "한국어": {
    "title": "madOS",
    "subtitle": "AI 오케스트레이션 Arch Linux | Powered by OpenCode",
    "features": [
        "ZRAM 압축",
        "Sway 컴포지터",
        "Node.js + npm",
        "Chromium + VS Code",
        "Git 사전 설치",
        "커널 튜닝",
        "Steam Deck ready",
        "Xbox 컨트롤러",
    ],
    "language": "언어:",
    "start_install": "설치 시작",
    "exit": "종료",
    "select_disk": "디스크 선택",
    "warning": "경고: 모든 데이터가 삭제됩니다",
    "layout": "레이아웃:",
    "back": "← 뒤로",
    "next": "다음 →",
    "partitioning": "파티션 구성",
    "disk_info": "디스크:",
    "sep_home_radio": "별도의 /home 파티션",
    "sep_home_title": "별도의 /home 파티션:",
    "sep_home_pro1": "데이터 손실 없이 OS 재설치",
    "sep_home_pro2": "백업에 더 좋음",
    "sep_home_con": "공간 유연성이 낮음",
    "all_root_radio": "모두 /에 (<128GB 권장)",
    "all_root_title": "모두 /에 (별도 /home 없음):",
    "all_root_pro1": "최대 공간 유연성",
    "all_root_pro2": "작은 디스크에 더 좋음",
    "all_root_con": "재설치 시 백업 필요",
    "efi_label": "EFI",
    "root_label": "루트",
    "home_label": "홈",
    "rest_label": "나머지",
    "all_rest_label": "모든 나머지",
    "home_dir_label": "/home를 디렉토리로",
    "create_user": "사용자 계정 생성",
    "username": "사용자명:",
    "pwd_label": "비밀번호:",
    "pwd_confirm_label": "비밀번호 확인:",
    "hostname": "호스트명:",
    "regional": "지역 설정",
    "timezone": "시간대:",
    "locale_label": "시스템 언어:",
    "summary": "설치 요약",
    "sys_config": "시스템 구성:",
    "disk": "디스크:",
    "partitions": "파티션:",
    "software": "포함된 소프트웨어:",
    "software_list": "- Sway Wayland 컴포지터\n- OpenCode AI 어시스턴트\n- Chromium, VS Code, Git\n- 개발 도구 (Node.js, npm)\n- 1.9GB RAM 최적화",
    "start_install_btn": "설치 시작",
    "installing": "madOS 설치 중",
    "preparing": "설치 준비 중...",
    "success_title": "설치 완료!",
    "success_msg": "madOS 기본 시스템이 설치되었습니다!\n\n<b>첫 부팅 시</b> 남은 패키지와\n구성이 자동으로 설치됩니다.\n인터넷 연결이 필요합니다.\n\n다음 단계:\n1. 설치 미디어 제거\n2. 컴퓨터 재부팅\n3. 초기 설정 완료 대기\n4. 자격 증명으로 로그인\n5. \"opencode\" 입력하여 AI 어시스턴트 시작",
    "reboot_now": "지금 재부팅",
    "exit_live": "Live 시스템으로 종료",
    "wifi_setup": "네트워크 연결",
    "wifi_networks": "사용 가능한 네트워크",
    "wifi_scan": "검색",
    "wifi_scanning": "검색 중",
    "wifi_password": "비밀번호:",
    "wifi_pass_placeholder": "WiFi 비밀번호 입력",
    "wifi_connect": "연결",
    "wifi_skip": "건너뛰기 / 다음 →",
    "wifi_detecting": "WiFi 어댑터 감지됨",
    "wifi_no_adapter": "WiFi 어댑터가 감지되지 않음 — 이더넷으로 연결",
    "wifi_no_networks": "네트워크를 찾을 수 없습니다. 다시 검색하세요.",
    "wifi_connecting": "연결 중",
    "wifi_connected": "연결됨",
    "wifi_failed": "연결 실패. 비밀번호를 확인하고 다시 시도하세요.",
    "wifi_enter_password": "WiFi 비밀번호를 입력하세요.",
    "show_log": "▶ 로그 표시",
    "hide_log": "▼ 로그 숨기기",
    },
}

# Default language
DEFAULT_LANGUAGE = "English"

# List of available languages
AVAILABLE_LANGUAGES = list(TRANSLATIONS.keys())


def detect_system_language():
    """Detect the system language from environment variables.

    Returns:
        The language name matching available translations, or 'English' as default.
    """
    import os
    import locale

    # Try to get locale from environment
    lang_code = None
    for var in ["LC_ALL", "LC_MESSAGES", "LANG", "LANGUAGE"]:
        lang_code = os.environ.get(var)
        if lang_code:
            break

    if not lang_code:
        try:
            lang_code, _ = locale.getdefaultlocale()
        except (OSError, ValueError):
            pass

    if not lang_code:
        return DEFAULT_LANGUAGE

    # Extract language prefix (e.g., 'es' from 'es_ES.UTF-8')
    lang_prefix = lang_code.split("_")[0].split(".")[0].lower()

    # Map language codes to translation keys
    lang_map = {
        "en": "English",
        "es": "Español",
        "fr": "Français",
        "de": "Deutsch",
        "zh": "中文",
        "ja": "日本語",
    }

    return lang_map.get(lang_prefix, DEFAULT_LANGUAGE)


def get_text(key, language=None):
    """Get translated text for a given key and language.

    Args:
        key: The translation key to look up.
        language: The language to use. Defaults to English if not specified
                  or if the key is not found in the specified language.

    Returns:
        The translated string, or the key itself if no translation is found.
    """
    if language is None:
        language = DEFAULT_LANGUAGE

    lang_dict = TRANSLATIONS.get(language, TRANSLATIONS[DEFAULT_LANGUAGE])
    return lang_dict.get(key, TRANSLATIONS[DEFAULT_LANGUAGE].get(key, key))


def get_preset_display_name(preset_key, language=None):
    """Get the localized display name for a built-in preset.

    Args:
        preset_key: The internal preset key (e.g., 'rock', 'jazz').
        language: The language to use for translation.

    Returns:
        The localized preset name string.
    """
    return get_text(preset_key, language)
