#!/usr/bin/env bash
# line_length_stats.sh — Statistics on line lengths (chars and tokens)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "line_length_stats" "Statistics on line lengths (characters and tokens)" \
        "line_length_stats.sh -i corpus.txt" \
        "-i, --input"   "Input text file" \
        "--chars"        "Measure in characters (default)" \
        "--tokens"       "Measure in tokens (whitespace-separated)" \
        "--histogram"    "Show length histogram" \
        "--bins"         "Number of histogram bins (default: 10)" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; MODE="chars" ; HISTOGRAM=0 ; BINS=10
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)    INPUT="$2"; shift 2 ;;
        --chars)       MODE="chars"; shift ;;
        --tokens)      MODE="tokens"; shift ;;
        --histogram)   HISTOGRAM=1; shift ;;
        --bins)        BINS="$2"; shift 2 ;;
        -o|--output)   OUTPUT="$2"; shift 2 ;;
        -h|--help)     show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    echo -e "${BOLD}═══ Line Length Statistics ($MODE) ═══${NC}"
    echo ""

    # Compute lengths and sort them
    local SORTED_LENS
    if [[ "$MODE" == "chars" ]]; then
        SORTED_LENS=$(awk '{ print length($0) }' "$INPUT" | sort -n)
    else
        SORTED_LENS=$(awk '{ print NF }' "$INPUT" | sort -n)
    fi
    
    local COUNT=$(echo "$SORTED_LENS" | wc -l | tr -d ' ')
    local MIN=$(echo "$SORTED_LENS" | head -1)
    local MAX=$(echo "$SORTED_LENS" | tail -1)
    local TOTAL=$(echo "$SORTED_LENS" | awk '{s+=$1} END {print s}')
    local AVG=$(awk "BEGIN { printf \"%.1f\", $TOTAL / $COUNT }")
    
    # Median
    local MED_POS=$(( (COUNT + 1) / 2 ))
    local MEDIAN=$(echo "$SORTED_LENS" | sed -n "${MED_POS}p")
    
    # Percentiles
    local P25=$(echo "$SORTED_LENS" | sed -n "$(( COUNT * 25 / 100 + 1 ))p")
    local P75=$(echo "$SORTED_LENS" | sed -n "$(( COUNT * 75 / 100 + 1 ))p")
    local P90=$(echo "$SORTED_LENS" | sed -n "$(( COUNT * 90 / 100 + 1 ))p")
    local P95=$(echo "$SORTED_LENS" | sed -n "$(( COUNT * 95 / 100 + 1 ))p")
    local P99=$(echo "$SORTED_LENS" | sed -n "$(( COUNT * 99 / 100 + 1 ))p")
    
    # Std Dev
    local STDDEV=$(echo "$SORTED_LENS" | awk -v avg="$AVG" '{
        diff = $1 - avg; sum_sq += diff * diff
    } END { printf "%.1f", sqrt(sum_sq / NR) }')
    
    printf "  %-15s %d\n" "Count:" "$COUNT"
    printf "  %-15s %d\n" "Min:" "$MIN"
    printf "  %-15s %d\n" "Max:" "$MAX"
    printf "  %-15s %s\n" "Mean:" "$AVG"
    printf "  %-15s %s\n" "Median:" "$MEDIAN"
    printf "  %-15s %s\n" "Std Dev:" "$STDDEV"
    printf "  %-15s %s\n" "P25:" "$P25"
    printf "  %-15s %s\n" "P75:" "$P75"
    printf "  %-15s %s\n" "P90:" "$P90"
    printf "  %-15s %s\n" "P95:" "$P95"
    printf "  %-15s %s\n" "P99:" "$P99"
    
    if [[ $HISTOGRAM -eq 1 ]]; then
        echo ""
        echo "  Length Distribution:"
        echo ""
        local BIN_SIZE=$(( (MAX - MIN + BINS) / BINS ))
        [[ $BIN_SIZE -lt 1 ]] && BIN_SIZE=1
        
        echo "$SORTED_LENS" | awk -v min="$MIN" -v bin_size="$BIN_SIZE" -v bins="$BINS" '
        {
            b = int(($1 - min) / bin_size)
            if (b >= bins) b = bins - 1
            histogram[b]++
            if (histogram[b] > hist_max) hist_max = histogram[b]
        }
        END {
            for (b=0; b<bins; b++) {
                lo = min + b * bin_size
                hi = lo + bin_size - 1
                c = histogram[b] + 0
                bar_len = (hist_max > 0) ? int(c * 30 / hist_max) : 0
                bar = ""
                for (j=0; j<bar_len; j++) bar = bar "#"
                printf "  [%4d-%4d] %5d %s\n", lo, hi, c, bar
            }
        }'
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Line length stats → $OUTPUT"
else
    process
fi
