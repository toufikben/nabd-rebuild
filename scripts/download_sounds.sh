#!/bin/bash
# download_sounds.sh — يستخدم مصدرين احتياطيين + روابط مباشرة.
#
# المصادر:
#   1. Mixkit (مجاني، بدون attribution)
#   2. Pixabay (يحتاج headers)
#   3. Freesound (CC0)

set -e

SOUNDS_DIR="assets/sounds"
mkdir -p "$SOUNDS_DIR"

# User-Agent مهم لتجنب 403 من Pixabay
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# ═══════════════════════════════════════════════════════════════
# مصدر 1: Mixkit — روابط مباشرة، بدون حماية
# ═══════════════════════════════════════════════════════════════
declare -A MIXKIT_SOUNDS=(
  ["rain_soft"]="https://assets.mixkit.co/active_storage/sfx/2515/2515-preview.mp3"
  ["birds_distant"]="https://assets.mixkit.co/active_storage/sfx/18/18-preview.mp3"
  ["paper_turn"]="https://assets.mixkit.co/active_storage/sfx/1106/1106-preview.mp3"
  ["piano_gentle"]="https://assets.mixkit.co/active_storage/sfx/576/576-preview.mp3"
  ["drums_soft"]="https://assets.mixkit.co/active_storage/sfx/2516/2516-preview.mp3"
  ["harp_soft"]="https://assets.mixkit.co/active_storage/sfx/567/567-preview.mp3"
  ["whisper_gentle"]="https://assets.mixkit.co/active_storage/sfx/2517/2517-preview.mp3"
  ["flute_dawn"]="https://assets.mixkit.co/active_storage/sfx/567/567-preview.mp3"
  ["oud_soft"]="https://assets.mixkit.co/active_storage/sfx/2518/2518-preview.mp3"
  ["tibetan_bowl"]="https://assets.mixkit.co/active_storage/sfx/2519/2519-preview.mp3"
)

# ═══════════════════════════════════════════════════════════════
# مصدر 2 (احتياطي): Freesound CC0 روابط CDN
# ═══════════════════════════════════════════════════════════════
declare -A FREESOUND_BACKUP=(
  ["rain_soft"]="https://cdn.freesound.org/previews/531/531947_11187133-lq.mp3"
  ["birds_distant"]="https://cdn.freesound.org/previews/415/415209_5121236-lq.mp3"
  ["paper_turn"]="https://cdn.freesound.org/previews/240/240660_4284968-lq.mp3"
  ["piano_gentle"]="https://cdn.freesound.org/previews/352/352663_5121236-lq.mp3"
  ["drums_soft"]="https://cdn.freesound.org/previews/362/362775_5121236-lq.mp3"
  ["harp_soft"]="https://cdn.freesound.org/previews/361/361992_5121236-lq.mp3"
  ["whisper_gentle"]="https://cdn.freesound.org/previews/458/458821_5121236-lq.mp3"
  ["flute_dawn"]="https://cdn.freesound.org/previews/372/372142_5121236-lq.mp3"
  ["oud_soft"]="https://cdn.freesound.org/previews/371/371562_5121236-lq.mp3"
  ["tibetan_bowl"]="https://cdn.freesound.org/previews/475/475837_5121236-lq.mp3"
)

MIN_SIZE=3000
CURL_OPTS=(
  --fail
  --location
  --silent
  --show-error
  --max-time 60
  --retry 2
  --retry-delay 3
  --user-agent "$USER_AGENT"
)

# ═══════════════════════════════════════════════════════════════
# الدالة الرئيسية
# ═══════════════════════════════════════════════════════════════
download_sound() {
  local name="$1"
  local file="$SOUNDS_DIR/$name.mp3"
  local mime

  if [ -f "$file" ]; then
    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
    if [ "$size" -ge "$MIN_SIZE" ]; then
      echo "  ✅ $name.mp3 موجود"
      return 0
    fi
    rm -f "$file"
  fi

  # جرب Mixkit أولاً
  if [ -n "${MIXKIT_SOUNDS[$name]}" ]; then
    echo "  ⬇️  $name.mp3 (Mixkit)..."
    if curl "${CURL_OPTS[@]}" -o "$file.tmp" "${MIXKIT_SOUNDS[$name]}" 2>/dev/null; then
      if validate_mp3 "$file.tmp"; then
        mv "$file.tmp" "$file"
        echo "     ✅ ($(du -h "$file" | cut -f1))"
        return 0
      fi
      rm -f "$file.tmp"
    fi
  fi

  # جرب Freesound كاحتياطي
  if [ -n "${FREESOUND_BACKUP[$name]}" ]; then
    echo "  ⬇️  $name.mp3 (Freesound)..."
    if curl "${CURL_OPTS[@]}" -o "$file.tmp" "${FREESOUND_BACKUP[$name]}" 2>/dev/null; then
      if validate_mp3 "$file.tmp"; then
        mv "$file.tmp" "$file"
        echo "     ✅ ($(du -h "$file" | cut -f1))"
        return 0
      fi
      rm -f "$file.tmp"
    fi
  fi

  echo "     ❌ فشل من جميع المصادر"
  return 1
}

validate_mp3() {
  local file="$1"
  [ ! -f "$file" ] && return 1

  local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
  [ "$size" -lt "$MIN_SIZE" ] && return 1

  local mime=$(file -b --mime-type "$file" 2>/dev/null)
  case "$mime" in
    audio/mpeg|audio/mp3|audio/*) return 0 ;;
    *) return 1 ;;
  esac
}

# ═══════════════════════════════════════════════════════════════
# التنفيذ
# ═══════════════════════════════════════════════════════════════
echo "🎵 تحميل 10 أصوات..."
echo ""

SUCCESS=0
FAILED=0

for name in "${!MIXKIT_SOUNDS[@]}"; do
  if download_sound "$name"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo "📊 النتيجة:"
echo "   ✅ نجح: $SUCCESS"
echo "   ❌ فشل: $FAILED"
echo "═══════════════════════════════════════"

# قائمة المفقود
if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "⚠️  الأصوات المفقودة:"
  for name in "${!MIXKIT_SOUNDS[@]}"; do
    [ ! -f "$SOUNDS_DIR/$name.mp3" ] && echo "   • $name.mp3"
  done
  echo ""
  echo "📥 حمّلها يدوياً من:"
  echo "   • https://mixkit.co/free-sound-effects/"
  echo "   • https://freesound.org (ابحث عن CC0)"
  echo "   • https://pixabay.com/music/"
  exit 1
fi

echo "✅ كل الأصوات جاهزة"
