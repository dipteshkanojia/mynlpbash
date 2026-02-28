#!/usr/bin/env bash
# cross_validate_split.sh — Create k-fold cross-validation splits
# Author: Diptesh
# Status: Original — foundational script
# cross_validate_split.sh — Create k-fold cross-validation splits was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "cross_validate_split" "Create k-fold cross-validation splits" \
        "cross_validate_split.sh -i data.csv -k 5 [-o prefix]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-k, --folds"     "Number of folds (default: 5)" \
        "--shuffle"        "Shuffle before splitting" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output prefix (default: fold)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; FOLDS=5 ; SHUFFLE=0 ; OUTPUT="fold" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -k|--folds)     FOLDS="$2"; shift 2 ;;
        --shuffle)      SHUFFLE=1; shift ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

HEADER=$(head -1 "$INPUT")
TMPDATA=$(make_temp)

if [[ $SHUFFLE -eq 1 ]]; then
    if command -v gshuf &>/dev/null; then tail -n +2 "$INPUT" | gshuf > "$TMPDATA"
    elif command -v shuf &>/dev/null; then tail -n +2 "$INPUT" | shuf > "$TMPDATA"
    else tail -n +2 "$INPUT" | awk 'BEGIN{srand()}{print rand()"\t"$0}' | sort -n | cut -f2- > "$TMPDATA"
    fi
else
    tail -n +2 "$INPUT" > "$TMPDATA"
fi

TOTAL=$(wc -l < "$TMPDATA" | tr -d ' ')
FOLD_SIZE=$(( TOTAL / FOLDS ))

echo -e "${BOLD}═══ ${FOLDS}-Fold Cross-Validation Split ═══${NC}"
echo ""

for (( f=1; f<=FOLDS; f++ )); do
    TRAIN_FILE="${OUTPUT}_${f}_train.csv"
    TEST_FILE="${OUTPUT}_${f}_test.csv"
    
    START=$(( (f-1) * FOLD_SIZE + 1 ))
    if [[ $f -eq $FOLDS ]]; then
        END=$TOTAL
    else
        END=$(( f * FOLD_SIZE ))
    fi
    TEST_SIZE=$(( END - START + 1 ))
    
    echo "$HEADER" > "$TRAIN_FILE"
    echo "$HEADER" > "$TEST_FILE"
    
    awk -v start="$START" -v end="$END" \
        -v train="$TRAIN_FILE" -v test="$TEST_FILE" '
    NR >= start && NR <= end { print >> test; next }
    { print >> train }
    ' "$TMPDATA"
    
    TRAIN_SIZE=$(( TOTAL - TEST_SIZE ))
    printf "  Fold %d: train=%d, test=%d → %s, %s\n" "$f" "$TRAIN_SIZE" "$TEST_SIZE" "$TRAIN_FILE" "$TEST_FILE"
done

echo ""
success "Created $FOLDS folds from $TOTAL samples"
