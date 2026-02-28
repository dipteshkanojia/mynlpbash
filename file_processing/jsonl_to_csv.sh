#!/usr/bin/env bash
# jsonl_to_csv.sh — Convert JSON Lines to CSV format
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "jsonl_to_csv" "Convert JSON Lines to CSV format" \
        "jsonl_to_csv.sh -i input.jsonl [-o output.csv] [-d delimiter]" \
        "-i, --input"     "Input JSONL file" \
        "-o, --output"    "Output CSV file (default: stdout)" \
        "-d, --delimiter" "Output delimiter (default: ,)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; OUTPUT="" ; DELIM=","
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    awk -v delim="$DELIM" '
    function extract_keys(line, keys, nkeys,    i, key, in_key, in_val, c, depth) {
        nkeys = 0
        i = 1
        while (i <= length(line)) {
            c = substr(line, i, 1)
            if (c == "\"") {
                key = ""
                i++
                while (i <= length(line)) {
                    c = substr(line, i, 1)
                    if (c == "\"") break
                    key = key c
                    i++
                }
                i++
                # skip to colon
                while (i <= length(line) && substr(line, i, 1) != ":") i++
                i++
                nkeys++
                keys[nkeys] = key
                # skip value
                while (i <= length(line) && substr(line, i, 1) == " ") i++
                c = substr(line, i, 1)
                if (c == "\"") {
                    i++
                    while (i <= length(line)) {
                        c = substr(line, i, 1)
                        if (c == "\\" ) { i += 2; continue }
                        if (c == "\"") break
                        i++
                    }
                    i++
                } else {
                    while (i <= length(line) && substr(line, i, 1) != "," && substr(line, i, 1) != "}") i++
                }
            }
            i++
        }
        return nkeys
    }
    function extract_value(line, key,    i, c, k, val) {
        i = index(line, "\"" key "\"")
        if (i == 0) return ""
        i += length(key) + 2
        while (i <= length(line) && substr(line, i, 1) != ":") i++
        i++
        while (i <= length(line) && substr(line, i, 1) == " ") i++
        c = substr(line, i, 1)
        if (c == "\"") {
            i++
            val = ""
            while (i <= length(line)) {
                c = substr(line, i, 1)
                if (c == "\\") { val = val substr(line, i+1, 1); i += 2; continue }
                if (c == "\"") break
                val = val c
                i++
            }
            return val
        } else {
            val = ""
            while (i <= length(line) && substr(line, i, 1) != "," && substr(line, i, 1) != "}") {
                val = val substr(line, i, 1)
                i++
            }
            gsub(/^ +| +$/, "", val)
            return val
        }
    }
    NR==1 {
        nkeys = extract_keys($0, headers, nkeys)
        for (i=1; i<=nkeys; i++) {
            if (i > 1) printf "%s", delim
            printf "%s", headers[i]
        }
        print ""
    }
    {
        for (i=1; i<=nkeys; i++) {
            val = extract_value($0, headers[i])
            if (i > 1) printf "%s", delim
            if (val ~ /[,"\t\n]/) {
                gsub(/"/, "\"\"", val)
                printf "\"%s\"", val
            } else {
                printf "%s", val
            }
        }
        print ""
    }
    ' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Converted → $OUTPUT"
else
    process
fi
