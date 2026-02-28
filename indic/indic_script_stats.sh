#!/usr/bin/env bash
# indic_script_stats.sh — Per-script breakdown of a text
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_script_stats" "Per-script character breakdown (Devanagari, Latin, digits, etc.)" \
        "indic_script_stats.sh -i text.txt [--per-line]" \
        "-i, --input"     "Input text file" \
        "--per-line"       "Show per-line script percentages" \
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

echo -e "${BOLD}═══ Script Statistics ═══${NC}"
echo ""

awk -v per_line="$PER_LINE" '
BEGIN { for (i=0; i<256; i++) ord[sprintf("%c",i)] = i }
{
    lat=0; dev=0; ben=0; tam=0; tel=0; kan=0; mal=0; guj=0; gur=0; odi=0
    dig=0; pnc=0; spc=0; oth=0; total=0
    
    n = split($0, arr, "")
    for (i=1; i<=n; i++) {
        c = arr[i]; b = ord[c]; total++
        if (c ~ /[A-Za-z]/) lat++
        else if (c ~ /[0-9]/) dig++
        else if (c ~ /[[:space:]]/) spc++
        else if (c ~ /[[:punct:]]/) pnc++
        else if (b >= 0xE0 && i+2 <= n) {
            b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
            cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
            if (cp >= 0x0900 && cp <= 0x097F) dev++
            else if (cp >= 0x0980 && cp <= 0x09FF) ben++
            else if (cp >= 0x0A00 && cp <= 0x0A7F) gur++
            else if (cp >= 0x0A80 && cp <= 0x0AFF) guj++
            else if (cp >= 0x0B00 && cp <= 0x0B7F) odi++
            else if (cp >= 0x0B80 && cp <= 0x0BFF) tam++
            else if (cp >= 0x0C00 && cp <= 0x0C7F) tel++
            else if (cp >= 0x0C80 && cp <= 0x0CFF) kan++
            else if (cp >= 0x0D00 && cp <= 0x0D7F) mal++
            else oth++
        } else oth++
    }
    
    g_lat += lat; g_dev += dev; g_ben += ben; g_tam += tam; g_tel += tel
    g_kan += kan; g_mal += mal; g_guj += guj; g_gur += gur; g_odi += odi
    g_dig += dig; g_pnc += pnc; g_spc += spc; g_oth += oth; g_total += total
    lines++
    
    # Code-mixing: count script chars only
    script_chars = lat + dev + ben + tam + tel + kan + mal + guj + gur + odi
    if (script_chars > 0) {
        max_s = lat
        if (dev > max_s) max_s = dev
        if (ben > max_s) max_s = ben
        cmi = (script_chars > 0) ? 1.0 - max_s / script_chars : 0
        total_cmi += cmi
    }
    
    if (per_line && total > 0) {
        printf "  L%d: ", NR
        ns = total - spc
        if (ns > 0) {
            if (lat > 0) printf "Lat:%d%% ", int(lat*100/ns)
            if (dev > 0) printf "Dev:%d%% ", int(dev*100/ns)
            if (ben > 0) printf "Ben:%d%% ", int(ben*100/ns)
            if (tam > 0) printf "Tam:%d%% ", int(tam*100/ns)
            if (tel > 0) printf "Tel:%d%% ", int(tel*100/ns)
            if (dig > 0) printf "Dig:%d%% ", int(dig*100/ns)
            if (cmi > 0) printf "[CMI:%.2f]", cmi
        }
        print ""
    }
}
END {
    ns = g_total - g_spc
    printf "\n  %-20s %7s %7s\n", "Script", "Chars", "%"
    printf "  %-20s %7s %7s\n", "──────", "─────", "───"
    if (g_dev > 0) printf "  %-20s %7d %6.1f%%\n", "Devanagari", g_dev, g_dev*100/ns
    if (g_lat > 0) printf "  %-20s %7d %6.1f%%\n", "Latin", g_lat, g_lat*100/ns
    if (g_ben > 0) printf "  %-20s %7d %6.1f%%\n", "Bengali", g_ben, g_ben*100/ns
    if (g_tam > 0) printf "  %-20s %7d %6.1f%%\n", "Tamil", g_tam, g_tam*100/ns
    if (g_tel > 0) printf "  %-20s %7d %6.1f%%\n", "Telugu", g_tel, g_tel*100/ns
    if (g_kan > 0) printf "  %-20s %7d %6.1f%%\n", "Kannada", g_kan, g_kan*100/ns
    if (g_mal > 0) printf "  %-20s %7d %6.1f%%\n", "Malayalam", g_mal, g_mal*100/ns
    if (g_guj > 0) printf "  %-20s %7d %6.1f%%\n", "Gujarati", g_guj, g_guj*100/ns
    if (g_gur > 0) printf "  %-20s %7d %6.1f%%\n", "Gurmukhi", g_gur, g_gur*100/ns
    if (g_odi > 0) printf "  %-20s %7d %6.1f%%\n", "Odia", g_odi, g_odi*100/ns
    if (g_dig > 0) printf "  %-20s %7d %6.1f%%\n", "Digits", g_dig, g_dig*100/ns
    if (g_pnc > 0) printf "  %-20s %7d %6.1f%%\n", "Punctuation", g_pnc, g_pnc*100/ns
    if (g_oth > 0) printf "  %-20s %7d %6.1f%%\n", "Other", g_oth, g_oth*100/ns
    printf "\n  %-20s %.3f\n", "Avg CMI:", total_cmi / lines
}' "$INPUT"
echo ""
