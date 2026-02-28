#!/usr/bin/env bash
# csv_sort.sh — Sort CSV/TSV file by one or more columns
# Author: Diptesh
# Status: Original — foundational script
# csv_sort.sh — Sort CSV/TSV file by one or more columns was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_sort" "Sort CSV/TSV by column(s)" \
        "csv_sort.sh -i input.csv -c 'label' [-n] [-r]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Column name or index to sort by" \
        "-n, --numeric"   "Numeric sort" \
        "-r, --reverse"   "Reverse (descending) sort" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; COLUMN="" ; DELIM="" ; NUMERIC=0 ; REVERSE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -n|--numeric)   NUMERIC=1; shift ;;
        -r|--reverse)   REVERSE=1; shift ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
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

SORT_OPTS="-t${DELIM} -k${COL_IDX},${COL_IDX}"
[[ "$NUMERIC" -eq 1 ]] && SORT_OPTS="$SORT_OPTS -n"
[[ "$REVERSE" -eq 1 ]] && SORT_OPTS="$SORT_OPTS -r"

process() {
    head -1 "$INPUT"
    tail -n +2 "$INPUT" | sort $SORT_OPTS
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Sorted by column $COLUMN → $OUTPUT"
else
    process
fi
