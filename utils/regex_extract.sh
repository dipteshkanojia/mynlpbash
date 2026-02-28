#!/usr/bin/env bash
# regex_extract.sh — Extract patterns from text (emails, URLs, hashtags, etc.)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "regex_extract" "Extract patterns from text (emails, URLs, hashtags, dates)" \
        "regex_extract.sh -i text.txt --type email" \
        "-i, --input"     "Input text file" \
        "--type"           "Pattern type: email, url, hashtag, mention, phone, date, custom" \
        "--pattern"        "Custom regex pattern (when --type custom)" \
        "--context"        "Show N chars of context around match" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; TYPE="" ; PATTERN="" ; CONTEXT=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --type)       TYPE="$2"; shift 2 ;;
        --pattern)    PATTERN="$2"; shift 2 ;;
        --context)    CONTEXT="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$TYPE" ]] && die "Pattern type required (--type)"
require_file "$INPUT"

case "$TYPE" in
    email)    REGEX='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' ;;
    url)      REGEX='https?://[A-Za-z0-9._~:/?#\[\]@!$&()*+,;=-]+' ;;
    hashtag)  REGEX='#[A-Za-z0-9_]+' ;;
    mention)  REGEX='@[A-Za-z0-9_]+' ;;
    phone)    REGEX='[+]?[0-9]{1,4}[-. ]?[(]?[0-9]{1,3}[)]?[-. ]?[0-9]{3,4}[-. ]?[0-9]{3,4}' ;;
    date)     REGEX='[0-9]{1,4}[-/][0-9]{1,2}[-/][0-9]{1,4}' ;;
    custom)   [[ -z "$PATTERN" ]] && die "Custom pattern required (--pattern)"; REGEX="$PATTERN" ;;
    *)        die "Unknown type: $TYPE (use: email, url, hashtag, mention, phone, date, custom)" ;;
esac

process() {
    echo -e "${BOLD}═══ Pattern Extraction ($TYPE) ═══${NC}"
    echo ""
    grep -noE "$REGEX" "$INPUT" | awk -F: '{
        printf "  L%-5d %s\n", $1, $2
        matches++
    } END {
        printf "\n  Total matches: %d\n", matches+0
    }'
}

if [[ -n "$OUTPUT" ]]; then
    grep -oE "$REGEX" "$INPUT" > "$OUTPUT"
    COUNT=$(wc -l < "$OUTPUT" | tr -d ' ')
    success "Extracted $COUNT matches → $OUTPUT"
else
    process
    echo ""
fi
