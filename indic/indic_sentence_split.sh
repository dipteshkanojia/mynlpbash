#!/usr/bin/env bash
# indic_sentence_split.sh — Split on Indic sentence terminators
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_sentence_split" "Split text on Indic sentence terminators (।, ॥, .!?)" \
        "indic_sentence_split.sh -i hindi.txt" \
        "-i, --input"     "Input text file" \
        "--use-indicnlp"   "Use indic_nlp_library for ML-aware splitting" \
        "-l, --lang"      "Language code for --use-indicnlp (default: hi)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; USE_INDICNLP=0 ; LANG="hi"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        --use-indicnlp)   USE_INDICNLP=1; shift ;;
        -l|--lang)        LANG="$2"; shift 2 ;;
        -o|--output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

if [[ $USE_INDICNLP -eq 1 ]]; then
    SCRIPT_DIR="$(dirname "$0")"
    ARGS=(-i "$INPUT" -l "$LANG")
    [[ -n "$OUTPUT" ]] && ARGS+=(-o "$OUTPUT")
    exec bash "$SCRIPT_DIR/indicnlp_sentence_split.sh" "${ARGS[@]}"
fi

process() {
    awk '{
        # Replace sentence terminators with newline markers
        gsub(/॥/, "॥\n", $0)
        gsub(/।/, "।\n", $0)
        gsub(/\. /, ".\n", $0)
        gsub(/! /, "!\n", $0)
        gsub(/\? /, "?\n", $0)
        # Print each segment
        n = split($0, parts, "\n")
        for (i=1; i<=n; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
            if (parts[i] != "") print parts[i]
        }
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Indic sentence split → $OUTPUT"
else
    process
fi
