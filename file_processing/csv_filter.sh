#!/usr/bin/env bash
# csv_filter.sh — Filter CSV/TSV rows by column value
# Author: Diptesh
# Status: Original — foundational script
# csv_filter.sh — Filter CSV/TSV rows by column value was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_filter" "Filter rows by column value (regex, equals, comparison)" \
        "csv_filter.sh -i input.csv -c label -m 'positive'" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Column name or index to filter on" \
        "-m, --match"     "Value to match (exact match)" \
        "-r, --regex"     "Regex pattern to match" \
        "-v, --invert"    "Invert match (exclude matching rows)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "--gt VALUE"      "Greater than (numeric)" \
        "--lt VALUE"      "Less than (numeric)" \
        "--gte VALUE"     "Greater than or equal (numeric)" \
        "--lte VALUE"     "Less than or equal (numeric)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; COLUMN="" ; MATCH="" ; REGEX="" ; DELIM=""
INVERT=0 ; GT="" ; LT="" ; GTE="" ; LTE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -m|--match)     MATCH="$2"; shift 2 ;;
        -r|--regex)     REGEX="$2"; shift 2 ;;
        -v|--invert)    INVERT=1; shift ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        --gt)           GT="$2"; shift 2 ;;
        --lt)           LT="$2"; shift 2 ;;
        --gte)          GTE="$2"; shift 2 ;;
        --lte)          LTE="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Column required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

# Resolve column
if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

process() {
    awk -F"$DELIM" -v OFS="$DELIM" -v col="$COL_IDX" \
        -v match="$MATCH" -v regex="$REGEX" -v invert="$INVERT" \
        -v gt="$GT" -v lt="$LT" -v gte="$GTE" -v lte="$LTE" '
    NR==1 { print; next }
    {
        val = $col
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        gsub(/^"|"$/, "", val)
        matched = 0
        if (match != "" && val == match) matched = 1
        if (regex != "" && val ~ regex) matched = 1
        if (gt != "" && val+0 > gt+0) matched = 1
        if (lt != "" && val+0 < lt+0) matched = 1
        if (gte != "" && val+0 >= gte+0) matched = 1
        if (lte != "" && val+0 <= lte+0) matched = 1
        if (invert) matched = !matched
        if (matched) print
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    rows=$(( $(wc -l < "$OUTPUT" | tr -d ' ') - 1 ))
    success "Filtered: $rows matching rows → $OUTPUT"
else
    process
fi
