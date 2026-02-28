#!/usr/bin/env bash
# detect_script.sh — Detect dominant Unicode script per line or document
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "detect_script" "Detect dominant Unicode script per line or document" \
        "detect_script.sh -i text.txt [--per-line]" \
        "-i, --input"     "Input text file" \
        "--per-line"       "Output script per line (default: corpus summary)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; PER_LINE=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --per-line)  PER_LINE=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    awk -v per_line="$PER_LINE" '
    BEGIN {
        for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
    }
    function detect_line(line,   n,arr,i,c,b,b2,b3,cp,scripts,max_s,max_c,s) {
        delete scripts
        n = split(line, arr, "")
        for (i=1; i<=n; i++) {
            c = arr[i]
            b = ord[c]
            if (c ~ /[A-Za-z]/) scripts["Latin"]++
            else if (b >= 0xE0 && i+2 <= n) {
                b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
                cp = (b - 0xE0)*4096 + (b2 - 0x80)*64 + (b3 - 0x80)
                if (cp >= 0x0900 && cp <= 0x097F) scripts["Devanagari"]++
                else if (cp >= 0x0980 && cp <= 0x09FF) scripts["Bengali"]++
                else if (cp >= 0x0A00 && cp <= 0x0A7F) scripts["Gurmukhi"]++
                else if (cp >= 0x0A80 && cp <= 0x0AFF) scripts["Gujarati"]++
                else if (cp >= 0x0B00 && cp <= 0x0B7F) scripts["Odia"]++
                else if (cp >= 0x0B80 && cp <= 0x0BFF) scripts["Tamil"]++
                else if (cp >= 0x0C00 && cp <= 0x0C7F) scripts["Telugu"]++
                else if (cp >= 0x0C80 && cp <= 0x0CFF) scripts["Kannada"]++
                else if (cp >= 0x0D00 && cp <= 0x0D7F) scripts["Malayalam"]++
                else if (cp >= 0x0600 && cp <= 0x06FF) scripts["Arabic"]++
                else if (cp >= 0x4E00 && cp <= 0x9FFF) scripts["CJK"]++
                else if (cp >= 0x0400 && cp <= 0x04FF) scripts["Cyrillic"]++
            } else if (b >= 0xC0 && i+1 <= n) {
                b2 = ord[arr[i+1]]
                cp = (b - 0xC0)*64 + (b2 - 0x80)
                if (cp >= 0x00C0 && cp <= 0x024F) scripts["Latin"]++
                else if (cp >= 0x0400 && cp <= 0x04FF) scripts["Cyrillic"]++
            }
        }
        max_s = "Unknown"; max_c = 0
        for (s in scripts) {
            corpus_scripts[s] += scripts[s]
            if (scripts[s] > max_c) { max_c = scripts[s]; max_s = s }
        }
        return max_s
    }
    {
        dominant = detect_line($0)
        line_scripts[dominant]++
        lines++
        if (per_line) printf "%s\t%s\n", dominant, $0
    }
    END {
        if (!per_line) {
            printf "  %-15s %6s %7s\n", "Script", "Lines", "%"
            printf "  %-15s %6s %7s\n", "──────", "─────", "───"
            for (s in line_scripts) {
                printf "  %-15s %6d %6.1f%%\n", s, line_scripts[s], line_scripts[s]*100/lines
            }
            print ""
            tc = 0; for (s in corpus_scripts) tc += corpus_scripts[s]
            printf "  Character-level breakdown (%d script chars):\n", tc
            for (s in corpus_scripts) {
                printf "    %-15s %6d (%5.1f%%)\n", s, corpus_scripts[s], corpus_scripts[s]*100/tc
            }
        }
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Script detection → $OUTPUT"
else
    echo -e "${BOLD}═══ Script Detection ═══${NC}"
    echo ""
    process
    echo ""
fi
