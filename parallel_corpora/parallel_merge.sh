#!/usr/bin/env bash
# parallel_merge.sh — Merge source + target into tab-separated single file
# Author: Diptesh
# Status: Original — foundational script
# parallel_merge.sh — Merge source + target into tab-separated single file was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_merge" "Merge source + target into tab-separated file" \
        "parallel_merge.sh -s source.txt -t target.txt [-o merged.txt]" \
        "-s, --source"     "Source language file" \
        "-t, --target"     "Target language file" \
        "-d, --delimiter"  "Merge delimiter (default: TAB)" \
        "-o, --output"     "Output file (default: stdout)" \
        "-h, --help"       "Show this help"
}

SRC="" ; TGT="" ; OUTPUT="" ; DELIM=$'\t'
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)    SRC="$2"; shift 2 ;;
        -t|--target)    TGT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
require_file "$SRC"; require_file "$TGT"

if [[ -n "$OUTPUT" ]]; then
    paste -d"$DELIM" "$SRC" "$TGT" > "$OUTPUT"
    LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
    success "Merged $LINES pairs → $OUTPUT"
else
    paste -d"$DELIM" "$SRC" "$TGT"
fi
