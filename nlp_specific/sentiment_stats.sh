#!/usr/bin/env bash
# sentiment_stats.sh — Sentiment-specific statistics
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "sentiment_stats" "Sentiment-specific statistics (polarity distribution, per-class lengths)" \
        "sentiment_stats.sh -i data.csv -c label -t text" \
        "-i, --input"      "Input CSV/TSV file" \
        "-c, --column"     "Sentiment label column" \
        "-t, --text-col"   "Text column" \
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

echo -e "${BOLD}═══ Sentiment Analysis Statistics ═══${NC}"
echo ""

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
    
    exc = gsub(/!/, "!", text)
    qst = gsub(/\?/, "?", text)
    caps = 0
    for (i=1; i<=toks; i++) {
        if (w[i] ~ /^[A-Z][A-Z]+$/) caps++
    }
    
    count[label]++
    total_len[label] += tlen
    total_toks[label] += toks
    total_exc[label] += exc
    total_qst[label] += qst
    total_caps[label] += caps
    total++
}
END {
    printf "  %-15s %6s %7s\n", "Sentiment", "Count", "%"
    printf "  %-15s %6s %7s\n", "─────────", "─────", "───"
    for (l in count) {
        printf "  %-15s %6d %6.1f%%\n", l, count[l], count[l]*100/total
    }
    
    print ""
    printf "  %-15s %8s %8s %8s %8s %8s\n", "Sentiment", "AvgLen", "AvgToks", "Avg!", "Avg?", "AvgCAPS"
    printf "  %-15s %8s %8s %8s %8s %8s\n", "─────────", "──────", "──────", "────", "────", "──────"
    for (l in count) {
        c = count[l]
        printf "  %-15s %8.1f %8.1f %8.2f %8.2f %8.2f\n", l, total_len[l]/c, total_toks[l]/c, total_exc[l]/c, total_qst[l]/c, total_caps[l]/c
    }
}' "$INPUT"
echo ""
