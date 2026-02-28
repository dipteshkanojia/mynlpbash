#!/usr/bin/env bash
# confusion_matrix.sh — Build confusion matrix from gold and predicted labels
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "confusion_matrix" "Build confusion matrix from gold and predicted labels" \
        "confusion_matrix.sh -g gold.txt -p pred.txt" \
        "-g, --gold"       "Gold/reference labels file (one per line)" \
        "-p, --predicted"  "Predicted labels file (one per line)" \
        "-h, --help"       "Show this help"
}

GOLD="" ; PRED=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--gold)      GOLD="$2"; shift 2 ;;
        -p|--predicted) PRED="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$GOLD" ]] && die "Gold file required (-g)"
[[ -z "$PRED" ]] && die "Predicted file required (-p)"
require_file "$GOLD"; require_file "$PRED"

G_LINES=$(wc -l < "$GOLD" | tr -d ' ')
P_LINES=$(wc -l < "$PRED" | tr -d ' ')
[[ "$G_LINES" -ne "$P_LINES" ]] && die "Line count mismatch: gold=$G_LINES, pred=$P_LINES"

echo -e "${BOLD}═══ Confusion Matrix ═══${NC}"
echo ""

paste "$GOLD" "$PRED" | awk -F'\t' '
{
    g = $1; p = $2
    gsub(/^[ \t]+|[ \t]+$/, "", g)
    gsub(/^[ \t]+|[ \t]+$/, "", p)
    matrix[g, p]++
    all_labels[g] = 1
    all_labels[p] = 1
    if (g == p) correct++
    total++
}
END {
    # Collect and sort labels
    n = 0
    for (l in all_labels) { n++; labels[n] = l }
    for (i=2; i<=n; i++) {
        key = labels[i]
        j = i - 1
        while (j > 0 && labels[j] > key) {
            labels[j+1] = labels[j]
            j--
        }
        labels[j+1] = key
    }
    
    # Header
    printf "%-12s", "Gold\\Pred"
    for (j=1; j<=n; j++) printf " %10s", labels[j]
    print ""
    
    printf "%-12s", "────────"
    for (j=1; j<=n; j++) printf " %10s", "──────────"
    print ""
    
    for (i=1; i<=n; i++) {
        printf "%-12s", labels[i]
        for (j=1; j<=n; j++) {
            val = matrix[labels[i], labels[j]] + 0
            printf " %10d", val
        }
        print ""
    }
    
    print ""
    printf "Accuracy: %d/%d = %.4f (%.1f%%)\n", correct, total, correct/total, correct*100/total
}'
echo ""
