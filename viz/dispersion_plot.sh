#!/usr/bin/env bash
# dispersion_plot.sh — Lexical dispersion plot for corpora
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "dispersion_plot" "Generate a terminal-based lexical dispersion plot (NLTK style)" \
        "dispersion_plot.sh -i corpus.txt -w 'word1,word2,word3'" \
        "-i, --input"    "Input text file" \
        "-w, --words"    "Comma-separated list of words to plot" \
        "--lower"        "Lowercase text before matching (recommended)" \
        "--width"        "Width of the plot in characters (default: 60)" \
        "-h, --help"     "Show this help"
}

INPUT=""
WORDS=""
WIDTH=60
LOWER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) INPUT="$2"; shift 2 ;;
        -w|--words) WORDS="$2"; shift 2 ;;
        --width)    WIDTH="$2"; shift 2 ;;
        --lower)    LOWER=true; shift 1 ;;
        -h|--help)  show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
[[ -z "$WORDS" ]] && die "Words list required (-w)"
require_file "$INPUT"

if ! [[ "$WIDTH" =~ ^[0-9]+$ ]] || [ "$WIDTH" -lt 10 ]; then
    die "Width must be an integer >= 10"
fi

echo -e "${BOLD}═══ Lexical Dispersion Plot ═══${NC}"

{
    if $LOWER; then
        tr '[:upper:]' '[:lower:]' < "$INPUT" | tr -s '[:space:][:punct:]' '\n'
    else
        tr -s '[:space:][:punct:]' '\n' < "$INPUT"
    fi
} | awk -v WORDS="$WORDS" -v WIDTH="$WIDTH" -v LOWER="$LOWER" '
BEGIN {
    # Parse words
    split(WORDS, w_arr, ",")
    num_targets = 0
    for (i in w_arr) {
        w = w_arr[i]
        # Trim spaces
        sub(/^ +/, "", w)
        sub(/ +$/, "", w)
        if (LOWER == "true") w = tolower(w)
        if (length(w) > 0) {
            targets[++num_targets] = w
            target_set[w] = num_targets
        }
    }
    
    if (num_targets == 0) {
        print "No valid words provided."
        exit 1
    }
    
    total_tokens = 0
}
{
    word = $1
    if (length(word) == 0) next
    total_tokens++
    
    if (word in target_set) {
        idx = target_set[word]
        occurrences[idx, ++counts[idx]] = total_tokens
    }
}
END {
    if (total_tokens == 0) {
        print "  No tokens found in file."
        exit
    }
    
    printf "  Corpus size: %s tokens\n", total_tokens
    printf "  Plot width:  %s bins\n\n", WIDTH
    
    # Calculate bin size
    # If total_tokens < WIDTH, bin size is 1 token per bin
    bin_size = total_tokens / WIDTH
    
    # Sort targets to print them in the order they were provided
    longest_word_len = 0
    for (i = 1; i <= num_targets; i++) {
        if (length(targets[i]) > longest_word_len) {
            longest_word_len = length(targets[i])
        }
    }
    
    # Plot header
    printf "  %*s | ", longest_word_len, "Word"
    # Print an axis line
    for (b = 0; b < WIDTH; b++) {
        if (b == 0) printf "0"
        else if (b == WIDTH - 1) printf "N"
        else if (b == int(WIDTH / 2)) printf "|"
        else printf " "
    }
    printf "\n"
    
    printf "  %*s | ", longest_word_len, ""
    for (b = 0; b < WIDTH; b++) printf "-"
    printf "\n"
    
    # Process each target word
    for (i = 1; i <= num_targets; i++) {
        w = targets[i]
        cnt = counts[i]
        
        # Build array of bins for this word
        for (b = 0; b < WIDTH; b++) bin_hits[b] = 0
        
        for (c = 1; c <= cnt; c++) {
            pos = occurrences[i, c]
            bin = int((pos - 1) / bin_size)
            if (bin >= WIDTH) bin = WIDTH - 1
            if (bin < 0) bin = 0
            bin_hits[bin] = 1
        }
        
        printf "  %*s | ", longest_word_len, w
        for (b = 0; b < WIDTH; b++) {
            if (bin_hits[b] == 1) printf "│"
            else printf " "
        }
        printf " (%d hits)\n", (cnt+0)
    }
}
' || true

exit 0
