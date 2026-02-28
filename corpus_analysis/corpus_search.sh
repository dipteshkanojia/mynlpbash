#!/usr/bin/env bash
# corpus_search.sh — KWIC (Key Word In Context) concordance search
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "corpus_search" "KWIC (Key Word In Context) concordance search" \
        "corpus_search.sh -i corpus.txt -q 'word' [-w 5]" \
        "-i, --input"    "Input text file" \
        "-q, --query"    "Search word or phrase" \
        "-w, --window"   "Context window size in words (default: 5)" \
        "-n, --max"      "Maximum results to show" \
        "--case"          "Case-sensitive search" \
        "--count"         "Only show count of matches" \
        "-o, --output"   "Output file (default: stdout)" \
        "-h, --help"     "Show this help"
}

INPUT="" ; OUTPUT="" ; QUERY="" ; WINDOW=5 ; MAX="" ; CASE_SENSITIVE=0 ; COUNT_ONLY=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -q|--query)  QUERY="$2"; shift 2 ;;
        -w|--window) WINDOW="$2"; shift 2 ;;
        -n|--max)    MAX="$2"; shift 2 ;;
        --case)      CASE_SENSITIVE=1; shift ;;
        --count)     COUNT_ONLY=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$QUERY" ]] && die "Query required (-q)"
require_file "$INPUT"

if [[ $COUNT_ONLY -eq 1 ]]; then
    if [[ $CASE_SENSITIVE -eq 1 ]]; then
        COUNT=$(grep -c "$QUERY" "$INPUT")
    else
        COUNT=$(grep -ci "$QUERY" "$INPUT")
    fi
    echo "$COUNT matches for '$QUERY'"
    exit 0
fi

process() {
    awk -v query="$QUERY" -v window="$WINDOW" -v case_s="$CASE_SENSITIVE" -v maxr="${MAX:-999999}" '
    BEGIN {
        matches = 0
        if (!case_s) query = tolower(query)
    }
    {
        line = $0
        check = case_s ? line : tolower(line)
        n = split(line, words, /[[:space:]]+/)

        # Check each word position
        qwords = split(query, qw, /[[:space:]]+/)
        for (i=1; i<=n-qwords+1 && matches < maxr; i++) {
            match_str = words[i]
            check_str = case_s ? words[i] : tolower(words[i])
            for (j=2; j<=qwords; j++) {
                match_str = match_str " " words[i+j-1]
                check_str = check_str " " (case_s ? words[i+j-1] : tolower(words[i+j-1]))
            }

            # Remove punctuation for matching
            clean = check_str
            gsub(/[[:punct:]]/, "", clean)
            clean_q = query
            gsub(/[[:punct:]]/, "", clean_q)

            if (clean == clean_q || check_str == query) {
                matches++
                # Build left context
                left = ""
                start = (i - window > 0) ? i - window : 1
                for (k=start; k<i; k++) left = left " " words[k]

                # Build right context
                right = ""
                end_pos = i + qwords - 1
                for (k=end_pos+1; k<=end_pos+window && k<=n; k++) right = right words[k] " "

                printf "%4d │ %30s  ◆ %-15s ◆  %-30s │ L%d\n", matches, left, match_str, right, NR
            }
        }
    }
    END {
        printf "\n%d concordance matches found\n", matches
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Concordance results → $OUTPUT"
else
    echo -e "${BOLD}═══ KWIC Concordance: \"$QUERY\" (window=$WINDOW) ═══${NC}"
    echo ""
    process
fi
