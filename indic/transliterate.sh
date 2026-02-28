#!/usr/bin/env bash
# transliterate.sh — Romanize Indic scripts using IAST/ISO 15919 maps
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "transliterate" "Romanize Indic scripts (Devanagari → IAST)" \
        "transliterate.sh -i hindi.txt --from devanagari" \
        "-i, --input"     "Input text file" \
        "--from"           "Source script: devanagari (default)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; FROM="devanagari" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --from)       FROM="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    if [[ "$FROM" == "devanagari" ]]; then
        # Devanagari → IAST romanization via sed
        sed \
            -e 's/क्ष/kṣa/g' -e 's/त्र/tra/g' -e 's/ज्ञ/jña/g' -e 's/श्र/śra/g' \
            -e 's/क/ka/g' -e 's/ख/kha/g' -e 's/ग/ga/g' -e 's/घ/gha/g' -e 's/ङ/ṅa/g' \
            -e 's/च/ca/g' -e 's/छ/cha/g' -e 's/ज/ja/g' -e 's/झ/jha/g' -e 's/ञ/ña/g' \
            -e 's/ट/ṭa/g' -e 's/ठ/ṭha/g' -e 's/ड/ḍa/g' -e 's/ढ/ḍha/g' -e 's/ण/ṇa/g' \
            -e 's/त/ta/g' -e 's/थ/tha/g' -e 's/द/da/g' -e 's/ध/dha/g' -e 's/न/na/g' \
            -e 's/प/pa/g' -e 's/फ/pha/g' -e 's/ब/ba/g' -e 's/भ/bha/g' -e 's/म/ma/g' \
            -e 's/य/ya/g' -e 's/र/ra/g' -e 's/ल/la/g' -e 's/व/va/g' \
            -e 's/श/śa/g' -e 's/ष/ṣa/g' -e 's/स/sa/g' -e 's/ह/ha/g' \
            -e 's/अ/a/g' -e 's/आ/ā/g' -e 's/इ/i/g' -e 's/ई/ī/g' \
            -e 's/उ/u/g' -e 's/ऊ/ū/g' -e 's/ऋ/ṛ/g' \
            -e 's/ए/e/g' -e 's/ऐ/ai/g' -e 's/ओ/o/g' -e 's/औ/au/g' \
            -e 's/ा/ā/g' -e 's/ि/i/g' -e 's/ी/ī/g' \
            -e 's/ु/u/g' -e 's/ू/ū/g' -e 's/ृ/ṛ/g' \
            -e 's/े/e/g' -e 's/ै/ai/g' -e 's/ो/o/g' -e 's/ौ/au/g' \
            -e 's/्//g' \
            -e 's/ं/ṃ/g' -e 's/ः/ḥ/g' -e 's/ँ/m̐/g' \
            -e 's/।/./g' -e 's/॥/../g' \
            -e 's/ऽ/ʾ/g' \
            -e 's/०/0/g' -e 's/१/1/g' -e 's/२/2/g' -e 's/३/3/g' -e 's/४/4/g' \
            -e 's/५/5/g' -e 's/६/6/g' -e 's/७/7/g' -e 's/८/8/g' -e 's/९/9/g' \
            "$INPUT"
    else
        die "Unsupported source script: $FROM (currently only devanagari is supported)"
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Transliteration ($FROM → IAST) → $OUTPUT"
else
    process
fi
