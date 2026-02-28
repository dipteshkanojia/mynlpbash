#!/usr/bin/env bash
# unicode_stats.sh — Unicode character analysis per line and corpus
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Unicode support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "unicode_stats" "Unicode character category and script block analysis" \
        "unicode_stats.sh -i text.txt" \
        "-i, --input"     "Input text file" \
        "--per-line"       "Show per-line breakdown" \
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

echo -e "${BOLD}═══ Unicode Statistics ═══${NC}"
echo ""

awk '
function classify_char(c) {
    # Use character code ranges to classify
    n = 0
    for (i=1; i<=length(c); i++) {
        n = n * 256 + ord[substr(c,i,1)]
    }
    return n
}
BEGIN {
    for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
}
{
    chars = 0; letters = 0; digits = 0; punct = 0; spaces = 0; other = 0
    latin = 0; devnag = 0; bengali = 0; tamil = 0; telugu = 0; cjk = 0; arab = 0
    
    n = split($0, arr, "")
    for (i=1; i<=n; i++) {
        c = arr[i]
        chars++
        
        if (c ~ /[A-Za-z]/) { letters++; latin++ }
        else if (c ~ /[0-9]/) digits++
        else if (c ~ /[[:punct:]]/) punct++
        else if (c ~ /[[:space:]]/) spaces++
        else {
            # Multi-byte: check first byte
            b = ord[c]
            if (b >= 0xE0) {
                # 3-byte UTF-8: check script ranges
                if (i+2 <= n) {
                    b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
                    cp = (b - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80)
                    if (cp >= 0x0900 && cp <= 0x097F) { devnag++; letters++ }
                    else if (cp >= 0x0980 && cp <= 0x09FF) { bengali++; letters++ }
                    else if (cp >= 0x0A00 && cp <= 0x0A7F) { letters++ } # Gurmukhi
                    else if (cp >= 0x0A80 && cp <= 0x0AFF) { letters++ } # Gujarati
                    else if (cp >= 0x0B00 && cp <= 0x0B7F) { letters++ } # Odia
                    else if (cp >= 0x0B80 && cp <= 0x0BFF) { tamil++; letters++ }
                    else if (cp >= 0x0C00 && cp <= 0x0C7F) { telugu++; letters++ }
                    else if (cp >= 0x0C80 && cp <= 0x0CFF) { letters++ } # Kannada
                    else if (cp >= 0x0D00 && cp <= 0x0D7F) { letters++ } # Malayalam
                    else if (cp >= 0x0600 && cp <= 0x06FF) { arab++; letters++ }
                    else if (cp >= 0x4E00 && cp <= 0x9FFF) { cjk++; letters++ }
                    else other++
                }
            } else if (b >= 0xC0) {
                # 2-byte UTF-8
                if (i+1 <= n) {
                    b2 = ord[arr[i+1]]
                    cp = (b - 0xC0) * 64 + (b2 - 0x80)
                    if (cp >= 0x00C0 && cp <= 0x024F) { latin++; letters++ }
                    else other++
                }
            } else other++
        }
    }
    
    total_chars += chars
    total_letters += letters; total_digits += digits
    total_punct += punct; total_spaces += spaces; total_other += other
    total_latin += latin; total_devnag += devnag
    total_bengali += bengali; total_tamil += tamil
    total_telugu += telugu; total_cjk += cjk; total_arab += arab
    lines++
}
END {
    printf "  %-25s %d\n", "Lines:", lines
    printf "  %-25s %d\n", "Total characters:", total_chars
    print ""
    print "  Character Categories:"
    printf "    %-20s %6d  (%5.1f%%)\n", "Letters:", total_letters, total_letters*100/total_chars
    printf "    %-20s %6d  (%5.1f%%)\n", "Digits:", total_digits, total_digits*100/total_chars
    printf "    %-20s %6d  (%5.1f%%)\n", "Punctuation:", total_punct, total_punct*100/total_chars
    printf "    %-20s %6d  (%5.1f%%)\n", "Whitespace:", total_spaces, total_spaces*100/total_chars
    printf "    %-20s %6d  (%5.1f%%)\n", "Other:", total_other, total_other*100/total_chars
    print ""
    print "  Script Blocks:"
    if (total_latin > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Latin:", total_latin, total_latin*100/total_chars
    if (total_devnag > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Devanagari:", total_devnag, total_devnag*100/total_chars
    if (total_bengali > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Bengali:", total_bengali, total_bengali*100/total_chars
    if (total_tamil > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Tamil:", total_tamil, total_tamil*100/total_chars
    if (total_telugu > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Telugu:", total_telugu, total_telugu*100/total_chars
    if (total_arab > 0) printf "    %-20s %6d  (%5.1f%%)\n", "Arabic:", total_arab, total_arab*100/total_chars
    if (total_cjk > 0) printf "    %-20s %6d  (%5.1f%%)\n", "CJK:", total_cjk, total_cjk*100/total_chars
}' "$INPUT"
echo ""
