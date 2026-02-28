#!/usr/bin/env bash
# indic_char_freq.sh — Indic character frequency analysis
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_char_freq" "Indic character frequency (consonants, vowels, matras, virama)" \
        "indic_char_freq.sh -i hindi.txt [-n 20]" \
        "-i, --input"     "Input text file" \
        "-n, --top"       "Show top N (default: all)" \
        "--script"         "Script to focus on: devanagari, bengali, tamil (default: devanagari)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; TOP="" ; SCRIPT="devanagari"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -n|--top)    TOP="$2"; shift 2 ;;
        --script)    SCRIPT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

echo -e "${BOLD}═══ Indic Character Frequency ($SCRIPT) ═══${NC}"
echo ""

awk -v script="$SCRIPT" '
BEGIN {
    for (i=0; i<256; i++) ord[sprintf("%c",i)] = i
    
    # Devanagari ranges
    if (script == "devanagari") {
        # Vowels: U+0904-U+0914
        # Consonants: U+0915-U+0939
        # Matras: U+093E-U+094C
        # Virama: U+094D
        # Anusvara: U+0902, Visarga: U+0903, Chandrabindu: U+0901
        # Nukta: U+093C
        # Digits: U+0966-U+096F
    }
}
{
    n = split($0, arr, "")
    for (i=1; i<=n; i++) {
        c = arr[i]; b = ord[c]
        if (b >= 0xE0 && i+2 <= n) {
            b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
            cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
            
            if (script == "devanagari" && cp >= 0x0900 && cp <= 0x097F) {
                # Reconstruct the full character for display
                fullchar = arr[i] arr[i+1] arr[i+2]
                freq[fullchar]++
                total++
                
                if (cp == 0x0901) type[fullchar] = "Chandrabindu"
                else if (cp == 0x0902) type[fullchar] = "Anusvara"
                else if (cp == 0x0903) type[fullchar] = "Visarga"
                else if (cp >= 0x0904 && cp <= 0x0914) type[fullchar] = "Vowel"
                else if (cp >= 0x0915 && cp <= 0x0939) type[fullchar] = "Consonant"
                else if (cp == 0x093C) type[fullchar] = "Nukta"
                else if (cp >= 0x093E && cp <= 0x094C) type[fullchar] = "Matra"
                else if (cp == 0x094D) type[fullchar] = "Halant"
                else if (cp >= 0x0958 && cp <= 0x095F) type[fullchar] = "Consonant+"
                else if (cp >= 0x0966 && cp <= 0x096F) type[fullchar] = "Digit"
                else type[fullchar] = "Other"
            } else if (script == "bengali" && cp >= 0x0980 && cp <= 0x09FF) {
                fullchar = arr[i] arr[i+1] arr[i+2]
                freq[fullchar]++; total++; type[fullchar] = "Bengali"
            } else if (script == "tamil" && cp >= 0x0B80 && cp <= 0x0BFF) {
                fullchar = arr[i] arr[i+1] arr[i+2]
                freq[fullchar]++; total++; type[fullchar] = "Tamil"
            }
        }
    }
}
END {
    # Summary by type
    for (c in freq) type_count[type[c]] += freq[c]
    
    printf "  %-12s %6s %7s\n", "Category", "Count", "%"
    printf "  %-12s %6s %7s\n", "────────", "─────", "───"
    for (t in type_count) {
        printf "  %-12s %6d %6.1f%%\n", t, type_count[t], type_count[t]*100/total
    }
    printf "  %-12s %6d\n", "Total", total
    
    print "\n  Top Characters:"
    printf "  %-5s %6s %10s %7s\n", "Char", "Count", "Type", "%"
    printf "  %-5s %6s %10s %7s\n", "────", "─────", "────", "───"
    
    # Sort by frequency (manual)
    n_items = 0
    for (c in freq) { n_items++; items[n_items] = c; counts[n_items] = freq[c] }
    for (i=2; i<=n_items; i++) {
        kc = counts[i]; ki = items[i]; j = i-1
        while (j>0 && counts[j] < kc) { counts[j+1] = counts[j]; items[j+1] = items[j]; j-- }
        counts[j+1] = kc; items[j+1] = ki
    }
    for (i=1; i<=n_items; i++) {
        printf "  %-5s %6d %10s %6.1f%%\n", items[i], counts[i], type[items[i]], counts[i]*100/total
    }
}' "$INPUT"
echo ""
