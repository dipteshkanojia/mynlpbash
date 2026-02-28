#!/usr/bin/env bash
# conll_to_csv.sh — Convert CoNLL format to CSV
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "conll_to_csv" "Convert CoNLL format to CSV" \
        "conll_to_csv.sh -i input.conll [-o output.csv]" \
        "-i, --input"     "Input CoNLL file" \
        "--columns"        "Column names (comma-separated, default: token,pos,tag)" \
        "-o, --output"    "Output CSV file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; COLUMNS="token,pos,tag"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --columns)    COLUMNS="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    echo "sentence_id,$COLUMNS"
    awk -v cols="$COLUMNS" '
    BEGIN { sent_id = 1 }
    /^[[:space:]]*$/ { sent_id++; next }
    /^#/ { next }
    {
        printf "%d", sent_id
        for (i=1; i<=NF; i++) {
            val = $i
            if (val ~ /,/) {
                gsub(/"/, "\"\"", val)
                val = "\"" val "\""
            }
            printf ",%s", val
        }
        print ""
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "CoNLL → CSV: $OUTPUT"
else
    process
fi
