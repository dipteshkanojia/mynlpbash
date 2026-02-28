#!/usr/bin/env bash
# parallel_stats.sh — Statistics on parallel corpus
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_stats" "Comprehensive statistics on parallel corpus" \
        "parallel_stats.sh -s source.txt -t target.txt" \
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

echo -e "${BOLD}═══ Parallel Corpus Statistics ═══${NC}"
echo ""

for side in source target; do
    if [[ "$side" == "source" ]]; then f="$SRC"; else f="$TGT"; fi
    side_label=$(echo "$side" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    echo -e "${BOLD}── ${side_label}: $(basename "$f") ──${NC}"
    awk '{
        tokens += NF
        chars += length($0)
        if (NF < min_t || NR==1) min_t = NF
        if (NF > max_t) max_t = NF
        lines++
    } END {
        printf "  %-20s %d\n", "Sentences:", lines
        printf "  %-20s %d\n", "Tokens:", tokens
        printf "  %-20s %d\n", "Characters:", chars
        printf "  %-20s %.1f\n", "Avg tokens/sent:", tokens/lines
        printf "  %-20s %d\n", "Min tokens/sent:", min_t
        printf "  %-20s %d\n", "Max tokens/sent:", max_t
        printf "  %-20s %d\n", "Vocabulary:", 0
    }' "$f"
    VOCAB=$(tr -s '[:space:][:punct:]' '\n' < "$f" | grep -v '^$' | sort -u | wc -l | tr -d ' ')
    printf "  %-20s %d\n" "Vocabulary:" "$VOCAB"
    echo ""
done

# Cross-side stats
echo -e "${BOLD}── Cross-side Analysis ──${NC}"
paste "$SRC" "$TGT" | awk -F'\t' '
{
    st = split($1, sw, /[[:space:]]+/)
    tt = split($2, tw, /[[:space:]]+/)
    if (tt > 0) { ratio = st/tt } else { ratio = 0 }
    total_r += ratio
    if (st == 0 && tt == 0) both_empty++
    if (st == 0 || tt == 0) one_empty++
    count++
}
END {
    printf "  %-25s %.3f\n", "Avg length ratio (s/t):", total_r/count
    printf "  %-25s %d\n", "Both-empty pairs:", both_empty+0
    printf "  %-25s %d\n", "One-side-empty pairs:", one_empty+0
}'
echo ""
