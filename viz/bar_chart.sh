#!/usr/bin/env bash
# bar_chart.sh — Standalone colored bar chart with labels
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "bar_chart" "Render labeled bar chart from label-value pairs" \
        "bar_chart.sh -i data.tsv  OR  echo 'label<TAB>value' | bar_chart.sh" \
        "-i, --input"     "Input file (label<TAB>value per line)" \
        "--width"          "Max bar width (default: 40)" \
        "--color"          "Bar color: green, blue, red, yellow, cyan (default: green)" \
        "--sort"           "Sort: value, label, none (default: none)" \
        "--title"          "Chart title" \
        "-h, --help"      "Show this help"
}

INPUT="" ; WIDTH=40 ; COLOR="green" ; SORT="none" ; TITLE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) INPUT="$2"; shift 2 ;;
        --width)    WIDTH="$2"; shift 2 ;;
        --color)    COLOR="$2"; shift 2 ;;
        --sort)     SORT="$2"; shift 2 ;;
        --title)    TITLE="$2"; shift 2 ;;
        -h|--help)  show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

case "$COLOR" in
    green)  BAR_COLOR="$GREEN" ;;
    blue)   BAR_COLOR="$BLUE" ;;
    red)    BAR_COLOR="$RED" ;;
    yellow) BAR_COLOR="$YELLOW" ;;
    cyan)   BAR_COLOR="$CYAN" ;;
    *)      BAR_COLOR="$GREEN" ;;
esac

DATA=""
if [[ -n "$INPUT" ]]; then
    require_file "$INPUT"
    DATA=$(cat "$INPUT")
else
    DATA=$(cat)
fi

case "$SORT" in
    value) DATA=$(echo "$DATA" | sort -t$'\t' -k2 -rn) ;;
    label) DATA=$(echo "$DATA" | sort -t$'\t' -k1) ;;
esac

[[ -n "$TITLE" ]] && echo -e "${BOLD}$TITLE${NC}" && echo ""

MAX_VAL=$(echo "$DATA" | awk -F'\t' '{if($2+0 > m) m=$2+0} END{print m}')

echo "$DATA" | awk -F'\t' -v max_val="$MAX_VAL" -v width="$WIDTH" -v bar_color="'"$BAR_COLOR"'" -v nc="'"$NC"'" '
{
    label = $1; val = $2 + 0
    bar_len = (max_val > 0) ? int(val * width / max_val) : 0
    bar = ""
    for (i=0; i<bar_len; i++) bar = bar "█"
    printf "  %-20s %8.0f %s%s%s\n", label, val, bar_color, bar, nc
}'
echo ""
