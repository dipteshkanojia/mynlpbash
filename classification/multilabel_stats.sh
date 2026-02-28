#!/usr/bin/env bash
# multilabel_stats.sh — Multi-label co-occurrence and cardinality stats
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "multilabel_stats" "Multi-label co-occurrence and cardinality statistics" \
        "multilabel_stats.sh -i data.csv -c labels [-s ',']" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Labels column (name or index)" \
        "-s, --sep"       "Label separator within field (default: ,)" \
        "-d, --delimiter" "File delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; SEP="," ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -s|--sep)       SEP="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Label column required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

echo -e "${BOLD}═══ Multi-Label Statistics ═══${NC}"
echo ""

awk -F"$DELIM" -v col="$COL_IDX" -v sep="$SEP" '
NR==1 { next }
{
    field = $col
    gsub(/^[ \t]+|[ \t]+$/, "", field)
    gsub(/^"|"$/, "", field)
    
    n = split(field, labels, sep)
    total_labels += n
    cardinality[n]++
    samples++
    
    for (i=1; i<=n; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", labels[i])
        label_counts[labels[i]]++
        unique_labels[labels[i]] = 1
        
        for (j=i+1; j<=n; j++) {
            gsub(/^[ \t]+|[ \t]+$/, "", labels[j])
            a = labels[i]; b = labels[j]
            if (a > b) { tmp=a; a=b; b=tmp }
            cooccur[a " + " b]++
        }
    }
}
END {
    printf "  %-25s %d\n", "Total samples:", samples
    ul = 0; for (l in unique_labels) ul++
    printf "  %-25s %d\n", "Unique labels:", ul
    printf "  %-25s %.2f\n", "Avg label cardinality:", total_labels/samples
    print ""
    
    print "  Label Counts:"
    for (l in label_counts) {
        printf "    %-20s %d\n", l, label_counts[l]
    }
    
    print ""
    print "  Cardinality Distribution:"
    for (c in cardinality) {
        printf "    %s label(s): %d samples (%.1f%%)\n", c, cardinality[c], cardinality[c]*100/samples
    }
    
    if (length(cooccur) > 0) {
        print ""
        print "  Co-occurrences:"
        for (pair in cooccur) {
            printf "    %-30s %d\n", pair, cooccur[pair]
        }
    }
}' "$INPUT"
echo ""
