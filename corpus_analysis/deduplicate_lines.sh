#!/usr/bin/env bash
# deduplicate_lines.sh — Remove duplicate lines from text
# Author: Diptesh
# Status: Original — foundational script
# deduplicate_lines.sh — Remove duplicate lines from text was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "deduplicate_lines" "Remove duplicate lines from text" \
        "deduplicate_lines.sh -i input.txt [-o output.txt]" \
        "-i, --input"    "Input text file (or stdin)" \
        "-o, --output"   "Output file (default: stdout)" \
        "--case"          "Case-insensitive dedup" \
        "--trim"          "Trim whitespace before comparison" \
        "--report"        "Show deduplication report" \
        "-h, --help"     "Show this help"
}

INPUT="" ; OUTPUT="" ; CASE_I=0 ; TRIM=0 ; REPORT=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        --case)      CASE_I=1; shift ;;
        --trim)      TRIM=1; shift ;;
        --report)    REPORT=1; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

process() {
    local src
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        src="$INPUT"
    else
        src="/dev/stdin"
    fi

    awk -v case_i="$CASE_I" -v do_trim="$TRIM" -v report="$REPORT" '
    {
        line = $0
        key = line
        if (do_trim) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        }
        if (case_i) key = tolower(key)
        if (!(key in seen)) {
            print line
            unique++
        } else {
            dups++
        }
        seen[key]++
        total++
    }
    END {
        if (report) {
            printf "\n--- Deduplication Report ---\n" > "/dev/stderr"
            printf "  Total lines:      %d\n", total > "/dev/stderr"
            printf "  Unique lines:     %d\n", unique > "/dev/stderr"
            printf "  Duplicates found: %d\n", dups+0 > "/dev/stderr"
            printf "  Reduction:        %.1f%%\n", (dups+0)*100/total > "/dev/stderr"
        }
    }' "$src"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Deduplicated → $OUTPUT"
else
    process
fi
