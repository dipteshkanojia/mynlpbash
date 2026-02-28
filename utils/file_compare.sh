#!/usr/bin/env bash
# file_compare.sh — Compare two data files
# Author: Diptesh
# Status: Original — foundational script
# file_compare.sh — Compare two data files was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "file_compare" "Compare two data files (line-level diff and stats)" \
        "file_compare.sh -a file1.txt -b file2.txt" \
        "-a, --file-a"    "First file" \
        "-b, --file-b"    "Second file" \
        "--summary"        "Summary only (no line-level details)" \
        "-h, --help"      "Show this help"
}

FILE_A="" ; FILE_B="" ; SUMMARY=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--file-a) FILE_A="$2"; shift 2 ;;
        -b|--file-b) FILE_B="$2"; shift 2 ;;
        --summary)   SUMMARY=1; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$FILE_A" ]] && die "File A required (-a)"
[[ -z "$FILE_B" ]] && die "File B required (-b)"
require_file "$FILE_A"; require_file "$FILE_B"

LINES_A=$(wc -l < "$FILE_A" | tr -d ' ')
LINES_B=$(wc -l < "$FILE_B" | tr -d ' ')
SIZE_A=$(ls -lh "$FILE_A" | awk '{print $5}')
SIZE_B=$(ls -lh "$FILE_B" | awk '{print $5}')
WORDS_A=$(wc -w < "$FILE_A" | tr -d ' ')
WORDS_B=$(wc -w < "$FILE_B" | tr -d ' ')

echo -e "${BOLD}═══ File Comparison ═══${NC}"
echo ""
printf "  %-20s %-20s %-20s\n" "" "File A" "File B"
printf "  %-20s %-20s %-20s\n" "Name:" "$(basename "$FILE_A")" "$(basename "$FILE_B")"
printf "  %-20s %-20s %-20s\n" "Size:" "$SIZE_A" "$SIZE_B"
printf "  %-20s %-20s %-20s\n" "Lines:" "$LINES_A" "$LINES_B"
printf "  %-20s %-20s %-20s\n" "Words:" "$WORDS_A" "$WORDS_B"
echo ""

# Common and unique lines
COMMON=$(comm -12 <(sort "$FILE_A") <(sort "$FILE_B") | wc -l | tr -d ' ')
ONLY_A=$(comm -23 <(sort "$FILE_A") <(sort "$FILE_B") | wc -l | tr -d ' ')
ONLY_B=$(comm -13 <(sort "$FILE_A") <(sort "$FILE_B") | wc -l | tr -d ' ')

echo -e "${BOLD}── Line-level Comparison (ignoring order) ──${NC}"
printf "  %-25s %d\n" "Common lines:" "$COMMON"
printf "  %-25s %d\n" "Only in A:" "$ONLY_A"
printf "  %-25s %d\n" "Only in B:" "$ONLY_B"

# Identical check
if diff -q "$FILE_A" "$FILE_B" &>/dev/null; then
    echo ""
    success "Files are identical"
else
    echo ""
    warn "Files differ"
    
    if [[ $SUMMARY -eq 0 ]]; then
        echo ""
        echo -e "${BOLD}── First 10 Differences ──${NC}"
        diff --unified=0 "$FILE_A" "$FILE_B" | head -30
    fi
fi
echo ""
