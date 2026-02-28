#!/usr/bin/env bash
# data_profile.sh — Comprehensive dataset profiling report
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "data_profile" "Comprehensive dataset profiling report" \
        "data_profile.sh -i data.csv" \
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
COLS=$(count_columns "$INPUT" "$DELIM")
FILE_SIZE=$(ls -lh "$INPUT" | awk '{print $5}')
ENCODING=$(file -bi "$INPUT" 2>/dev/null | sed 's/.*charset=//')

echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Dataset Profile Report         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}── Overview ──${NC}"
printf "  %-20s %s\n" "File:" "$(basename "$INPUT")"
printf "  %-20s %s\n" "Size:" "$FILE_SIZE"
printf "  %-20s %s\n" "Encoding:" "$ENCODING"
printf "  %-20s %s\n" "Rows:" "$(format_number $TOTAL)"
printf "  %-20s %s\n" "Columns:" "$COLS"

# Delimiter info
if [[ "$DELIM" == $'\t' ]]; then
    printf "  %-20s %s\n" "Format:" "TSV"
else
    printf "  %-20s %s\n" "Format:" "CSV"
fi

# Empty lines
EMPTY=$(grep -c '^[[:space:]]*$' "$INPUT" 2>/dev/null || echo "0")
DUPES=$(tail -n +2 "$INPUT" | sort | uniq -d | wc -l | tr -d ' ')

echo ""
echo -e "${BOLD}── Data Quality ──${NC}"
printf "  %-20s %s\n" "Empty lines:" "$EMPTY"
printf "  %-20s %s\n" "Duplicate rows:" "$DUPES"

# Per-column analysis
echo ""
echo -e "${BOLD}── Column Analysis ──${NC}"
echo ""

awk -F"$DELIM" -v total="$TOTAL" '
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
        
        if (val == "" || lval == "null" || lval == "na" || lval == "n/a" || lval == "none") {
            missing[i]++
        } else {
            nonempty[i]++
            len = length(val)
            total_len[i] += len
            if (len < min_len[i] || nonempty[i] == 1) min_len[i] = len
            if (len > max_len[i]) max_len[i] = len
        }
        unique[i][val] = 1
    }
}
END {
    for (i=1; i<=ncols; i++) {
        ucount = 0
        for (v in unique[i]) ucount++
        
        m = missing[i]+0
        n = nonempty[i]+0
        avg = (n > 0) ? total_len[i]/n : 0
        
        printf "  Column %d: %s\n", i, name[i]
        printf "    Non-null: %d/%d (%.1f%%)\n", n, total, n*100/total
        printf "    Missing:  %d (%.1f%%)\n", m, m*100/total
        printf "    Unique:   %d", ucount
        if (ucount == total) printf " (all unique - possible ID)"
        else if (ucount <= 10) printf " (categorical)"
        printf "\n"
        if (n > 0) {
            printf "    Avg length: %.1f chars\n", avg
            printf "    Min length: %d | Max length: %d\n", min_len[i], max_len[i]
        }
        print ""
    }
}' "$INPUT"
