#!/usr/bin/env bash
# parallel_shuffle.sh — Shuffle parallel corpus maintaining alignment
# Author: Diptesh
# Status: Original — foundational script
# parallel_shuffle.sh — Shuffle parallel corpus maintaining alignment was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_shuffle" "Shuffle parallel corpus maintaining line alignment" \
        "parallel_shuffle.sh -s source.txt -t target.txt -o prefix" \
        "-s, --source"  "Source language file" \
        "-t, --target"  "Target language file" \
        "-o, --output"  "Output prefix (creates prefix.src, prefix.tgt)" \
        "-h, --help"    "Show this help"
}

SRC="" ; TGT="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SRC="$2"; shift 2 ;;
        -t|--target) TGT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
[[ -z "$OUTPUT" ]] && die "Output prefix required (-o)"
require_file "$SRC"; require_file "$TGT"

MERGED=$(make_temp)
paste -d$'\x01' "$SRC" "$TGT" > "$MERGED"

if command -v gshuf &>/dev/null; then
    gshuf "$MERGED"
elif command -v shuf &>/dev/null; then
    shuf "$MERGED"
else
    awk 'BEGIN{srand()} {print rand()"\t"$0}' "$MERGED" | sort -n | cut -f2-
fi | tee >(cut -d$'\x01' -f1 > "${OUTPUT}.src") | cut -d$'\x01' -f2 > "${OUTPUT}.tgt"

LINES=$(wc -l < "${OUTPUT}.src" | tr -d ' ')
success "Shuffled $LINES pairs → ${OUTPUT}.src, ${OUTPUT}.tgt"
