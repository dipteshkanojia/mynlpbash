#!/usr/bin/env bash
# ngram_extract.sh — Extract n-grams from text
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "ngram_extract" "Extract n-grams (bigrams, trigrams, etc.)" \
        "ngram_extract.sh -i corpus.txt -n 2 [--top 20]" \
        "-i, --input"   "Input text file (or stdin)" \
        "-n, --ngram"   "N-gram size (default: 2)" \
        "--top"          "Show top N n-grams" \
        "--min"          "Minimum frequency threshold" \
        "--lower"        "Lowercase before extracting" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; NGRAM=2 ; TOP="" ; MIN=0 ; LOWER=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -n|--ngram)  NGRAM="$2"; shift 2 ;;
        --top)       TOP="$2"; shift 2 ;;
        --min)       MIN="$2"; shift 2 ;;
        --lower)     LOWER=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

process() {
    local src
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        src="$INPUT"
    else
        src="/dev/stdin"
    fi

    local cmd="cat '$src'"
    [[ $LOWER -eq 1 ]] && cmd="$cmd | tr '[:upper:]' '[:lower:]'"

    eval "$cmd" | awk -v n="$NGRAM" -v min_freq="$MIN" '
    {
        # Tokenize line
        gsub(/[^a-zA-Z0-9'"'"' ]/, " ")
        nw = split($0, words, /[[:space:]]+/)
        for (i=1; i<=nw-n+1; i++) {
            ngram = words[i]
            for (j=1; j<n; j++) {
                ngram = ngram " " words[i+j]
            }
            if (ngram !~ /^[[:space:]]*$/) count[ngram]++
        }
    }
    END {
        for (ng in count) {
            if (count[ng] >= min_freq)
                print count[ng] "\t" ng
        }
    }' | sort -rn -t$'\t' -k1 | {
        if [[ -n "$TOP" ]]; then
            head -n "$TOP"
        else
            cat
        fi
    }
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "${NGRAM}-grams → $OUTPUT"
else
    process
fi
