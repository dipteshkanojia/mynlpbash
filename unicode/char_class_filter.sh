#!/usr/bin/env bash
# char_class_filter.sh — Filter text by Unicode character class or script
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "char_class_filter" "Filter/keep text by Unicode character class or script" \
        "char_class_filter.sh -i text.txt --keep devanagari" \
        "-i, --input"     "Input text file" \
        "--keep"           "Keep only: latin, devanagari, bengali, tamil, telugu, digits, punct" \
        "--remove"         "Remove: latin, devanagari, bengali, tamil, telugu, digits, punct" \
        "--keep-spaces"    "Keep whitespace even when filtering (default: yes)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; KEEP="" ; REMOVE="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --keep)       KEEP="$2"; shift 2 ;;
        --remove)     REMOVE="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$KEEP" && -z "$REMOVE" ]] && die "Specify --keep or --remove"
require_file "$INPUT"

MODE="keep"
SCRIPT_FILTER="$KEEP"
[[ -n "$REMOVE" ]] && MODE="remove" && SCRIPT_FILTER="$REMOVE"

process() {
    awk -v mode="$MODE" -v script_filter="$SCRIPT_FILTER" '
    BEGIN {
        for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
        split(script_filter, filters, ",")
        for (f in filters) wanted[filters[f]] = 1
    }
    function char_script(arr, pos,   b,b2,b3,cp) {
        b = ord[arr[pos]]
        if (arr[pos] ~ /[A-Za-z]/) return "latin"
        if (arr[pos] ~ /[0-9]/) return "digits"
        if (arr[pos] ~ /[[:punct:]]/) return "punct"
        if (arr[pos] ~ /[[:space:]]/) return "space"
        if (b >= 0xE0 && pos+2 <= length(arr)) {
            b2 = ord[arr[pos+1]]; b3 = ord[arr[pos+2]]
            cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
            if (cp >= 0x0900 && cp <= 0x097F) return "devanagari"
            if (cp >= 0x0980 && cp <= 0x09FF) return "bengali"
            if (cp >= 0x0A00 && cp <= 0x0A7F) return "gurmukhi"
            if (cp >= 0x0A80 && cp <= 0x0AFF) return "gujarati"
            if (cp >= 0x0B00 && cp <= 0x0B7F) return "odia"
            if (cp >= 0x0B80 && cp <= 0x0BFF) return "tamil"
            if (cp >= 0x0C00 && cp <= 0x0C7F) return "telugu"
            if (cp >= 0x0C80 && cp <= 0x0CFF) return "kannada"
            if (cp >= 0x0D00 && cp <= 0x0D7F) return "malayalam"
        }
        return "other"
    }
    {
        n = split($0, arr, "")
        result = ""
        for (i=1; i<=n; i++) {
            s = char_script(arr, i)
            if (s == "space") { result = result arr[i]; continue }
            if (mode == "keep") {
                if (s in wanted) result = result arr[i]
            } else {
                if (!(s in wanted)) result = result arr[i]
            }
        }
        # Collapse multiple spaces
        gsub(/  +/, " ", result)
        gsub(/^ +| +$/, "", result)
        if (result != "") print result
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Filtered ($MODE $SCRIPT_FILTER) → $OUTPUT"
else
    process
fi
