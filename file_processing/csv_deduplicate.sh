#!/usr/bin/env bash
# csv_deduplicate.sh — Remove duplicate rows from CSV/TSV
# Author: Diptesh
# Status: Original — foundational script
# csv_deduplicate.sh — Remove duplicate rows from CSV/TSV was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_deduplicate" "Remove duplicate rows from CSV/TSV" \
        "csv_deduplicate.sh -i input.csv [-c column] [-o output.csv]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Deduplicate based on this column only (name or index)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "--keep"          "Which duplicate to keep: first, last (default: first)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; COLUMN="" ; DELIM="" ; KEEP="first"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        --keep)         KEEP="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

BEFORE=$(count_rows "$INPUT")

if [[ -n "$COLUMN" ]]; then
    if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
        COL_IDX="$COLUMN"
    else
        COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
        [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
    fi
    process() {
        awk -F"$DELIM" -v col="$COL_IDX" 'NR==1 {print; next} !seen[$col]++ {print}' "$INPUT"
    }
else
    process() {
        awk 'NR==1 {print; next} !seen[$0]++' "$INPUT"
    }
fi

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    AFTER=$(count_rows "$OUTPUT")
    REMOVED=$(( BEFORE - AFTER ))
    success "Deduplicated: $BEFORE → $AFTER rows ($REMOVED duplicates removed) → $OUTPUT"
else
    process
fi
