#!/usr/bin/env bash
# indicnlp_phonetic_sim.sh — Phonetic similarity across Indic scripts
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_phonetic_sim" "Compute phonetic similarity between Indic characters/words" \
        "indicnlp_phonetic_sim.sh --char क hi ক bn" \
        "--char"          "Compare two chars: <char1> <lang1> <char2> <lang2>" \
        "--word"          "Compare two words: <word1> <lang1> <word2> <lang2>" \
        "--matrix"        "Show phonetic distance matrix for a word" \
        "-h, --help"      "Show this help"
}

MODE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --char)   MODE="char"; CHAR1="$2"; LANG1="$3"; CHAR2="$4"; LANG2="$5"; shift 5 ;;
        --word)   MODE="word"; WORD1="$2"; LANG1="$3"; WORD2="$4"; LANG2="$5"; shift 5 ;;
        --matrix) MODE="matrix"; WORD="$2"; LANG1="$3"; shift 3 ;;
        -h|--help) show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$MODE" ]] && die "Specify --char, --word, or --matrix"

if [[ "$MODE" == "char" ]]; then
    python3 -c "
from indicnlp import loader
from indicnlp.script import phonetic_sim as ps
from indicnlp.script import indic_scripts as isc
loader.load()

c1, l1 = '$CHAR1', '$LANG1'
c2, l2 = '$CHAR2', '$LANG2'

try:
    v1 = isc.get_phonetic_feature_vector(c1, l1)
    v2 = isc.get_phonetic_feature_vector(c2, l2)
    sim = ps.cosine(v1, v2)
    print(f'Character 1: {c1} ({l1})')
    print(f'Character 2: {c2} ({l2})')
    print(f'Phonetic similarity: {sim:.4f}')
    print(f'Same sound: {\"Yes\" if sim > 0.9 else \"No\"}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1

elif [[ "$MODE" == "word" ]]; then
    python3 -c "
from indicnlp import loader
from indicnlp.script import phonetic_sim as ps
from indicnlp.script import indic_scripts as isc
loader.load()

w1, l1 = '$WORD1', '$LANG1'
w2, l2 = '$WORD2', '$LANG2'

# Character-level similarity across words
min_len = min(len(w1), len(w2))
total_sim = 0
matches = 0
for i in range(min_len):
    try:
        v1 = isc.get_phonetic_feature_vector(w1[i], l1)
        v2 = isc.get_phonetic_feature_vector(w2[i], l2)
        sim = ps.cosine(v1, v2)
        total_sim += sim
        matches += 1
        print(f'  {w1[i]} ({l1}) ↔ {w2[i]} ({l2}): {sim:.3f}')
    except:
        pass

if matches > 0:
    avg = total_sim / matches
    print(f'')
    print(f'  Average similarity: {avg:.4f}')
    print(f'  Cognate likelihood: {\"High\" if avg > 0.7 else \"Medium\" if avg > 0.4 else \"Low\"}')
" 2>&1

elif [[ "$MODE" == "matrix" ]]; then
    python3 -c "
from indicnlp.transliterate import unicode_transliterate as ut

word = '$WORD'
src_lang = '$LANG1'
targets = ['hi', 'bn', 'ta', 'te', 'kn', 'ml', 'gu', 'pa', 'or']

print(f'Cross-script representation of: {word} ({src_lang})')
print()
for tgt in targets:
    if tgt != src_lang:
        try:
            transliterated = ut.UnicodeIndicTransliterator.transliterate(word, src_lang, tgt)
            print(f'  {tgt}: {transliterated.strip()}')
        except:
            pass
" 2>&1
fi
