#!/usr/bin/env bash
# indicnlp_langinfo.sh — Character and script property lookup via indic_nlp_library
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
source "$(dirname "$0")/../lib/common.sh"
[[ -f "$(dirname "$0")/../lib/indicnlp_env.sh" ]] && source "$(dirname "$0")/../lib/indicnlp_env.sh"

show_help() {
    print_help "indicnlp_langinfo" "Query Indic script/character properties" \
        "indicnlp_langinfo.sh --list-langs" \
        "--list-langs"      "List all supported language codes" \
        "--char-info"       "Character info: is_vowel, is_consonant, etc." \
        "-l, --lang"        "Language code for char-info" \
        "--analyze-text"    "Analyze text and report char categories" \
        "-i, --input"       "Input text file (for --analyze-text)" \
        "-h, --help"        "Show this help"
}

MODE="" ; LANG="hi" ; INPUT="" ; CHAR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --list-langs)    MODE="list"; shift ;;
        --char-info)     MODE="charinfo"; CHAR="$2"; shift 2 ;;
        --analyze-text)  MODE="analyze"; shift ;;
        -l|--lang)       LANG="$2"; shift 2 ;;
        -i|--input)      INPUT="$2"; shift 2 ;;
        -h|--help)       show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$MODE" ]] && die "Specify --list-langs, --char-info <char>, or --analyze-text"

if [[ "$MODE" == "list" ]]; then
    python3 -c "
from indicnlp.script import indic_scripts as isc
print('Supported languages and Unicode blocks:')
print()
langs = {
    'hi': 'Hindi (Devanagari)',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'mr': 'Marathi (Devanagari)',
    'pa': 'Punjabi (Gurmukhi)',
    'gu': 'Gujarati',
    'or': 'Odia',
    'as': 'Assamese (Bengali)',
    'ur': 'Urdu',
    'si': 'Sinhala',
    'ne': 'Nepali (Devanagari)',
    'sd': 'Sindhi',
    'ks': 'Kashmiri',
    'sa': 'Sanskrit (Devanagari)',
}
for code, name in sorted(langs.items()):
    print(f'  {code:4s}  {name}')
" 2>&1

elif [[ "$MODE" == "charinfo" ]]; then
    python3 -c "
import sys
from indicnlp import loader
from indicnlp.script import indic_scripts as isc
from indicnlp import langinfo as li
loader.load()

char = '$CHAR'
lang = '$LANG'

print(f'Character: {char}')
print(f'Language:  {lang}')
print()

try:
    script_range = li.SCRIPT_RANGES.get(lang, [0, 0])
    cp = ord(char)
    print(f'Code point: U+{cp:04X}')
    print(f'Offset:     {isc.get_offset(char, lang)}')
    v = isc.get_phonetic_feature_vector(char, lang)
    print(f'Is vowel:           {isc.is_vowel(v)}')
    print(f'Is consonant:       {isc.is_consonant(v)}')
    print(f'Is dependent vowel: {isc.is_dependent_vowel(v)}')
    print(f'Is halant:          {isc.is_halant(v)}')
    print(f'Is nukta:           {isc.is_nukta(v)}')
    print(f'Is anusvaar:        {isc.is_anusvaar(v)}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1

elif [[ "$MODE" == "analyze" ]]; then
    [[ -z "$INPUT" ]] && die "Input file required (-i) for --analyze-text"
    require_file "$INPUT"

    python3 -c "
import sys, os
os.environ.setdefault('INDIC_RESOURCES_PATH', os.path.join(os.path.dirname('$0'), '..', 'lib', 'indic_nlp_resources'))
from indicnlp import loader
from indicnlp.script import indic_scripts as isc
from indicnlp import langinfo as li
loader.load()

lang = '$LANG'
vowels = consonants = dep_vowels = halants = nuktas = anusvaar = other = 0
script_range = li.SCRIPT_RANGES.get(lang, [0, 0])

for line in open('$INPUT', encoding='utf-8'):
    for ch in line:
        cp = ord(ch)
        if cp >= script_range[0] and cp <= script_range[1]:
            try:
                v = isc.get_phonetic_feature_vector(ch, lang)
                if isc.is_vowel(v): vowels += 1
                elif isc.is_consonant(v): consonants += 1
                elif isc.is_dependent_vowel(v): dep_vowels += 1
                elif isc.is_halant(v): halants += 1
                elif isc.is_nukta(v): nuktas += 1
                elif isc.is_anusvaar(v): anusvaar += 1
                else: other += 1
            except:
                other += 1

total = vowels + consonants + dep_vowels + halants + nuktas + anusvaar + other
print(f'Character Analysis ({lang})')
print()
if total == 0:
    print('  No Indic characters found for this language code.')
else:
    print(f'  Vowels (indep):   {vowels:6d}  ({vowels*100/total:.1f}%)')
    print(f'  Consonants:       {consonants:6d}  ({consonants*100/total:.1f}%)')
    print(f'  Vowel signs:      {dep_vowels:6d}  ({dep_vowels*100/total:.1f}%)')
    print(f'  Halants:          {halants:6d}  ({halants*100/total:.1f}%)')
    print(f'  Nuktas:           {nuktas:6d}  ({nuktas*100/total:.1f}%)')
    print(f'  Anusvaar:         {anusvaar:6d}  ({anusvaar*100/total:.1f}%)')
    print(f'  Other script:     {other:6d}  ({other*100/total:.1f}%)')
    print(f'  ─────────────────────')
    print(f'  Total:            {total:6d}')
" 2>&1
fi
