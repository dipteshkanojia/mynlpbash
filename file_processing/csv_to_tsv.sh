#!/usr/bin/env bash
# csv_to_tsv.sh — Convert CSV files to TSV format
# Author: Diptesh
# Status: Original — foundational script
# csv_to_tsv.sh — Convert CSV files to TSV format was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_to_tsv" "Convert CSV to TSV format" \
        "csv_to_tsv.sh -i input.csv [-o output.tsv]" \
        "-i, --input"    "Input CSV file (or stdin)" \
        "-o, --output"   "Output TSV file (default: stdout)" \
        "-h, --help"     "Show this help"
}

INPUT="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

process() {
    awk -v FPAT='([^,]*)|("[^"]*")' -v OFS='\t' '{
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/""/, "\"", $i)
        }
        $1=$1; print
    }'
}

if [[ -n "$INPUT" ]]; then
    require_file "$INPUT"
    if [[ -n "$OUTPUT" ]]; then
        process < "$INPUT" > "$OUTPUT"
        success "Converted $(wc -l < "$INPUT" | tr -d ' ') lines → $OUTPUT"
    else
        process < "$INPUT"
    fi
else
    process
fi
