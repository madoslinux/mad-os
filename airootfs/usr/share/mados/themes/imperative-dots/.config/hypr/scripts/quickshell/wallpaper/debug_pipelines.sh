#!/usr/bin/env bash

# ==============================================================================
# EXTENSIVE DEBUG SCRIPT FOR DDG WALLPAPER PIPELINE
# ==============================================================================

# Setup Master Log and tee all output to both console and file
MASTER_LOG="/tmp/ddg_pipeline_master_debug.log"
> "$MASTER_LOG" # Clear previous master log
exec > >(tee -a "$MASTER_LOG") 2>&1

echo "======================================================================"
echo "  [START] DDG PIPELINE DIAGNOSTIC RUN"
echo "  Time: $(date)"
echo "======================================================================"

# Define paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PY_SCRIPT="$SCRIPT_DIR/get_ddg_links.py"
SH_SCRIPT="$SCRIPT_DIR/ddg_search.sh"

CACHE_DIR="$HOME/.cache/wallpaper_picker"
SEARCH_DIR="$CACHE_DIR/search_thumbs"
MAP_FILE="$CACHE_DIR/search_map.txt"

CONTROL_FILE="/tmp/ddg_search_control"
PY_LOG="/tmp/qs_python_scraper.log"
SH_LOG="/tmp/qs_ddg_downloader.log"

TEST_QUERY="test debug nature"

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 1: SYSTEM & DEPENDENCY CHECKS ---"
# ------------------------------------------------------------------------------
commands=("python3" "curl" "bash")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[OK] Command found: $cmd ($(command -v "$cmd"))"
    else
        echo "[FAIL] Missing required command: $cmd"
        exit 1
    fi
done

# Check Internet Connectivity to DDG
if curl -s -I "https://duckduckgo.com" > /dev/null; then
    echo "[OK] Internet connectivity to duckduckgo.com verified."
else
    echo "[FAIL] Cannot reach duckduckgo.com. Network issue?"
fi

# Check Script Existence and Permissions
if [ -f "$PY_SCRIPT" ]; then
    echo "[OK] Python script found at $PY_SCRIPT"
    [ -x "$PY_SCRIPT" ] || chmod +x "$PY_SCRIPT"
else
    echo "[FAIL] Python script not found at $PY_SCRIPT"
    exit 1
fi

if [ -f "$SH_SCRIPT" ]; then
    echo "[OK] Bash script found at $SH_SCRIPT"
    [ -x "$SH_SCRIPT" ] || chmod +x "$SH_SCRIPT"
else
    echo "[FAIL] Bash script not found at $SH_SCRIPT"
    exit 1
fi

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 2: ENVIRONMENT CLEANUP ---"
# ------------------------------------------------------------------------------
echo "Cleaning up old cache and logs to ensure a fresh test..."
rm -rf "$SEARCH_DIR"
rm -f "$MAP_FILE" "$CONTROL_FILE" "$PY_LOG" "$SH_LOG"
echo "[OK] Old files removed."

# Create required control file for starting state
echo "run" > "$CONTROL_FILE"
echo "[OK] Control file initialized with 'run'."

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 3: ISOLATED PYTHON SCRAPER TEST ---"
# ------------------------------------------------------------------------------
echo "Running get_ddg_links.py directly with query: '$TEST_QUERY'..."
echo "Only fetching the first 3 results to verify stdout format..."

# Run python script, capture first 3 lines of output
PY_OUTPUT=$(timeout 15s python3 "$PY_SCRIPT" "$TEST_QUERY" | head -n 3)
PY_EXIT=$?

if [ $PY_EXIT -eq 124 ]; then
    echo "[WARNING] Python script timed out after 15 seconds."
elif [ -n "$PY_OUTPUT" ]; then
    echo "[OK] Python script generated output:"
    echo "$PY_OUTPUT" | while read -r line; do
        echo "  -> $line"
    done
else
    echo "[FAIL] Python script returned no standard output."
fi

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 4: FULL PIPELINE INTEGRATION TEST ---"
# ------------------------------------------------------------------------------
echo "Running ddg_search.sh in the background..."
rm -f "$CONTROL_FILE"; echo "run" > "$CONTROL_FILE"

# Start the pipeline
"$SH_SCRIPT" "$TEST_QUERY" &
SH_PID=$!
echo "[INFO] Bash script started with PID: $SH_PID"

# Let it run for 10 seconds to download some files
echo "Waiting 10 seconds to allow downloads..."
sleep 10

# Test Pause functionality
echo "pause" > "$CONTROL_FILE"
echo "[INFO] Sent 'pause' signal via control file. Waiting 3 seconds..."
sleep 3

# Test Stop functionality
echo "stop" > "$CONTROL_FILE"
echo "[INFO] Sent 'stop' signal via control file. Waiting for process to exit..."

# Wait for process to cleanly exit
wait $SH_PID 2>/dev/null
echo "[OK] Pipeline process ($SH_PID) has terminated."

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 5: DIRECTORY & OUTPUT ANALYSIS ---"
# ------------------------------------------------------------------------------
echo "Checking Output Directories..."

if [ -d "$SEARCH_DIR" ]; then
    FILE_COUNT=$(find "$SEARCH_DIR" -maxdepth 1 -type f | wc -l)
    echo "[OK] Cache directory exists: $SEARCH_DIR"
    echo "[INFO] Downloaded $FILE_COUNT image(s)."
    ls -lh "$SEARCH_DIR" | awk '{print "  -> " $9, $5}' | grep -v "^\s*->\s*$"
else
    echo "[FAIL] Cache directory was not created: $SEARCH_DIR"
fi

echo "Checking Map File ($MAP_FILE)..."
if [ -f "$MAP_FILE" ]; then
    LINE_COUNT=$(wc -l < "$MAP_FILE")
    echo "[OK] Map file exists. Contains $LINE_COUNT entries."
    head -n 5 "$MAP_FILE" | awk '{print "  -> " $0}'
else
    echo "[FAIL] Map file does not exist."
fi

# ------------------------------------------------------------------------------
echo -e "\n--- PHASE 6: FULL LOG DUMP ---"
# ------------------------------------------------------------------------------

echo ">>> DUMPING PYTHON LOG: $PY_LOG <<<"
if [ -f "$PY_LOG" ]; then
    cat "$PY_LOG"
else
    echo "[NO LOG FILE FOUND AT $PY_LOG]"
fi
echo ">>> END PYTHON LOG <<<"

echo ""

echo ">>> DUMPING BASH LOG: $SH_LOG <<<"
if [ -f "$SH_LOG" ]; then
    cat "$SH_LOG"
else
    echo "[NO LOG FILE FOUND AT $SH_LOG]"
fi
echo ">>> END BASH LOG <<<"

echo "======================================================================"
echo "  [FINISH] DIAGNOSTIC RUN COMPLETE"
echo "  All output has been saved to: $MASTER_LOG"
echo "======================================================================"
