#!/usr/bin/env bash
# stopword_remove.sh — Remove stopwords from text
# Author: Diptesh
# Status: Original — foundational script
# stopword_remove.sh — Remove stopwords from text was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "stopword_remove" "Remove stopwords from text" \
        "stopword_remove.sh -i input.txt [-o output.txt] [--lang en]" \
        "-i, --input"      "Input text file (or stdin)" \
        "-o, --output"     "Output file (default: stdout)" \
        "-s, --stopwords"  "Custom stopword file (one per line)" \
        "--lang"            "Language for built-in list: en (default)" \
        "-h, --help"       "Show this help"
}

# Built-in English stopwords
ENGLISH_STOPWORDS="a an the is am are was were be been being have has had do does did will would shall should may might can could and but or nor not no so for yet both either neither each every all any few more most other some such than too very of in on at to from by with as into through during before after above below between under again further then once here there when where why how what which who whom this that these those i me my myself we our ours ourselves you your yours yourself yourselves he him his himself she her hers herself it its itself they them their theirs themselves"

INPUT="" ; OUTPUT="" ; STOPFILE="" ; LANG="en"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -s|--stopwords) STOPFILE="$2"; shift 2 ;;
        --lang)         LANG="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

# Build stopword list
if [[ -n "$STOPFILE" ]]; then
    require_file "$STOPFILE"
    STOPS=$(cat "$STOPFILE" | tr '\n' '|' | sed 's/|$//')
else
    STOPS=$(echo "$ENGLISH_STOPWORDS" | tr ' ' '|')
fi

process() {
    local src
    if [[ -n "$INPUT" ]]; then
        require_file "$INPUT"
        src="$INPUT"
    else
        src="/dev/stdin"
    fi

    awk -v stops="$STOPS" '
    BEGIN {
        n = split(stops, sw, "|")
        for (i=1; i<=n; i++) stopwords[tolower(sw[i])] = 1
    }
    {
        result = ""
        n = split($0, words, /[[:space:]]+/)
        for (i=1; i<=n; i++) {
            w = words[i]
            clean = tolower(w)
            gsub(/[^a-z]/, "", clean)
            if (!(clean in stopwords) && clean != "") {
                result = result (result=="" ? "" : " ") w
            }
        }
        print result
    }' "$src"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Stopwords removed → $OUTPUT"
else
    process
fi
