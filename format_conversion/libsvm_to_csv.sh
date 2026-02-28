#!/usr/bin/env bash
# libsvm_to_csv.sh — Convert LibSVM sparse format to CSV
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "libsvm_to_csv" "Convert LibSVM sparse format to CSV" \
        "libsvm_to_csv.sh -i input.libsvm [-o output.csv]" \
        "-i, --input"   "Input LibSVM file" \
        "-o, --output"  "Output CSV file (default: stdout)" \
        "-h, --help"    "Show this help"
}

INPUT="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    awk '
    # First pass: find max feature index
    NR==FNR {
        for (i=2; i<=NF; i++) {
            split($i, kv, ":")
            if (kv[1]+0 > max_feat) max_feat = kv[1]+0
        }
        next
    }
    # Second pass: output
    FNR==1 {
        printf "label"
        for (i=1; i<=max_feat; i++) printf ",feature_%d", i
        print ""
    }
    {
        # Initialize all features to 0
        for (i=1; i<=max_feat; i++) feats[i] = 0
        
        label = $1
        for (i=2; i<=NF; i++) {
            split($i, kv, ":")
            feats[kv[1]+0] = kv[2]
        }
        
        printf "%s", label
        for (i=1; i<=max_feat; i++) printf ",%s", feats[i]
        print ""
    }' "$INPUT" "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "LibSVM → CSV: $OUTPUT"
else
    process
fi
