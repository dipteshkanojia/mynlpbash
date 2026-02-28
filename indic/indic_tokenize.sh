#!/usr/bin/env bash
# indic_tokenize.sh — Indic-aware tokenizer
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_tokenize" "Indic-aware tokenizer (handles purna viram, conjuncts, ZWJ)" \
        "indic_tokenize.sh -i hindi.txt [-o tokens.txt]" \
        "-i, --input"     "Input text file" \
        "--keep-punct"     "Keep punctuation as separate tokens" \
        "--use-indicnlp"   "Use indic_nlp_library for higher quality tokenization" \
        "-l, --lang"      "Language code for --use-indicnlp (default: hi)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; KEEP_PUNCT=0 ; USE_INDICNLP=0 ; LANG="hi"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        --keep-punct)     KEEP_PUNCT=1; shift ;;
        --use-indicnlp)   USE_INDICNLP=1; shift ;;
        -l|--lang)        LANG="$2"; shift 2 ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Delegate to IndicNLP library if requested
if [[ $USE_INDICNLP -eq 1 ]]; then
    SCRIPT_DIR="$(dirname "$0")"
    ARGS=(-i "$INPUT" -l "$LANG")
    [[ -n "$OUTPUT" ]] && ARGS+=(-o "$OUTPUT")
    exec bash "$SCRIPT_DIR/indicnlp_tokenize.sh" "${ARGS[@]}"
fi

process() {
    awk -v keep="$KEEP_PUNCT" '
    {
        # Separate Indic punctuation: purna viram, double danda, commas
        gsub(/।/, " । ", $0)
        gsub(/॥/, " ॥ ", $0)
        # Separate Latin punctuation from words
        gsub(/([,;:!?\.\(\)\[\]"'"'"'])/, " \\1 ", $0)
        # Separate hyphens if between different script words
        gsub(/([[:alpha:]])-([[:alpha:]])/, "\\1 - \\2", $0)
        # Collapse whitespace
        gsub(/[[:space:]]+/, " ", $0)
        gsub(/^ +| +$/, "", $0)
        
        if (!keep) {
            # Remove standalone punctuation tokens
            gsub(/ [,;:!?\.\(\)\[\]"'"'"'] /, " ", $0)
            gsub(/^ [,;:!?\.\(\)\[\]"'"'"'] /, "", $0)
            gsub(/ [,;:!?\.\(\)\[\]"'"'"']$/, "", $0)
        }
        
        print
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Indic tokenization → $OUTPUT"
else
    process
fi
