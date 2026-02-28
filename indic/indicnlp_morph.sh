#!/usr/bin/env bash
# indicnlp_morph.sh — Unsupervised morphological analysis via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_morph" "Unsupervised morphological analysis (segment words into morphemes)" \
        "indicnlp_morph.sh -i hindi.txt -l hi" \
        "-i, --input"     "Input text file" \
        "-l, --lang"      "Language code (hi, bn, ta, te, kn, ml, mr, pa, gu, or)" \
        "--add-marker"     "Add morpheme boundary markers (+)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="hi" ; OUTPUT="" ; ADD_MARKER="False"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -l|--lang)      LANG="$2"; shift 2 ;;
        --add-marker)   ADD_MARKER="True"; shift ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    python3 -c "
import sys, os
os.environ.setdefault('INDIC_RESOURCES_PATH', os.path.join(os.path.dirname('$0'), '..', 'lib', 'indic_nlp_resources'))
from indicnlp import loader
from indicnlp.morph import unsupervised_morph
loader.load()

lang = '$LANG'
add_marker = $ADD_MARKER
analyzer = unsupervised_morph.UnsupervisedMorphAnalyzer(lang, add_marker)

for line in open('$INPUT', encoding='utf-8'):
    line = line.strip()
    if line:
        words = line.split(' ')
        morph_tokens = analyzer.morph_analyze_document(words)
        print(' '.join(morph_tokens))
    else:
        print()
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "IndicNLP morphological analysis ($LANG) → $OUTPUT"
else
    process
fi
