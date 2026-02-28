#!/usr/bin/env bash
# normalize_unicode.sh — Unicode normalization (NFC/NFD/NFKC/NFKD)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "normalize_unicode" "Unicode normalization using iconv/uconv/python fallback" \
        "normalize_unicode.sh -i text.txt --form NFC" \
        "-i, --input"     "Input text file" \
        "--form"           "Normalization form: NFC, NFD, NFKC, NFKD (default: NFC)" \
        "--strip-zwj"      "Remove Zero-Width Joiner/Non-Joiner" \
        "--strip-bom"      "Remove Byte Order Mark" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; FORM="NFC" ; STRIP_ZWJ=0 ; STRIP_BOM=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --form)       FORM="$2"; shift 2 ;;
        --strip-zwj)  STRIP_ZWJ=1; shift ;;
        --strip-bom)  STRIP_BOM=1; shift ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    local tmpfile
    tmpfile=$(make_temp)
    
    # Try uconv first (ICU), then python3, then pass through
    if command -v uconv &>/dev/null; then
        uconv -x "::${FORM};" < "$INPUT" > "$tmpfile"
        info "Normalized using uconv (ICU) → ${FORM}" >&2
    elif command -v python3 &>/dev/null; then
        python3 -c "
import unicodedata, sys
for line in sys.stdin:
    sys.stdout.write(unicodedata.normalize('${FORM}', line))
" < "$INPUT" > "$tmpfile"
        info "Normalized using python3 → ${FORM}" >&2
    else
        cp "$INPUT" "$tmpfile"
        warn "No uconv or python3 found; passing through unchanged" >&2
    fi
    
    # Strip ZWJ/ZWNJ (U+200D / U+200C)
    if [[ $STRIP_ZWJ -eq 1 ]]; then
        sed 's/\xe2\x80\x8d//g; s/\xe2\x80\x8c//g' "$tmpfile" > "${tmpfile}.2" && mv "${tmpfile}.2" "$tmpfile"
        info "Stripped ZWJ/ZWNJ characters" >&2
    fi
    
    # Strip BOM (U+FEFF)
    if [[ $STRIP_BOM -eq 1 ]]; then
        sed '1s/^\xef\xbb\xbf//' "$tmpfile" > "${tmpfile}.2" && mv "${tmpfile}.2" "$tmpfile"
        info "Stripped BOM" >&2
    fi
    
    cat "$tmpfile"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Unicode normalization ($FORM) → $OUTPUT"
else
    process
fi
