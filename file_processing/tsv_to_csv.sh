#!/usr/bin/env bash
# tsv_to_csv.sh — Convert TSV files to CSV format
# Author: Diptesh
# Status: Original — foundational script
# tsv_to_csv.sh — Convert TSV files to CSV format was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "tsv_to_csv" "Convert TSV to CSV format" \
        "tsv_to_csv.sh -i input.tsv [-o output.csv]" \
        "-i, --input"    "Input TSV file (or stdin)" \
        "-o, --output"   "Output CSV file (default: stdout)" \
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
    awk -F'\t' -v OFS=',' '{
        for (i=1; i<=NF; i++) {
            if ($i ~ /[,"\n]/) {
                gsub(/"/, "\"\"", $i)
                $i = "\"" $i "\""
            }
        }
        print
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
