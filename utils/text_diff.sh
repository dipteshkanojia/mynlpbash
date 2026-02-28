#!/usr/bin/env bash
# text_diff.sh — Word-level diff between two text files
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "text_diff" "Word-level diff between two text files" \
        "text_diff.sh -a file1.txt -b file2.txt" \
        "-a, --file-a"    "First file" \
        "-b, --file-b"    "Second file" \
        "--summary"        "Show summary only" \
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

echo -e "${BOLD}═══ Text Diff ═══${NC}"
echo ""

paste "$FILE_A" "$FILE_B" | awk -F'\t' -v summary="$SUMMARY" '
{
    lines++
    a = $1; b = $2
    if (a == b) { same_lines++; next }
    diff_lines++
    
    if (!summary) {
        # Word-level comparison
        na = split(a, wa, /[[:space:]]+/)
        nb = split(b, wb, /[[:space:]]+/)
        
        printf "  L%-4d\n", NR
        printf "    - %s\n", a
        printf "    + %s\n", b
        
        # Show word-level changes
        max = (na > nb) ? na : nb
        changes = ""
        for (i=1; i<=max; i++) {
            if (i <= na && i <= nb && wa[i] != wb[i]) {
                changes = changes sprintf("      [%s] → [%s]\n", wa[i], wb[i])
                word_changes++
            } else if (i > na) {
                changes = changes sprintf("      + [%s]\n", wb[i])
                word_adds++
            } else if (i > nb) {
                changes = changes sprintf("      - [%s]\n", wa[i])
                word_dels++
            }
        }
        if (changes != "") printf "%s", changes
        print ""
    }
}
END {
    printf "  ── Summary ──\n"
    printf "  %-20s %d\n", "Total lines:", lines
    printf "  %-20s %d (%.1f%%)\n", "Identical:", same_lines+0, (same_lines+0)*100/lines
    printf "  %-20s %d (%.1f%%)\n", "Different:", diff_lines+0, (diff_lines+0)*100/lines
    if (!summary && (word_changes+0 > 0 || word_adds+0 > 0 || word_dels+0 > 0)) {
        printf "  %-20s %d changed, %d added, %d deleted\n", "Word edits:", word_changes+0, word_adds+0, word_dels+0
    }
}'
echo ""
