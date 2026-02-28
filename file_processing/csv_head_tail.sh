#!/usr/bin/env bash
# csv_head_tail.sh — Pretty-print first/last N rows of CSV/TSV
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_head_tail" "Pretty-print first/last N rows of CSV/TSV" \
        "csv_head_tail.sh -i input.csv [-n 5] [--tail]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-n, --nrows"     "Number of rows (default: 10)" \
        "--tail"          "Show last N rows instead of first" \
        "--no-truncate"   "Don't truncate long fields" \
        "-w, --width"     "Max field width (default: 30)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; NROWS=10 ; TAIL=0 ; TRUNCATE=1 ; WIDTH=30 ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -n|--nrows)     NROWS="$2"; shift 2 ;;
        --tail)         TAIL=1; shift ;;
        --no-truncate)  TRUNCATE=0; shift ;;
        -w|--width)     WIDTH="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

TOTAL=$(count_rows "$INPUT")

if [[ $TAIL -eq 1 ]]; then
    LABEL="Last $NROWS of $TOTAL rows"
    DATA=$(tail -n "$NROWS" "$INPUT")
    # Add header back
    DATA="$(head -1 "$INPUT")
$DATA"
else
    LABEL="First $NROWS of $TOTAL rows"
    DATA=$(head -n $(( NROWS + 1 )) "$INPUT")
fi

echo -e "${BOLD}$LABEL${NC} from $(basename "$INPUT")"
echo ""

echo "$DATA" | awk -F"$DELIM" -v width="$WIDTH" -v trunc="$TRUNCATE" '
{
    for (i=1; i<=NF; i++) {
        val = $i
        gsub(/^"|"$/, "", val)
        if (trunc && length(val) > width) {
            val = substr(val, 1, width-3) "..."
        }
        if (length(val) > maxw[i]) maxw[i] = length(val)
        data[NR][i] = val
    }
    cols = (NF > cols) ? NF : cols
    rows = NR
}
END {
    # Print header separator
    for (r=1; r<=rows; r++) {
        for (i=1; i<=cols; i++) {
            w = maxw[i] + 2
            if (i > 1) printf " │ "
            printf "%-*s", w, data[r][i]
        }
        print ""
        if (r == 1) {
            for (i=1; i<=cols; i++) {
                w = maxw[i] + 2
                if (i > 1) printf "─┼─"
                for (j=1; j<=w; j++) printf "─"
            }
            print ""
        }
    }
}'
echo ""
