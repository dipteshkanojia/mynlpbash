#!/usr/bin/env bash
# parallel_check.sh — Verify parallel corpus alignment
# Author: Diptesh
# Status: Original — foundational script
# parallel_check.sh — Verify parallel corpus alignment was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_check" "Verify parallel corpus alignment (line counts, empty lines, ratios)" \
        "parallel_check.sh -s source.txt -t target.txt" \
        "-s, --source"  "Source language file" \
        "-t, --target"  "Target language file" \
        "-h, --help"    "Show this help"
}

SRC="" ; TGT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SRC="$2"; shift 2 ;;
        -t|--target) TGT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
require_file "$SRC"; require_file "$TGT"

echo -e "${BOLD}═══ Parallel Corpus Alignment Check ═══${NC}"
echo ""

SRC_LINES=$(wc -l < "$SRC" | tr -d ' ')
TGT_LINES=$(wc -l < "$TGT" | tr -d ' ')

printf "  %-25s %s\n" "Source file:" "$(basename "$SRC")"
printf "  %-25s %s\n" "Target file:" "$(basename "$TGT")"
printf "  %-25s %s\n" "Source lines:" "$SRC_LINES"
printf "  %-25s %s\n" "Target lines:" "$TGT_LINES"
echo ""

if [[ "$SRC_LINES" -eq "$TGT_LINES" ]]; then
    success "Line counts match: $SRC_LINES"
else
    error "Line count MISMATCH: $SRC_LINES vs $TGT_LINES (diff: $(( SRC_LINES - TGT_LINES )))"
fi

# Check empty lines
SRC_EMPTY=$(grep -c '^[[:space:]]*$' "$SRC" || true)
TGT_EMPTY=$(grep -c '^[[:space:]]*$' "$TGT" || true)
echo ""
printf "  %-25s %s\n" "Source empty lines:" "$SRC_EMPTY"
printf "  %-25s %s\n" "Target empty lines:" "$TGT_EMPTY"

# Check for misaligned empty lines
if [[ "$SRC_EMPTY" -gt 0 ]] || [[ "$TGT_EMPTY" -gt 0 ]]; then
    MISALIGNED=$(paste "$SRC" "$TGT" | awk -F'\t' '{
        s_empty = ($1 ~ /^[[:space:]]*$/)
        t_empty = ($2 ~ /^[[:space:]]*$/)
        if (s_empty != t_empty) count++
    } END { print count+0 }')
    if [[ "$MISALIGNED" -gt 0 ]]; then
        warn "$MISALIGNED line(s) where only one side is empty"
    else
        success "Empty lines are aligned"
    fi
fi

# Length ratio analysis
echo ""
# ─── AI Enhancement (Claude Opus): Statistical length ratio analysis ───
echo -e "${BOLD}── Length Ratio Analysis ──${NC}"
paste "$SRC" "$TGT" | awk -F'\t' '
{
    s = split($1, sw, /[[:space:]]+/)
    t = split($2, tw, /[[:space:]]+/)
    if (t > 0) ratio = s / t; else ratio = 0
    total += ratio
    if (ratio < 0.3 || ratio > 3.0) suspicious++
    count++
}
END {
    avg = total / count
    printf "  %-25s %.2f\n", "Mean length ratio:", avg
    printf "  %-25s %d (%.1f%%)\n", "Suspicious pairs:", suspicious+0, (suspicious+0)*100/count
    print ""
    if (suspicious+0 > 0)
        printf "  ⚠  %d pair(s) have ratio < 0.3 or > 3.0\n", suspicious+0
}'
echo ""
