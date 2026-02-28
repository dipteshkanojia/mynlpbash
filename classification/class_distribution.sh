#!/usr/bin/env bash
# class_distribution.sh — Show class distribution with bar chart
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "class_distribution" "Show class counts, percentages, and bar chart" \
        "class_distribution.sh -i data.csv -c label" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Label column (name or index)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Column required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

TOTAL=$(count_rows "$INPUT")

echo -e "${BOLD}═══ Class Distribution ═══${NC}"
echo ""
printf "  %-15s %s\n" "File:" "$(basename "$INPUT")"
printf "  %-15s %s\n" "Total samples:" "$(format_number $TOTAL)"
printf "  %-15s %s\n" "Label column:" "$COLUMN (col $COL_IDX)"
echo ""

# Extract labels, count, sort
LABEL_COUNTS=$(awk -F"$DELIM" -v col="$COL_IDX" '
NR == 1 { next }
{
    val = $col
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    gsub(/^"|"$/, "", val)
    counts[val]++
}
END {
    for (c in counts) print counts[c] "\t" c
}' "$INPUT" | sort -rn)

MAX_COUNT=$(echo "$LABEL_COUNTS" | head -1 | awk '{print $1}')
MIN_COUNT=$(echo "$LABEL_COUNTS" | tail -1 | awk '{print $1}')
NUM_CLASSES=$(echo "$LABEL_COUNTS" | wc -l | tr -d ' ')

printf "  %-20s %8s %7s   %s\n" "Label" "Count" "%" "Distribution"
printf "  %-20s %8s %7s   %s\n" "─────" "─────" "───" "────────────"

echo "$LABEL_COUNTS" | while IFS=$'\t' read -r count label; do
    pct=$(awk "BEGIN { printf \"%.1f\", $count * 100 / $TOTAL }")
    bar_len=$(( count * 35 / MAX_COUNT ))
    bar=$(printf '█%.0s' $(seq 1 "$bar_len" 2>/dev/null) || true)
    printf "  %-20s %8d %6s%%   %s\n" "$label" "$count" "$pct" "$bar"
done

echo ""
RATIO=$(awk "BEGIN { printf \"%.1f\", $MAX_COUNT / $MIN_COUNT }")
printf "  Classes: %d | Imbalance ratio: %s:1\n" "$NUM_CLASSES" "$RATIO"
echo ""
