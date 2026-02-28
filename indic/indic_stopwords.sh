#!/usr/bin/env bash
# indic_stopwords.sh — Remove Indic stopwords (Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati)
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 Indic language support
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "indic_stopwords" "Remove Indic stopwords (Hindi, Bengali, Tamil, etc.)" \
        "indic_stopwords.sh -i hindi.txt --lang hindi" \
        "-i, --input"     "Input text file" \
        "--lang"           "Language: hindi, bengali, tamil, telugu, marathi, gujarati (default: hindi)" \
        "--custom"          "Custom stopword file (one per line)" \
        "-o, --output"    "Output file (default: stdout)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; LANG="hindi" ; CUSTOM="" ; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)   INPUT="$2"; shift 2 ;;
        --lang)       LANG="$2"; shift 2 ;;
        --custom)     CUSTOM="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"

process() {
    awk -v lang="$LANG" -v custom_file="$CUSTOM" '
    BEGIN {
        # Embedded stopword lists
        if (lang == "hindi") {
            split("का के की है हैं था थे थी को में से पर ने भी और या यह वह इस उस जो कि एक कर नहीं हो तो यहां वहां अब जब तक अगर लेकिन मगर क्योंकि फिर इसलिए कुछ सब बहुत ज्यादा कम अपना अपनी अपने मेरा मेरी मेरे तेरा तुम उनका उनकी उनके इसका इसकी इसके जिसका जिसकी जैसा जैसे ऐसा ऐसे वैसा दो तीन चार बाद पहले ऊपर नीचे साथ बिना द्वारा हूं हूँ हम वे उन्होंने होता होती होते रहा रहे रहते गया गई गए दिया दी दिए करना करने करता करती करते सकता सकती सकते चाहिए", stopwords, " ")
        } else if (lang == "bengali") {
            split("এবং বা যে এই সেই তার করে হয় করা হত থেকে জন্য সব কিছু তা তিনি আমি তুমি আপনি নয় হতে পরে আর এর ও কি কে", stopwords, " ")
        } else if (lang == "tamil") {
            split("மற்றும் ஒரு இது அது என்று அவர் அவன் அவள் நான் நீ இல்லை உள்ள செய்து செய்ய வேண்டும் என் உன் அந்த இந்த", stopwords, " ")
        } else if (lang == "telugu") {
            split("మరియు ఒక ఈ ఆ అని అతను ఆమె నేను నువ్వు కాదు ఉన్న చేసి చేయ యొక్క నా", stopwords, " ")
        } else if (lang == "marathi") {
            split("आणि एक हा ही हे त्या या मी तू आपण नाही आहे होता होते करणे करून काही सर्व बरेच जास्त कमी माझा माझी तुझा तुम्ही त्यांचा पण तर मग कारण पुन्हा म्हणून ते ती तो", stopwords, " ")
        } else if (lang == "gujarati") {
            split("અને એક આ તે છે હતું હતા કરવા કરે છે થી માં પર ના ની નો નું કે જે", stopwords, " ")
        }
        
        for (i in stopwords) is_stop[stopwords[i]] = 1
        
        # Load custom stopwords if provided
        if (custom_file != "") {
            while ((getline line < custom_file) > 0) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line != "") is_stop[line] = 1
            }
        }
    }
    {
        nw = split($0, words, /[[:space:]]+/)
        result = ""
        for (w=1; w<=nw; w++) {
            if (!(words[w] in is_stop)) {
                result = result (result=="" ? "" : " ") words[w]
            } else removed++
        }
        print result
        total += nw
    }
    END {
        printf "Removed %d/%d stopwords (%.1f%%)\n", removed+0, total, (removed+0)*100/total > "/dev/stderr"
    }' "$INPUT"
}

if [[ -n "$OUTPUT" ]]; then
    process > "$OUTPUT"
    success "Stopwords removed ($LANG) → $OUTPUT"
else
    process
fi
