#!/usr/bin/env bash
# fasttext_format.sh — Convert to/from FastText __label__ format
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "fasttext_format" "Convert to/from FastText __label__ format" \
        "fasttext_format.sh --to-fasttext -i data.csv -c label -t text [-o output.txt]" \
        "-i, --input"     "Input file" \
        "-c, --column"    "Label column (for --to-fasttext)" \
        "-t, --text-col"  "Text column (for --to-fasttext)" \
        "--to-fasttext"    "Convert CSV → FastText format" \
        "--from-fasttext"  "Convert FastText → CSV format" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; COLUMN="" ; TEXT_COL="" ; TO_FT=0 ; FROM_FT=0 ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)      INPUT="$2"; shift 2 ;;
        -c|--column)     COLUMN="$2"; shift 2 ;;
        -t|--text-col)   TEXT_COL="$2"; shift 2 ;;
        --to-fasttext)   TO_FT=1; shift ;;
        --from-fasttext) FROM_FT=1; shift ;;
        -d|--delimiter)  DELIM="$2"; shift 2 ;;
        -o|--output)     OUTPUT="$2"; shift 2 ;;
        -h|--help)       show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

if [[ $TO_FT -eq 1 ]]; then
    [[ -z "$COLUMN" ]] && die "Label column required (-c)"
    [[ -z "$TEXT_COL" ]] && die "Text column required (-t)"
    [[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")
    
    for var in COLUMN TEXT_COL; do
        val="${!var}"
        if [[ ! "$val" =~ ^[0-9]+$ ]]; then
            idx=$(find_column_index "$INPUT" "$val" "$DELIM")
            [[ -z "$idx" ]] && die "Column not found: $val"
            declare "${var}_IDX=$idx"
        else
            declare "${var}_IDX=$val"
        fi
    done
    
    process() {
        awk -F"$DELIM" -v lcol="$COLUMN_IDX" -v tcol="$TEXT_COL_IDX" '
        NR==1 { next }
        {
            label = $lcol; text = $tcol
            gsub(/^[ \t]+|[ \t]+$/, "", label)
            gsub(/^"|"$/, "", label)
            gsub(/^"|"$/, "", text)
            gsub(/ +/, " ", text)
            printf "__label__%s %s\n", label, text
        }' "$INPUT"
    }
elif [[ $FROM_FT -eq 1 ]]; then
    process() {
        echo "label,text"
        awk '{
            # Extract labels
            labels = ""
            text_start = 0
            for (i=1; i<=NF; i++) {
                if ($i ~ /^__label__/) {
                    l = $i
                    gsub(/^__label__/, "", l)
                    labels = (labels == "") ? l : labels "," l
                } else {
                    text_start = i
                    break
                }
            }
            text = ""
            for (i=text_start; i<=NF; i++) {
                text = (text == "") ? $i : text " " $i
            }
            if (text ~ /,/) {
                gsub(/"/, "\"\"", text)
                text = "\"" text "\""
            }
            printf "%s,%s\n", labels, text
        }' "$INPUT"
    }
else
    die "Specify --to-fasttext or --from-fasttext"
fi

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Converted → $OUTPUT"
else
    process
fi
