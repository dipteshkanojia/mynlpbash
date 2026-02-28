#!/usr/bin/env bash
# indic_ngram.sh — Indic-aware n-gram extraction
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_ngram" "Indic-aware word and character n-grams" \
        "indic_ngram.sh -i hindi.txt -n 2 --top 10" \
        "-i, --input"     "Input text file" \
        "-n, --ngram"     "N-gram size (default: 2)" \
        "--top"            "Show top N (default: 20)" \
        "--char"           "Character n-grams instead of word" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; N=2 ; TOP=20 ; CHAR_MODE=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -n|--ngram)  N="$2"; shift 2 ;;
        --top)       TOP="$2"; shift 2 ;;
        --char)      CHAR_MODE=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    if [[ $CHAR_MODE -eq 1 ]]; then
        awk -v n="$N" '{
            # Split into characters (UTF-8 aware via awk)
            len = length($0)
            for (i=1; i<=len-n+1; i++) {
                ngram = substr($0, i, n)
                if (ngram !~ /^[[:space:]]+$/) counts[ngram]++
            }
        } END {
            for (ng in counts) print counts[ng] "\t" ng
        }' "$INPUT" | sort -rn | head -"$TOP"
    else
        awk -v n="$N" '{
            # Tokenize (split on spaces, separate danda)
            gsub(/।/, " ।", $0)
            gsub(/॥/, " ॥", $0)
            nw = split($0, words, /[[:space:]]+/)
            for (i=1; i<=nw-n+1; i++) {
                ngram = words[i]
                for (j=1; j<n; j++) ngram = ngram " " words[i+j]
                counts[ngram]++
            }
        } END {
            for (ng in counts) print counts[ng] "\t" ng
        }' "$INPUT" | sort -rn | head -"$TOP"
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Indic ${N}-grams → $OUTPUT"
else
    echo -e "${BOLD}═══ Indic ${N}-grams (top $TOP) ═══${NC}"
    echo ""
    process | awk '{printf "  %6d  %s\n", $1, substr($0, index($0,$2))}'
    echo ""
fi
