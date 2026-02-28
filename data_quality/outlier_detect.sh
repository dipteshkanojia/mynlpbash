#!/usr/bin/env bash
# outlier_detect.sh — Detect outliers by text length using IQR method
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "outlier_detect" "Detect outliers by text length (IQR method)" \
        "outlier_detect.sh -i data.csv -c text [--factor 1.5]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Text column (name or index)" \
        "--factor"         "IQR multiplier (default: 1.5)" \
        "--by"             "Measure by: chars, tokens (default: tokens)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; FACTOR="1.5" ; BY="tokens" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        --factor)       FACTOR="$2"; shift 2 ;;
        --by)           BY="$2"; shift 2 ;;
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

echo -e "${BOLD}═══ Outlier Detection (IQR, factor=$FACTOR, by=$BY) ═══${NC}"
echo ""

# Extract lengths and sort
SORTED_LENS=$(awk -F"$DELIM" -v col="$COL_IDX" -v by="$BY" '
NR==1 { next }
{
    val = $col; gsub(/^"|"$/, "", val)
    if (by == "chars") print length(val)
    else print split(val, w, /[[:space:]]+/)
}' "$INPUT" | sort -n)

COUNT=$(echo "$SORTED_LENS" | wc -l | tr -d ' ')
Q1_POS=$(( COUNT * 25 / 100 + 1 ))
Q3_POS=$(( COUNT * 75 / 100 + 1 ))
MED_POS=$(( (COUNT + 1) / 2 ))
Q1=$(echo "$SORTED_LENS" | sed -n "${Q1_POS}p")
Q3=$(echo "$SORTED_LENS" | sed -n "${Q3_POS}p")
MEDIAN=$(echo "$SORTED_LENS" | sed -n "${MED_POS}p")
IQR=$(( Q3 - Q1 ))

LOWER=$(awk "BEGIN { v = $Q1 - $FACTOR * $IQR; printf \"%.0f\", (v < 0) ? 0 : v }")
UPPER=$(awk "BEGIN { printf \"%.0f\", $Q3 + $FACTOR * $IQR }")

SHORT=$(echo "$SORTED_LENS" | awk -v fence="$LOWER" '$1 < fence' | wc -l | tr -d ' ')
LONG=$(echo "$SORTED_LENS" | awk -v fence="$UPPER" '$1 > fence' | wc -l | tr -d ' ')
TOTAL_OUTLIERS=$(( SHORT + LONG ))

printf "  %-20s %d\n" "Total samples:" "$COUNT"
printf "  %-20s %d\n" "Q1 (25th pct):" "$Q1"
printf "  %-20s %d\n" "Median:" "$MEDIAN"
printf "  %-20s %d\n" "Q3 (75th pct):" "$Q3"
printf "  %-20s %d\n" "IQR:" "$IQR"
printf "  %-20s %s\n" "Lower fence:" "$LOWER"
printf "  %-20s %s\n" "Upper fence:" "$UPPER"
echo ""
printf "  Short outliers (<%s): %d\n" "$LOWER" "$SHORT"
printf "  Long outliers (>%s):  %d\n" "$UPPER" "$LONG"
printf "  Total outliers:       %d (%.1f%%)\n" "$TOTAL_OUTLIERS" "$(pct $TOTAL_OUTLIERS $COUNT)"
echo ""
