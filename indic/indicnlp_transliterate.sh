#!/usr/bin/env bash
# indicnlp_transliterate.sh — Cross-script transliteration via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_transliterate" "Transliterate text between any two Indic scripts" \
        "indicnlp_transliterate.sh -i hindi.txt -s hi -t bn" \
        "-i, --input"     "Input text file" \
        "-s, --src-lang"  "Source language code (e.g., hi, bn, ta, te, kn, ml, gu, pa, or)" \
        "-t, --tgt-lang"  "Target language code" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; SRC="" ; TGT="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -s|--src-lang)  SRC="$2"; shift 2 ;;
        -t|--tgt-lang)  TGT="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$SRC" ]] && die "Source language required (-s)"
[[ -z "$TGT" ]] && die "Target language required (-t)"
require_file "$INPUT"

process() {
    python3 -c "
import sys, os
os.environ.setdefault('INDIC_RESOURCES_PATH', os.path.join(os.path.dirname('$0'), '..', 'lib', 'indic_nlp_resources'))
from indicnlp import loader
from indicnlp.transliterate import unicode_transliterate
loader.load()

src_lang = '$SRC'
tgt_lang = '$TGT'

for line in open('$INPUT', encoding='utf-8'):
    transliterated = unicode_transliterate.UnicodeIndicTransliterator.transliterate(
        line, src_lang, tgt_lang)
    print(transliterated, end='')
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "IndicNLP transliteration ($SRC → $TGT) → $OUTPUT"
else
    process
fi
