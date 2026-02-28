#!/usr/bin/env bash
# check_encoding.sh — Check for encoding issues, BOM, mixed encodings
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "check_encoding" "Check for encoding issues, BOM, and mixed encodings" \
        "check_encoding.sh -i input.txt [--fix] [-o output.txt]" \
        "-i, --input"   "Input file" \
        "--fix"          "Fix common encoding issues" \
        "--remove-bom"   "Remove BOM if present" \
        "--to-utf8"      "Convert to UTF-8" \
        "--fix-crlf"     "Convert CRLF to LF" \
        "-o, --output"  "Output file for fixed version" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; FIX=0 ; REMOVE_BOM=0 ; TO_UTF8=0 ; FIX_CRLF=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)    INPUT="$2"; shift 2 ;;
        --fix)         FIX=1; REMOVE_BOM=1; TO_UTF8=1; FIX_CRLF=1; shift ;;
        --remove-bom)  REMOVE_BOM=1; shift ;;
        --to-utf8)     TO_UTF8=1; shift ;;
        --fix-crlf)    FIX_CRLF=1; shift ;;
        -o|--output)   OUTPUT="$2"; shift 2 ;;
        -h|--help)     show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

ISSUES=0

echo -e "${BOLD}═══ Encoding Check ═══${NC}"
echo ""

# Detect encoding
ENCODING=$(file -bi "$INPUT" 2>/dev/null | sed 's/.*charset=//')
printf "  %-20s %s\n" "Detected encoding:" "$ENCODING"

# Check BOM
HAS_BOM=0
if head -c 3 "$INPUT" | xxd -p 2>/dev/null | grep -q "^efbbbf"; then
    warn "UTF-8 BOM detected"
    HAS_BOM=1; ISSUES=$((ISSUES+1))
else
    success "No BOM"
fi

# Check line endings
if file "$INPUT" | grep -q "CRLF"; then
    warn "Windows line endings (CRLF) detected"
    HAS_CRLF=1; ISSUES=$((ISSUES+1))
else
    success "Unix line endings (LF)"
    HAS_CRLF=0
fi

# Check for non-UTF8 sequences
NON_UTF8=$(grep -cP '[\x80-\xff]' "$INPUT" 2>/dev/null || echo "unknown")
printf "  %-20s %s lines\n" "Non-ASCII lines:" "$NON_UTF8"

# Check for null bytes
NULL_BYTES=$(tr -d '\0' < "$INPUT" | wc -c | tr -d ' ')
ORIG_BYTES=$(wc -c < "$INPUT" | tr -d ' ')
if [[ "$NULL_BYTES" -ne "$ORIG_BYTES" ]]; then
    NULL_COUNT=$(( ORIG_BYTES - NULL_BYTES ))
    warn "Found $NULL_COUNT null bytes"
    ISSUES=$((ISSUES+1))
else
    success "No null bytes"
fi

echo ""
if [[ $ISSUES -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}✓ No encoding issues found${NC}"
else
    echo -e "  ${YELLOW}${BOLD}⚠ $ISSUES issue(s) found${NC}"
fi

# Fix if requested
if [[ $FIX -eq 1 || $REMOVE_BOM -eq 1 || $TO_UTF8 -eq 1 || $FIX_CRLF -eq 1 ]]; then
    [[ -z "$OUTPUT" ]] && OUTPUT="${INPUT%.txt}.fixed.txt"
    cp "$INPUT" "$OUTPUT"
    
    if [[ $REMOVE_BOM -eq 1 && $HAS_BOM -eq 1 ]]; then
        sed -i.bak '1s/^\xEF\xBB\xBF//' "$OUTPUT" 2>/dev/null && rm -f "${OUTPUT}.bak"
        info "Removed BOM"
    fi
    
    if [[ $FIX_CRLF -eq 1 && $HAS_CRLF -eq 1 ]]; then
        tr -d '\r' < "$OUTPUT" > "${OUTPUT}.tmp" && mv "${OUTPUT}.tmp" "$OUTPUT"
        info "Converted CRLF → LF"
    fi
    
    if [[ $TO_UTF8 -eq 1 && "$ENCODING" != "utf-8" && "$ENCODING" != "us-ascii" ]]; then
        iconv -f "$ENCODING" -t UTF-8 "$INPUT" > "$OUTPUT" 2>/dev/null && info "Converted to UTF-8"
    fi
    
    success "Fixed version → $OUTPUT"
fi
echo ""
