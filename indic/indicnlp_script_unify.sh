#!/usr/bin/env bash
# indicnlp_script_unify.sh — Script unification via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_script_unify" "Map multiple Indic scripts to a common representation" \
        "indicnlp_script_unify.sh -i text.txt -l ta --mode basic --common hi" \
        "-i, --input"     "Input text file" \
        "-l, --lang"      "Source language code" \
        "--mode"           "Unification mode: naive, basic, aggressive (default: basic)" \
        "--common"         "Common target language (default: hi)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="" ; MODE="basic" ; COMMON="hi" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -l|--lang)    LANG="$2"; shift 2 ;;
        --mode)       MODE="$2"; shift 2 ;;
        --common)     COMMON="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$LANG" ]] && die "Source language required (-l)"
require_file "$INPUT"

process() {
    python3 -c "
import sys, os
os.environ.setdefault('INDIC_RESOURCES_PATH', os.path.join(os.path.dirname('$0'), '..', 'lib', 'indic_nlp_resources'))
from indicnlp import loader
from indicnlp.transliterate import script_unifier
loader.load()

lang = '$LANG'
mode = '$MODE'
common_lang = '$COMMON'

if mode == 'aggressive':
    unifier = script_unifier.AggressiveScriptUnifier(
        nasals_mode='to_anusvaara_relaxed', common_lang=common_lang)
elif mode == 'basic':
    unifier = script_unifier.BasicScriptUnifier(
        nasals_mode='do_nothing', common_lang=common_lang)
elif mode == 'naive':
    unifier = script_unifier.NaiveScriptUnifier(common_lang=common_lang)
else:
    print(f'Unknown mode: {mode}', file=sys.stderr)
    sys.exit(1)

for line in open('$INPUT', encoding='utf-8'):
    unified = unifier.transform(line, lang)
    print(unified, end='')
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Script unification ($LANG → $COMMON, mode=$MODE) → $OUTPUT"
else
    process
fi
