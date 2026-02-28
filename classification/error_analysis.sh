#!/usr/bin/env bash
# error_analysis.sh — Extract and analyze misclassified samples
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 classification utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "error_analysis" "Extract misclassified samples grouped by confusion pair" \
        "error_analysis.sh -g gold.txt -p pred.txt [-t texts.txt]" \
        "-g, --gold"       "Gold/reference labels file" \
        "-p, --predicted"  "Predicted labels file" \
        "-t, --text"       "Text file (aligned, one per line)" \
        "--top"             "Show top N errors per pair (default: 3)" \
        "-o, --output"     "Output file (default: stdout)" \
        "-h, --help"       "Show this help"
}

GOLD="" ; PRED="" ; TEXT="" ; TOP=3 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--gold)      GOLD="$2"; shift 2 ;;
        -p|--predicted) PRED="$2"; shift 2 ;;
        -t|--text)      TEXT="$2"; shift 2 ;;
        --top)          TOP="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$GOLD" ]] && die "Gold file required (-g)"
[[ -z "$PRED" ]] && die "Predicted file required (-p)"
require_file "$GOLD"; require_file "$PRED"

process() {
    echo -e "${BOLD}═══ Error Analysis ═══${NC}"
    echo ""
    
    if [[ -n "$TEXT" ]]; then
        require_file "$TEXT"
        paste "$GOLD" "$PRED" "$TEXT"
    else
        paste "$GOLD" "$PRED" | awk -F'\t' '{print $1 "\t" $2 "\t(no text)"}'
    fi | awk -F'\t' -v top="$TOP" '
    {
        g = $1; p = $2; t = $3
        gsub(/^[ \t]+|[ \t]+$/, "", g)
        gsub(/^[ \t]+|[ \t]+$/, "", p)
        total++
        if (g != p) {
            errors++
            pair = g " → " p
            pair_count[pair]++
            # Store examples (up to top)
            idx = pair_count[pair]
            if (idx <= top) {
                examples[pair, idx] = sprintf("L%d: %s", NR, substr(t, 1, 80))
            }
        }
    }
    END {
        printf "  Total samples:  %d\n", total
        printf "  Errors:         %d (%.1f%%)\n", errors, errors*100/total
        printf "  Error pairs:    %d\n\n", length(pair_count)
        
        # Sort pairs by frequency
        n = 0
        for (p in pair_count) { n++; pairs[n] = p; counts[n] = pair_count[p] }
        for (i=2; i<=n; i++) {
            kc = counts[i]; kp = pairs[i]; j = i-1
            while (j>0 && counts[j] < kc) { counts[j+1] = counts[j]; pairs[j+1] = pairs[j]; j-- }
            counts[j+1] = kc; pairs[j+1] = kp
        }
        
        for (i=1; i<=n; i++) {
            p = pairs[i]; c = counts[i]
            printf "  %-30s  %d errors (%.1f%%)\n", p, c, c*100/errors
            show = (c < top) ? c : top
            for (e=1; e<=show; e++) {
                printf "    %s\n", examples[p, e]
            }
            print ""
        }
    }'
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Error analysis → $OUTPUT"
else
    process
    echo ""
fi
