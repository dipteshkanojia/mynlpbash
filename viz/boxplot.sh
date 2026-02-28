#!/usr/bin/env bash
# boxplot.sh — Terminal box plot using box-drawing characters
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "boxplot" "Draw terminal box plot(s) from numeric data" \
        "boxplot.sh -i data.txt [--width 50]" \
        "-i, --input"     "Input file (one number per line or CSV)" \
        "-c, --column"    "Column index if CSV (default: 1)" \
        "--label"          "Label for the box plot" \
        "--width"          "Plot width in chars (default: 50)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COL=1 ; LABEL="data" ; WIDTH=50 ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COL="$2"; shift 2 ;;
        --label)        LABEL="$2"; shift 2 ;;
        --width)        WIDTH="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Extract and sort values
if [[ -n "$DELIM" ]] || head -1 "$INPUT" | grep -q '[,\t]'; then
    [[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")
    SORTED=$(awk -F"$DELIM" -v col="$COL" 'NR>1{v=$col; gsub(/^[ \t"]+|[ \t"]+$/, "", v); if(v+0==v) print v+0}' "$INPUT" | sort -n)
else
    SORTED=$(grep -v '^[[:space:]]*$' "$INPUT" | sort -n)
fi

N=$(echo "$SORTED" | wc -l | tr -d ' ')
MIN_V=$(echo "$SORTED" | head -1)
MAX_V=$(echo "$SORTED" | tail -1)
Q1=$(echo "$SORTED" | sed -n "$(( N * 25 / 100 + 1 ))p")
MEDIAN=$(echo "$SORTED" | sed -n "$(( (N + 1) / 2 ))p")
Q3=$(echo "$SORTED" | sed -n "$(( N * 75 / 100 + 1 ))p")
IQR=$(awk "BEGIN { print $Q3 - $Q1 }")
LOWER_W=$(awk "BEGIN { v = $Q1 - 1.5 * $IQR; print (v < $MIN_V) ? $MIN_V : v }")
UPPER_W=$(awk "BEGIN { v = $Q3 + 1.5 * $IQR; print (v > $MAX_V) ? $MAX_V : v }")

echo -e "${BOLD}═══ Box Plot ═══${NC}"
echo ""

# Scale positions to WIDTH
RANGE=$(awk "BEGIN { print $MAX_V - $MIN_V }")
[[ "$RANGE" == "0" ]] && RANGE=1
pos() { awk "BEGIN { printf \"%d\", ($1 - $MIN_V) / $RANGE * $WIDTH }"; }

P_LW=$(pos "$LOWER_W")
P_Q1=$(pos "$Q1")
P_MED=$(pos "$MEDIAN")
P_Q3=$(pos "$Q3")
P_UW=$(pos "$UPPER_W")

# Draw the box plot
printf "  %-10s " "$LABEL"
awk -v w="$WIDTH" -v lw="$P_LW" -v q1="$P_Q1" -v med="$P_MED" -v q3="$P_Q3" -v uw="$P_UW" '
BEGIN {
    for (i=0; i<=w; i++) {
        if (i == lw) c = "├"
        else if (i == uw) c = "┤"
        else if (i == med) c = "│"
        else if (i == q1 || i == q3) c = "│"
        else if (i > lw && i < q1) c = "─"
        else if (i > q1 && i < q3) c = "━"
        else if (i > q3 && i < uw) c = "─"
        else c = " "
        printf "%s", c
    }
    print ""
}'

# Scale labels
printf "  %10s " ""
awk -v w="$WIDTH" -v mn="$MIN_V" -v mx="$MAX_V" '
BEGIN {
    printf "%-*s%s\n", w, mn, mx
}'

echo ""
printf "  %-15s %s\n" "N:" "$N"
printf "  %-15s %s\n" "Min:" "$MIN_V"
printf "  %-15s %s\n" "Q1 (25th):" "$Q1"
printf "  %-15s %s\n" "Median:" "$MEDIAN"
printf "  %-15s %s\n" "Q3 (75th):" "$Q3"
printf "  %-15s %s\n" "Max:" "$MAX_V"
printf "  %-15s %s\n" "IQR:" "$IQR"
echo ""
