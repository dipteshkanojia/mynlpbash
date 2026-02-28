#!/usr/bin/env bash
# progress_dashboard.sh — Live-updating dashboard for batch processing
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "progress_dashboard" "Live-updating progress dashboard for pipeline monitoring" \
        "progress_dashboard.sh --total 100 --label 'Processing files'" \
        "--total"         "Total items to process" \
        "--label"          "Progress label (default: Processing)" \
        "--log"            "Log file to tail for status updates" \
        "--width"          "Progress bar width (default: 40)" \
        "-h, --help"      "Show this help"
}

TOTAL=100 ; LABEL="Processing" ; LOG_FILE="" ; BAR_WIDTH=40
while [[ $# -gt 0 ]]; do
    case "$1" in
        --total)  TOTAL="$2"; shift 2 ;;
        --label)  LABEL="$2"; shift 2 ;;
        --log)    LOG_FILE="$2"; shift 2 ;;
        --width)  BAR_WIDTH="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

# This script reads current progress from stdin (one number per update)
# Usage: for i in $(seq 1 100); do echo $i; sleep 0.1; done | progress_dashboard.sh --total 100

draw_bar() {
    local current="$1" total="$2" width="$3" label="$4"
    local pct=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local elapsed="$5"
    
    # ETA calculation
    local eta=""
    if [[ "$current" -gt 0 && -n "$elapsed" ]]; then
        local rate=$(awk "BEGIN { printf \"%.2f\", $current / $elapsed }")
        local remaining=$(awk "BEGIN { r = ($total - $current) / ($current / $elapsed); printf \"%.0f\", r }")
        eta="ETA: ${remaining}s"
    fi
    
    printf "\r  ${BOLD}%s${NC} [" "$label"
    printf "${GREEN}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${NC}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] %3d%% (%d/%d) %s  " "$pct" "$current" "$total" "$eta"
}

START_TIME=$(date +%s)

while IFS= read -r line; do
    CURRENT=$(echo "$line" | tr -d '[:space:]')
    [[ "$CURRENT" =~ ^[0-9]+$ ]] || continue
    NOW=$(date +%s)
    ELAPSED=$(( NOW - START_TIME ))
    [[ $ELAPSED -lt 1 ]] && ELAPSED=1
    draw_bar "$CURRENT" "$TOTAL" "$BAR_WIDTH" "$LABEL" "$ELAPSED"
    
    if [[ "$CURRENT" -ge "$TOTAL" ]]; then
        echo ""
        success "$LABEL complete: $TOTAL items in ${ELAPSED}s"
        break
    fi
done
