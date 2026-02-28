#!/usr/bin/env bash
# word_freq.sh — Word frequency analysis
# Author: Diptesh
# Status: Original — foundational script
# word_freq.sh — Word frequency analysis was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "word_freq" "Word frequency counts with optional top-N and min-freq" \
        "word_freq.sh -i corpus.txt [-n 20] [--min 5]" \
        "-i, --input"   "Input text file (or stdin)" \
        "-n, --top"     "Show top N words (default: all)" \
        "--min"          "Minimum frequency threshold" \
        "--lower"        "Lowercase before counting" \
        "--bar"          "Show bar chart" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; TOP="" ; MIN=0 ; LOWER=0 ; BAR=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -n|--top)    TOP="$2"; shift 2 ;;
        --min)       MIN="$2"; shift 2 ;;
        --lower)     LOWER=1; shift ;;
        --bar)       BAR=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

process() {
    local input_cmd="cat"
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        input_cmd="cat '$INPUT'"
    fi

    local pipeline="$input_cmd"
    [[ $LOWER -eq 1 ]] && pipeline="$pipeline | tr '[:upper:]' '[:lower:]'"
    pipeline="$pipeline | tr -s '[:space:][:punct:]' '\n' | grep -v '^$' | sort | uniq -c | sort -rn"
    [[ "$MIN" -gt 0 ]] && pipeline="$pipeline | awk '\$1 >= $MIN'"
    [[ -n "$TOP" ]] && pipeline="$pipeline | head -n $TOP"

    # ─── AI Enhancement (Claude Opus): Visual bar chart rendering ────────
    if [[ $BAR -eq 1 ]]; then
        local data
        data=$(eval "$pipeline")
        local max_count
        max_count=$(echo "$data" | head -1 | awk '{print $1}')
        echo -e "${BOLD}Word Frequency${NC}"
        echo ""
        echo "$data" | awk -v max="$max_count" '{
            freq = $1; word = $2
            bar_len = int(freq * 30 / max)
            bar = ""
            for (i=0; i<bar_len; i++) bar = bar "█"
            printf "  %8d %-20s %s\n", freq, word, bar
        }'
    else
        eval "$pipeline" | awk '{printf "%s\t%s\n", $1, $2}'
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Word frequencies → $OUTPUT"
else
    process
fi
