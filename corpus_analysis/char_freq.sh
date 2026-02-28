#!/usr/bin/env bash
# char_freq.sh — Character frequency analysis
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "char_freq" "Character frequency analysis" \
        "char_freq.sh -i corpus.txt [-n 20]" \
        "-i, --input"   "Input text file (or stdin)" \
        "-n, --top"     "Show top N characters (default: all)" \
        "--bar"          "Show bar chart" \
        "--no-space"     "Exclude whitespace characters" \
        "-o, --output"  "Output file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT="" ; TOP="" ; BAR=0 ; NO_SPACE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        -n|--top)     TOP="$2"; shift 2 ;;
        --bar)        BAR=1; shift ;;
        --no-space)   NO_SPACE=1; shift ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

process() {
    local src
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        src="$INPUT"
    else
        src="/dev/stdin"
    fi

    local filter=""
    [[ $NO_SPACE -eq 1 ]] && filter='| grep -v "^[[:space:]]$"'

    local pipeline="fold -w1 < '$src' $filter | sort | uniq -c | sort -rn"
    [[ -n "$TOP" ]] && pipeline="$pipeline | head -n $TOP"

    if [[ $BAR -eq 1 ]]; then
        local data
        data=$(eval "$pipeline")
        local max_count
        max_count=$(echo "$data" | head -1 | awk '{print $1}')
        echo -e "${BOLD}Character Frequency${NC}"
        echo ""
        echo "$data" | while read -r count char; do
            # Show special chars readably
            case "$char" in
                " ") display="SPACE" ;;
                "")  display="NEWLINE" ;;
                *)   display="$char" ;;
            esac
            bar_len=$(( count * 30 / max_count ))
            bar=$(printf '█%.0s' $(seq 1 "$bar_len" 2>/dev/null) || true)
            printf "  %8d %-10s %s\n" "$count" "'$display'" "$bar"
        done
    else
        eval "$pipeline" | while read -r count char; do
            case "$char" in
                " ") char="SPACE" ;;
                "")  char="NEWLINE" ;;
            esac
            printf "%s\t%s\n" "$count" "$char"
        done
    fi
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Character frequencies → $OUTPUT"
else
    process
fi
