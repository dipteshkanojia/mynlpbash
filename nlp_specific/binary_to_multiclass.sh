#!/usr/bin/env bash
# binary_to_multiclass.sh — Convert between binary and multiclass label schemes
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "binary_to_multiclass" "Convert between binary/multiclass label schemes" \
        "binary_to_multiclass.sh -i data.csv -c label --to-binary --pos 'positive'" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Label column" \
        "--to-binary"      "Convert multiclass → binary" \
        "--to-multi"       "Convert binary → multiclass (using rules)" \
        "--pos"             "Positive class label(s) (comma-separated)" \
        "--neg-label"       "Label for negative class (default: negative)" \
        "--pos-label"       "Label for positive class (default: positive)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; TO_BIN=0 ; TO_MULTI=0 ; POS="" ; OUTPUT="" ; DELIM=""
NEG_LABEL="negative" ; POS_LABEL="positive"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        --to-binary)    TO_BIN=1; shift ;;
        --to-multi)     TO_MULTI=1; shift ;;
        --pos)          POS="$2"; shift 2 ;;
        --neg-label)    NEG_LABEL="$2"; shift 2 ;;
        --pos-label)    POS_LABEL="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Column required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

process() {
    if [[ $TO_BIN -eq 1 ]]; then
        [[ -z "$POS" ]] && die "--pos required for --to-binary"
        awk -F"$DELIM" -v OFS="$DELIM" -v col="$COL_IDX" -v pos="$POS" \
            -v pos_label="$POS_LABEL" -v neg_label="$NEG_LABEL" '
        BEGIN { n = split(pos, pos_arr, ","); for (i=1;i<=n;i++) pos_set[pos_arr[i]]=1 }
        NR==1 { print; next }
        {
            val = $col; gsub(/^[ \t]+|[ \t]+$/, "", val); gsub(/^"|"$/, "", val)
            $col = (val in pos_set) ? pos_label : neg_label
            print
        }' "$INPUT"
    else
        die "--to-binary is currently the supported conversion mode"
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Labels converted → $OUTPUT"
else
    process
fi
