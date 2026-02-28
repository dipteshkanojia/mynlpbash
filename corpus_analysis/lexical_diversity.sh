#!/usr/bin/env bash
# lexical_diversity.sh — Calculate MATTR, MSTTR, and standard TTR
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "lexical_diversity" "Calculate TTR, MATTR (Moving-Average TTR), and MSTTR (Mean Segmental TTR)" \
        "lexical_diversity.sh -i corpus.txt --window 500" \
        "-i, --input"    "Input text file" \
        "-w, --window"   "Window/segment size (default: 50)" \
        "--lower"        "Lowercase all text before processing" \
        "-h, --help"     "Show this help"
}

INPUT=""
WINDOW=50
LOWER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)  INPUT="$2"; shift 2 ;;
        -w|--window) WINDOW="$2"; shift 2 ;;
        --lower)     LOWER=true; shift 1 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

if ! [[ "$WINDOW" =~ ^[0-9]+$ ]] || [ "$WINDOW" -lt 1 ]; then
    die "Window size must be a positive integer"
fi

echo -e "${BOLD}═══ Lexical Diversity ═══${NC}"

# Preprocess and Calculate TTR, MSTTR, and MATTR in a single fast awk pass
{
    if $LOWER; then
        tr '[:upper:]' '[:lower:]' < "$INPUT" | tr -s '[:space:][:punct:]' '\n'
    else
        tr -s '[:space:][:punct:]' '\n' < "$INPUT"
    fi
} | awk -v W="$WINDOW" '
BEGIN {
    tokens = 0
    types = 0
    ttr = 0.0
    
    # MATTR vars
    mattr_sum = 0.0
    mattr_count = 0
    
    # MSTTR vars
    msttr_sum = 0.0
    msttr_count = 0
    seg_types = 0
}
{
    word = $1
    if (length(word) == 0) next
    
    tokens++
    
    # Global Types
    if (!(word in global_vocab)) {
        global_vocab[word] = 1
        types++
    }
    
    # MATTR Sliding Window
    window[tokens] = word
    win_vocab[word]++
    if (win_vocab[word] == 1) {
        win_unique_count++
    }
    
    if (tokens >= W) {
        # Record window score
        mattr_sum += (win_unique_count / W)
        mattr_count++
        
        # Remove oldest token from window
        oldest_idx = tokens - W + 1
        oldest_word = window[oldest_idx]
        win_vocab[oldest_word]--
        if (win_vocab[oldest_word] == 0) {
            win_unique_count--
            delete win_vocab[oldest_word]
        }
        delete window[oldest_idx]
    }
    
    # MSTTR Disjoint Segments
    seg_vocab[word] = 1
    if (tokens % W == 0) {
        for (w in seg_vocab) {
            seg_types++
        }
        msttr_sum += (seg_types / W)
        msttr_count++
        
        # Reset segment
        delete seg_vocab
        seg_types = 0
    }
}
END {
    if (tokens == 0) {
        print "  No tokens found."
        exit
    }
    
    ttr = types / tokens
    
    printf "  Tokens:               %-10d\n", tokens
    printf "  Types:                %-10d\n", types
    printf "  Window size (W):      %-10d\n\n", W
    
    printf "  Standard TTR:         %.4f  (Types / Tokens)\n", ttr
    
    if (msttr_count > 0) {
        printf "  MSTTR (Mean Segment): %.4f  (Avg over %d strict segments)\n", (msttr_sum / msttr_count), msttr_count
    } else {
        printf "  MSTTR (Mean Segment): N/A     (Text length < Window size)\n"
    }
    
    if (mattr_count > 0) {
        printf("  MATTR (Moving Avg):   %.4f  (Avg over %d sliding windows)\n", (mattr_sum / mattr_count), mattr_count)
    } else {
        printf("  MATTR (Moving Avg):   N/A     (Text length < Window size)\n")
    }
}
' || true

exit 0
