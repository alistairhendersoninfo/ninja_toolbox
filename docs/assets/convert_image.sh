#!/usr/bin/env bash
# -----------------------------------------------------------
# convert_image.sh - Image converter with brand backgrounds
# -----------------------------------------------------------
# Takes any image, trims borders, converts to clean PNG/WebP
# with transparent and brand-coloured backgrounds.
#
# Usage:
#   ./convert_image.sh <image_file> [--png] [--both]
#
# Options:
#   --png   Output PNG instead of WebP (default: WebP)
#   --both  Output both PNG and WebP
#
# Output files are saved alongside the original as:
#   <name>_transparent.<ext>
#   <name>_<hex>.<ext>
#
# Examples:
#   ./convert_image.sh images/logo.jpg
#   ./convert_image.sh images/photo.PNG --png
#   ./convert_image.sh images/icon.bmp --both
# -----------------------------------------------------------

set -euo pipefail

# ========================
# Brand Colour Palette
# ========================
# Format: "hex:Label" — add/remove colours here
COLOURS=(
    "000000:Black"
    "14213d:Prussian Blue"
    "fca311:Orange"
    "e5e5e5:Alabaster Grey"
    "ffffff:White"
)

# Fuzz percentage for border trimming (adjust if trim is too aggressive/weak)
TRIM_FUZZ="15%"

# WebP quality (0-100, 90+ is near-lossless for photos, 100 = lossless)
WEBP_QUALITY=90

# ========================
# Preflight Checks
# ========================
if ! command -v magick &>/dev/null; then
    echo "Error: ImageMagick 7+ is required. Install with: brew install imagemagick"
    exit 1
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <image_file> [--png] [--both]"
    echo ""
    echo "Options:"
    echo "  --png   Output PNG only (default: WebP)"
    echo "  --both  Output both PNG and WebP"
    exit 1
fi

INPUT_FILE="$1"
shift

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# Parse flags
OUTPUT_PNG=false
OUTPUT_WEBP=true
for arg in "$@"; do
    case "$arg" in
        --png)
            OUTPUT_PNG=true
            OUTPUT_WEBP=false
            ;;
        --both)
            OUTPUT_PNG=true
            OUTPUT_WEBP=true
            ;;
    esac
done

# ========================
# Setup paths
# ========================
INPUT_DIR="$(cd "$(dirname "$INPUT_FILE")" && pwd)"
INPUT_BASENAME="$(basename "$INPUT_FILE")"
NAME="${INPUT_BASENAME%.*}"

# Working directory for intermediates
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

COUNT=0

echo "============================================"
echo " Image Converter - Brand Backgrounds"
echo "============================================"
echo ""
echo "  Input:  $INPUT_FILE"
echo "  Name:   $NAME"
echo ""

# ========================
# Step 1: Convert to PNG
# ========================
echo "[1/4] Converting to PNG..."
CLEAN_PNG="$WORK_DIR/${NAME}_clean.png"
magick "$INPUT_FILE" -strip "$CLEAN_PNG"
echo "       $(magick identify -format '%wx%h %[channels]' "$CLEAN_PNG")"

# ========================
# Step 2: Trim borders
# ========================
echo "[2/4] Trimming borders (fuzz: $TRIM_FUZZ)..."
TRIMMED_PNG="$WORK_DIR/${NAME}_trimmed.png"
magick "$CLEAN_PNG" \
    -fuzz "$TRIM_FUZZ" \
    -trim +repage \
    "$TRIMMED_PNG"

TRIMMED_SIZE="$(magick identify -format '%wx%h' "$TRIMMED_PNG")"
echo "       Trimmed to: $TRIMMED_SIZE"

# ========================
# Step 3: Remove background + square + pad
# ========================
echo "[3/4] Removing background, squaring and padding..."

# Remove the white/light background to create true transparency
NOBG_PNG="$WORK_DIR/${NAME}_nobg.png"
magick "$TRIMMED_PNG" \
    -fuzz "$TRIM_FUZZ" \
    -transparent white \
    "$NOBG_PNG"

SQUARE_PNG="$WORK_DIR/${NAME}_square.png"
magick "$NOBG_PNG" \
    -background none \
    -gravity center \
    -extent "%[fx:max(w,h)]x%[fx:max(w,h)]" \
    -background none \
    -gravity center \
    -extent "%[fx:w*1.10]x%[fx:h*1.10]" \
    +repage \
    "$SQUARE_PNG"

SQUARE_SIZE="$(magick identify -format '%wx%h' "$SQUARE_PNG")"
echo "       Final canvas: $SQUARE_SIZE"

# ========================
# Step 4: Generate variants
# ========================
echo "[4/4] Generating background variants..."
echo ""

# Helper: generate one variant
generate() {
    local src="$1" bg="$2" label="$3" outbase="$4"

    if $OUTPUT_WEBP; then
        local out="$INPUT_DIR/${outbase}.webp"
        if [[ "$bg" == "none" ]]; then
            magick "$src" -quality "$WEBP_QUALITY" "$out"
        else
            magick "$src" -background "$bg" -flatten -quality "$WEBP_QUALITY" "$out"
        fi
        local size
        size=$(du -h "$out" | cut -f1 | xargs)
        printf "  %-40s %8s  %s\n" "${outbase}.webp" "($size)" "- $label"
        COUNT=$((COUNT + 1))
    fi
    if $OUTPUT_PNG; then
        local out="$INPUT_DIR/${outbase}.png"
        if [[ "$bg" == "none" ]]; then
            magick "$src" "$out"
        else
            magick "$src" -background "$bg" -flatten "$out"
        fi
        local size
        size=$(du -h "$out" | cut -f1 | xargs)
        printf "  %-40s %8s  %s\n" "${outbase}.png" "($size)" "- $label"
        COUNT=$((COUNT + 1))
    fi
}

# --- Transparent ---
generate "$SQUARE_PNG" "none" "Transparent" "${NAME}_transparent"

# --- Coloured backgrounds ---
for entry in "${COLOURS[@]}"; do
    hex="${entry%%:*}"
    label="${entry#*:}"
    generate "$SQUARE_PNG" "#${hex}" "$label" "${NAME}_${hex}"
done

echo ""
echo "============================================"
echo " Done! Generated ${COUNT} files in:"
echo " $INPUT_DIR"
echo "============================================"
