#!/usr/bin/env bash
# vocab_extract.sh — Extract unique vocabulary from corpus
# Author: Diptesh
# Status: Original — foundational script
# vocab_extract.sh — Extract unique vocabulary from corpus was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "vocab_extract" "Extract unique vocabulary from text corpus" \
        "vocab_extract.sh -i corpus.txt [-o vocab.txt] [--lower] [--min 2]" \
        "-i, --input"   "Input text file" \
        "-o, --output"  "Output vocabulary file (default: stdout)" \
        "--lower"        "Lowercase before extracting" \
        "--min"          "Minimum frequency to include (default: 1)" \
        "--sort"         "Sort order: alpha, freq (default: freq)" \
        "--with-freq"    "Include frequency counts" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; LOWER=0 ; MIN=1 ; SORT="freq" ; WITH_FREQ=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        --lower)      LOWER=1; shift ;;
        --min)        MIN="$2"; shift 2 ;;
        --sort)       SORT="$2"; shift 2 ;;
        --with-freq)  WITH_FREQ=1; shift ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    local cmd="cat '$INPUT'"
    [[ $LOWER -eq 1 ]] && cmd="$cmd | tr '[:upper:]' '[:lower:]'"
    cmd="$cmd | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | sort | uniq -c"
    
    if [[ $WITH_FREQ -eq 1 ]]; then
        if [[ "$SORT" == "alpha" ]]; then
            eval "$cmd" | awk -v min="$MIN" '$1 >= min { printf "%s\t%d\n", $2, $1 }' | sort -t$'\t' -k1
        else
            eval "$cmd" | awk -v min="$MIN" '$1 >= min { printf "%s\t%d\n", $2, $1 }' | sort -t$'\t' -k2 -rn
        fi
    else
        if [[ "$SORT" == "alpha" ]]; then
            eval "$cmd" | awk -v min="$MIN" '$1 >= min { print $2 }' | sort
        else
            eval "$cmd" | awk -v min="$MIN" '$1 >= min { print $2 }' | sort -rn
        fi
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    VOCAB_SIZE=$(wc -l < "$OUTPUT" | tr -d ' ')
    success "Extracted vocabulary: $VOCAB_SIZE types → $OUTPUT"
else
    process
fi
