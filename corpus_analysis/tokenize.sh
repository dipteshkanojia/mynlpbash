#!/usr/bin/env bash
# tokenize.sh — Simple whitespace and punctuation tokenizer
# Author: Diptesh
# Status: Original — foundational script
# tokenize.sh — Simple whitespace and punctuation tokenizer was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "tokenize" "Tokenize text (whitespace + punctuation splitting)" \
        "tokenize.sh -i input.txt [-o output.txt] [--mode word|char]" \
        "-i, --input"   "Input text file (or stdin)" \
        "-o, --output"  "Output file (default: stdout)" \
        "--mode"         "Tokenization mode: word (default), char" \
        "--lower"        "Lowercase tokens" \
        "--one-per-line" "One token per line" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; MODE="word" ; LOWER=0 ; OPL=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        --mode)         MODE="$2"; shift 2 ;;
        --lower)        LOWER=1; shift ;;
        --one-per-line) OPL=1; shift ;;
        -h|--help)      show_help; exit 0 ;;
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

    if [[ "$MODE" == "char" ]]; then
        local cmd="cat '$src'"
        [[ $LOWER -eq 1 ]] && cmd="$cmd | tr '[:upper:]' '[:lower:]'"
        if [[ $OPL -eq 1 ]]; then
            eval "$cmd" | fold -w1
        else
            eval "$cmd" | fold -w1 | paste -sd' ' -
        fi
    else
        # Word tokenization: split on whitespace and separate punctuation
        local cmd="cat '$src'"
        [[ $LOWER -eq 1 ]] && cmd="$cmd | tr '[:upper:]' '[:lower:]'"
        if [[ $OPL -eq 1 ]]; then
            eval "$cmd" | sed -E '
                s/([[:punct:]])/ \1 /g
                s/[[:space:]]+/\n/g
            ' | grep -v '^$'
        else
            eval "$cmd" | sed -E '
                s/([[:punct:]])/ \1 /g
                s/[[:space:]]+/ /g
            '
        fi
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Tokenized ($MODE mode) → $OUTPUT"
else
    process
fi
