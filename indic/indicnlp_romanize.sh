#!/usr/bin/env bash
# indicnlp_romanize.sh — Bidirectional ITRANS romanization via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_romanize" "Bidirectional ITRANS romanization (Indic↔Latin)" \
        "indicnlp_romanize.sh -i hindi.txt -l hi --to-roman" \
        "-i, --input"     "Input text file" \
        "-l, --lang"      "Language code (hi, bn, ta, te, kn, ml, mr, pa, gu, or)" \
        "--to-roman"       "Indic → ITRANS romanization (default)" \
        "--from-roman"     "ITRANS → Indic (indicization)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="hi" ; OUTPUT="" ; MODE="to_roman"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)    INPUT="$2"; shift 2 ;;
        -l|--lang)     LANG="$2"; shift 2 ;;
        --to-roman)    MODE="to_roman"; shift ;;
        --from-roman)  MODE="from_roman"; shift ;;
        -o|--output)   OUTPUT="$2"; shift 2 ;;
        -h|--help)     show_help; exit 0 ;;
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
from indicnlp.transliterate import unicode_transliterate
loader.load()

lang = '$LANG'
mode = '$MODE'

for line in open('$INPUT', encoding='utf-8'):
    if mode == 'to_roman':
        result = unicode_transliterate.ItransTransliterator.to_itrans(line, lang)
    else:
        result = unicode_transliterate.ItransTransliterator.from_itrans(line, lang)
    print(result, end='')
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    if [[ "$MODE" == "to_roman" ]]; then
        success "Romanization ($LANG → ITRANS) → $OUTPUT"
    else
        success "Indicization (ITRANS → $LANG) → $OUTPUT"
    fi
else
    process
fi
