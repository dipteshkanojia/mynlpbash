#!/usr/bin/env bash
# indic_vocab_coverage.sh — Check vocabulary coverage against frequency lists
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_vocab_coverage" "Check vocabulary coverage and OOV rate for Indic text" \
        "indic_vocab_coverage.sh -i corpus.txt --vocab vocab.txt" \
        "-i, --input"     "Input corpus file" \
        "--vocab"          "Vocabulary file (one word per line)" \
        "--top-k"          "Use only top-K vocab words (default: all)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; VOCAB="" ; TOP_K=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --vocab)     VOCAB="$2"; shift 2 ;;
        --top-k)     TOP_K="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$VOCAB" ]] && die "Vocab file required (--vocab)"
require_file "$INPUT"; require_file "$VOCAB"

echo -e "${BOLD}═══ Vocabulary Coverage ═══${NC}"
echo ""

awk -v vocab_file="$VOCAB" -v top_k="$TOP_K" '
BEGIN {
    k = 0
    while ((getline line < vocab_file) > 0) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line != "") {
            k++
            vocab[line] = 1
            if (top_k != "" && k >= top_k) break
        }
    }
    close(vocab_file)
    vocab_size = k
}
{
    gsub(/।/, " ", $0); gsub(/॥/, " ", $0)
    nw = split($0, words, /[[:space:]]+/)
    for (i=1; i<=nw; i++) {
        w = words[i]
        gsub(/^[[:punct:]]+|[[:punct:]]+$/, "", w)
        if (w == "") continue
        total_tokens++
        corpus_types[w]++
        if (w in vocab) covered_tokens++
        else { oov_types[w]++; oov_tokens++ }
    }
}
END {
    n_types = 0; for (w in corpus_types) n_types++
    n_oov_types = 0; for (w in oov_types) n_oov_types++
    
    printf "  %-25s %d\n", "Vocab size:", vocab_size
    printf "  %-25s %d\n", "Corpus tokens:", total_tokens
    printf "  %-25s %d\n", "Corpus types:", n_types
    printf "  %-25s %d (%.1f%%)\n", "Covered tokens:", covered_tokens+0, (covered_tokens+0)*100/total_tokens
    printf "  %-25s %d (%.1f%%)\n", "OOV tokens:", oov_tokens+0, (oov_tokens+0)*100/total_tokens
    printf "  %-25s %d (%.1f%%)\n", "OOV types:", n_oov_types, n_oov_types*100/n_types
    
    if (n_oov_types > 0) {
        print ""
        print "  Top OOV words:"
        # Sort OOV by frequency
        n_items = 0
        for (w in oov_types) { n_items++; items[n_items] = w; counts[n_items] = oov_types[w] }
        for (i=2; i<=n_items; i++) {
            kc = counts[i]; ki = items[i]; j = i-1
            while (j>0 && counts[j] < kc) { counts[j+1] = counts[j]; items[j+1] = items[j]; j-- }
            counts[j+1] = kc; items[j+1] = ki
        }
        top = (n_items < 15) ? n_items : 15
        for (i=1; i<=top; i++) printf "    %5d  %s\n", counts[i], items[i]
    }
}' "$INPUT"
echo ""
