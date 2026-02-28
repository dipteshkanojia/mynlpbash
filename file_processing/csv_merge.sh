#!/usr/bin/env bash
# csv_merge.sh — Vertically merge (concatenate) multiple CSV/TSV files
# Author: Diptesh
# Status: Original — foundational script
# csv_merge.sh — Vertically merge (concatenate) multiple CSV/TSV files was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_merge" "Vertically merge multiple CSV/TSV files" \
        "csv_merge.sh -i file1.csv file2.csv [...] [-o output.csv]" \
        "-i, --input"     "Input files (multiple)" \
        "-o, --output"    "Output file (default: stdout)" \
        "--no-header"     "Input files have no header" \
        "-h, --help"      "Show this help"
}

FILES=() ; OUTPUT="" ; NO_HEADER=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                FILES+=("$1"); shift
            done ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        --no-header)  NO_HEADER=1; shift ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ ${#FILES[@]} -lt 2 ]] && die "At least 2 input files required"
for f in "${FILES[@]}"; do require_file "$f"; done

process() {
    local first=1
    local total_rows=0
    for f in "${FILES[@]}"; do
        if [[ $first -eq 1 ]]; then
            cat "$f"
            first=0
        elif [[ $NO_HEADER -eq 1 ]]; then
            cat "$f"
        else
            tail -n +2 "$f"
        fi
        total_rows=$(( total_rows + $(wc -l < "$f" | tr -d ' ') ))
    done
    info "Merged ${#FILES[@]} files, ~$total_rows total lines" >&2
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Merged ${#FILES[@]} files → $OUTPUT"
else
    process
fi
