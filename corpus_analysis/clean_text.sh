#!/usr/bin/env bash
# clean_text.sh — Clean text by removing HTML, URLs, emails, special chars
# Author: Diptesh
# Status: Original — foundational script
# clean_text.sh — Clean text by removing HTML, URLs, emails, special chars was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

# NOTE: Basic text cleaning (Diptesh). Extended multi-pattern cleaning
# (special chars, social media, unicode) enhanced by Claude Opus.
show_help() {
    print_help "clean_text" "Clean text (remove HTML, URLs, emails, special chars)" \
        "clean_text.sh -i input.txt [-o output.txt] [options]" \
        "-i, --input"      "Input text file (or stdin)" \
        "-o, --output"     "Output file (default: stdout)" \
        "--html"            "Remove HTML tags" \
        "--urls"            "Remove URLs" \
        "--emails"          "Remove email addresses" \
        "--hashtags"        "Remove hashtags" \
        "--mentions"        "Remove @mentions" \
        "--emojis"          "Remove common emoji patterns" \
        "--special"         "Remove special characters (keep alphanumeric + basic punct)" \
        "--all"             "Apply all cleaning operations" \
        "-h, --help"       "Show this help"
}

INPUT="" ; OUTPUT=""
DO_HTML=0 ; DO_URLS=0 ; DO_EMAILS=0 ; DO_HASHTAGS=0 ; DO_MENTIONS=0 ; DO_EMOJIS=0 ; DO_SPECIAL=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        --html)       DO_HTML=1; shift ;;
        --urls)       DO_URLS=1; shift ;;
        --emails)     DO_EMAILS=1; shift ;;
        --hashtags)   DO_HASHTAGS=1; shift ;;
        --mentions)   DO_MENTIONS=1; shift ;;
        --emojis)     DO_EMOJIS=1; shift ;;
        --special)    DO_SPECIAL=1; shift ;;
        --all)        DO_HTML=1; DO_URLS=1; DO_EMAILS=1; DO_HASHTAGS=1; DO_MENTIONS=1; DO_EMOJIS=1; DO_SPECIAL=1; shift ;;
        -h|--help)    show_help; exit 0 ;;
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
    [[ $DO_HTML -eq 1 ]]     && cmd="$cmd | sed 's/<[^>]*>//g'"
    [[ $DO_URLS -eq 1 ]]     && cmd="$cmd | sed -E 's|https?://[^ ]*||g; s|www\.[^ ]*||g'"
    [[ $DO_EMAILS -eq 1 ]]   && cmd="$cmd | sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}//g'"
    [[ $DO_HASHTAGS -eq 1 ]] && cmd="$cmd | sed 's/#[a-zA-Z0-9_]*//g'"
    [[ $DO_MENTIONS -eq 1 ]] && cmd="$cmd | sed 's/@[a-zA-Z0-9_]*//g'"
    [[ $DO_SPECIAL -eq 1 ]]  && cmd="$cmd | sed 's/[^a-zA-Z0-9 .!?,;:'\''\"()-]//g'"
    # Normalize multiple spaces
    cmd="$cmd | tr -s ' '"

    eval "$cmd"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Cleaned text → $OUTPUT"
else
    process
fi
