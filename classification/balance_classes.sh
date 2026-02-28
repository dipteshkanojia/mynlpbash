#!/usr/bin/env bash
# balance_classes.sh — Undersample majority or oversample minority classes
# Author: Diptesh
# Status: Original — foundational script
# balance_classes.sh — Undersample majority or oversample minority classes was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "balance_classes" "Balance class distribution by under/oversampling" \
        "balance_classes.sh -i data.csv -c label --method undersample [-o output.csv]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Label column (name or index)" \
        "--method"         "Balance method: undersample, oversample (default: undersample)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; METHOD="undersample" ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        --method)       METHOD="$2"; shift 2 ;;
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

HEADER=$(head -1 "$INPUT")
TMPDIR_BAL=$(mktemp -d)
trap "rm -rf $TMPDIR_BAL" EXIT

# Split by class
tail -n +2 "$INPUT" | awk -F"$DELIM" -v col="$COL_IDX" -v dir="$TMPDIR_BAL" '{
    val = $col
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    gsub(/^"|"$/, "", val)
    gsub(/[^a-zA-Z0-9_-]/, "_", val)
    print >> (dir "/" val ".tmp")
}'

# Find min/max class size
MIN_SIZE=999999999; MAX_SIZE=0
for f in "$TMPDIR_BAL"/*.tmp; do
    n=$(wc -l < "$f" | tr -d ' ')
    [[ $n -lt $MIN_SIZE ]] && MIN_SIZE=$n
    [[ $n -gt $MAX_SIZE ]] && MAX_SIZE=$n
done

TARGET_SIZE=$MIN_SIZE
[[ "$METHOD" == "oversample" ]] && TARGET_SIZE=$MAX_SIZE

process() {
    echo "$HEADER"
    for f in "$TMPDIR_BAL"/*.tmp; do
        n=$(wc -l < "$f" | tr -d ' ')
        if [[ "$METHOD" == "undersample" ]]; then
            if command -v gshuf &>/dev/null; then gshuf -n "$TARGET_SIZE" "$f"
            elif command -v shuf &>/dev/null; then shuf -n "$TARGET_SIZE" "$f"
            else awk 'BEGIN{srand()}{print rand()"\t"$0}' "$f" | sort -n | head -n "$TARGET_SIZE" | cut -f2-
            fi
        else
            # ─── AI Enhancement (Claude Opus): Oversampling with repeat logic ───
            # Oversample: repeat file until we have enough
            cat "$f"
            remaining=$(( TARGET_SIZE - n ))
            while [[ $remaining -gt 0 ]]; do
                if [[ $remaining -ge $n ]]; then
                    cat "$f"
                    remaining=$(( remaining - n ))
                else
                    head -n "$remaining" "$f"
                    remaining=0
                fi
            done
        fi
    done
}

info "Method: $METHOD, target per class: $TARGET_SIZE"

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    NEW_TOTAL=$(count_rows "$OUTPUT")
    success "Balanced: $NEW_TOTAL total samples → $OUTPUT"
else
    process
fi
