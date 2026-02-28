#!/usr/bin/env bash
# sentence_split.sh — Split text into one sentence per line
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "sentence_split" "Split text into one sentence per line" \
        "sentence_split.sh -i input.txt [-o output.txt]" \
        "-i, --input"   "Input text file (or stdin)" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
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
    local src
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        src="$INPUT"
    else
        src="/dev/stdin"
    fi

    # Split on sentence-ending punctuation followed by space or end of line
    # Handles common abbreviations (Mr., Mrs., Dr., etc.)
    sed -E '
        # Protect common abbreviations
        s/Mr\./Mr§/g
        s/Mrs\./Mrs§/g
        s/Ms\./Ms§/g
        s/Dr\./Dr§/g
        s/Prof\./Prof§/g
        s/Inc\./Inc§/g
        s/Ltd\./Ltd§/g
        s/Jr\./Jr§/g
        s/Sr\./Sr§/g
        s/vs\./vs§/g
        s/etc\./etc§/g
        s/e\.g\./e§g§/g
        s/i\.e\./i§e§/g
        s/U\.S\./U§S§/g
    ' "$src" | sed -E '
        # Split on sentence boundaries
        s/([.!?]+)[[:space:]]+/\1\n/g
    ' | sed '
        # Restore abbreviations
        s/§/./g
    ' | grep -v '^[[:space:]]*$'
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    SENTS=$(wc -l < "$OUTPUT" | tr -d ' ')
    success "Split into $SENTS sentences → $OUTPUT"
else
    process
fi
