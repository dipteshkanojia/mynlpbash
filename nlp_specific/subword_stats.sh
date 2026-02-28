#!/usr/bin/env bash
# subword_stats.sh — Subword tokenizer fertility estimation
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 NLP utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "subword_stats" "Estimate subword tokenizer fertility on a corpus" \
        "subword_stats.sh -i corpus.txt --vocab vocab.txt" \
        "-i, --input"     "Input corpus file" \
        "--vocab"          "Subword vocab file (one token per line)" \
        "--per-line"       "Show fertility per line" \
        "-h, --help"      "Show this help"
}

INPUT="" ; VOCAB="" ; PER_LINE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --vocab)     VOCAB="$2"; shift 2 ;;
        --per-line)  PER_LINE=1; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$VOCAB" ]] && die "Vocab file required (--vocab)"
require_file "$INPUT"; require_file "$VOCAB"

echo -e "${BOLD}═══ Subword Tokenizer Fertility ═══${NC}"
echo ""

awk -v vocab_file="$VOCAB" -v per_line="$PER_LINE" '
BEGIN {
    while ((getline line < vocab_file) > 0) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line != "") { vocab_size++; vocab[line] = 1 }
    }
    close(vocab_file)
    printf "  Vocab size: %d\n\n", vocab_size
}
{
    nw = split($0, words, /[[:space:]]+/)
    line_words = 0; line_subwords = 0
    
    for (w=1; w<=nw; w++) {
        word = words[w]
        if (word == "") continue
        line_words++
        total_words++
        
        # Greedy longest-match subword segmentation
        remaining = word
        sw_count = 0
        while (length(remaining) > 0) {
            matched = 0
            for (L=length(remaining); L>=1; L--) {
                prefix = substr(remaining, 1, L)
                # Check with and without ## prefix (WordPiece style)
                if (prefix in vocab || ("##" prefix) in vocab || ("▁" prefix) in vocab) {
                    sw_count++
                    remaining = substr(remaining, L+1)
                    matched = 1
                    break
                }
            }
            if (!matched) {
                # Unknown char = 1 subword
                sw_count++
                remaining = substr(remaining, 2)
            }
        }
        line_subwords += sw_count
        total_subwords += sw_count
        
        # Track per-word fertility
        fertility = sw_count
        if (fertility > max_fert) max_fert = fertility
        fert_dist[fertility]++
    }
    
    if (per_line && line_words > 0) {
        printf "  L%d: %d words → %d subwords (fertility: %.2f)\n", NR, line_words, line_subwords, line_subwords/line_words
    }
    lines++
}
END {
    avg_fert = total_subwords / total_words
    printf "\n  ── Corpus Statistics ──\n"
    printf "  %-25s %d\n", "Lines:", lines
    printf "  %-25s %d\n", "Words:", total_words
    printf "  %-25s %d\n", "Subwords:", total_subwords
    printf "  %-25s %.3f\n", "Avg fertility:", avg_fert
    printf "  %-25s %d\n", "Max fertility:", max_fert
    
    printf "\n  Fertility Distribution:\n"
    for (f=1; f<=max_fert; f++) {
        if (fert_dist[f]+0 > 0) {
            printf "    %2d subwords: %6d words (%5.1f%%)\n", f, fert_dist[f], fert_dist[f]*100/total_words
        }
    }
}' "$INPUT"
echo ""
