#!/usr/bin/env bash
# csv_stats.sh — Display basic statistics about a CSV/TSV file
# Author: Diptesh
# Status: Original — foundational script
# csv_stats.sh — Display basic statistics about a CSV/TSV file was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_stats" "Display basic statistics about a CSV/TSV file" \
        "csv_stats.sh -i input.csv" \
        "-i, --input"     "Input CSV/TSV file" \
        "-d, --delimiter" "Delimiter (auto-detected if omitted)" \
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

TOTAL_LINES=$(wc -l < "$INPUT" | tr -d ' ')
ROWS=$(( TOTAL_LINES - 1 ))
COLS=$(count_columns "$INPUT" "$DELIM")
FILE_SIZE=$(ls -lh "$INPUT" | awk '{print $5}')
FILE_BYTES=$(wc -c < "$INPUT" | tr -d ' ')

if [[ "$DELIM" == $'\t' ]]; then
    DELIM_NAME="TAB (TSV)"
else
    DELIM_NAME="$DELIM (CSV)"
fi

echo -e "${BOLD}═══ File Statistics ═══${NC}"
echo ""
printf "  %-20s %s\n" "File:" "$(basename "$INPUT")"
printf "  %-20s %s\n" "Size:" "$FILE_SIZE ($FILE_BYTES bytes)"
printf "  %-20s %s\n" "Delimiter:" "$DELIM_NAME"
printf "  %-20s %s\n" "Rows:" "$(format_number $ROWS)"
printf "  %-20s %s\n" "Columns:" "$COLS"
echo ""
echo -e "${BOLD}═══ Columns ═══${NC}"
echo ""
get_column_names "$INPUT" "$DELIM" | while IFS= read -r line; do
    printf "  %s\n" "$line"
done

# Column-level stats
echo ""
# ─── AI Enhancement (Claude Opus): Rich formatted column analysis ──────
echo -e "${BOLD}═══ Column Details ═══${NC}"
echo ""
printf "  ${DIM}%-6s %-20s %8s %8s %8s${NC}\n" "Col#" "Name" "Non-empty" "Empty" "Unique"
separator " " 60 | head -c 60; echo

head -1 "$INPUT" | awk -F"$DELIM" '{for(i=1;i<=NF;i++) print $i}' | while IFS= read -r colname; do
    idx=$(find_column_index "$INPUT" "$colname" "$DELIM")
    if [[ -n "$idx" ]]; then
        stats=$(awk -F"$DELIM" -v col="$idx" 'NR>1 {
            val=$col
            gsub(/^[ \t]+|[ \t]+$/, "", val)
            if (val == "" || val == "\"\"") empty++; else nonempty++
            seen[val]++
        } END {
            print nonempty+0, empty+0, length(seen)
        }' "$INPUT")
        nonempty=$(echo "$stats" | awk '{print $1}')
        empty=$(echo "$stats" | awk '{print $2}')
        unique=$(echo "$stats" | awk '{print $3}')
        printf "  %-6s %-20s %8s %8s %8s\n" "$idx" "$colname" "$nonempty" "$empty" "$unique"
    fi
done
echo ""
