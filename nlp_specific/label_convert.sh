#!/usr/bin/env bash
# label_convert.sh — Convert between label formats
# Author: Diptesh
# Status: Original — foundational script
# label_convert.sh — Convert between label formats was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "label_convert" "Convert label formats (numeric↔text, remap)" \
        "label_convert.sh -i data.csv -c label --map 'positive=1,negative=0,neutral=2'" \
        "-i, --input"     "Input CSV/TSV file" \
        "-c, --column"    "Label column (name or index)" \
        "--map"            "Label mapping (old=new,old=new,...)" \
        "--map-file"       "File with mappings (old<TAB>new per line)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; MAP="" ; MAP_FILE="" ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        --map)          MAP="$2"; shift 2 ;;
        --map-file)     MAP_FILE="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$COLUMN" ]] && die "Column required (-c)"
[[ -z "$MAP" && -z "$MAP_FILE" ]] && die "Mapping required (--map or --map-file)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
    COL_IDX="$COLUMN"
else
    COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
    [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
fi

# Build mapping string for awk
if [[ -n "$MAP_FILE" ]]; then
    require_file "$MAP_FILE"
    MAP_STR=$(awk -F'\t' '{printf "%s=%s,", $1, $2}' "$MAP_FILE" | sed 's/,$//')
else
    MAP_STR="$MAP"
fi

process() {
    awk -F"$DELIM" -v OFS="$DELIM" -v col="$COL_IDX" -v mapstr="$MAP_STR" '
    BEGIN {
        n = split(mapstr, pairs, ",")
        for (i=1; i<=n; i++) {
            split(pairs[i], kv, "=")
            mapping[kv[1]] = kv[2]
        }
    }
    NR==1 { print; next }
    {
        val = $col
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        gsub(/^"|"$/, "", val)
        if (val in mapping) {
            $col = mapping[val]
            converted++
        } else {
            unmapped++
        }
        print
    }
    END {
        printf "Converted: %d, Unmapped: %d\n", converted+0, unmapped+0 > "/dev/stderr"
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Labels converted → $OUTPUT"
else
    process
fi
