#!/usr/bin/env bash
# indicnlp_detokenize.sh — Indic detokenization via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_detokenize" "Reassemble tokenized Indic text back into natural form" \
        "indicnlp_detokenize.sh -i tokens.txt -l hi" \
        "-i, --input"     "Input tokenized file" \
        "-l, --lang"      "Language code (hi, bn, ta, te, kn, ml, mr, pa, gu, or)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="hi" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -l|--lang)    LANG="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
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
from indicnlp.tokenize import indic_detokenize
loader.load()
lang = '$LANG'
for line in open('$INPUT', encoding='utf-8'):
    line = line.strip()
    if line:
        detok = indic_detokenize.trivial_detokenize(line, lang)
        print(detok.strip())
    else:
        print()
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "IndicNLP detokenization ($LANG) → $OUTPUT"
else
    process
fi
