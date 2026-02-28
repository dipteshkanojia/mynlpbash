#!/usr/bin/env bash
# lang_detect.sh — Simple n-gram-based language detection
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 NLP utility
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "lang_detect" "N-gram-based language detection (English, Hindi, French, etc.)" \
        "lang_detect.sh -i text.txt [--per-line]" \
        "-i, --input"     "Input text file" \
        "--per-line"       "Detect language per line" \
        "-h, --help"      "Show this help"
}

INPUT="" ; PER_LINE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        --per-line)  PER_LINE=1; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

echo -e "${BOLD}═══ Language Detection ═══${NC}"
echo ""

awk -v per_line="$PER_LINE" '
BEGIN {
    for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
    
    # Common word signatures for detection
    split("the and is to of in that it was for on are with", en_words, " ")
    for (w in en_words) en_sig[en_words[w]] = 1
    
    split("le la les de des un une et est en que qui du au", fr_words, " ")
    for (w in fr_words) fr_sig[fr_words[w]] = 1
    
    split("der die das und ist ein eine von mit dem den", de_words, " ")
    for (w in de_words) de_sig[de_words[w]] = 1
    
    split("el la los las de en que es un una por con del", es_words, " ")
    for (w in es_words) es_sig[es_words[w]] = 1
}
function detect(text,   nw,words,w,lw,en,fr,de,es,lat,dev,ben,tam,tel, best,best_score) {
    nw = split(tolower(text), words, /[[:space:]]+/)
    en=0; fr=0; de=0; es=0; lat=0; dev=0; ben=0; tam=0; tel=0
    
    for (w=1; w<=nw; w++) {
        lw = words[w]
        if (lw in en_sig) en++
        if (lw in fr_sig) fr++
        if (lw in de_sig) de++
        if (lw in es_sig) es++
    }
    
    # Check script via first bytes
    n = split(text, arr, "")
    for (i=1; i<=n; i++) {
        b = ord[arr[i]]
        if (arr[i] ~ /[A-Za-z]/) lat++
        else if (b >= 0xE0 && i+2 <= n) {
            b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
            cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
            if (cp >= 0x0900 && cp <= 0x097F) dev++
            else if (cp >= 0x0980 && cp <= 0x09FF) ben++
            else if (cp >= 0x0B80 && cp <= 0x0BFF) tam++
            else if (cp >= 0x0C00 && cp <= 0x0C7F) tel++
        }
    }
    
    # Script-based detection takes priority for non-Latin
    if (dev > lat) return "Hindi"
    if (ben > lat) return "Bengali"
    if (tam > lat) return "Tamil"
    if (tel > lat) return "Telugu"
    
    # Latin-based: use word signatures
    best = "English"; best_score = en
    if (fr > best_score) { best = "French"; best_score = fr }
    if (de > best_score) { best = "German"; best_score = de }
    if (es > best_score) { best = "Spanish"; best_score = es }
    
    return best
}
{
    lang = detect($0)
    lang_count[lang]++
    lines++
    if (per_line) printf "  %-10s  %s\n", lang, substr($0, 1, 70)
}
END {
    printf "\n  ── Language Distribution ──\n"
    for (l in lang_count) {
        printf "  %-15s %5d lines (%5.1f%%)\n", l, lang_count[l], lang_count[l]*100/lines
    }
}' "$INPUT"
echo ""
