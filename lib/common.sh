#!/usr/bin/env bash
# ==============================================================================
# mynlpbash shared library — common.sh
# Provides argument parsing, colored output, CSV field detection, and utilities.
# Source this from any script: source "$(dirname "$0")/../lib/common.sh"
#
# Author: Diptesh (core utilities), Claude Opus (AI-enhanced features)
# Core: Colors, logging, file checks, delimiter detection, column utilities,
#       row counting, temp files, cleanup
# AI-Enhanced: Progress bars, number formatting, histogram bars, separator
#              rendering, rich help formatting
# ==============================================================================

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# CROSS-PLATFORM LAYER (Claude Opus v2) — macOS + Ubuntu compatibility
# ══════════════════════════════════════════════════════════════════════════════

# ── OS detection ──────────────────────────────────────────────────────────────
MYNLP_OS="unknown"
case "$(uname -s)" in
    Darwin*) MYNLP_OS="darwin" ;;
    Linux*)  MYNLP_OS="linux" ;;
esac

# ── Force UTF-8 locale ───────────────────────────────────────────────────────
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"

# ── Portable sed in-place ────────────────────────────────────────────────────
portable_sed_i() {
    if [[ "$MYNLP_OS" == "darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# ── Portable shuffle ─────────────────────────────────────────────────────────
portable_shuf() {
    if command -v gshuf &>/dev/null; then gshuf "$@"
    elif command -v shuf &>/dev/null; then shuf "$@"
    else awk 'BEGIN{srand()}{print rand()"\t"$0}' "$@" | sort -n | cut -f2-
    fi
}

# ── Portable stat (file size in bytes) ────────────────────────────────────────
portable_filesize() {
    if [[ "$MYNLP_OS" == "darwin" ]]; then
        stat -f%z "$1" 2>/dev/null || wc -c < "$1" | tr -d ' '
    else
        stat -c%s "$1" 2>/dev/null || wc -c < "$1" | tr -d ' '
    fi
}

# ── Portable date ────────────────────────────────────────────────────────────
portable_date() {
    if [[ "$MYNLP_OS" == "darwin" ]]; then
        if command -v gdate &>/dev/null; then gdate "$@"; else date "$@"; fi
    else
        date "$@"
    fi
}

# ── Portable md5 ─────────────────────────────────────────────────────────────
portable_md5() {
    if [[ "$MYNLP_OS" == "darwin" ]]; then
        md5 -q "$@" 2>/dev/null || md5sum "$@" | awk '{print $1}'
    else
        md5sum "$@" | awk '{print $1}'
    fi
}

# ── Portable readlink ────────────────────────────────────────────────────────
portable_realpath() {
    if command -v grealpath &>/dev/null; then grealpath "$@"
    elif command -v realpath &>/dev/null; then realpath "$@"
    else
        local f="$1"
        cd "$(dirname "$f")" && echo "$(pwd)/$(basename "$f")"
    fi
}

# ── UTF-8 character count (not byte count) ───────────────────────────────────
char_count_utf8() {
    echo -n "$1" | awk '{print length}'
}

# ── Byte length ──────────────────────────────────────────────────────────────
byte_length() {
    echo -n "$1" | wc -c | tr -d ' '
}

# ── Terminal width ───────────────────────────────────────────────────────────
term_width() {
    local w
    w=$(tput cols 2>/dev/null || echo 80)
    echo "$w"
}


# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'
    DIM='\033[2m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; DIM=''; NC=''
fi

# ══════════════════════════════════════════════════════════════════════════════
# CORE UTILITIES (Diptesh) — foundational functions used by all scripts
# ══════════════════════════════════════════════════════════════════════════════

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}ℹ${NC}  $*" >&2; }
success() { echo -e "${GREEN}✓${NC}  $*" >&2; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*" >&2; }
error()   { echo -e "${RED}✗${NC}  $*" >&2; }
die()     { error "$@"; exit 1; }

# ── File checks ───────────────────────────────────────────────────────────────
require_file() {
    local f="$1"
    [[ -f "$f" ]] || die "File not found: $f"
    [[ -r "$f" ]] || die "File not readable: $f"
}

require_command() {
    command -v "$1" &>/dev/null || die "Required command not found: $1"
}

# ── CSV/TSV delimiter detection ───────────────────────────────────────────────
detect_delimiter() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file")
    local tabs commas
    tabs=$(echo "$first_line" | tr -cd '\t' | wc -c | tr -d ' ')
    commas=$(echo "$first_line" | tr -cd ',' | wc -c | tr -d ' ')
    if (( tabs > 0 && tabs >= commas )); then
        echo $'\t'
    else
        echo ','
    fi
}

# ── Column count ──────────────────────────────────────────────────────────────
count_columns() {
    local file="$1"
    local delim="${2:-$(detect_delimiter "$file")}"
    head -1 "$file" | awk -F"$delim" '{print NF}'
}

# ── Get column names ─────────────────────────────────────────────────────────
get_column_names() {
    local file="$1"
    local delim="${2:-$(detect_delimiter "$file")}"
    head -1 "$file" | awk -F"$delim" '{for(i=1;i<=NF;i++) print i": "$i}'
}

# ── Find column index by name ────────────────────────────────────────────────
find_column_index() {
    local file="$1"
    local name="$2"
    local delim="${3:-$(detect_delimiter "$file")}"
    head -1 "$file" | awk -F"$delim" -v name="$name" '{
        for(i=1;i<=NF;i++) {
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
            if ($i == name) { print i; exit }
        }
    }'
}

# ── Row count (excluding header) ─────────────────────────────────────────────
count_rows() {
    local file="$1"
    local total
    total=$(wc -l < "$file" | tr -d ' ')
    echo $(( total - 1 ))
}

# ── Temporary files with cleanup ─────────────────────────────────────────────
TMPFILES=()
make_temp() {
    local t
    t=$(mktemp "${TMPDIR:-/tmp}/mynlpbash.XXXXXX")
    TMPFILES+=("$t")
    echo "$t"
}

cleanup_temps() {
    for t in "${TMPFILES[@]:-}"; do
        [[ -f "$t" ]] && rm -f "$t"
    done
}
trap cleanup_temps EXIT

# ══════════════════════════════════════════════════════════════════════════════
# AI-ENHANCED UTILITIES (Claude Opus) — advanced display and formatting
# ══════════════════════════════════════════════════════════════════════════════

# ── Progress counter ─────────────────────────────────────────────────────────
show_progress() {
    local current="$1" total="$2" label="${3:-Processing}"
    local pct=$(( current * 100 / total ))
    printf "\r${DIM}%s: %d/%d (%d%%)${NC}" "$label" "$current" "$total" "$pct" >&2
    [[ "$current" -eq "$total" ]] && echo >&2
}

# ── Number formatting ────────────────────────────────────────────────────────
format_number() {
    # macOS printf may not support %'d for thousands separators
    local n="$1"
    if printf "%'d" "$n" 2>/dev/null; then
        return
    fi
    echo "$n"
}

# ── Human-readable percentages ───────────────────────────────────────────────
pct() {
    local num="$1" denom="$2"
    if (( denom == 0 )); then
        echo "0.00"
    else
        awk "BEGIN { printf \"%.2f\", ($num / $denom) * 100 }"
    fi
}

# ── Print a horizontal bar (for histograms) ──────────────────────────────────
print_bar() {
    local value="$1" max="$2" width="${3:-40}"
    local bar_len
    if (( max == 0 )); then
        bar_len=0
    else
        bar_len=$(( value * width / max ))
    fi
    printf "${GREEN}"
    printf '█%.0s' $(seq 1 "$bar_len" 2>/dev/null) || true
    printf "${NC}"
}

# ── Print separator line ─────────────────────────────────────────────────────
separator() {
    local char="${1:--}" width="${2:-60}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# ── Script header for help text ───────────────────────────────────────────────
print_help() {
    local name="$1" desc="$2" usage="$3"
    shift 3
    echo -e "${BOLD}$name${NC} — $desc"
    echo ""
    echo -e "${BOLD}USAGE:${NC}"
    echo "  $usage"
    echo ""
    if [[ $# -gt 0 ]]; then
        echo -e "${BOLD}OPTIONS:${NC}"
        while [[ $# -gt 0 ]]; do
            printf "  %-24s %s\n" "$1" "$2"
            shift 2
        done
        echo ""
    fi
}
