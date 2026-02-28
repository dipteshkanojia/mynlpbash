#!/usr/bin/env bash
# annotation_agreement.sh — Compute inter-annotator agreement
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "annotation_agreement" "Compute Cohen's kappa and percentage agreement" \
        "annotation_agreement.sh -a annotator1.txt -b annotator2.txt" \
        "-a, --ann-a"    "First annotator labels (one per line)" \
        "-b, --ann-b"    "Second annotator labels (one per line)" \
        "-h, --help"     "Show this help"
}

ANN_A="" ; ANN_B=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--ann-a) ANN_A="$2"; shift 2 ;;
        -b|--ann-b) ANN_B="$2"; shift 2 ;;
        -h|--help)  show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$ANN_A" ]] && die "Annotator A file required (-a)"
[[ -z "$ANN_B" ]] && die "Annotator B file required (-b)"
require_file "$ANN_A"; require_file "$ANN_B"

echo -e "${BOLD}═══ Inter-Annotator Agreement ═══${NC}"
echo ""

paste "$ANN_A" "$ANN_B" | awk -F'\t' '
{
    a = $1; b = $2
    gsub(/^[ \t]+|[ \t]+$/, "", a)
    gsub(/^[ \t]+|[ \t]+$/, "", b)
    
    count_a[a]++
    count_b[b]++
    if (a == b) agree++
    labels[a] = 1; labels[b] = 1
    total++
}
END {
    # Observed agreement
    po = agree / total
    
    # Expected agreement (by chance)
    pe = 0
    for (l in labels) {
        pa = (count_a[l] + 0) / total
        pb = (count_b[l] + 0) / total
        pe += pa * pb
    }
    
    # Cohens kappa
    if (pe < 1) kappa = (po - pe) / (1 - pe)
    else kappa = 1
    
    printf "  %-25s %d\n", "Total items:", total
    printf "  %-25s %d\n", "Agreements:", agree
    printf "  %-25s %d\n", "Disagreements:", total - agree
    print ""
    printf "  %-25s %.4f (%.1f%%)\n", "Observed agreement:", po, po*100
    printf "  %-25s %.4f (%.1f%%)\n", "Expected agreement:", pe, pe*100
    printf "  %-25s %.4f\n", "Cohen'\''s kappa:", kappa
    print ""
    
    # Interpretation
    if (kappa < 0) interp = "Poor (less than chance)"
    else if (kappa < 0.20) interp = "Slight"
    else if (kappa < 0.40) interp = "Fair"
    else if (kappa < 0.60) interp = "Moderate"
    else if (kappa < 0.80) interp = "Substantial"
    else interp = "Almost perfect"
    
    printf "  Interpretation: %s agreement\n", interp
}'
echo ""
