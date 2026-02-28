#!/usr/bin/env bash
# parallel_extract.sh — Extract source/target from merged parallel file
# Author: Diptesh
# Status: Original — foundational script
# parallel_extract.sh — Extract source/target from merged parallel file was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_extract" "Extract source/target from merged parallel file" \
        "parallel_extract.sh -i merged.txt -o prefix" \
        "-i, --input"      "Input merged file" \
        "-d, --delimiter"  "Delimiter (default: TAB)" \
        "--src-col"         "Source column (default: 1)" \
        "--tgt-col"         "Target column (default: 2)" \
        "-o, --output"     "Output prefix (creates prefix.src, prefix.tgt)" \
        "-h, --help"       "Show this help"
}

INPUT="" ; OUTPUT="" ; DELIM=$'\t' ; SRC_COL=1 ; TGT_COL=2
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        --src-col)      SRC_COL="$2"; shift 2 ;;
        --tgt-col)      TGT_COL="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$OUTPUT" ]] && die "Output prefix required (-o)"
require_file "$INPUT"

cut -d"$DELIM" -f"$SRC_COL" "$INPUT" > "${OUTPUT}.src"
cut -d"$DELIM" -f"$TGT_COL" "$INPUT" > "${OUTPUT}.tgt"

LINES=$(wc -l < "${OUTPUT}.src" | tr -d ' ')
success "Extracted $LINES pairs → ${OUTPUT}.src, ${OUTPUT}.tgt"
