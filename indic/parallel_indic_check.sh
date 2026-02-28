#!/usr/bin/env bash
# parallel_indic_check.sh — Indic-specific parallel corpus checks
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "parallel_indic_check" "Indic-specific parallel corpus checks (script leakage, untranslated)" \
        "parallel_indic_check.sh -s source_en.txt -t target_hi.txt" \
        "-s, --source"    "Source (English) file" \
        "-t, --target"    "Target (Indic) file" \
        "--target-script"  "Expected script: devanagari, bengali, tamil (default: devanagari)" \
        "-h, --help"      "Show this help"
}

SRC="" ; TGT="" ; TARGET_SCRIPT="devanagari"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)        SRC="$2"; shift 2 ;;
        -t|--target)        TGT="$2"; shift 2 ;;
        --target-script)    TARGET_SCRIPT="$2"; shift 2 ;;
        -h|--help)          show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SRC" ]] && die "Source file required (-s)"
[[ -z "$TGT" ]] && die "Target file required (-t)"
require_file "$SRC"; require_file "$TGT"

echo -e "${BOLD}═══ Indic Parallel Corpus Check ═══${NC}"
echo ""

paste "$SRC" "$TGT" | awk -F'\t' -v tgt_script="$TARGET_SCRIPT" '
BEGIN { for (i=0; i<256; i++) ord[sprintf("%c",i)] = i }
function count_latin(text,   n,arr,i,cnt) {
    n = split(text, arr, ""); cnt = 0
    for (i=1; i<=n; i++) if (arr[i] ~ /[A-Za-z]/) cnt++
    return cnt
}
function count_indic(text,   n,arr,i,b,b2,b3,cp,cnt) {
    n = split(text, arr, ""); cnt = 0
    for (i=1; i<=n; i++) {
        b = ord[arr[i]]
        if (b >= 0xE0 && i+2 <= n) {
            b2 = ord[arr[i+1]]; b3 = ord[arr[i+2]]
            cp = (b-0xE0)*4096 + (b2-0x80)*64 + (b3-0x80)
            if (cp >= 0x0900 && cp <= 0x0D7F) cnt++
        }
    }
    return cnt
}
{
    src = $1; tgt = $2
    src_lat = count_latin(src)
    tgt_lat = count_latin(tgt)
    tgt_indic = count_indic(tgt)
    tgt_total = tgt_lat + tgt_indic
    
    total++
    
    # Check: target has too much Latin (potential untranslated)
    if (tgt_total > 0 && tgt_lat > tgt_indic) {
        high_latin++
        if (high_latin <= 5) printf "  ⚠ L%d: Target mostly Latin: %s\n", NR, substr(tgt, 1, 60)
    }
    
    # Check: target has no Indic chars at all
    if (tgt_indic == 0 && length(tgt) > 5) {
        no_indic++
        if (no_indic <= 5) printf "  ✗ L%d: No Indic script in target: %s\n", NR, substr(tgt, 1, 60)
    }
    
    # Check: source and target are identical (copy error)
    if (src == tgt) {
        identical++
    }
    
    # Check: target is empty
    if (tgt ~ /^[[:space:]]*$/) empty_tgt++
    if (src ~ /^[[:space:]]*$/) empty_src++
}
END {
    printf "\n  ── Summary ──\n"
    printf "  %-30s %d\n", "Total pairs:", total
    printf "  %-30s %d\n", "Empty source:", empty_src+0
    printf "  %-30s %d\n", "Empty target:", empty_tgt+0
    printf "  %-30s %d (%.1f%%)\n", "Identical src/tgt:", identical+0, (identical+0)*100/total
    printf "  %-30s %d (%.1f%%)\n", "Target mostly Latin:", high_latin+0, (high_latin+0)*100/total
    printf "  %-30s %d (%.1f%%)\n", "Target no Indic chars:", no_indic+0, (no_indic+0)*100/total
    print ""
    if (identical+0 == 0 && high_latin+0 == 0 && no_indic+0 == 0)
        printf "  ✓ No issues detected\n"
    else
        printf "  ✗ %d potential issue(s) found\n", identical+0 + high_latin+0 + no_indic+0
}' 
echo ""
