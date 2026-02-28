#!/usr/bin/env bash
# dataset_compare.sh — Compare two datasets (vocab overlap, label diff, length diff)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "dataset_compare" "Compare two datasets (vocab overlap, label distribution, lengths)" \
        "dataset_compare.sh -a train.csv -b test.csv -c label -t text" \
        "-a, --file-a"    "First dataset (CSV/TSV)" \
        "-b, --file-b"    "Second dataset (CSV/TSV)" \
        "-c, --label-col" "Label column (name or index)" \
        "-t, --text-col"  "Text column (name or index)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

FILE_A="" ; FILE_B="" ; LABEL="" ; TEXT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--file-a)    FILE_A="$2"; shift 2 ;;
        -b|--file-b)    FILE_B="$2"; shift 2 ;;
        -c|--label-col) LABEL="$2"; shift 2 ;;
        -t|--text-col)  TEXT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$FILE_A" ]] && die "File A required (-a)"
[[ -z "$FILE_B" ]] && die "File B required (-b)"
require_file "$FILE_A"; require_file "$FILE_B"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$FILE_A")

echo -e "${BOLD}═══ Dataset Comparison ═══${NC}"
echo ""

# Basic file stats
ROWS_A=$(awk 'END{print NR-1}' "$FILE_A")
ROWS_B=$(awk 'END{print NR-1}' "$FILE_B")
COLS_A=$(head -1 "$FILE_A" | awk -F"$DELIM" '{print NF}')
COLS_B=$(head -1 "$FILE_B" | awk -F"$DELIM" '{print NF}')

printf "  %-25s %-15s %-15s\n" "" "Dataset A" "Dataset B"
printf "  %-25s %-15s %-15s\n" "─────────" "─────────" "─────────"
printf "  %-25s %-15s %-15s\n" "File:" "$(basename "$FILE_A")" "$(basename "$FILE_B")"
printf "  %-25s %-15d %-15d\n" "Rows:" "$ROWS_A" "$ROWS_B"
printf "  %-25s %-15d %-15d\n" "Columns:" "$COLS_A" "$COLS_B"
echo ""

# Label distribution comparison
if [[ -n "$LABEL" ]]; then
    if [[ "$LABEL" =~ ^[0-9]+$ ]]; then
        LCOL="$LABEL"
    else
        LCOL=$(find_column_index "$FILE_A" "$LABEL" "$DELIM")
    fi
    
    if [[ -n "$LCOL" ]]; then
        echo -e "${BOLD}── Label Distribution ──${NC}"
        printf "  %-20s %8s %8s %8s %8s\n" "Label" "A count" "A %" "B count" "B %"
        printf "  %-20s %8s %8s %8s %8s\n" "─────" "───────" "────" "───────" "────"
        
        # Get label counts from both files
        LABELS_A=$(awk -F"$DELIM" -v col="$LCOL" 'NR>1{gsub(/^[ \t"]+|[ \t"]+$/, "", $col); print $col}' "$FILE_A" | sort | uniq -c | sort -rn)
        LABELS_B=$(awk -F"$DELIM" -v col="$LCOL" 'NR>1{gsub(/^[ \t"]+|[ \t"]+$/, "", $col); print $col}' "$FILE_B" | sort | uniq -c | sort -rn)
        
        # Combine into table
        {
            echo "$LABELS_A" | awk -v t="$ROWS_A" '{printf "%s\tA\t%d\t%.1f\n", $2, $1, $1*100/t}'
            echo "$LABELS_B" | awk -v t="$ROWS_B" '{printf "%s\tB\t%d\t%.1f\n", $2, $1, $1*100/t}'
        } | sort -t$'\t' -k1,1 | awk -F'\t' '
        {
            if ($1 != prev && prev != "") {
                printf "  %-20s %8d %7.1f%% %8d %7.1f%%\n", prev, a_count, a_pct, b_count, b_pct
                a_count=0; a_pct=0; b_count=0; b_pct=0
            }
            if ($2 == "A") { a_count=$3; a_pct=$4 }
            else { b_count=$3; b_pct=$4 }
            prev = $1
        }
        END { printf "  %-20s %8d %7.1f%% %8d %7.1f%%\n", prev, a_count, a_pct, b_count, b_pct }'
        echo ""
    fi
fi

# Text length comparison
if [[ -n "$TEXT" ]]; then
    if [[ "$TEXT" =~ ^[0-9]+$ ]]; then
        TCOL="$TEXT"
    else
        TCOL=$(find_column_index "$FILE_A" "$TEXT" "$DELIM")
    fi
    
    if [[ -n "$TCOL" ]]; then
        echo -e "${BOLD}── Text Length Stats ──${NC}"
        printf "  %-20s %10s %10s\n" "" "Dataset A" "Dataset B"
        printf "  %-20s %10s %10s\n" "─────" "─────────" "─────────"
        
        STATS_A=$(awk -F"$DELIM" -v col="$TCOL" 'NR>1{gsub(/^"|"$/, "", $col); print split($col, w, /[[:space:]]+/)}' "$FILE_A" | sort -n | awk '{
            s+=$1; ss+=$1*$1; vals[NR]=$1; n=NR
        } END {
            avg=s/n; med=vals[int((n+1)/2)]
            printf "%.1f\t%.1f\t%d\t%d", avg, med, vals[1], vals[n]
        }')
        STATS_B=$(awk -F"$DELIM" -v col="$TCOL" 'NR>1{gsub(/^"|"$/, "", $col); print split($col, w, /[[:space:]]+/)}' "$FILE_B" | sort -n | awk '{
            s+=$1; ss+=$1*$1; vals[NR]=$1; n=NR
        } END {
            avg=s/n; med=vals[int((n+1)/2)]
            printf "%.1f\t%.1f\t%d\t%d", avg, med, vals[1], vals[n]
        }')
        
        A_AVG=$(echo "$STATS_A" | cut -f1)
        A_MED=$(echo "$STATS_A" | cut -f2)
        A_MIN=$(echo "$STATS_A" | cut -f3)
        A_MAX=$(echo "$STATS_A" | cut -f4)
        B_AVG=$(echo "$STATS_B" | cut -f1)
        B_MED=$(echo "$STATS_B" | cut -f2)
        B_MIN=$(echo "$STATS_B" | cut -f3)
        B_MAX=$(echo "$STATS_B" | cut -f4)
        
        printf "  %-20s %10s %10s\n" "Avg tokens:" "$A_AVG" "$B_AVG"
        printf "  %-20s %10s %10s\n" "Median tokens:" "$A_MED" "$B_MED"
        printf "  %-20s %10s %10s\n" "Min tokens:" "$A_MIN" "$B_MIN"
        printf "  %-20s %10s %10s\n" "Max tokens:" "$A_MAX" "$B_MAX"
    fi
fi
echo ""
