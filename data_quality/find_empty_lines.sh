#!/usr/bin/env bash
# find_empty_lines.sh — Find and report empty/whitespace-only lines
# Author: Diptesh
# Status: Original — foundational script
# find_empty_lines.sh — Find and report empty/whitespace-only lines was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "find_empty_lines" "Find and report empty/whitespace-only lines" \
        "find_empty_lines.sh -i input.txt [--remove]" \
        "-i, --input"   "Input file" \
        "--remove"       "Remove empty lines and output cleaned text" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; REMOVE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --remove)    REMOVE=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

TOTAL=$(wc -l < "$INPUT" | tr -d ' ')
EMPTY=$(grep -cn '^[[:space:]]*$' "$INPUT" 2>/dev/null || echo "0")

if [[ $REMOVE -eq 0 ]]; then
    echo -e "${BOLD}═══ Empty Line Report ═══${NC}"
    echo ""
    printf "  %-20s %s\n" "Total lines:" "$TOTAL"
    printf "  %-20s %s (%.1f%%)\n" "Empty lines:" "$EMPTY" "$(pct $EMPTY $TOTAL)"
    echo ""
    if [[ "$EMPTY" -gt 0 ]]; then
        echo "  Empty line numbers:"
        grep -n '^[[:space:]]*$' "$INPUT" | head -20 | awk -F: '{ printf "    Line %s\n", $1 }'
        [[ "$EMPTY" -gt 20 ]] && echo "    ... and $(( EMPTY - 20 )) more"
    fi
else
    if [[ -n "$OUTPUT" ]]; then
        grep -v '^[[:space:]]*$' "$INPUT" > "$OUTPUT"
        REMAINING=$(wc -l < "$OUTPUT" | tr -d ' ')
        success "Removed $EMPTY empty lines: $TOTAL → $REMAINING lines → $OUTPUT"
    else
        grep -v '^[[:space:]]*$' "$INPUT"
    fi
fi
