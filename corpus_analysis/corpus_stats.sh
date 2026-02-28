#!/usr/bin/env bash
# corpus_stats.sh — Comprehensive corpus statistics
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "corpus_stats" "Comprehensive corpus statistics (tokens, types, TTR, etc.)" \
        "corpus_stats.sh -i corpus.txt" \
        "-i, --input"   "Input text file" \
        "-h, --help"    "Show this help"
}

INPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) INPUT="$2"; shift 2 ;;
        -h|--help)  show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

echo -e "${BOLD}═══ Corpus Statistics ═══${NC}"
echo ""
echo -e "${BOLD}File:${NC} $(basename "$INPUT")"
echo ""

# Basic counts
LINES=$(wc -l < "$INPUT" | tr -d ' ')
CHARS=$(wc -c < "$INPUT" | tr -d ' ')
WORDS=$(wc -w < "$INPUT" | tr -d ' ')
FILE_SIZE=$(ls -lh "$INPUT" | awk '{print $5}')

# Token/type analysis
TOKENS=$(cat "$INPUT" | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | wc -l | tr -d ' ')
TYPES=$(cat "$INPUT" | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | sort -u | wc -l | tr -d ' ')
HAPAX=$(cat "$INPUT" | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | sort | uniq -c | awk '$1==1' | wc -l | tr -d ' ')

# TTR (Type-Token Ratio)
TTR=$(awk "BEGIN { printf \"%.4f\", $TYPES / $TOKENS }")

# Average word length
AVG_WORD_LEN=$(cat "$INPUT" | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | awk '{ total += length($0); count++ } END { printf "%.1f", total/count }')

# Sentence length stats using sort for median
LINE_LENGTHS=$(awk '{ print split($0, words, /[[:space:]]+/) }' "$INPUT" | sort -n)
MIN_LEN=$(echo "$LINE_LENGTHS" | head -1)
MAX_LEN=$(echo "$LINE_LENGTHS" | tail -1)
AVG_LEN=$(echo "$LINE_LENGTHS" | awk '{ total += $1; count++ } END { printf "%.1f", total/count }')
MED_POS=$(( (LINES + 1) / 2 ))
MED_LEN=$(echo "$LINE_LENGTHS" | sed -n "${MED_POS}p")

echo -e "${BOLD}── General ──${NC}"
printf "  %-25s %s\n" "File size:" "$FILE_SIZE"
printf "  %-25s %s\n" "Lines/sentences:" "$(format_number $LINES)"
printf "  %-25s %s\n" "Characters:" "$(format_number $CHARS)"
printf "  %-25s %s\n" "Words (whitespace):" "$(format_number $WORDS)"
echo ""

echo -e "${BOLD}── Vocabulary ──${NC}"
printf "  %-25s %s\n" "Tokens:" "$(format_number $TOKENS)"
printf "  %-25s %s\n" "Types (unique):" "$(format_number $TYPES)"
printf "  %-25s %s\n" "Hapax legomena:" "$(format_number $HAPAX) ($(pct $HAPAX $TYPES)% of types)"
printf "  %-25s %s\n" "Type-token ratio:" "$TTR"
printf "  %-25s %s\n" "Avg word length:" "$AVG_WORD_LEN chars"
echo ""

echo -e "${BOLD}── Sentence Length ──${NC}"
printf "  %-25s %s\n" "Min tokens/line:" "$MIN_LEN"
printf "  %-25s %s\n" "Max tokens/line:" "$MAX_LEN"
printf "  %-25s %s\n" "Avg tokens/line:" "$AVG_LEN"
printf "  %-25s %s\n" "Median tokens/line:" "$MED_LEN"
echo ""

# Top 10 most frequent words
echo -e "${BOLD}── Top 10 Words ──${NC}"
cat "$INPUT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | sort | uniq -c | sort -rn | head -10 | awk '{
    printf "  %6d  %s\n", $1, $2
}'
echo ""
