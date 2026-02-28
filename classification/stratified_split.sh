#!/usr/bin/env bash
# stratified_split.sh — Stratified train/dev/test split for classification data
# Author: Diptesh
# Status: Original — foundational script
# stratified_split.sh — Stratified train/dev/test split for classification data was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "stratified_split" "Stratified train/dev/test split preserving class proportions" \
        "stratified_split.sh -i data.csv -c label [-p 80:10:10] [-o prefix]" \
        "-i, --input"       "Input CSV/TSV file" \
        "-c, --column"      "Label column for stratification" \
        "-p, --proportions"  "Train:dev:test proportions (default: 80:10:10)" \
        "--shuffle"          "Shuffle before splitting" \
        "-d, --delimiter"   "Delimiter (auto-detected)" \
        "-o, --output"      "Output prefix (default: split)" \
        "-h, --help"        "Show this help"
}

INPUT="" ; COLUMN="" ; PROP="80:10:10" ; SHUFFLE=0 ; OUTPUT="split" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        -c|--column)      COLUMN="$2"; shift 2 ;;
        -p|--proportions) PROP="$2"; shift 2 ;;
        --shuffle)        SHUFFLE=1; shift ;;
        -d|--delimiter)   DELIM="$2"; shift 2 ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
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

IFS=':' read -r TRAIN_PCT DEV_PCT TEST_PCT <<< "$PROP"
HEADER=$(head -1 "$INPUT")

# Initialize output files with header
for split in train dev test; do
    echo "$HEADER" > "${OUTPUT}.${split}.csv"
done

# ─── AI Enhancement (Claude Opus): Proportional stratification logic ────
# Process each class separately for stratification
TMPDIR_STRAT=$(mktemp -d)
trap "rm -rf $TMPDIR_STRAT" EXIT

# Get unique labels
tail -n +2 "$INPUT" | awk -F"$DELIM" -v col="$COL_IDX" '{
    val=$col; gsub(/^[ \t]+|[ \t]+$/, "", val); gsub(/^"|"$/, "", val)
    print val
}' | sort -u > "$TMPDIR_STRAT/labels.txt"

TOTAL_TRAIN=0; TOTAL_DEV=0; TOTAL_TEST=0

while IFS= read -r label; do
    # Extract rows for this label
    LABEL_FILE="$TMPDIR_STRAT/label_${label}.tmp"
    tail -n +2 "$INPUT" | awk -F"$DELIM" -v col="$COL_IDX" -v label="$label" '{
        val=$col; gsub(/^[ \t]+|[ \t]+$/, "", val); gsub(/^"|"$/, "", val)
        if (val == label) print
    }' > "$LABEL_FILE"
    
    if [[ $SHUFFLE -eq 1 ]]; then
        SHUFFLED="$TMPDIR_STRAT/shuffled.tmp"
        if command -v gshuf &>/dev/null; then gshuf "$LABEL_FILE" > "$SHUFFLED"
        elif command -v shuf &>/dev/null; then shuf "$LABEL_FILE" > "$SHUFFLED"
        else awk 'BEGIN{srand()}{print rand()"\t"$0}' "$LABEL_FILE" | sort -n | cut -f2- > "$SHUFFLED"
        fi
        mv "$SHUFFLED" "$LABEL_FILE"
    fi
    
    N=$(wc -l < "$LABEL_FILE" | tr -d ' ')
    TRAIN_N=$(( N * TRAIN_PCT / 100 ))
    DEV_N=$(( N * DEV_PCT / 100 ))
    TEST_N=$(( N - TRAIN_N - DEV_N ))
    [[ $TEST_N -lt 0 ]] && TEST_N=0
    
    head -n "$TRAIN_N" "$LABEL_FILE" >> "${OUTPUT}.train.csv"
    tail -n +$(( TRAIN_N + 1 )) "$LABEL_FILE" | head -n "$DEV_N" >> "${OUTPUT}.dev.csv"
    tail -n +$(( TRAIN_N + DEV_N + 1 )) "$LABEL_FILE" >> "${OUTPUT}.test.csv"
    
    TOTAL_TRAIN=$(( TOTAL_TRAIN + TRAIN_N ))
    TOTAL_DEV=$(( TOTAL_DEV + DEV_N ))
    TOTAL_TEST=$(( TOTAL_TEST + TEST_N ))
done < "$TMPDIR_STRAT/labels.txt"

echo -e "${BOLD}═══ Stratified Split ($PROP) ═══${NC}"
printf "  %-8s %6d samples → %s\n" "Train:" "$TOTAL_TRAIN" "${OUTPUT}.train.csv"
printf "  %-8s %6d samples → %s\n" "Dev:" "$TOTAL_DEV" "${OUTPUT}.dev.csv"
printf "  %-8s %6d samples → %s\n" "Test:" "$TOTAL_TEST" "${OUTPUT}.test.csv"
success "Stratified split complete"
