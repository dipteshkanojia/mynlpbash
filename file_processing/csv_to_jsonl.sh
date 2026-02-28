#!/usr/bin/env bash
# csv_to_jsonl.sh — Convert CSV to JSON Lines format
# Author: Diptesh
# Status: Original — foundational script
# csv_to_jsonl.sh — Convert CSV to JSON Lines format was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_to_jsonl" "Convert CSV/TSV to JSON Lines format" \
        "csv_to_jsonl.sh -i input.csv [-o output.jsonl]" \
        "-i, --input"    "Input CSV/TSV file" \
        "-d, --delimiter" "Delimiter (auto-detected if omitted)" \
        "-o, --output"   "Output JSONL file (default: stdout)" \
        "-h, --help"     "Show this help"
}

INPUT="" ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

process() {
    awk -F"$DELIM" '
    NR==1 {
        for (i=1; i<=NF; i++) {
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
            gsub(/^"|"$/, "", $i)
            headers[i] = $i
        }
        ncols = NF
        next
    }
    {
        printf "{"
        for (i=1; i<=ncols; i++) {
            val = $i
            gsub(/^[ \t]+|[ \t]+$/, "", val)
            gsub(/^"|"$/, "", val)
            gsub(/\\/, "\\\\", val)
            gsub(/"/, "\\\"", val)
            if (i > 1) printf ", "
            # Try to detect numbers
            if (val ~ /^-?[0-9]+\.?[0-9]*$/) {
                printf "\"%s\": %s", headers[i], val
            } else {
                printf "\"%s\": \"%s\"", headers[i], val
            }
        }
        print "}"
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    rows=$(( $(wc -l < "$OUTPUT" | tr -d ' ') ))
    success "Converted $rows records → $OUTPUT"
else
    process
fi
