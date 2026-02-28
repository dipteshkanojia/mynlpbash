#!/usr/bin/env bash
# code_mixing_detect.sh — Detect and analyze code-mixing in text
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "code_mixing_detect" "Detect code-mixing (Hindi-English, Tamil-English, etc.)" \
        "code_mixing_detect.sh -i text.txt [--tag-words]" \
        "-i, --input"      "Input text file" \
        "--tag-words"       "Tag each word as Indic/Latin/Other" \
        "--min-cmi"         "Min CMI to flag as mixed (default: 0.1)" \
        "-o, --output"     "Output file (default: stdout)" \
        "-h, --help"       "Show this help"
}

INPUT="" ; TAG_WORDS=0 ; MIN_CMI="0.1" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)    INPUT="$2"; shift 2 ;;
        --tag-words)   TAG_WORDS=1; shift ;;
        --min-cmi)     MIN_CMI="$2"; shift 2 ;;
        -o|--output)   OUTPUT="$2"; shift 2 ;;
        -h|--help)     show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    echo -e "${BOLD}═══ Code-Mixing Analysis ═══${NC}"
    echo ""
    
    awk -v tag_words="$TAG_WORDS" -v min_cmi="$MIN_CMI" '
    BEGIN { for (i=0; i<256; i++) ord[sprintf("%c",i)] = i }
    function word_lang(word,   n,arr,i,b,b2,b3,cp,lat,indic) {
        n = split(word, arr, "")
        lat = 0; indic = 0
        for (i=1; i<=n; i++) {
            b = ord[arr[i]]
            if (arr[i] ~ /[A-Za-z]/) lat++
            else if (b >= 0xE0 && i+2 <= n) {
                b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
                cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
                if (cp >= 0x0900 && cp <= 0x0D7F) indic++
            }
        }
        if (lat > indic) return "EN"
        else if (indic > 0) return "HI"
        else return "OT"
    }
    {
        nw = split($0, words, /[[:space:]]+/)
        en=0; hi=0; ot=0; tagged=""
        for (w=1; w<=nw; w++) {
            if (words[w] == "") continue
            lang = word_lang(words[w])
            if (lang == "EN") en++
            else if (lang == "HI") hi++
            else ot++
            if (tag_words) tagged = tagged sprintf("[%s|%s] ", lang, words[w])
        }
        
        total_w = en + hi
        if (total_w > 0) {
            max_lang = (en > hi) ? en : hi
            cmi = 1.0 - max_lang / total_w
        } else cmi = 0
        
        if (cmi >= min_cmi) {
            mixed_lines++
            total_cmi += cmi
            if (tag_words) printf "  CMI=%.2f  %s\n", cmi, tagged
        }
        
        total_en += en; total_hi += hi
        total_lines++
    }
    END {
        printf "\n  ── Summary ──\n"
        printf "  %-25s %d\n", "Total lines:", total_lines
        printf "  %-25s %d (%.1f%%)\n", "Mixed lines (CMI≥" min_cmi "):", mixed_lines+0, (mixed_lines+0)*100/total_lines
        printf "  %-25s %d\n", "Total Latin words:", total_en
        printf "  %-25s %d\n", "Total Indic words:", total_hi
        tw = total_en + total_hi
        if (tw > 0) {
            printf "  %-25s %.1f%%\n", "Latin word ratio:", total_en*100/tw
            printf "  %-25s %.1f%%\n", "Indic word ratio:", total_hi*100/tw
        }
        if (mixed_lines+0 > 0)
            printf "  %-25s %.3f\n", "Avg CMI (mixed):", total_cmi / mixed_lines
    }' "$INPUT"
    echo ""
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Code-mixing analysis → $OUTPUT"
else
    process
fi
