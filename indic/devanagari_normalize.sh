#!/usr/bin/env bash
# devanagari_normalize.sh — Hindi/Marathi-specific Devanagari normalization
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "devanagari_normalize" "Devanagari text normalization (nukta, anusvara, digits)" \
        "devanagari_normalize.sh -i hindi.txt [-o normalized.txt]" \
        "-i, --input"        "Input text file" \
        "--nukta"             "Normalize nukta consonants (default: on)" \
        "--chandrabindu"      "Chandrabindu → anusvara (default: off)" \
        "--digits"            "Devanagari digits → Arabic digits (default: on)" \
        "--strip-zwj"         "Remove ZWJ/ZWNJ (default: on)" \
        "--collapse-spaces"   "Collapse multiple spaces (default: on)" \
        "-o, --output"       "Output file (default: stdout)" \
        "-h, --help"         "Show this help"
}

INPUT="" ; OUTPUT="" ; NUKTA=1 ; CHANDRA=0 ; DIGITS=1 ; ZWJ=1 ; SPACES=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)           INPUT="$2"; shift 2 ;;
        --nukta)              NUKTA=1; shift ;;
        --no-nukta)           NUKTA=0; shift ;;
        --chandrabindu)       CHANDRA=1; shift ;;
        --digits)             DIGITS=1; shift ;;
        --no-digits)          DIGITS=0; shift ;;
        --strip-zwj)          ZWJ=1; shift ;;
        --no-strip-zwj)       ZWJ=0; shift ;;
        --collapse-spaces)    SPACES=1; shift ;;
        -o|--output)          OUTPUT="$2"; shift 2 ;;
        -h|--help)            show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    local cmd="cat '$INPUT'"
    
    if [[ $NUKTA -eq 1 ]]; then
        # Normalize nukta consonants to base equivalents
        # क़→क, ख़→ख, ग़→ग, ज़→ज, ड़→ड, ढ़→ढ, फ़→फ, य़→य
        cmd="$cmd | sed -e 's/क़/क/g' -e 's/ख़/ख/g' -e 's/ग़/ग/g' -e 's/ज़/ज/g' -e 's/ड़/ड/g' -e 's/ढ़/ढ/g' -e 's/फ़/फ/g'"
    fi
    
    if [[ $CHANDRA -eq 1 ]]; then
        # Chandrabindu → anusvara
        cmd="$cmd | sed 's/ँ/ं/g'"
    fi
    
    if [[ $DIGITS -eq 1 ]]; then
        # Devanagari digits → Arabic
        cmd="$cmd | sed -e 's/०/0/g' -e 's/१/1/g' -e 's/२/2/g' -e 's/३/3/g' -e 's/४/4/g' -e 's/५/5/g' -e 's/६/6/g' -e 's/७/7/g' -e 's/८/8/g' -e 's/९/9/g'"
    fi
    
    if [[ $ZWJ -eq 1 ]]; then
        # Remove Zero-Width Joiner (U+200D) and Non-Joiner (U+200C)
        cmd="$cmd | sed 's/\xe2\x80\x8d//g; s/\xe2\x80\x8c//g'"
    fi
    
    if [[ $SPACES -eq 1 ]]; then
        cmd="$cmd | sed 's/  */ /g; s/^ //; s/ $//'"
    fi
    
    eval "$cmd"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Devanagari normalization → $OUTPUT"
else
    process
fi
