#!/bin/bash
# setup_assets.sh — يهيئ كل الأصول (PNG + Sounds + Icons).
#
# يتطلب:
#   • svgexport (npm install -g svgexport) أو librsvg أو inkscape
#   • Flutter SDK (لتوليد الأيقونات)
#   • curl (لتحميل الأصوات)

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🎨 نبض — Asset Setup v2"
echo "======================="
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. المجلدات
# ═══════════════════════════════════════════════════════════════
echo "📁 إنشاء المجلدات..."
mkdir -p assets/icons assets/sounds assets/store/screenshots assets/store/output assets/social
echo "  ✅"

# ═══════════════════════════════════════════════════════════════
# 2. كشف أداة تحويل SVG
# ═══════════════════════════════════════════════════════════════
SVG_TOOL=""
if command -v svgexport &> /dev/null; then
  SVG_TOOL="svgexport"
elif command -v inkscape &> /dev/null; then
  SVG_TOOL="inkscape"
elif command -v rsvg-convert &> /dev/null; then
  SVG_TOOL="rsvg-convert"
elif command -v convert &> /dev/null; then
  SVG_TOOL="convert"
fi

convert_svg() {
  local svg="$1"
  local png="$2"
  local size="$3"

  case "$SVG_TOOL" in
    svgexport)
      svgexport "$svg" "$png" "$size"
      ;;
    inkscape)
      inkscape "$svg" --export-type=png --export-filename="$png" \
        --export-width="${size%%:*}" --export-height="${size##*:}"
      ;;
    rsvg-convert)
      rsvg-convert -w "${size%%:*}" -h "${size##*:}" "$svg" -o "$png"
      ;;
    convert)
      convert -background none -resize "$size" "$svg" "$png"
      ;;
  esac
}

if [ -z "$SVG_TOOL" ]; then
  echo "⚠️  لم يتم العثور على أداة SVG → PNG"
  echo ""
  echo "   ثبّت واحدة من التالي:"
  echo "   • npm install -g svgexport"
  echo "   • brew install librsvg    # rsvg-convert"
  echo "   • brew install --cask inkscape"
  echo "   • brew install imagemagick # convert"
  echo ""
  echo "   ثم أعد تشغيل السكربت."
  echo ""
else
  echo "🎨 استخدام: $SVG_TOOL"
  echo ""

  # ─── App Icon ───
  [ -f assets/icons/app_icon.svg ] && {
    echo "  → app_icon.png (1024×1024)"
    convert_svg assets/icons/app_icon.svg assets/icons/app_icon.png "1024:1024"
  }

  # ─── App Icon Foreground ───
  [ -f assets/icons/app_icon_fg.svg ] && {
    echo "  → app_icon_fg.png (1024×1024)"
    convert_svg assets/icons/app_icon_fg.svg assets/icons/app_icon_fg.png "1024:1024"
  }

  # ─── Splash Logo ───
  [ -f assets/icons/splash_logo.svg ] && {
    echo "  → splash.png (800×800)"
    convert_svg assets/icons/splash_logo.svg assets/icons/splash.png "800:800"
  }

  # ─── Feature Graphic ───
  [ -f assets/store/feature_graphic.svg ] && {
    echo "  → feature_graphic.png (1024×500)"
    svgexport assets/store/feature_graphic.svg assets/store/feature_graphic.png "1024:500" 2>/dev/null || \
      convert -background none -resize "1024x500" assets/store/feature_graphic.svg assets/store/feature_graphic.png
  }

  # ─── Play Store Icon ───
  [ -f assets/icons/app_icon.svg ] && {
    echo "  → app_icon_playstore.png (512×512)"
    convert_svg assets/icons/app_icon.svg assets/store/app_icon_playstore.png "512:512"
  }

  # ─── Adaptive Icon Foreground ───
  [ -f assets/icons/app_icon_fg.svg ] && {
    echo "  → ic_launcher_foreground.png (432×432)"
    convert_svg assets/icons/app_icon_fg.svg assets/icons/ic_launcher_foreground.png "432:432"
  }

  # ─── Store Screenshots ───
  if [ -d assets/store/screenshots ]; then
    for svg in assets/store/screenshots/*.svg; do
      [ -f "$svg" ] || continue
      filename=$(basename "$svg" .svg)
      echo "  → screenshots/$filename.png (1080×1920)"
      svgexport "$svg" "assets/store/output/$filename.png" "1080:1920" 2>/dev/null || \
        convert -background none -resize "1080x1920" "$svg" "assets/store/output/$filename.png"
    done
  fi

  echo "  ✅ SVG conversion complete"
fi

# ═══════════════════════════════════════════════════════════════
# 3. الأصوات
# ═══════════════════════════════════════════════════════════════
echo ""
echo "🔊 إعداد الأصوات..."
if bash scripts/download_sounds.sh; then
  echo "  ✅ تم"
else
  echo "  ⚠️  بعض الأصوات فشلت — راجع السجل أعلاه"
fi

# ═══════════════════════════════════════════════════════════════
# 4. توليد أيقونات Flutter
# ═══════════════════════════════════════════════════════════════
echo ""
echo "🎨 توليد أيقونات Flutter..."

if [ -f "assets/icons/app_icon.png" ]; then
  if command -v flutter &> /dev/null; then
    flutter pub get
    dart run flutter_launcher_icons || echo "  ⚠️  flutter_launcher_icons فشل"
    dart run flutter_native_splash:create || echo "  ⚠️  flutter_native_splash فشل"
    echo "  ✅"
  else
    echo "  ⚠️  Flutter غير مثبت — تخطّي التوليد"
  fi
else
  echo "  ⚠️  app_icon.png غير موجود — تخطّي"
fi

# ═══════════════════════════════════════════════════════════════
# 5. التحقق النهائي
# ═══════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📊 النتيجة النهائية:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "   الأيقونات:      $(ls assets/icons/*.png 2>/dev/null | wc -l) / 5 متوقع"
echo "   الأصوات:        $(ls assets/sounds/*.mp3 2>/dev/null | wc -l) / 10 متوقع"
echo "   Screenshots:    $(ls assets/store/output/*.png 2>/dev/null | wc -l) / 6 متوقع"
echo ""

# فحص الملفات الحرجة
MISSING=()
for f in assets/icons/app_icon.png assets/icons/app_icon_fg.png assets/icons/splash.png; do
  [ ! -f "$f" ] && MISSING+=("$f")
done

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "   ✅ كل الأصول الحرجة موجودة"
else
  echo "   ❌ ناقص:"
  for f in "${MISSING[@]}"; do
    echo "      • $f"
  done
fi
echo ""

if command -v flutter &> /dev/null; then
  echo "🎯 الخطوات التالية:"
  echo "   1. flutter pub get"
  echo "   2. flutter gen-l10n"
  echo "   3. flutter analyze"
  echo "   4. flutter test"
  echo "   5. flutter build appbundle --release"
else
  echo "⚠️  Flutter غير مثبت. ثبّته ثم أعد التشغيل."
fi
