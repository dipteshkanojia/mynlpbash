#!/usr/bin/env bash
# hf_download_csv.sh — Download HuggingFace Dataset to CSV
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — introduced by Claude Opus to supercharge mynlpbash
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "hf_download_csv" "Download HuggingFace Dataset to CSV via Datasets Server API" \
        "hf_download_csv.sh -d \"dair-ai/emotion\" -s train -o emotion.csv" \
        "-d, --dataset"  "Dataset name on HF (e.g., dair-ai/emotion)" \
        "-c, --config"   "Configuration subset (default: split or default, will try to guess)" \
        "-s, --split"    "Dataset split (default: train)" \
        "-n, --lines"    "Total number of lines to download (default: 100)" \
        "-o, --output"   "Output CSV file" \
        "-h, --help"     "Show this help"
}

DATASET=""
CONFIG=""
SPLIT="train"
LINES=100
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dataset) DATASET="$2"; shift 2 ;;
        -c|--config)  CONFIG="$2"; shift 2 ;;
        -s|--split)   SPLIT="$2"; shift 2 ;;
        -n|--lines)   LINES="$2"; shift 2 ;;
        -o|--output)  OUTPUT="$2"; shift 2 ;;
        -h|--help)    show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$DATASET" ]] && die "Dataset name required (-d/--dataset)"
[[ -z "$OUTPUT" ]] && die "Output file required (-o/--output)"

# URL Encode the dataset string (e.g., dair-ai/emotion -> dair-ai%2Femotion)
ENCODED_DATASET=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$DATASET', safe=''))")

# If config is empty, first try 'default', if that fails try the dataset basename, if that fails try 'split'
# The HF Datasets Server API requires a config parameter.
if [[ -z "$CONFIG" ]]; then
    # Auto-detect config using a simple guess array
    BASENAME=$(basename "$DATASET")
    GUESSES=("default" "$BASENAME" "split" "$DATASET")
    FOUND_CONFIG=""
    
    echo -e "${BOLD}Detecting dataset config...${NC}" >&2
    for guess in "${GUESSES[@]}"; do
        ENCODED_GUESS=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$guess', safe=''))")
        TEST_URL="https://datasets-server.huggingface.co/rows?dataset=${ENCODED_DATASET}&config=${ENCODED_GUESS}&split=${SPLIT}&offset=0&length=1"
        
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL")
        
        if [[ "$HTTP_CODE" == "200" ]]; then
            FOUND_CONFIG="$guess"
            echo "  ✓ Config found: $FOUND_CONFIG" >&2
            break
        fi
    done
    
    if [[ -z "$FOUND_CONFIG" ]]; then
        die "Could not auto-detect config for $DATASET. Please specify manually with -c/--config."
    fi
    CONFIG="$FOUND_CONFIG"
fi

ENCODED_CONFIG=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CONFIG', safe=''))")
ENCODED_SPLIT=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SPLIT', safe=''))")

echo -e "${BOLD}═══ Downloading from HuggingFace ═══${NC}" >&2
echo "Dataset: $DATASET" >&2
echo "Config:  $CONFIG" >&2
echo "Split:   $SPLIT" >&2
echo "Target:  $LINES rows" >&2

PAGE_SIZE=100
OFFSET=0
TOTAL_DOWNLOADED=0

# Create an empty file to clear it or start it
> "$OUTPUT"

FIRST_PAGE=true

# Python parser script to handle deep HF JSON and convert to flat CSV
# We output standard CSV structure using python's built-in csv module.
export PARSER_SCRIPT='
import sys
import json
import csv

try:
    data = json.load(sys.stdin)
except Exception as e:
    sys.exit(1)

if "error" in data:
    print("API Error: " + data["error"], file=sys.stderr)
    sys.exit(1)

if "rows" not in data or "features" not in data:
    sys.exit(0)

first_page = sys.argv[1] == "true"
writer = csv.writer(sys.stdout)

# Extract flat feature names
feature_names = [f["name"] for f in data["features"]]

if first_page:
    writer.writerow(feature_names)

for r in data["rows"]:
    row_data = r["row"]
    out_row = []
    for f in feature_names:
        val = row_data.get(f, "")
        out_row.append(str(val))
    writer.writerow(out_row)
'

# Download loop
while [[ $TOTAL_DOWNLOADED -lt $LINES ]]; do
    FETCH_LEN=$PAGE_SIZE
    REMAINING=$(( LINES - TOTAL_DOWNLOADED ))
    if [[ $REMAINING -lt $PAGE_SIZE ]]; then
        FETCH_LEN=$REMAINING
    fi
    
    API_URL="https://datasets-server.huggingface.co/rows?dataset=${ENCODED_DATASET}&config=${ENCODED_CONFIG}&split=${ENCODED_SPLIT}&offset=${OFFSET}&length=${FETCH_LEN}"
    
    # We download the chunk
    TEMP_JSON=$(mktemp)
    curl -s -o "$TEMP_JSON" -w "%{http_code}" "$API_URL" > /tmp/http_code
    
    HTTP_CODE=$(< /tmp/http_code)
    
    if [[ "$HTTP_CODE" != "200" ]]; then
        echo -e "\n${RED}Error downloading chunk at offset $OFFSET (HTTP $HTTP_CODE).${NC}" >&2
        cat "$TEMP_JSON" >&2
        rm -f "$TEMP_JSON" /tmp/http_code
        exit 1
    fi
    
    # Parse and append to CSV
    if ! python3 -c "$PARSER_SCRIPT" "$FIRST_PAGE" < "$TEMP_JSON" >> "$OUTPUT"; then
        echo -e "\n${RED}Error parsing JSON from HuggingFace API.${NC}" >&2
        rm -f "$TEMP_JSON" /tmp/http_code
        exit 1
    fi
    
    # Check if we got fewer rows than requested (end of dataset)
    ROWS_RETRIEVED=$(python3 -c "import json, sys; d=json.load(sys.stdin); print(len(d.get('rows', [])))" < "$TEMP_JSON")
    
    TOTAL_DOWNLOADED=$(( TOTAL_DOWNLOADED + ROWS_RETRIEVED ))
    OFFSET=$(( OFFSET + PAGE_SIZE ))
    FIRST_PAGE=false
    
    rm -f "$TEMP_JSON" /tmp/http_code
    
    # Show progress
    printf "\r  Downloaded: %d / %d rows..." "$TOTAL_DOWNLOADED" "$LINES" >&2
    
    if [[ $ROWS_RETRIEVED -lt $FETCH_LEN ]]; then
        # Reached the end of the remote split
        break
    fi
done

echo -e "\n\n${BOLD}Done! Data saved to: ${NC}$OUTPUT" >&2
echo "Rows downloaded: $TOTAL_DOWNLOADED" >&2

exit 0
