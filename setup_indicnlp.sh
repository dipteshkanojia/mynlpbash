#!/usr/bin/env bash
# setup_indicnlp.sh — One-time setup for indic_nlp_library integration
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 IndicNLP integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
INL_DIR="$LIB_DIR/indic_nlp_library"
RES_DIR="$LIB_DIR/indic_nlp_resources"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${BOLD}═══ mynlpbash — IndicNLP Library Setup ═══${NC}"
echo ""

# 1. Initialize submodules
echo -e "${BOLD}[1/4] Initializing git submodules...${NC}"
if [[ -d "$INL_DIR/.git" ]] || [[ -f "$INL_DIR/.git" ]]; then
    echo -e "  ${GREEN}✓${NC} indic_nlp_library already cloned"
else
    cd "$SCRIPT_DIR" && git submodule update --init lib/indic_nlp_library
    echo -e "  ${GREEN}✓${NC} Cloned indic_nlp_library"
fi

if [[ -d "$RES_DIR/.git" ]] || [[ -f "$RES_DIR/.git" ]]; then
    echo -e "  ${GREEN}✓${NC} indic_nlp_resources already cloned"
else
    cd "$SCRIPT_DIR" && git submodule update --init lib/indic_nlp_resources
    echo -e "  ${GREEN}✓${NC} Cloned indic_nlp_resources"
fi
echo ""

# 2. Check Python
echo -e "${BOLD}[2/4] Checking Python...${NC}"
if command -v python3 &>/dev/null; then
    PY_VERSION=$(python3 --version 2>&1)
    echo -e "  ${GREEN}✓${NC} $PY_VERSION"
else
    echo -e "  ${RED}✗${NC} Python 3 not found. Please install Python 3.x"
    exit 1
fi
echo ""

# 3. Install dependencies
echo -e "${BOLD}[3/4] Installing indic-nlp-library...${NC}"
pip3 install indic-nlp-library 2>/dev/null || pip install indic-nlp-library 2>/dev/null || {
    echo -e "  ${YELLOW}⚠${NC} pip install failed, trying from source..."
    cd "$INL_DIR" && pip3 install -r requirements.txt 2>/dev/null && pip3 install -e . 2>/dev/null
}
echo -e "  ${GREEN}✓${NC} indic-nlp-library installed"
echo ""

# 4. Set environment and verify
echo -e "${BOLD}[4/4] Verifying installation...${NC}"
export INDIC_RESOURCES_PATH="$RES_DIR"
export PYTHONPATH="${PYTHONPATH:-}:$INL_DIR"

python3 -c "
from indicnlp import loader
from indicnlp.tokenize import indic_tokenize
from indicnlp.normalize import indic_normalize
from indicnlp.transliterate import unicode_transliterate
from indicnlp.syllable import syllabifier
from indicnlp.morph import unsupervised_morph
import os
os.environ['INDIC_RESOURCES_PATH'] = '$RES_DIR'
loader.load()
# Quick test
tokens = indic_tokenize.trivial_tokenize('नमस्ते दुनिया!', 'hi')
print('  Tokenize test: ', ' '.join(tokens))
print('  ✓ All modules loaded successfully')
" 2>&1

echo ""
echo -e "${BOLD}═══ Setup Complete ═══${NC}"
echo ""
echo "Add these to your shell profile (~/.bashrc or ~/.zshrc):"
echo ""
echo "  export INDIC_RESOURCES_PATH=\"$RES_DIR\""
echo "  export PYTHONPATH=\"\${PYTHONPATH:-}:$INL_DIR\""
echo ""
echo "Or source the env file before using indicnlp scripts:"
echo "  source $SCRIPT_DIR/lib/indicnlp_env.sh"

# Create env file
cat > "$SCRIPT_DIR/lib/indicnlp_env.sh" << EOF
#!/usr/bin/env bash
# Source this file to set up IndicNLP environment
export INDIC_RESOURCES_PATH="$RES_DIR"
export PYTHONPATH="\${PYTHONPATH:-}:$INL_DIR"
EOF
chmod +x "$SCRIPT_DIR/lib/indicnlp_env.sh"
echo ""
echo -e "  ${GREEN}✓${NC} Created lib/indicnlp_env.sh"
