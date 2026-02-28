#!/usr/bin/env bash
# color_matrix.sh — Color-coded confusion matrix with intensity scaling
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "color_matrix" "Color-coded confusion matrix with ANSI intensity" \
        "color_matrix.sh -g gold.txt -p pred.txt" \
        "-g, --gold"       "Gold/reference labels file" \
        "-p, --predicted"  "Predicted labels file" \
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

echo -e "${BOLD}═══ Color Confusion Matrix ═══${NC}"
echo ""

paste "$GOLD" "$PRED" | awk -F'\t' '
{
    g=$1; p=$2
    gsub(/^[ \t]+|[ \t]+$/, "", g)
    gsub(/^[ \t]+|[ \t]+$/, "", p)
    matrix[g, p]++
    all[g]=1; all[p]=1
    if (g==p) correct++
    total++
}
END {
    # Sort labels
    n=0; for (l in all) { n++; labels[n]=l }
    for (i=2; i<=n; i++) {
        key=labels[i]; j=i-1
        while (j>0 && labels[j]>key) { labels[j+1]=labels[j]; j-- }
        labels[j+1]=key
    }
    
    # Find max for scaling
    mx=0
    for (i=1; i<=n; i++) for (j=1; j<=n; j++) {
        v = matrix[labels[i], labels[j]] + 0
        if (v > mx) mx = v
    }
    
    # Header
    printf "  %-12s", "Gold\\Pred"
    for (j=1; j<=n; j++) printf " %10s", labels[j]
    print ""
    printf "  %-12s", ""
    for (j=1; j<=n; j++) printf " %10s", "──────────"
    print ""
    
    # Matrix with colors
    for (i=1; i<=n; i++) {
        printf "  %-12s", labels[i]
        for (j=1; j<=n; j++) {
            v = matrix[labels[i], labels[j]] + 0
            if (v == 0) {
                printf " %10s", "·"
            } else if (i == j) {
                # Diagonal = correct = green intensity
                intensity = int(v * 4 / mx)
                if (intensity >= 3) color = "\033[1;32m"
                else if (intensity >= 2) color = "\033[0;32m"
                else color = "\033[2;32m"
                printf " %s%10d\033[0m", color, v
            } else {
                # Off-diagonal = errors = red intensity
                intensity = int(v * 4 / mx)
                if (intensity >= 3) color = "\033[1;31m"
                else if (intensity >= 2) color = "\033[0;31m"
                else color = "\033[2;31m"
                printf " %s%10d\033[0m", color, v
            }
        }
        print ""
    }
    
    print ""
    acc = correct / total
    printf "  Accuracy: %d/%d = %.4f (%.1f%%)\n", correct, total, acc, acc*100
    printf "  Legend: \033[32m■ correct\033[0m  \033[31m■ errors\033[0m  (intensity = frequency)\n"
}'
echo ""
