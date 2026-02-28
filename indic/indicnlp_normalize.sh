#!/usr/bin/env bash
# indicnlp_normalize.sh — Indic text normalization via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_normalize" "Language-specific Indic normalization (nuktas, nasals, visarga)" \
        "indicnlp_normalize.sh -i hindi.txt -l hi [-o normalized.txt]" \
        "-i, --input"        "Input text file" \
        "-l, --lang"         "Language code (hi, bn, ta, te, kn, ml, mr, pa, gu, or)" \
        "--remove-nuktas"     "Remove nukta characters" \
        "--nasals"            "Nasal normalization: do_nothing, to_anusvaara_strict, to_anusvaara_relaxed, to_nasal_consonants (default: do_nothing)" \
        "-o, --output"       "Output file (default: stdout)" \
        "-h, --help"         "Show this help"
}

INPUT="" ; LANG="hi" ; OUTPUT="" ; NUKTAS="false" ; NASALS="do_nothing"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        -l|--lang)        LANG="$2"; shift 2 ;;
        --remove-nuktas)  NUKTAS="true"; shift ;;
        --nasals)         NASALS="$2"; shift 2 ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    local py_nuktas="False"
    [[ "$NUKTAS" == "true" ]] && py_nuktas="True"
    python3 -c "
import sys, os
os.environ.setdefault('INDIC_RESOURCES_PATH', os.path.join(os.path.dirname('$0'), '..', 'lib', 'indic_nlp_resources'))
from indicnlp import loader
from indicnlp.normalize import indic_normalize
loader.load()

lang = '$LANG'
remove_nuktas = $py_nuktas
nasals_mode = '$NASALS'

factory = indic_normalize.IndicNormalizerFactory()
normalizer = factory.get_normalizer(lang,
    remove_nuktas=remove_nuktas,
    nasals_mode=nasals_mode)

for line in open('$INPUT', encoding='utf-8'):
    normalized = normalizer.normalize(line)
    print(normalized, end='')
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "IndicNLP normalization ($LANG) → $OUTPUT"
else
    process
fi
