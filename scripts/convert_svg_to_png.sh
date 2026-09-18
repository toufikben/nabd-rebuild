#!/bin/bash
# convert_svg_to_png.sh — يحول SVG إلى PNG بكل الأحجام المطلوبة.
#
# المتطلبات:
#   npm install -g svgexport
#   أو: brew install librsvg

set -e

ASSETS_DIR="assets"
ICONS_DIR="$ASSETS_DIR/icons"
STORE_DIR="$ASSETS_DIR/store"

mkdir -p "$ICONS_DIR" "$STORE_DIR"

echo "🎨 Converting SVG to PNG..."

# ═══════════════════════════════════════════════════════════
# 1. App Icon — 1024×1024
# ═══════════════════════════════════════════════════════════
echo "→ app_icon.png (1024×1024)"
svgexport "$ICONS_DIR/app_icon.svg" "$ICONS_DIR/app_icon.png" 1024:1024

echo "→ app_icon_fg.png (1024×1024)"
svgexport "$ICONS_DIR/app_icon_fg.svg" "$ICONS_DIR/app_icon_fg.png" 1024:1024

# ═══════════════════════════════════════════════════════════
# 2. Splash Logo — 800×800
# ═══════════════════════════════════════════════════════════
echo "→ splash.png (800×800)"
svgexport "$ICONS_DIR/splash_logo.svg" "$ICONS_DIR/splash.png" 800:800

# ═══════════════════════════════════════════════════════════
# 3. Feature Graphic — 1024×500 (Play Store)
# ═══════════════════════════════════════════════════════════
echo "→ feature_graphic.png (1024×500)"
svgexport "$STORE_DIR/feature_graphic.svg" "$STORE_DIR/feature_graphic.png" 1024:500

# ═══════════════════════════════════════════════════════════
# 4. Play Store Icon — 512×512
# ═══════════════════════════════════════════════════════════
echo "→ app_icon_playstore.png (512×512)"
svgexport "$ICONS_DIR/app_icon.svg" "$STORE_DIR/app_icon_playstore.png" 512:512

# ═══════════════════════════════════════════════════════════
# 5. Adaptive Icon Foreground — 432×432
# ═══════════════════════════════════════════════════════════
echo "→ ic_launcher_foreground.png (432×432)"
svgexport "$ICONS_DIR/app_icon_fg.svg" "$ICONS_DIR/ic_launcher_foreground.png" 432:432

echo ""
echo "✅ All PNGs created successfully!"
echo ""
echo "📁 Files:"
ls -lh "$ICONS_DIR"/*.png "$STORE_DIR"/*.png 2>/dev/null || true
