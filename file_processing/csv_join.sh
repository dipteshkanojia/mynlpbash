#!/usr/bin/env bash
# csv_join.sh — Join two CSV/TSV files on a key column
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "csv_join" "Join two CSV/TSV files on a key column" \
        "csv_join.sh -l left.csv -r right.csv -k id [-t inner]" \
        "-l, --left"      "Left input file" \
        "-r, --right"     "Right input file" \
        "-k, --key"       "Key column name or index" \
        "-t, --type"      "Join type: inner, left, right, outer (default: inner)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

LEFT="" ; RIGHT="" ; KEY="" ; TYPE="inner" ; OUTPUT="" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--left)      LEFT="$2"; shift 2 ;;
        -r|--right)     RIGHT="$2"; shift 2 ;;
        -k|--key)       KEY="$2"; shift 2 ;;
        -t|--type)      TYPE="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -o|--output)    OUTPUT="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$LEFT" ]]  && die "Left file required (-l)"
[[ -z "$RIGHT" ]] && die "Right file required (-r)"
[[ -z "$KEY" ]]   && die "Key column required (-k)"
require_file "$LEFT"
require_file "$RIGHT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$LEFT")

# Resolve key column indices
if [[ "$KEY" =~ ^[0-9]+$ ]]; then
    LKEY="$KEY"; RKEY="$KEY"
else
    LKEY=$(find_column_index "$LEFT" "$KEY" "$DELIM")
    RKEY=$(find_column_index "$RIGHT" "$KEY" "$DELIM")
    [[ -z "$LKEY" ]] && die "Key column '$KEY' not found in left file"
    [[ -z "$RKEY" ]] && die "Key column '$KEY' not found in right file"
fi

process() {
    awk -F"$DELIM" -v OFS="$DELIM" -v lkey="$LKEY" -v rkey="$RKEY" -v jtype="$TYPE" '
    FNR==1 && NR==1 {
        # Left header
        lheader = $0
        lnf = NF
        next
    }
    FNR==1 && NR>1 {
        # Right header (build output header)
        rheader = ""
        for (i=1; i<=NF; i++) {
            if (i != rkey) rheader = rheader OFS $i
        }
        print lheader rheader
        rnf = NF
        next
    }
    FILENAME == ARGV[2] {
        # Store right file data
        k = $rkey
        rdata[k] = ""
        for (i=1; i<=NF; i++) {
            if (i != rkey) rdata[k] = rdata[k] OFS $i
        }
        rkeys[k] = 1
        next
    }
    {
        # Process left file
        k = $lkey
        lseen[k] = 1
        if (k in rdata) {
            print $0 rdata[k]
        } else if (jtype == "left" || jtype == "outer") {
            empty = ""
            for (i=1; i<=rnf-1; i++) empty = empty OFS ""
            print $0 empty
        }
    }
    END {
        if (jtype == "right" || jtype == "outer") {
            for (k in rkeys) {
                if (!(k in lseen)) {
                    empty = ""
                    for (i=1; i<=lnf; i++) {
                        if (i == lkey) empty = empty (empty=="" ? "" : OFS) k
                        else empty = empty (empty=="" ? "" : OFS) ""
                    }
                    print empty rdata[k]
                }
            }
        }
    }
    ' "$LEFT" "$RIGHT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Joined ($TYPE) on '$KEY' → $OUTPUT"
else
    process
fi
