#!/usr/bin/env bash
# length_ratio.sh — Compute and filter by source/target length ratios
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "length_ratio" "Compute and filter by source/target length ratios" \
        "length_ratio.sh -s source.txt -t target.txt [--min 0.5 --max 2.0]" \
        "-s, --source"  "Source language file" \
        "-t, --target"  "Target language file" \
        "--min"          "Minimum ratio to keep (default: 0)" \
        "--max"          "Maximum ratio to keep (default: inf)" \
        "--report"       "Show ratio distribution report" \
        "-o, --output"  "Output prefix for filtered files" \
        "-h, --help"    "Show this help"
}

SRC="" ; TGT="" ; MIN=0 ; MAX=999999 ; REPORT=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SRC="$2"; shift 2 ;;
        -t|--target) TGT="$2"; shift 2 ;;
        --min)       MIN="$2"; shift 2 ;;
        --max)       MAX="$2"; shift 2 ;;
        --report)    REPORT=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
require_file "$SRC"; require_file "$TGT"

if [[ $REPORT -eq 1 ]]; then
    echo -e "${BOLD}═══ Length Ratio Distribution ═══${NC}"
    echo ""
    paste "$SRC" "$TGT" | awk -F'\t' '
    {
        st = split($1, sw, /[[:space:]]+/)
        tt = split($2, tw, /[[:space:]]+/)
        if (tt > 0) ratio = st/tt; else ratio = 0
        if (ratio < 0.5) bucket["< 0.5"]++
        else if (ratio < 0.8) bucket["0.5-0.8"]++
        else if (ratio < 1.2) bucket["0.8-1.2"]++
        else if (ratio < 2.0) bucket["1.2-2.0"]++
        else if (ratio < 3.0) bucket["2.0-3.0"]++
        else bucket[">= 3.0"]++
        count++
    }
    END {
        labels[1]="< 0.5"; labels[2]="0.5-0.8"; labels[3]="0.8-1.2"
        labels[4]="1.2-2.0"; labels[5]="2.0-3.0"; labels[6]=">= 3.0"
        for (i=1; i<=6; i++) {
            l = labels[i]; c = bucket[l]+0
            pct = c*100/count
            bar_len = int(pct * 30 / 100)
            bar = ""; for (j=0; j<bar_len; j++) bar = bar "█"
            printf "  %-10s %6d (%5.1f%%) %s\n", l, c, pct, bar
        }
    }'
    echo ""
fi

if [[ -n "$OUTPUT" ]]; then
    paste "$SRC" "$TGT" | awk -F'\t' -v min="$MIN" -v max="$MAX" \
        -v src_out="${OUTPUT}.src" -v tgt_out="${OUTPUT}.tgt" '
    {
        st = split($1, sw, /[[:space:]]+/)
        tt = split($2, tw, /[[:space:]]+/)
        if (tt > 0) ratio = st/tt; else ratio = 0
        if (ratio >= min && ratio <= max) {
            print $1 > src_out
            print $2 > tgt_out
            kept++
        }
        total++
    }
    END {
        printf "Kept %d/%d pairs (%.1f%%) with ratio in [%.1f, %.1f]\n", kept, total, kept*100/total, min, max > "/dev/stderr"
    }'
    success "Filtered → ${OUTPUT}.src, ${OUTPUT}.tgt"
elif [[ $REPORT -eq 0 ]]; then
    # Just print ratios
    paste "$SRC" "$TGT" | awk -F'\t' '{
        st = split($1, sw, /[[:space:]]+/)
        tt = split($2, tw, /[[:space:]]+/)
        if (tt > 0) ratio = st/tt; else ratio = 0
        printf "%d\t%.3f\t%s\t%s\n", NR, ratio, $1, $2
    }'
fi
