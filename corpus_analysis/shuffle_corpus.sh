#!/usr/bin/env bash
# shuffle_corpus.sh — Randomly shuffle lines in a corpus
# Author: Diptesh
# Status: Original — foundational script
# shuffle_corpus.sh — Randomly shuffle lines in a corpus was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "shuffle_corpus" "Randomly shuffle lines in a corpus" \
        "shuffle_corpus.sh -i corpus.txt [-o shuffled.txt] [-s 42]" \
        "-i, --input"   "Input text file" \
        "-s, --seed"    "Random seed for reproducibility" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; SEED=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -s|--seed)   SEED="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Find available shuf command
if command -v gshuf &>/dev/null; then
    SHUF="gshuf"
elif command -v shuf &>/dev/null; then
    SHUF="shuf"
else
    # Fallback: awk-based shuffle
    SHUF=""
fi

process() {
    if [[ -n "$SHUF" ]]; then
        if [[ -n "$SEED" ]]; then
            # Create a deterministic source from seed
            $SHUF --random-source=<(openssl enc -aes-256-ctr -pass pass:"$SEED" -nosalt </dev/zero 2>/dev/null || echo "$SEED") "$INPUT" 2>/dev/null || $SHUF "$INPUT"
        else
            $SHUF "$INPUT"
        fi
    else
        awk 'BEGIN{srand()} {print rand()"\t"$0}' "$INPUT" | sort -n | cut -f2-
    fi
}

LINES=$(wc -l < "$INPUT" | tr -d ' ')

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Shuffled $LINES lines → $OUTPUT"
else
    process
fi
