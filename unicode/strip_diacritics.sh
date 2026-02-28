#!/usr/bin/env bash
# strip_diacritics.sh — Remove combining diacritical marks
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "strip_diacritics" "Remove combining diacritical marks from text" \
        "strip_diacritics.sh -i text.txt [-o output.txt]" \
        "-i, --input"     "Input text file" \
        "--keep-base"      "Keep base characters, remove only combining marks" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    if command -v uconv &>/dev/null; then
        # Decompose to NFD, then remove combining marks (category Mn)
        uconv -x "::NFD; [:Nonspacing Mark:] >; ::NFC;" < "$INPUT"
        info "Stripped diacritics using uconv (ICU)" >&2
    elif command -v python3 &>/dev/null; then
        python3 -c "
import unicodedata, sys
for line in sys.stdin:
    nfd = unicodedata.normalize('NFD', line)
    stripped = ''.join(c for c in nfd if unicodedata.category(c) != 'Mn')
    sys.stdout.write(unicodedata.normalize('NFC', stripped))
" < "$INPUT"
        info "Stripped diacritics using python3" >&2
    elif command -v iconv &>/dev/null; then
        # Fallback: transliterate to ASCII (lossy)
        iconv -f UTF-8 -t ASCII//TRANSLIT < "$INPUT" 2>/dev/null
        warn "Used iconv ASCII transliteration (lossy fallback)" >&2
    else
        cat "$INPUT"
        warn "No suitable tool found; passing through unchanged" >&2
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Diacritics stripped → $OUTPUT"
else
    process
fi
