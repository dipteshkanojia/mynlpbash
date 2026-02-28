#!/usr/bin/env bash
# scatter_plot.sh — Terminal scatter plot on a character grid
# Author: Claude Opus (AI-assisted)
# Status: AI-Enhanced — mynlpbash v2 visualization
source "$(dirname "$0")/../lib/common.sh"

show_help() {
    print_help "scatter_plot" "Render terminal scatter plot from two numeric columns" \
        "scatter_plot.sh -i data.csv -x 1 -y 2" \
        "-i, --input"     "Input CSV/TSV file" \
        "-x, --x-col"     "X-axis column (index, default: 1)" \
        "-y, --y-col"     "Y-axis column (index, default: 2)" \
        "--width"          "Plot width (default: 60)" \
        "--height"         "Plot height (default: 20)" \
        "--marker"         "Marker character (default: ●)" \
        "-d, --delimiter" "Delimiter (auto-detected)" \
        "-h, --help"      "Show this help"
}

INPUT="" ; X_COL=1 ; Y_COL=2 ; PW=60 ; PH=20 ; MARKER="●" ; DELIM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)     INPUT="$2"; shift 2 ;;
        -x|--x-col)     X_COL="$2"; shift 2 ;;
        -y|--y-col)     Y_COL="$2"; shift 2 ;;
        --width)        PW="$2"; shift 2 ;;
        --height)       PH="$2"; shift 2 ;;
        --marker)       MARKER="$2"; shift 2 ;;
        -d|--delimiter) DELIM="$2"; shift 2 ;;
        -h|--help)      show_help; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -z "$INPUT" ]] && die "Input file required (-i)"
require_file "$INPUT"
[[ -z "$DELIM" ]] && DELIM=$(detect_delimiter "$INPUT")

echo -e "${BOLD}═══ Scatter Plot ═══${NC}"
echo ""

awk -F"$DELIM" -v xcol="$X_COL" -v ycol="$Y_COL" -v pw="$PW" -v ph="$PH" -v marker="$MARKER" '
NR==1 { xlabel=$xcol; ylabel=$ycol; next }
{
    x = $xcol + 0; y = $ycol + 0
    xs[NR-1] = x; ys[NR-1] = y
    if (NR==2) { xmin=x; xmax=x; ymin=y; ymax=y }
    if (x < xmin) xmin = x; if (x > xmax) xmax = x
    if (y < ymin) ymin = y; if (y > ymax) ymax = y
    n = NR - 1
}
END {
    xrange = xmax - xmin; if (xrange == 0) xrange = 1
    yrange = ymax - ymin; if (yrange == 0) yrange = 1
    
    # Place points on grid
    for (i=1; i<=n; i++) {
        gx = int((xs[i] - xmin) / xrange * (pw - 1))
        gy = int((ys[i] - ymin) / yrange * (ph - 1))
        grid[gy, gx]++
    }
    
    # Draw from top to bottom
    for (row=ph-1; row>=0; row--) {
        if (row == ph-1) printf "  %7.1f │", ymax
        else if (row == 0) printf "  %7.1f │", ymin
        else if (row == int(ph/2)) printf "  %7.1f │", (ymin+ymax)/2
        else printf "         │"
        
        for (col=0; col<pw; col++) {
            if (grid[row, col] > 0) printf "%s", marker
            else if (row == 0) printf "─"
            else printf " "
        }
        print ""
    }
    printf "         └"
    for (col=0; col<pw; col++) printf "─"
    print ""
    printf "          %-*s%*.1f\n", int(pw/2), sprintf("%.1f", xmin), pw - int(pw/2), xmax
    printf "\n  Points: %d | X: [%.1f, %.1f] | Y: [%.1f, %.1f]\n", n, xmin, xmax, ymin, ymax
}' "$INPUT"
echo ""
