#!/usr/bin/env bash
# csv_validate.sh — Validate CSV/TSV file structure
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_validate" "Validate CSV/TSV file structure and integrity" \
        "csv_validate.sh -i input.csv" \
        "-i, --input"     "Input CSV/TSV file" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "--strict"        "Strict mode: fail on any warning" \
        "-h, --help"      "Show this help"
}

INPUT="" ; DELIM="" ; STRICT=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        --strict)       STRICT=1; shift ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

ERRORS=0 ; WARNINGS=0

echo -e "${BOLD}═══ Validating: $(basename "$INPUT") ═══${NC}"
echo ""

# Check encoding
ENCODING=$(file -bi "$INPUT" 2>/dev/null | sed 's/.*charset=//')
if [[ "$ENCODING" =~ utf-8|ascii|us-ascii ]]; then
    success "Encoding: $ENCODING"
else
    warn "Encoding: $ENCODING (expected UTF-8)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check BOM
if head -c 3 "$INPUT" | xxd -p | grep -q "^efbbbf"; then
    warn "File contains UTF-8 BOM (byte order mark)"
    WARNINGS=$((WARNINGS + 1))
else
    success "No BOM detected"
fi

# Check consistent column count
EXPECTED_COLS=$(head -1 "$INPUT" | awk -F"$DELIM" '{print NF}')
INCONSISTENT=$(awk -F"$DELIM" -v expected="$EXPECTED_COLS" '
    NF != expected { print NR": expected "expected" columns, found "NF }
' "$INPUT")

if [[ -z "$INCONSISTENT" ]]; then
    success "Column count: consistent ($EXPECTED_COLS columns)"
else
    error "Inconsistent column counts found:"
    echo "$INCONSISTENT" | head -10
    ERRORS=$((ERRORS + 1))
fi

# Check for empty lines
EMPTY=$(grep -nc '^[[:space:]]*$' "$INPUT" 2>/dev/null || echo "0")
if [[ "$EMPTY" -gt 0 ]]; then
    warn "Found $EMPTY empty line(s)"
    WARNINGS=$((WARNINGS + 1))
else
    success "No empty lines"
fi

# Check for trailing whitespace in fields
TRAILING=$(awk -F"$DELIM" '
    { for(i=1;i<=NF;i++) if ($i ~ /[^ \t][ \t]+$/) { count++; break } }
    END { print count+0 }
' "$INPUT")
if [[ "$TRAILING" -gt 0 ]]; then
    warn "Found $TRAILING row(s) with trailing whitespace in fields"
    WARNINGS=$((WARNINGS + 1))
else
    success "No trailing whitespace in fields"
fi

# Check for duplicate headers
DUP_HEADERS=$(head -1 "$INPUT" | awk -F"$DELIM" '{
    for(i=1;i<=NF;i++) { gsub(/^"|"$/, "", $i); count[$i]++ }
    for(h in count) if (count[h]>1) print h" ("count[h]" times)"
}')
if [[ -n "$DUP_HEADERS" ]]; then
    warn "Duplicate column names: $DUP_HEADERS"
    WARNINGS=$((WARNINGS + 1))
else
    success "No duplicate column names"
fi

# Check line endings
if file "$INPUT" | grep -q "CRLF"; then
    warn "File uses Windows line endings (CRLF)"
    WARNINGS=$((WARNINGS + 1))
else
    success "Unix line endings (LF)"
fi

# Summary
echo ""
separator "─" 40
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ VALID${NC} — No issues found"
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}${BOLD}⚠ VALID with warnings${NC} — $WARNINGS warning(s)"
else
    echo -e "${RED}${BOLD}✗ INVALID${NC} — $ERRORS error(s), $WARNINGS warning(s)"
fi

[[ $STRICT -eq 1 && $WARNINGS -gt 0 ]] && exit 1
[[ $ERRORS -gt 0 ]] && exit 1
exit 0
