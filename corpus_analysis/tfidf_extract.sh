#!/usr/bin/env bash
# tfidf_extract.sh — Extract keywords using TF-IDF against background
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "tfidf_extract" "Extract keywords scoring by Term Frequency-Inverse Document Frequency (TF-IDF)" \
        "tfidf_extract.sh -i target.txt -b corpus.txt -n 10" \
        "-i, --input"      "Input target document to analyze" \
        "-b, --background" "Background corpus (defaults to treating input lines as documents)" \
        "-n, --top"        "Number of top keywords to display (default: 20)" \
        "--lower"          "Lowercase text before processing" \
        "-h, --help"       "Show this help"
}

INPUT=""
BACKGROUND=""
TOP=20
LOWER=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)      INPUT="$2"; shift 2 ;;
        -b|--background) BACKGROUND="$2"; shift 2 ;;
        -n|--top)        TOP="$2"; shift 2 ;;
        --lower)         LOWER=true; shift 1 ;;
        -h|--help)       show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

# If no background provided, we treat the input file as the corpus (1 line = 1 doc)
# If background is provided, we use the background as the corpus and input as a single query document.
if [[ -z "$BACKGROUND" ]]; then
    CORPUS_FILE="$INPUT"
    SINGLE_DOC_MODE=false
else
    require_file "$BACKGROUND"
    CORPUS_FILE="$BACKGROUND"
    SINGLE_DOC_MODE=true
fi

echo -e "${BOLD}═══ TF-IDF Keyword Extraction ═══${NC}"

# Preprocess corpus for Document Frequencies (do NOT strip newlines so awk counts lines as docs)
if $LOWER; then
    CORPUS_CMD="tr '[:upper:]' '[:lower:]' < \"$CORPUS_FILE\" | tr -c '[:alpha:]\n' ' ' | sed 's/^ *//;s/ *$//'"
else
    CORPUS_CMD="tr -c '[:alpha:]\n' ' ' < \"$CORPUS_FILE\" | sed 's/^ *//;s/ *$//'"
fi

# Preprocess target document for Term Frequencies
if $LOWER; then
    TARGET_CMD="tr '[:upper:]' '[:lower:]' < \"$INPUT\" | tr -s '[:space:][:punct:]' '\n' | grep -v '^$'"
else
    TARGET_CMD="tr -s '[:space:][:punct:]' '\n' < \"$INPUT\" | grep -v '^$'"
fi

# We build the TF and DF in awk.
# Since we might have a massive corpus, we compute DF first and pass it, but
# doing it in a single awk script where we read the corpus first, then the target is faster.
awk -v top="$TOP" -v single_doc="$SINGLE_DOC_MODE" '
# FNR == NR means we are reading the first file (Corpus for DF)
FNR == NR {
    doc_count++
    delete seen_in_doc
    for (i = 1; i <= NF; i++) {
        word = $i
        if (length(word) < 2) continue
        if (!(word in seen_in_doc)) {
            df[word]++
            seen_in_doc[word] = 1
        }
    }
    next
}

# FNR != NR means we are reading the second file (Target for TF)
{
    word = $1
    if (length(word) < 2) next
    
    tf[word]++
    total_terms++
}

END {
    if (total_terms == 0) {
        print "  No valid terms found in target document."
        exit
    }
    
    # In SINGLE_DOC_MODE, doc_count is background docs.
    # If not single doc, doc_count is lines in the self-same target file, so it acts as its own background.
    
    # Setup arrays for sorting
    n_words = 0
    for (word in tf) {
        # Term Frequency: (word count in doc) / (total words in doc)
        term_freq = tf[word] / total_terms
        
        # Document Frequency: number of docs containing word.
        doc_freq = (word in df) ? df[word] : 1
        
        # Inverse Document Frequency: log10( Total Docs / Doc Frequencies )
        # If SINGLE_DOC_MODE=false (input=corpus), doc_count is lines in file.
        # If doc_count == doc_freq, IDF is log(1) = 0. We add a small smooth so it is never perfectly 0.
        idf = log((doc_count + 1) / (doc_freq + 1))
        if (idf <= 0) idf = 0.001
        
        score = term_freq * idf
        
        words[++n_words] = word
        scores[word] = score
    }
    
    # Sort top N
    for (i = 1; i <= n_words; i++) {
        for (j = i + 1; j <= n_words; j++) {
            if (scores[words[j]] > scores[words[i]]) {
                tmp = words[i]
                words[i] = words[j]
                words[j] = tmp
            }
        }
    }
    
    printf "  %-15s %-12s %-10s %-10s\n", "Keyword", "TF-IDF Score", "TF", "DF"
    print "  " "──────────────────────────────────────────────────"
    limit = (n_words < top) ? n_words : top
    for (i = 1; i <= limit; i++) {
        w = words[i]
        printf "  %-15s %-12.6f %-10d %-10d\n", w, scores[w], tf[w], (w in df ? df[w] : 0)
    }
}
' <(eval "$CORPUS_CMD") <(eval "$TARGET_CMD" || true) || true


exit 0
