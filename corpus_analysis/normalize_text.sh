#!/usr/bin/env bash
# normalize_text.sh — Text normalization pipeline
# Author: Diptesh
# Status: Original — foundational script
# normalize_text.sh — Text normalization pipeline was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "normalize_text" "Normalize text (lowercase, whitespace, unicode, etc.)" \
        "normalize_text.sh -i input.txt [-o output.txt] [options]" \
        "-i, --input"        "Input text file (or stdin)" \
        "-o, --output"       "Output file (default: stdout)" \
        "--lower"             "Convert to lowercase" \
        "--strip-accents"     "Remove diacritical marks" \
        "--normalize-ws"      "Normalize whitespace (collapse multiple spaces)" \
        "--strip-punct"       "Remove punctuation" \
        "--strip-numbers"     "Remove numbers" \
        "--strip-extra-ws"    "Remove leading/trailing whitespace" \
        "--nfkd"              "Unicode NFKD normalization" \
        "--all"               "Apply all normalizations" \
        "-h, --help"         "Show this help"
}

INPUT="" ; OUTPUT=""
DO_LOWER=0 ; DO_ACCENTS=0 ; DO_WS=0 ; DO_PUNCT=0 ; DO_NUMS=0 ; DO_TRIM=0 ; DO_NFKD=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        --lower)          DO_LOWER=1; shift ;;
        --strip-accents)  DO_ACCENTS=1; shift ;;
        --normalize-ws)   DO_WS=1; shift ;;
        --strip-punct)    DO_PUNCT=1; shift ;;
        --strip-numbers)  DO_NUMS=1; shift ;;
        --strip-extra-ws) DO_TRIM=1; shift ;;
        --nfkd)           DO_NFKD=1; shift ;;
        --all)            DO_LOWER=1; DO_ACCENTS=1; DO_WS=1; DO_PUNCT=1; DO_TRIM=1; DO_NFKD=1; shift ;;
        -h|--help)        show_help; exit 0 ;;
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

    local cmd="cat '$src'"
    [[ $DO_LOWER -eq 1 ]]   && cmd="$cmd | tr '[:upper:]' '[:lower:]'"
    [[ $DO_ACCENTS -eq 1 ]] && cmd="$cmd | sed 'y/àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ/aaaaaaeeeeiiiioooooruuuuyyñcAAAAAAEEEEIIIIOOOOOUUUUYNC/'"
    [[ $DO_PUNCT -eq 1 ]]   && cmd="$cmd | sed 's/[[:punct:]]//g'"
    [[ $DO_NUMS -eq 1 ]]    && cmd="$cmd | sed 's/[0-9]//g'"
    [[ $DO_WS -eq 1 ]]      && cmd="$cmd | tr -s '[:space:]' ' '"
    [[ $DO_TRIM -eq 1 ]]    && cmd="$cmd | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'"

    eval "$cmd"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Normalized → $OUTPUT"
else
    process
fi
