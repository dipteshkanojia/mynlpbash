#!/usr/bin/env bash
# csv_split.sh — Split CSV/TSV into chunks or by column value
# Author: Diptesh
# Status: Original — foundational script
# csv_split.sh — Split CSV/TSV into chunks or by column value was part of the initial mynlpbash toolkit.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_split" "Split CSV/TSV into chunks or by column value" \
        "csv_split.sh -i input.csv [-n 1000 | -c label] [-p prefix]" \
        "-i, --input"     "Input CSV/TSV file" \
        "-n, --nrows"     "Split into chunks of N rows each" \
        "-c, --column"    "Split by unique values in this column" \
        "-p, --prefix"    "Output file prefix (default: split_)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; NROWS="" ; COLUMN="" ; PREFIX="split_" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -n|--nrows)     NROWS="$2"; shift 2 ;;
        -c|--column)    COLUMN="$2"; shift 2 ;;
        -p|--prefix)    PREFIX="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$NROWS" && -z "$COLUMN" ]] && die "Specify -n (chunk size) or -c (column to split by)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

HEADER=$(head -1 "$INPUT")

if [[ -n "$NROWS" ]]; then
    # Split by chunk size
    TOTAL=$(tail -n +2 "$INPUT" | wc -l | tr -d ' ')
    CHUNKS=$(( (TOTAL + NROWS - 1) / NROWS ))
    info "Splitting $TOTAL rows into chunks of $NROWS"
    chunk=0
    tail -n +2 "$INPUT" | while IFS= read -r line; do
        row=$(( row + 1 ))
        if (( (row - 1) % NROWS == 0 )); then
            chunk=$(( chunk + 1 ))
            outfile="${PREFIX}$(printf '%03d' $chunk).csv"
            echo "$HEADER" > "$outfile"
            info "Creating $outfile"
        fi
        echo "$line" >> "$outfile"
    done
    success "Created $CHUNKS chunks with prefix '${PREFIX}'"
elif [[ -n "$COLUMN" ]]; then
    # Split by column value
    if [[ "$COLUMN" =~ ^[0-9]+$ ]]; then
        COL_IDX="$COLUMN"
    else
        COL_IDX=$(find_column_index "$INPUT" "$COLUMN" "$DELIM")
        [[ -z "$COL_IDX" ]] && die "Column not found: $COLUMN"
    fi
    
    awk -F"$DELIM" -v col="$COL_IDX" -v prefix="$PREFIX" -v header="$HEADER" '
    NR==1 { next }
    {
        val = $col
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        gsub(/^"|"$/, "", val)
        gsub(/[^a-zA-Z0-9_-]/, "_", val)
        fname = prefix val ".csv"
        if (!(val in seen)) {
            print header > fname
            seen[val] = 1
        }
        print >> fname
    }
    END {
        for (v in seen) count++
        printf "Created %d files\n", count > "/dev/stderr"
    }' "$INPUT"
    success "Split by column '$COLUMN' with prefix '${PREFIX}'"
fi
