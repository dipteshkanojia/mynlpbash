#!/usr/bin/env bash
# heatmap.sh — Terminal heatmap using Unicode shading and ANSI colors
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "heatmap" "Render a matrix as a terminal heatmap" \
        "heatmap.sh -i matrix.csv [-d ',']" \
        "-i, --input"     "Input CSV/TSV matrix file" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "--no-header"      "No header row" \
        "--no-rownames"    "No row name column" \
        "-h, --help"      "Show this help"
}

INPUT="" ; DELIM="" ; NO_HEADER=0 ; NO_ROWNAMES=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        --no-header)    NO_HEADER=1; shift ;;
        --no-rownames)  NO_ROWNAMES=1; shift ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

echo -e "${BOLD}═══ Heatmap ═══${NC}"
echo ""

awk -F"$DELIM" -v no_header="$NO_HEADER" -v no_rownames="$NO_ROWNAMES" '
NR==1 && !no_header {
    start = no_rownames ? 1 : 2
    printf "  %12s", ""
    for (i=start; i<=NF; i++) {
        h = $i; gsub(/^[ \t"]+|[ \t"]+$/, "", h)
        printf " %8s", substr(h, 1, 8)
    }
    print ""
    next
}
{
    start = no_rownames ? 1 : 2
    # First pass: find min/max for this row
    for (i=start; i<=NF; i++) {
        v = $i + 0
        vals[NR][i] = v
        if (NR==1+(!no_header) && i==start) { gmin=v; gmax=v }
        if (v < gmin) gmin = v
        if (v > gmax) gmax = v
    }
    rows[NR] = $0
    nrows++
    ncols = NF
}
END {
    # Shading characters from light to dark
    shades[0] = "  "; shades[1] = "░░"; shades[2] = "▒▒"; shades[3] = "▓▓"; shades[4] = "██"
    
    range = gmax - gmin
    if (range == 0) range = 1
    
    for (r=1; r<=nrows; r++) {
        row_nr = r + (!no_header)
        split(rows[row_nr], fields, FS)
        if (!no_rownames) printf "  %12s", substr(fields[1], 1, 12)
        else printf "  %12s", "row" r
        
        start = no_rownames ? 1 : 2
        for (i=start; i<=ncols; i++) {
            v = fields[i] + 0
            level = int((v - gmin) / range * 4)
            if (level > 4) level = 4
            if (level < 0) level = 0
            # Color by intensity: blue(low) → green → yellow → red(high)
            if (level <= 1) color = "\033[34m"
            else if (level == 2) color = "\033[32m"
            else if (level == 3) color = "\033[33m"
            else color = "\033[31m"
            printf " %s%6s\033[0m", color, sprintf("%d%s", v, shades[level])
        }
        print ""
    }
    print ""
    printf "  Scale: min=%d max=%d  ", gmin, gmax
    printf "\033[34m░░\033[0m low  \033[32m▒▒\033[0m  \033[33m▓▓\033[0m  \033[31m██\033[0m high\n"
}'  "$INPUT"
echo ""
