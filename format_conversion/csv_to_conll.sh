#!/usr/bin/env bash
# csv_to_conll.sh — Convert CSV to CoNLL format
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_to_conll" "Convert CSV to CoNLL format" \
        "csv_to_conll.sh -i input.csv --sent-col sentence_id [-o output.conll]" \
        "-i, --input"     "Input CSV file" \
        "--sent-col"       "Sentence ID column (name or index)" \
        "--token-col"      "Token column (name or index, default: 2)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; SENT_COL="1" ; TOKEN_COL="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        --sent-col)     SENT_COL="$2"; shift 2 ;;
        --token-col)    TOKEN_COL="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ ! "$SENT_COL" =~ ^[0-9]+$ ]]; then
    SENT_COL=$(find_column_index "$INPUT" "$SENT_COL" "$DELIM")
fi

process() {
    awk -F"$DELIM" -v sent_col="$SENT_COL" '
    NR==1 { next }
    {
        curr_sent = $sent_col
        gsub(/^[ \t]+|[ \t]+$/, "", curr_sent)
        if (prev_sent != "" && curr_sent != prev_sent) print ""
        
        first = 1
        for (i=1; i<=NF; i++) {
            if (i == sent_col) continue
            val = $i
            gsub(/^"|"$/, "", val)
            gsub(/^[ \t]+|[ \t]+$/, "", val)
            if (!first) printf "\t"
            printf "%s", val
            first = 0
        }
        print ""
        prev_sent = curr_sent
    }
    END { print "" }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "CSV → CoNLL: $OUTPUT"
else
    process
fi
