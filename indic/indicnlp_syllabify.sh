#!/usr/bin/env bash
# indicnlp_syllabify.sh — Orthographic syllabification via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_syllabify" "Orthographic syllabification using Unicode-aware rules" \
        "indicnlp_syllabify.sh -i hindi.txt -l hi" \
        "-i, --input"     "Input text file" \
        "-l, --lang"      "Language code (hi, bn, ta, te, kn, ml, mr, pa, gu, or)" \
        "--count"          "Show syllable counts instead of syllables" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="hi" ; OUTPUT="" ; COUNT=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -l|--lang)    LANG="$2"; shift 2 ;;
        --count)      COUNT=1; shift ;;
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
from indicnlp.syllable import syllabifier
loader.load()

lang = '$LANG'
count_mode = $COUNT

for line in open('$INPUT', encoding='utf-8'):
    line = line.strip()
    if not line:
        print()
        continue
    words = line.split()
    if count_mode:
        total = 0
        for w in words:
            syls = syllabifier.orthographic_syllabify(w, lang)
            total += len(syls)
        print(f'{total}\t{line}')
    else:
        syllabified = []
        for w in words:
            syls = syllabifier.orthographic_syllabify(w, lang)
            syllabified.append('-'.join(syls))
        print(' '.join(syllabified))
" 2>&1
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "IndicNLP syllabification ($LANG) → $OUTPUT"
else
    process
fi
