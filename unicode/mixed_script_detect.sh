#!/usr/bin/env bash
# mixed_script_detect.sh — Detect lines with multiple Unicode scripts (code-mixing)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "mixed_script_detect" "Detect code-mixed lines (multiple Unicode scripts)" \
        "mixed_script_detect.sh -i text.txt" \
        "-i, --input"     "Input text file" \
        "--threshold"      "Min chars in 2nd script to flag (default: 2)" \
        "--show-labels"    "Show per-word script labels" \
        "-o, --output"    "Output file for mixed lines only" \
        "-h, --help"      "Show this help"
}

INPUT="" ; THRESHOLD=2 ; SHOW_LABELS=0 ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)      INPUT="$2"; shift 2 ;;
        --threshold)     THRESHOLD="$2"; shift 2 ;;
        --show-labels)   SHOW_LABELS=1; shift ;;
        -o|--output)     OUTPUT="$2"; shift 2 ;;
        -h|--help)       show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    awk -v threshold="$THRESHOLD" -v show_labels="$SHOW_LABELS" '
    BEGIN {
        for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
    }
    function word_script(word,   n,arr,i,c,b,b2,b3,cp,lat,indic) {
        n = split(word, arr, "")
        lat = 0; indic = 0
        for (i=1; i<=n; i++) {
            c = arr[i]; b = ord[c]
            if (c ~ /[A-Za-z]/) lat++
            else if (b >= 0xE0 && i+2 <= n) {
                b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
                cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
                if (cp >= 0x0900 && cp <= 0x0D7F) indic++
            }
        }
        if (lat > indic) return "Latin"
        else if (indic > 0) return "Indic"
        else return "Other"
    }
    {
        nw = split($0, words, /[[:space:]]+/)
        latin_count = 0; indic_count = 0
        labeled = ""
        for (w=1; w<=nw; w++) {
            if (words[w] == "") continue
            s = word_script(words[w])
            if (s == "Latin") latin_count++
            else if (s == "Indic") indic_count++
            if (show_labels) labeled = labeled sprintf("[%s:%s] ", s, words[w])
        }
        
        is_mixed = (latin_count >= threshold && indic_count >= threshold)
        total_words = latin_count + indic_count
        
        if (is_mixed) {
            mixed_count++
            if (total_words > 0) {
                cmi = 1.0 - (latin_count > indic_count ? latin_count : indic_count) / total_words
                total_cmi += cmi
            }
            if (show_labels) printf "  MIXED [L:%d I:%d CMI:%.2f] %s\n", latin_count, indic_count, cmi, labeled
        } else if (show_labels) {
            dominant = (indic_count > latin_count) ? "Indic" : "Latin"
            printf "  %5s [L:%d I:%d] %s\n", dominant, latin_count, indic_count, labeled
        }
        lines++
    }
    END {
        printf "\n  ── Summary ──\n"
        printf "  %-25s %d\n", "Total lines:", lines
        printf "  %-25s %d (%.1f%%)\n", "Code-mixed lines:", mixed_count+0, (mixed_count+0)*100/lines
        printf "  %-25s %d (%.1f%%)\n", "Monolingual lines:", lines-(mixed_count+0), (lines-(mixed_count+0))*100/lines
        if (mixed_count+0 > 0)
            printf "  %-25s %.3f\n", "Avg CMI (mixed only):", total_cmi/mixed_count
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Mixed script detection → $OUTPUT"
else
    echo -e "${BOLD}═══ Mixed Script Detection ═══${NC}"
    echo ""
    process
    echo ""
fi
