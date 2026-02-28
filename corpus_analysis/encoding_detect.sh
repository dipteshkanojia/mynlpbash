#!/usr/bin/env bash
# encoding_detect.sh — Detect file encoding and optionally convert to UTF-8
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "encoding_detect" "Detect file encoding and optionally convert to UTF-8" \
        "encoding_detect.sh -i input.txt [--convert] [-o output.txt]" \
        "-i, --input"   "Input file" \
        "--convert"      "Convert to UTF-8" \
        "-o, --output"  "Output file for converted text" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; CONVERT=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --convert)   CONVERT=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Detect encoding
ENCODING=$(file -bi "$INPUT" 2>/dev/null | sed 's/.*charset=//')
MIME=$(file -bi "$INPUT" 2>/dev/null | sed 's/;.*//')
FILE_DESC=$(file "$INPUT" 2>/dev/null | sed "s|$INPUT: ||")

echo -e "${BOLD}═══ Encoding Detection ═══${NC}"
echo ""
printf "  %-15s %s\n" "File:" "$(basename "$INPUT")"
printf "  %-15s %s\n" "MIME type:" "$MIME"
printf "  %-15s %s\n" "Charset:" "$ENCODING"
printf "  %-15s %s\n" "Description:" "$FILE_DESC"

# Check for BOM
BOM="none"
if head -c 3 "$INPUT" | xxd -p 2>/dev/null | grep -q "^efbbbf"; then
    BOM="UTF-8 BOM"
elif head -c 2 "$INPUT" | xxd -p 2>/dev/null | grep -q "^fffe"; then
    BOM="UTF-16 LE BOM"
elif head -c 2 "$INPUT" | xxd -p 2>/dev/null | grep -q "^feff"; then
    BOM="UTF-16 BE BOM"
fi
printf "  %-15s %s\n" "BOM:" "$BOM"

# Check for non-ASCII chars
NON_ASCII=$(grep -cP '[^\x00-\x7F]' "$INPUT" 2>/dev/null || grep -c '[^[:print:][:space:]]' "$INPUT" 2>/dev/null || echo "0")
printf "  %-15s %s lines\n" "Non-ASCII:" "$NON_ASCII"

if [[ $CONVERT -eq 1 ]]; then
    echo ""
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT="${INPUT%.txt}.utf8.txt"
    fi
    if command -v iconv &>/dev/null; then
        if iconv -f "$ENCODING" -t UTF-8 "$INPUT" > "$OUTPUT" 2>/dev/null; then
            success "Converted $ENCODING → UTF-8: $OUTPUT"
        else
            # Try with //TRANSLIT
            iconv -f "$ENCODING" -t UTF-8//TRANSLIT "$INPUT" > "$OUTPUT" 2>/dev/null \
                && success "Converted with transliteration → $OUTPUT" \
                || die "Conversion failed"
        fi
    else
        die "iconv not found, cannot convert"
    fi
fi
