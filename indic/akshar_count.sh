#!/usr/bin/env bash
# akshar_count.sh — Count orthographic syllables (akshars) in Devanagari text
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "akshar_count" "Count orthographic syllables (akshars) in Brahmic text" \
        "akshar_count.sh -i hindi.txt [--per-line]" \
        "-i, --input"     "Input text file" \
        "--per-line"       "Show count per line" \
        "-h, --help"      "Show this help"
}

INPUT="" ; PER_LINE=0 ; USE_INDICNLP=0 ; LANG="hi"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)       INPUT="$2"; shift 2 ;;
        --per-line)       PER_LINE=1; shift ;;
        --use-indicnlp)   USE_INDICNLP=1; shift ;;
        -l|--lang)        LANG="$2"; shift 2 ;;
        -h|--help)        show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

if [[ $USE_INDICNLP -eq 1 ]]; then
    SCRIPT_DIR="$(dirname "$0")"
    ARGS=(-i "$INPUT" -l "$LANG" --count)
    exec bash "$SCRIPT_DIR/indicnlp_syllabify.sh" "${ARGS[@]}"
fi

echo -e "${BOLD}═══ Akshar (Syllable) Count ═══${NC}"
echo ""

awk -v per_line="$PER_LINE" '
BEGIN { for (i=0; i<256; i++) ord[sprintf("%c",i)] = i }
{
    akshars = 0; chars = 0
    n = split($0, arr, "")
    prev_type = ""
    
    for (i=1; i<=n; i++) {
        b = ord[arr[i]]
        if (b < 0xE0) continue
        if (i+2 > n) continue
        
        b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
        cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
        
        # Skip if not Devanagari
        if (cp < 0x0900 || cp > 0x097F) continue
        chars++
        
        # An akshar starts with:
        # - A vowel (independent) U+0904-0914
        # - A consonant U+0915-0939
        # Matras, halant, anusvara, visarga are continuations
        if (cp >= 0x0904 && cp <= 0x0914) {
            akshars++  # Independent vowel = new akshar
        } else if (cp >= 0x0915 && cp <= 0x0939) {
            if (prev_type != "halant") akshars++  # New consonant = new akshar (unless after halant = conjunct)
        }
        
        if (cp == 0x094D) prev_type = "halant"
        else prev_type = ""
    }
    
    total_akshars += akshars
    total_chars += chars
    lines++
    
    if (per_line) printf "  L%d: %d akshars (%d chars)\n", NR, akshars, chars
}
END {
    printf "\n  %-20s %d\n", "Lines:", lines
    printf "  %-20s %d\n", "Total akshars:", total_akshars
    printf "  %-20s %d\n", "Total script chars:", total_chars
    if (lines > 0) printf "  %-20s %.1f\n", "Avg akshars/line:", total_akshars/lines
    if (total_akshars > 0) printf "  %-20s %.2f\n", "Chars/akshar:", total_chars/total_akshars
}' "$INPUT"
echo ""
