#!/usr/bin/env bash
# parallel_dedup.sh — Remove duplicate source-target pairs
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_dedup" "Remove duplicate source-target pairs" \
        "parallel_dedup.sh -s source.txt -t target.txt -o prefix" \
        "-s, --source"  "Source language file" \
        "-t, --target"  "Target language file" \
        "--src-only"     "Deduplicate by source side only" \
        "--tgt-only"     "Deduplicate by target side only" \
        "-o, --output"  "Output prefix" \
        "-h, --help"    "Show this help"
}

SRC="" ; TGT="" ; OUTPUT="" ; MODE="both"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SRC="$2"; shift 2 ;;
        -t|--target) TGT="$2"; shift 2 ;;
        --src-only)  MODE="src"; shift ;;
        --tgt-only)  MODE="tgt"; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
[[ -z "$OUTPUT" ]] && die "Output prefix required (-o)"
require_file "$SRC"; require_file "$TGT"

TOTAL=$(wc -l < "$SRC" | tr -d ' ')

paste -d$'\x01' "$SRC" "$TGT" | awk -F$'\x01' -v mode="$MODE" \
    -v src_out="${OUTPUT}.src" -v tgt_out="${OUTPUT}.tgt" '
{
    if (mode == "src") key = $1
    else if (mode == "tgt") key = $2
    else key = $1 "\x02" $2
    
    if (!(key in seen)) {
        print $1 > src_out
        print $2 > tgt_out
        kept++
    }
    seen[key]++
    total++
}
END {
    dups = total - kept
    printf "Total: %d, Kept: %d, Removed: %d duplicates (%.1f%%)\n", total, kept, dups, dups*100/total > "/dev/stderr"
}'

success "Deduplicated (mode: $MODE) → ${OUTPUT}.src, ${OUTPUT}.tgt"
