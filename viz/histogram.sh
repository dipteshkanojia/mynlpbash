#!/usr/bin/env bash
# histogram.sh — Terminal histogram from numeric data
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "histogram" "Draw terminal histogram from a column of numbers" \
        "histogram.sh -i data.txt [--bins 10] [--horizontal]" \
        "-i, --input"     "Input file (one number per line or CSV column)" \
        "-c, --column"    "Column index if CSV (default: 1)" \
        "--bins"           "Number of bins (default: 10)" \
        "--horizontal"     "Horizontal bars (default)" \
        "--vertical"       "Vertical bars" \
        "--width"          "Bar width in chars (default: 40)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COL=1 ; BINS=10 ; ORIENT="horizontal" ; WIDTH=40 ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COL="$2"; shift 2 ;;
        --bins)         BINS="$2"; shift 2 ;;
        --horizontal)   ORIENT="horizontal"; shift ;;
        --vertical)     ORIENT="vertical"; shift ;;
        --width)        WIDTH="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Extract numeric values
if [[ -n "$DELIM" ]] || head -1 "$INPUT" | grep -q '[,\t]'; then
    [[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")
    VALUES=$(awk -F"$DELIM" -v col="$COL" 'NR>1{v=$col; gsub(/^[ \t"]+|[ \t"]+$/, "", v); if(v+0==v) print v+0}' "$INPUT" | sort -n)
else
    VALUES=$(grep -v '^[[:space:]]*$' "$INPUT" | sort -n)
fi

COUNT=$(echo "$VALUES" | wc -l | tr -d ' ')
MIN_V=$(echo "$VALUES" | head -1)
MAX_V=$(echo "$VALUES" | tail -1)

echo -e "${BOLD}═══ Histogram ($BINS bins) ═══${NC}"
echo ""

echo "$VALUES" | awk -v bins="$BINS" -v min_v="$MIN_V" -v max_v="$MAX_V" -v width="$WIDTH" -v orient="$ORIENT" '
BEGIN {
    range = max_v - min_v
    if (range == 0) range = 1
    bin_size = range / bins
}
{
    b = int(($1 - min_v) / bin_size)
    if (b >= bins) b = bins - 1
    hist[b]++
    if (hist[b] > max_count) max_count = hist[b]
}
END {
    if (orient == "horizontal") {
        for (b=0; b<bins; b++) {
            lo = min_v + b * bin_size
            hi = lo + bin_size
            c = hist[b] + 0
            bar_len = (max_count > 0) ? int(c * width / max_count) : 0
            bar = ""
            for (j=0; j<bar_len; j++) bar = bar "█"
            printf "  [%7.1f - %7.1f] %5d %s\n", lo, hi, c, bar
        }
    } else {
        # Vertical: print top-down
        for (row=max_count; row>=1; row--) {
            printf "  "
            for (b=0; b<bins; b++) {
                if (hist[b]+0 >= row) printf " ██"
                else printf "   "
            }
            print ""
        }
        printf "  "
        for (b=0; b<bins; b++) printf "───"
        print ""
        printf "  "
        for (b=0; b<bins; b++) {
            lo = min_v + b * bin_size
            printf "%3d", lo
        }
        print ""
    }
    printf "\n  Total: %d | Range: [%.1f, %.1f] | Bin size: %.2f\n", NR, min_v, max_v, bin_size
}'
echo ""
