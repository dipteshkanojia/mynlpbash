#!/usr/bin/env bash
# classification_report.sh — Precision, recall, F1 per class + macro/micro/weighted
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "classification_report" "Precision, recall, F1 per class with macro/micro/weighted averages" \
        "classification_report.sh -g gold.txt -p pred.txt" \
        "-g, --gold"       "Gold/reference labels file (one per line)" \
        "-p, --predicted"  "Predicted labels file (one per line)" \
        "-o, --output"     "Output file (default: stdout)" \
        "-h, --help"       "Show this help"
}

GOLD="" ; PRED="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--gold)      GOLD="$2"; shift 2 ;;
        -p|--predicted) PRED="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$GOLD" ]] && die "Gold file required (-g)"
[[ -z "$PRED" ]] && die "Predicted file required (-p)"
require_file "$GOLD"; require_file "$PRED"

process() {
    echo -e "${BOLD}═══ Classification Report ═══${NC}"
    echo ""
    
    paste "$GOLD" "$PRED" | awk -F'\t' '
    {
        g = $1; p = $2
        gsub(/^[ \t]+|[ \t]+$/, "", g)
        gsub(/^[ \t]+|[ \t]+$/, "", p)
        
        gold_count[g]++
        pred_count[p]++
        if (g == p) tp[g]++
        all_labels[g] = 1
        all_labels[p] = 1
        total++
    }
    END {
        # Collect and sort labels using simple insertion sort
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
        
        printf "%-15s %9s %9s %9s %9s\n", "Label", "Precision", "Recall", "F1-Score", "Support"
        printf "%-15s %9s %9s %9s %9s\n", "───────", "─────────", "──────", "────────", "───────"
        
        total_tp = 0
        sum_p = 0; sum_r = 0; sum_f1 = 0
        w_sum_p = 0; w_sum_r = 0; w_sum_f1 = 0
        total_support = 0
        
        for (i=1; i<=n; i++) {
            l = labels[i]
            t = tp[l] + 0
            gc = gold_count[l] + 0
            pc = pred_count[l] + 0
            
            if (pc > 0) precision = t / pc; else precision = 0
            if (gc > 0) recall = t / gc; else recall = 0
            if (precision + recall > 0) f1 = 2 * precision * recall / (precision + recall); else f1 = 0
            
            printf "%-15s %9.4f %9.4f %9.4f %9d\n", l, precision, recall, f1, gc
            
            total_tp += t
            sum_p += precision; sum_r += recall; sum_f1 += f1
            w_sum_p += precision * gc; w_sum_r += recall * gc; w_sum_f1 += f1 * gc
            total_support += gc
        }
        
        print ""
        printf "%-15s %9s %9s %9s %9s\n", "───────", "─────────", "──────", "────────", "───────"
        
        acc = total_tp / total
        printf "%-15s %9s %9s %9.4f %9d\n", "accuracy", "", "", acc, total
        
        macro_p = sum_p / n
        macro_r = sum_r / n
        macro_f1 = sum_f1 / n
        printf "%-15s %9.4f %9.4f %9.4f %9d\n", "macro avg", macro_p, macro_r, macro_f1, total
        
        w_p = w_sum_p / total_support
        w_r = w_sum_r / total_support
        w_f1 = w_sum_f1 / total_support
        printf "%-15s %9.4f %9.4f %9.4f %9d\n", "weighted avg", w_p, w_r, w_f1, total
    }'
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Classification report → $OUTPUT"
else
    process
fi
echo ""
