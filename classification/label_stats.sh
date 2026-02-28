#!/usr/bin/env bash
# label_stats.sh — Per-label text length statistics
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "label_stats" "Per-label text length statistics" \
        "label_stats.sh -i data.csv -c label -t text" \
        "-i, --input"      "Input CSV/TSV file" \
        "-c, --column"     "Label column (name or index)" \
        "-t, --text-col"   "Text column (name or index)" \
        "-d, --delimiter"  "Delimiter (auto-detected)" \
        "-h, --help"       "Show this help"
}

INPUT="" ; COLUMN="" ; TEXT_COL="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -t|--text-col)  TEXT_COL="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Label column required (-c)"
[[ -z "$TEXT_COL" ]] && die "Text column required (-t)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

for var in COLUMN TEXT_COL; do
    val="${!var}"
    if [[ ! "$val" =~ ^[0-9]+$ ]]; then
        idx=$(find_column_index "$INPUT" "$val" "$DELIM")
        [[ -z "$idx" ]] && die "Column not found: $val"
        declare "${var}_IDX=$idx"
    else
        declare "${var}_IDX=$val"
    fi
done

echo -e "${BOLD}═══ Per-Label Text Statistics ═══${NC}"
echo ""
printf "  ${DIM}%-15s %6s %8s %8s %8s %8s${NC}\n" "Label" "Count" "AvgLen" "MinLen" "MaxLen" "AvgToks"
separator " " 65 | head -c 65; echo

awk -F"$DELIM" -v lcol="$COLUMN_IDX" -v tcol="$TEXT_COL_IDX" '
NR==1 { next }
{
    label = $lcol
    gsub(/^[ \t]+|[ \t]+$/, "", label)
    gsub(/^"|"$/, "", label)
    text = $tcol
    gsub(/^"|"$/, "", text)
    
    tlen = length(text)
    toks = split(text, w, /[[:space:]]+/)
    
    count[label]++
    total_len[label] += tlen
    total_toks[label] += toks
    if (!(label in min_len) || tlen < min_len[label]) min_len[label] = tlen
    if (tlen > max_len[label]) max_len[label] = tlen
}
END {
    # Collect and sort labels
    n = 0
    for (l in count) { n++; labels[n] = l }
    for (i=2; i<=n; i++) {
        key = labels[i]
        j = i - 1
        while (j > 0 && labels[j] > key) {
            labels[j+1] = labels[j]
            j--
        }
        labels[j+1] = key
    }
    for (i=1; i<=n; i++) {
        l = labels[i]
        avg_len = total_len[l] / count[l]
        avg_toks = total_toks[l] / count[l]
        printf "  %-15s %6d %8.1f %8d %8d %8.1f\n", l, count[l], avg_len, min_len[l], max_len[l], avg_toks
    }
}' "$INPUT"
echo ""
