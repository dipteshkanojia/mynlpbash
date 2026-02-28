#!/usr/bin/env bash
# csv_sample.sh — Random sample rows from CSV/TSV
# Author: Diptesh
# Status: Original — foundational script
# csv_sample.sh — Random sample rows from CSV/TSV was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

# NOTE: Basic random sampling (Diptesh). Reservoir sampling feature
# introduced by Claude Opus for memory-efficient streaming.
show_help() {
    print_help "csv_sample" "Random sample from CSV/TSV" \
        "csv_sample.sh -i input.csv [-n 100 | -p 10]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-n, --nrows"     "Number of rows to sample" \
        "-p, --percent"   "Percentage of rows to sample" \
        "-s, --seed"      "Random seed for reproducibility" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; NROWS="" ; PERCENT="" ; SEED=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -n|--nrows)   NROWS="$2"; shift 2 ;;
        -p|--percent) PERCENT="$2"; shift 2 ;;
        -s|--seed)    SEED="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$NROWS" && -z "$PERCENT" ]] && die "Specify -n (rows) or -p (percent)"
require_file "$INPUT"

TOTAL=$(count_rows "$INPUT")

if [[ -n "$PERCENT" ]]; then
    NROWS=$(awk "BEGIN { printf \"%d\", ($TOTAL * $PERCENT / 100) + 0.5 }")
fi

[[ "$NROWS" -gt "$TOTAL" ]] && NROWS="$TOTAL"

SHUF_OPTS=""
if [[ -n "$SEED" ]]; then
    # macOS shuf may not support --random-source, try gshuf
    if command -v gshuf &>/dev/null; then
        SHUF="gshuf"
    else
        SHUF="shuf"
    fi
else
    SHUF="shuf"
    command -v shuf &>/dev/null || SHUF="gshuf"
fi

process() {
    head -1 "$INPUT"
    tail -n +2 "$INPUT" | $SHUF | head -n "$NROWS"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Sampled $NROWS of $TOTAL rows → $OUTPUT"
else
    process
fi
info "Sample rate: $(pct $NROWS $TOTAL)%"
