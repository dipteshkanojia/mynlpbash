#!/usr/bin/env bash
# parallel_filter.sh — Filter parallel corpus pairs by length, ratio, or pattern
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_filter" "Filter parallel corpus pairs" \
        "parallel_filter.sh -s src.txt -t tgt.txt --min-len 3 --max-len 100 -o prefix" \
        "-s, --source"     "Source language file" \
        "-t, --target"     "Target language file" \
        "--min-len"         "Min tokens per sentence (either side)" \
        "--max-len"         "Max tokens per sentence (either side)" \
        "--min-ratio"       "Min source/target length ratio" \
        "--max-ratio"       "Max source/target length ratio" \
        "--src-pattern"     "Keep pairs where source matches regex" \
        "--tgt-pattern"     "Keep pairs where target matches regex" \
        "--remove-empty"    "Remove pairs with empty lines" \
        "-o, --output"     "Output prefix" \
        "-h, --help"       "Show this help"
}

SRC="" ; TGT="" ; OUTPUT=""
MIN_LEN=0 ; MAX_LEN=999999 ; MIN_RATIO=0 ; MAX_RATIO=999999
SRC_PAT="" ; TGT_PAT="" ; RM_EMPTY=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)      SRC="$2"; shift 2 ;;
        -t|--target)      TGT="$2"; shift 2 ;;
        --min-len)        MIN_LEN="$2"; shift 2 ;;
        --max-len)        MAX_LEN="$2"; shift 2 ;;
        --min-ratio)      MIN_RATIO="$2"; shift 2 ;;
        --max-ratio)      MAX_RATIO="$2"; shift 2 ;;
        --src-pattern)    SRC_PAT="$2"; shift 2 ;;
        --tgt-pattern)    TGT_PAT="$2"; shift 2 ;;
        --remove-empty)   RM_EMPTY=1; shift ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
[[ -z "$OUTPUT" ]] && die "Output prefix required (-o)"
require_file "$SRC"; require_file "$TGT"

TOTAL=$(wc -l < "$SRC" | tr -d ' ')

paste -d$'\x01' "$SRC" "$TGT" | awk -F$'\x01' \
    -v min_len="$MIN_LEN" -v max_len="$MAX_LEN" \
    -v min_ratio="$MIN_RATIO" -v max_ratio="$MAX_RATIO" \
    -v src_pat="$SRC_PAT" -v tgt_pat="$TGT_PAT" \
    -v rm_empty="$RM_EMPTY" \
    -v src_out="${OUTPUT}.src" -v tgt_out="${OUTPUT}.tgt" '
{
    s = $1; t = $2
    sn = split(s, sw, /[[:space:]]+/)
    tn = split(t, tw, /[[:space:]]+/)
    
    keep = 1
    if (rm_empty && (s ~ /^[[:space:]]*$/ || t ~ /^[[:space:]]*$/)) keep = 0
    if (sn < min_len || tn < min_len) keep = 0
    if (sn > max_len || tn > max_len) keep = 0
    if (tn > 0) { ratio = sn/tn } else { ratio = 0 }
    if (ratio < min_ratio || ratio > max_ratio) keep = 0
    if (src_pat != "" && s !~ src_pat) keep = 0
    if (tgt_pat != "" && t !~ tgt_pat) keep = 0
    
    if (keep) {
        print s > src_out
        print t > tgt_out
        kept++
    }
    total++
}
END {
    removed = total - kept
    printf "Kept: %d/%d (%.1f%%), Removed: %d\n", kept, total, kept*100/total, removed > "/dev/stderr"
}'

success "Filtered → ${OUTPUT}.src, ${OUTPUT}.tgt"
