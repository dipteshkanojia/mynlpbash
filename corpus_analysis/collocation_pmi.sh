#!/usr/bin/env bash
# collocation_pmi.sh — Extract n-grams using Pointwise Mutual Mutual Information (PMI)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "collocation_pmi" "Extract significant word pairs using Pointwise Mutual Information (PMI)" \
        "collocation_pmi.sh -i corpus.txt --min-freq 2" \
        "-i, --input"    "Input text file" \
        "-n, --top"      "Number of top collocations (default: 20)" \
        "-m, --min-freq" "Minimum bigram frequency (default: 2)" \
        "--lower"        "Lowercase text before processing" \
        "-h, --help"     "Show this help"
}

INPUT=""
TOP=20
MIN_FREQ=2
LOWER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)    INPUT="$2"; shift 2 ;;
        -n|--top)      TOP="$2"; shift 2 ;;
        -m|--min-freq) MIN_FREQ="$2"; shift 2 ;;
        --lower)       LOWER=true; shift 1 ;;
        -h|--help)     show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

echo -e "${BOLD}═══ PMI Collocation Extraction ═══${NC}"

{
    if $LOWER; then
        tr '[:upper:]' '[:lower:]' < "$INPUT" | tr -s '[:space:][:punct:]' '\n'
    else
        tr -s '[:space:][:punct:]' '\n' < "$INPUT"
    fi
} | awk -v MIN="$MIN_FREQ" -v TOP="$TOP" '
BEGIN {
    total_unigrams = 0
    total_bigrams = 0
}
{
    w2 = $1
    if (length(w2) == 0) next
    
    # Track word
    unigrams[w2]++
    total_unigrams++
    
    # Track bigram
    if (total_unigrams > 1) {
        bg = w1 " " w2
        bigrams[bg]++
        total_bigrams++
    }
    
    w1 = w2
}
END {
    if (total_bigrams == 0) exit
    
    n_pairs = 0
    
    for (bg in bigrams) {
        freq = bigrams[bg]
        if (freq >= MIN) {
            split(bg, parts, " ")
            w1 = parts[1]
            w2 = parts[2]
            
            p_w1 = unigrams[w1] / total_unigrams
            p_w2 = unigrams[w2] / total_unigrams
            p_bg = freq / total_bigrams
            
            # PMI = log2( P(w1, w2) / (P(w1) * P(w2)) )
            # We use natural log (log() in awk is ln), 
            # log2(x) = log(x) / log(2)
            pmi = log(p_bg / (p_w1 * p_w2)) / log(2)
            
            pairs[++n_pairs] = bg
            scores[bg] = pmi
        }
    }
    
    if (n_pairs == 0) {
        print "  No bigrams met the minimum frequency threshold (" MIN ")."
        exit
    }
    
    # Sort array by PMI score descending
    for (i = 1; i <= n_pairs; i++) {
        for (j = i + 1; j <= n_pairs; j++) {
            if (scores[pairs[j]] > scores[pairs[i]]) {
                tmp = pairs[i]
                pairs[i] = pairs[j]
                pairs[j] = tmp
            }
        }
    }
    
    printf "  %-30s %-10s %-10s\n", "Bigram Collection", "PMI", "Count"
    print "  " "──────────────────────────────────────────────────"
    
    limit = (n_pairs < TOP) ? n_pairs : TOP
    for (i = 1; i <= limit; i++) {
        bg = pairs[i]
        printf "  %-30s %-10.4f %-10d\n", bg, scores[bg], bigrams[bg]
    }
}
' || true || true

exit 0
