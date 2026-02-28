#!/usr/bin/env bash
# prediction_compare.sh — Compare two prediction files
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "prediction_compare" "Compare two prediction files, show agreements/disagreements" \
        "prediction_compare.sh -a pred1.txt -b pred2.txt [-g gold.txt]" \
        "-a, --pred-a"   "First prediction file" \
        "-b, --pred-b"   "Second prediction file" \
        "-g, --gold"     "Optional gold file for correctness analysis" \
        "-h, --help"     "Show this help"
}

PRED_A="" ; PRED_B="" ; GOLD=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--pred-a) PRED_A="$2"; shift 2 ;;
        -b|--pred-b) PRED_B="$2"; shift 2 ;;
        -g|--gold)   GOLD="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$PRED_A" ]] && die "Prediction file A required (-a)"
[[ -z "$PRED_B" ]] && die "Prediction file B required (-b)"
require_file "$PRED_A"; require_file "$PRED_B"

echo -e "${BOLD}═══ Prediction Comparison ═══${NC}"
echo ""

if [[ -n "$GOLD" ]]; then
    require_file "$GOLD"
    paste "$GOLD" "$PRED_A" "$PRED_B" | awk -F'\t' '
    {
        g=$1; a=$2; b=$3
        gsub(/^[ \t]+|[ \t]+$/, "", g)
        gsub(/^[ \t]+|[ \t]+$/, "", a)
        gsub(/^[ \t]+|[ \t]+$/, "", b)
        total++
        
        if (a == b) {
            agree++
            if (a == g) both_correct++
            else both_wrong++
        } else {
            disagree++
            if (a == g) a_correct++
            else if (b == g) b_correct++
            else neither_correct++
        }
    }
    END {
        printf "  %-30s %d\n", "Total samples:", total
        printf "  %-30s %d (%.1f%%)\n", "Agreement:", agree, agree*100/total
        printf "  %-30s %d (%.1f%%)\n", "Disagreement:", disagree, disagree*100/total
        print ""
        printf "  %-30s %d\n", "Both correct:", both_correct+0
        printf "  %-30s %d\n", "Both wrong:", both_wrong+0
        printf "  %-30s %d\n", "Only A correct:", a_correct+0
        printf "  %-30s %d\n", "Only B correct:", b_correct+0
        printf "  %-30s %d\n", "Neither correct:", neither_correct+0
        print ""
        a_acc = (both_correct + a_correct) * 100 / total
        b_acc = (both_correct + b_correct) * 100 / total
        printf "  A accuracy: %.1f%%\n", a_acc
        printf "  B accuracy: %.1f%%\n", b_acc
    }'
else
    paste "$PRED_A" "$PRED_B" | awk -F'\t' '
    {
        a=$1; b=$2
        gsub(/^[ \t]+|[ \t]+$/, "", a)
        gsub(/^[ \t]+|[ \t]+$/, "", b)
        total++
        if (a == b) agree++; else disagree++
    }
    END {
        printf "  %-25s %d\n", "Total samples:", total
        printf "  %-25s %d (%.1f%%)\n", "Agreement:", agree, agree*100/total
        printf "  %-25s %d (%.1f%%)\n", "Disagreement:", disagree, disagree*100/total
    }'
fi
echo ""
