#!/usr/bin/env bash
# missing_values.sh — Report missing/null/empty values per column
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "missing_values" "Report missing/null/empty values per column" \
        "missing_values.sh -i data.csv" \
        "-i, --input"     "Input CSV/TSV file" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

TOTAL=$(count_rows "$INPUT")

echo -e "${BOLD}═══ Missing Values Report ═══${NC}"
echo ""
printf "  %-15s %s\n" "File:" "$(basename "$INPUT")"
printf "  %-15s %s\n" "Total rows:" "$TOTAL"
echo ""
printf "  ${DIM}%-6s %-20s %8s %7s   %s${NC}\n" "Col#" "Name" "Missing" "%" "Status"
separator " " 65 | head -c 65; echo

awk -F"$DELIM" '
NR==1 {
    for (i=1; i<=NF; i++) {
        name[i] = $i
        gsub(/^[ \t]+|[ \t]+$/, "", name[i])
        gsub(/^"|"$/, "", name[i])
    }
    ncols = NF
    next
}
{
    for (i=1; i<=ncols; i++) {
        val = $i
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        gsub(/^"|"$/, "", val)
        lval = tolower(val)
        if (val == "" || lval == "null" || lval == "na" || lval == "n/a" || lval == "none" || lval == "nan" || lval == "nil" || val == "-") {
            missing[i]++
        }
    }
    total++
}
END {
    for (i=1; i<=ncols; i++) {
        m = missing[i] + 0
        pct = (total > 0) ? m * 100 / total : 0
        status = "✓"
        if (pct > 0 && pct <= 5) status = "⚠ low"
        else if (pct > 5 && pct <= 20) status = "⚠ moderate"
        else if (pct > 20) status = "✗ high"
        printf "  %-6d %-20s %8d %6.1f%%   %s\n", i, name[i], m, pct, status
    }
}' "$INPUT"
echo ""
