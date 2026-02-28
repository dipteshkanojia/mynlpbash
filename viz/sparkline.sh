#!/usr/bin/env bash
# sparkline.sh — Inline sparklines using Unicode block characters
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "sparkline" "Render inline sparklines from numeric data" \
        "sparkline.sh -i data.txt" \
        "-i, --input"     "Input file (one number per line)" \
        "-c, --column"    "Column index if CSV (default: 1)" \
        "--label"          "Label to prepend" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COL=1 ; LABEL="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COL="$2"; shift 2 ;;
        --label)        LABEL="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# Extract values
if [[ -n "$DELIM" ]] || head -1 "$INPUT" | grep -q '[,\t]'; then
    [[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")
    VALUES=$(awk -F"$DELIM" -v col="$COL" 'NR>1{v=$col; gsub(/^[ \t"]+|[ \t"]+$/, "", v); if(v+0==v) print v+0}' "$INPUT")
else
    VALUES=$(grep -v '^[[:space:]]*$' "$INPUT")
fi

[[ -n "$LABEL" ]] && printf "%s " "$LABEL"

echo "$VALUES" | awk '
BEGIN {
    # Unicode block elements: ▁▂▃▄▅▆▇█
    split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", blocks, " ")
}
{ vals[NR] = $1; if (NR==1) {mn=$1; mx=$1} if($1<mn)mn=$1; if($1>mx)mx=$1; n=NR }
END {
    range = mx - mn
    if (range == 0) range = 1
    spark = ""
    for (i=1; i<=n; i++) {
        level = int((vals[i] - mn) / range * 7) + 1
        if (level > 8) level = 8
        if (level < 1) level = 1
        spark = spark blocks[level]
    }
    printf "%s", spark
    printf "  (min: %.1f, max: %.1f, n: %d)\n", mn, mx, n
}'
