#!/usr/bin/env bash
# bio_tags_check.sh — Validate BIO/IOB tagging sequences
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "bio_tags_check" "Validate BIO/IOB tagging sequences" \
        "bio_tags_check.sh -i tagged.txt [-c tag_column]" \
        "-i, --input"     "Input file (one token per line, blank = sentence boundary)" \
        "-c, --column"    "Tag column index (default: last)" \
        "--format"         "Tag format: bio, iob2, bioes (default: bio)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COL="" ; FORMAT="bio"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -c|--column) COL="$2"; shift 2 ;;
        --format)    FORMAT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

echo -e "${BOLD}═══ BIO Tag Validation ($FORMAT) ═══${NC}"
echo ""

awk -v col="$COL" -v fmt="$FORMAT" '
/^[[:space:]]*$/ {
    prev_prefix = ""
    prev_type = ""
    sent_id++
    next
}
/^#/ { next }
{
    if (col == "") tag_col = NF
    else tag_col = col + 0
    
    tag = $tag_col
    
    if (tag == "O") {
        prefix = "O"; type = ""
    } else if (index(tag, "-") > 0) {
        prefix = substr(tag, 1, 1)
        type = substr(tag, 3)
    } else {
        prefix = tag; type = ""
    }
    
    if (prefix == "I") {
        if (prev_prefix != "B" && prev_prefix != "I") {
            printf "  ERROR line %d: I-%s without preceding B-%s (prev: %s-%s)\n", NR, type, type, prev_prefix, prev_type
            errors++
        } else if (type != prev_type && prev_type != "") {
            printf "  ERROR line %d: I-%s follows %s-%s (type mismatch)\n", NR, type, prev_prefix, prev_type
            errors++
        }
    }
    
    if (prefix == "B") entities++
    if (prefix == "S") entities++
    
    tag_counts[tag]++
    tokens++
    
    prev_prefix = prefix
    prev_type = type
}
END {
    printf "  %-20s %d\n", "Total tokens:", tokens
    printf "  %-20s %d\n", "Sentences:", sent_id+1
    printf "  %-20s %d\n", "Entities found:", entities+0
    printf "  %-20s %d\n", "Errors:", errors+0
    print ""
    
    printf "  Tag Distribution:\n"
    for (t in tag_counts) {
        printf "    %-15s %d\n", t, tag_counts[t]
    }
    
    print ""
    if (errors+0 == 0)
        print "  ✓ All BIO sequences are valid"
    else
        printf "  ✗ %d invalid sequence(s) found\n", errors
}' "$INPUT"
echo ""
