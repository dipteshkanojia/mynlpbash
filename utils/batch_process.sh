#!/usr/bin/env bash
# batch_process.sh — Apply any script to multiple files with progress
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
# Added advanced analytics, visualizations, and complex processing capabilities.
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "batch_process" "Apply any mynlpbash script to multiple files" \
        "batch_process.sh --script 'corpus_analysis/word_freq.sh' --args '-n 10 --lower' -i *.txt" \
        "--script"       "Script to run (relative to mynlpbash root)" \
        "--args"          "Arguments to pass to the script (quoted)" \
        "-i, --input"    "Input files (glob or list)" \
        "--output-dir"    "Output directory (default: current dir)" \
        "--suffix"        "Output file suffix (default: .out)" \
        "-h, --help"     "Show this help"
}

SCRIPT="" ; ARGS="" ; FILES=() ; OUTPUT_DIR="." ; SUFFIX=".out"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --script)     SCRIPT="$2"; shift 2 ;;
        --args)       ARGS="$2"; shift 2 ;;
        -i|--input)   shift
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                FILES+=("$1"); shift
            done ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --suffix)     SUFFIX="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$SCRIPT" ]] && die "Script required (--script)"
[[ ${#FILES[@]} -eq 0 ]] && die "Input files required (-i)"

SCRIPT_DIR="$(dirname "$0")/.."
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT"
[[ -f "$SCRIPT_PATH" ]] || die "Script not found: $SCRIPT_PATH"

mkdir -p "$OUTPUT_DIR"

TOTAL=${#FILES[@]}
CURRENT=0
FAILED=0

echo -e "${BOLD}═══ Batch Processing ═══${NC}"
echo ""
info "Script: $SCRIPT"
info "Files: $TOTAL"
info "Args: $ARGS"
echo ""

for f in "${FILES[@]}"; do
    CURRENT=$((CURRENT + 1))
    BASENAME=$(basename "$f")
    OUTFILE="$OUTPUT_DIR/${BASENAME}${SUFFIX}"
    
    show_progress "$CURRENT" "$TOTAL" "Processing"
    
    if bash "$SCRIPT_PATH" -i "$f" $ARGS > "$OUTFILE" 2>/dev/null; then
        : # success
    else
        warn "Failed: $f"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
SUCCEEDED=$(( TOTAL - FAILED ))
success "Processed $SUCCEEDED/$TOTAL files ($FAILED failures)"
