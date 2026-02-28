#!/usr/bin/env bash
# find_duplicates.sh — Find duplicate rows with occurrence counts
# Author: Diptesh
# Status: Original — foundational script
# find_duplicates.sh — Find duplicate rows with occurrence counts was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "find_duplicates" "Find duplicate rows with occurrence counts" \
        "find_duplicates.sh -i input.csv [-c column] [--top 20]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Check specific column only (name or index)" \
        "--top"            "Show top N duplicates (default: all)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; TOP="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        --top)          TOP="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

echo -e "${BOLD}═══ Duplicate Analysis ═══${NC}"
echo ""

if [[ -n "$COLUMN" ]]; then
    if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
        COL_IDX="$COLUMN"
    else
        COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
        [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
    fi
    info "Checking duplicates in column: $COLUMN (index $COL_IDX)"
    echo ""
    
    tail -n +2 "$INPUT" | awk -F"$DELIM" -v col="$COL_IDX" '{
        val=$col; gsub(/^[ \t]+|[ \t]+$/, "", val); gsub(/^"|"$/, "", val)
        print val
    }' | sort | uniq -c | sort -rn | awk '$1 > 1 {
        printf "  %6d × %s\n", $1, substr($0, index($0,$2))
        dup_count++; dup_total += $1
    }
    END {
        printf "\n  %d unique values with duplicates (%d total duplicate rows)\n", dup_count+0, dup_total+0
    }' | { [[ -n "$TOP" ]] && head -n "$((TOP + 2))" || cat; }
else
    TOTAL=$(count_rows "$INPUT")
    tail -n +2 "$INPUT" | sort | uniq -c | sort -rn | awk '$1 > 1 {
        printf "  %6d × %s\n", $1, substr($0, index($0,$2))
        dup_count++; dup_total += $1
    }
    END {
        printf "\n  %d unique rows with duplicates (%d total duplicate rows)\n", dup_count+0, dup_total+0
    }' | { [[ -n "$TOP" ]] && head -n "$((TOP + 2))" || cat; }
fi
echo ""
