#!/usr/bin/env bash
# parallel_split.sh — Split parallel corpus into train/dev/test
# Author: Diptesh
# Status: Original — foundational script
# parallel_split.sh — Split parallel corpus into train/dev/test was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_split" "Split parallel corpus into train/dev/test maintaining alignment" \
        "parallel_split.sh -s source.txt -t target.txt [-p 80:10:10] [-o prefix]" \
        "-s, --source"   "Source language file" \
        "-t, --target"   "Target language file" \
        "-p, --proportions" "Train:dev:test proportions (default: 80:10:10)" \
        "--shuffle"       "Shuffle before splitting" \
        "-o, --output"   "Output prefix (default: split)" \
        "-h, --help"     "Show this help"
}

SRC="" ; TGT="" ; PROP="80:10:10" ; SHUFFLE=0 ; OUTPUT="split"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)      SRC="$2"; shift 2 ;;
        -t|--target)      TGT="$2"; shift 2 ;;
        -p|--proportions) PROP="$2"; shift 2 ;;
        --shuffle)        SHUFFLE=1; shift ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
require_file "$SRC"; require_file "$TGT"

IFS=':' read -r TRAIN_PCT DEV_PCT TEST_PCT <<< "$PROP"
TOTAL=$(wc -l < "$SRC" | tr -d ' ')
TRAIN_N=$(( TOTAL * TRAIN_PCT / 100 ))
DEV_N=$(( TOTAL * DEV_PCT / 100 ))
TEST_N=$(( TOTAL - TRAIN_N - DEV_N ))

MERGED=$(make_temp)
paste -d$'\x01' "$SRC" "$TGT" > "$MERGED"

if [[ $SHUFFLE -eq 1 ]]; then
    SHUFFLED=$(make_temp)
    if command -v gshuf &>/dev/null; then
        gshuf "$MERGED" > "$SHUFFLED"
    elif command -v shuf &>/dev/null; then
        shuf "$MERGED" > "$SHUFFLED"
    else
        awk 'BEGIN{srand()} {print rand()"\t"$0}' "$MERGED" | sort -n | cut -f2- > "$SHUFFLED"
    fi
    MERGED="$SHUFFLED"
fi

# Split
head -n "$TRAIN_N" "$MERGED" | cut -d$'\x01' -f1 > "${OUTPUT}.train.src"
head -n "$TRAIN_N" "$MERGED" | cut -d$'\x01' -f2 > "${OUTPUT}.train.tgt"

tail -n +$(( TRAIN_N + 1 )) "$MERGED" | head -n "$DEV_N" | cut -d$'\x01' -f1 > "${OUTPUT}.dev.src"
tail -n +$(( TRAIN_N + 1 )) "$MERGED" | head -n "$DEV_N" | cut -d$'\x01' -f2 > "${OUTPUT}.dev.tgt"

tail -n +$(( TRAIN_N + DEV_N + 1 )) "$MERGED" | cut -d$'\x01' -f1 > "${OUTPUT}.test.src"
tail -n +$(( TRAIN_N + DEV_N + 1 )) "$MERGED" | cut -d$'\x01' -f2 > "${OUTPUT}.test.tgt"

echo -e "${BOLD}═══ Parallel Split ($PROP) ═══${NC}"
printf "  %-10s %6d pairs  →  %s.train.{src,tgt}\n" "Train:" "$TRAIN_N" "$OUTPUT"
printf "  %-10s %6d pairs  →  %s.dev.{src,tgt}\n" "Dev:" "$DEV_N" "$OUTPUT"
printf "  %-10s %6d pairs  →  %s.test.{src,tgt}\n" "Test:" "$TEST_N" "$OUTPUT"
success "Split $TOTAL pairs into 3 sets"
