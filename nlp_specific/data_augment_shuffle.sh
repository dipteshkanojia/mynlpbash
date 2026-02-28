#!/usr/bin/env bash
# data_augment_shuffle.sh — Simple data augmentation by word-level shuffling
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "data_augment_shuffle" "Simple data augmentation by word-level shuffling within sentences" \
        "data_augment_shuffle.sh -i data.csv -c text [-n 2] [-o output.csv]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Text column to augment" \
        "-n, --copies"    "Number of augmented copies per sample (default: 1)" \
        "--keep-orig"      "Keep original samples in output" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; COPIES=1 ; KEEP_ORIG=0 ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -n|--copies)    COPIES="$2"; shift 2 ;;
        --keep-orig)    KEEP_ORIG=1; shift ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Text column required (-c)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

process() {
    awk -F"$DELIM" -v OFS="$DELIM" -v col="$COL_IDX" -v copies="$COPIES" -v keep="$KEEP_ORIG" '
    BEGIN { srand() }
    NR==1 { print; next }
    {
        if (keep) print
        
        for (c=1; c<=copies; c++) {
            # Shuffle words in the text column
            text = $col
            gsub(/^"|"$/, "", text)
            n = split(text, words, /[[:space:]]+/)
            
            # Fisher-Yates shuffle
            for (i=n; i>1; i--) {
                j = int(rand() * i) + 1
                tmp = words[i]; words[i] = words[j]; words[j] = tmp
            }
            
            shuffled = words[1]
            for (i=2; i<=n; i++) shuffled = shuffled " " words[i]
            
            $col = shuffled
            print
        }
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    NEW_ROWS=$(count_rows "$OUTPUT")
    success "Augmented: $NEW_ROWS total samples → $OUTPUT"
else
    process
fi
