#!/usr/bin/env bash
# readability_scores.sh — Compute readability metrics for English text
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "readability_scores" "Compute Flesch-Kincaid, Flesch Reading Ease, and Gunning Fog Index" \
        "readability_scores.sh -i english_text.txt" \
        "-i, --input"   "Input text file (English text recommended)" \
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

echo -e "${BOLD}═══ Readability Scores ═══${NC}"
echo -e "${BOLD}File:${NC} $(basename "$INPUT")\n"

# We compute sentences, words, syllables, and complex words (>= 3 syllables) in awk.
# Sentence boundary: . ! ?
# Syllables: approximation via consecutive vowel groups [aeiouy]+
# Exception handling in awk: trailing 'e', 'es', 'ed'
awk '
BEGIN {
    words = 0
    sentences = 0
    syllables = 0
    complex_words = 0
}
{
    # Count sentences: count occurrences of . ! ?
    # Standardize punctuation slightly to count them safely
    s_line = $0
    sentences += gsub(/[.!?]+/, "&", s_line)
    
    # Process words
    # Remove punctuation for word/syllable analysis
    gsub(/[[:punct:]]/, "", $0)
    
    for (i = 1; i <= NF; i++) {
        w = tolower($i)
        if (length(w) == 0) continue
        
        words++
        
        # Count syllables approx
        # 1. Remove trailing e, es, ed
        sub(/(es|ed|e)$/, "", w)
        
        # 2. Count continuous vowel groups
        # In awk, we can split by consonants to count vowel groups
        n_vowels = split(w, arr, /[^aeiouy]+/)
        
        # Empty parts match boundaries; array length gives a good approximation
        # Let us do a stricter regex count of vowel groups
        syl_count = 0
        w_copy = w
        while (match(w_copy, /[aeiouy]+/)) {
            syl_count++
            w_copy = substr(w_copy, RSTART + RLENGTH)
        }
        
        # Every word has at least 1 syllable
        if (syl_count == 0) syl_count = 1
        
        syllables += syl_count
        if (syl_count >= 3) {
            complex_words++
        }
    }
}
END {
    if (words == 0) {
        print "  No words found."
        exit
    }
    if (sentences == 0) sentences = 1
    
    # metrics
    flesch_ease = 206.835 - 1.015 * (words / sentences) - 84.6 * (syllables / words)
    flesch_grade = 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59
    fog_index = 0.4 * ((words / sentences) + 100 * (complex_words / words))
    
    printf "  Sentences:             %-10d\n", sentences
    printf "  Words:                 %-10d\n", words
    printf "  Syllables (approx):    %-10d\n", syllables
    printf "  Complex words (3+):  %-10d (%.1f%%)\n\n", complex_words, (complex_words/words)*100
    
    printf "  Flesch Reading Ease:   %.2f\n", flesch_ease
    if (flesch_ease >= 90) print "                         (Very Easy, 5th grade)"
    else if (flesch_ease >= 80) print "                         (Easy, 6th grade)"
    else if (flesch_ease >= 70) print "                         (Fairly Easy, 7th grade)"
    else if (flesch_ease >= 60) print "                         (Standard, 8th-9th grade)"
    else if (flesch_ease >= 50) print "                         (Fairly Difficult, 10th-12th grade)"
    else if (flesch_ease >= 30) print "                         (Difficult, College)"
    else print "                         (Very Difficult, College Graduate)"
    
    print ""
    printf "  Flesch-Kincaid Grade:  %.2f  (US Grade Level)\n", flesch_grade
    printf "  Gunning Fog Index:     %.2f  (Years of formal education needed)\n", fog_index
}
' "$INPUT" || true

exit 0
