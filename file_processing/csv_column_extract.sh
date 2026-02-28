#!/usr/bin/env bash
# csv_column_extract.sh — Extract specific columns from CSV/TSV
# Author: Diptesh
# Status: Original — foundational script
# csv_column_extract.sh — Extract specific columns from CSV/TSV was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_column_extract" "Extract specific columns by name or index" \
        "csv_column_extract.sh -i input.csv -c 'col1,col2' [-o output.csv]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --columns"   "Columns to extract (names or indices, comma-separated)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; COLUMNS="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--columns)   COLUMNS="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMNS" ]] && die "Columns required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

# Resolve column names to indices
COL_INDICES=""
IFS=',' read -ra COL_LIST <<< "$COLUMNS"
for col in "${COL_LIST[@]}"; do
    col=$(echo "$col" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ "$col" =~ ^[0-9]+$ ]]; then
        COL_INDICES="${COL_INDICES:+$COL_INDICES,}$col"
    else
        idx=$(find_column_index "$INPUT" "$col" "$DELIM")
        [[ -z "$idx" ]] && die "Column not found: $col"
        COL_INDICES="${COL_INDICES:+$COL_INDICES,}$idx"
    fi
done

process() {
    awk -F"$DELIM" -v OFS="$DELIM" -v cols="$COL_INDICES" '
    BEGIN { n = split(cols, c, ",") }
    {
        for (i=1; i<=n; i++) {
            if (i > 1) printf "%s", OFS
            printf "%s", $c[i]
        }
        print ""
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Extracted columns [$COLUMNS] → $OUTPUT"
else
    process
fi
