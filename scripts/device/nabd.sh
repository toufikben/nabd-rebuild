#!/usr/bin/env bash
# أدوات adb لاختبار نبض على هاتف حقيقي. انظر docs/DEVICE_TEST_PLAN.md
#   scripts/device/nabd.sh <command> [args]
set -euo pipefail

PKG=com.nabd.journal
ACT=$PKG/.MainActivity
OUT=${NABD_OUT:-device-test-output}
ADB=${ADB:-adb}

mkdir -p "$OUT"

pid() { $ADB shell pidof "$PKG" 2>/dev/null | tr -d '\r' || true; }

case "${1:-help}" in
  devices)    $ADB devices -l ;;
  info)
    $ADB shell getprop ro.product.model
    $ADB shell getprop ro.build.version.release
    $ADB shell getprop ro.build.version.sdk
    $ADB shell dumpsys package "$PKG" | grep -E 'versionName|versionCode|firstInstallTime|lastUpdateTime' || echo "not installed"
    # Screenshots, run-as and the test hooks need a debuggable build.
    if $ADB shell dumpsys package "$PKG" | grep -q 'DEBUGGABLE'; then
      echo "build: debuggable"
    else
      echo "build: NOT debuggable (store/release build: screenshots stay black)"
    fi
    ;;
  install)    # install <apk> — يثبّت فوق نسخة debug سابقة دون حذف البيانات
    $ADB install -r "${2:?apk path}" ;;
  uninstall)  # تحذير: يحذف كل بيانات التطبيق
    $ADB uninstall "$PKG" ;;
  shots-on)   # يسمح بلقطات الشاشة في نسخة debug فقط (FLAG_SECURE يُتجاوز)
    $ADB shell setprop debug.nabd.screenshots 1 && echo "restart the app for it to apply" ;;
  shots-off)  $ADB shell setprop debug.nabd.screenshots 0 ;;
  start)      $ADB shell am start -n "$ACT" ;;
  cold)       # تشغيل بارد مع قياس الزمن
    $ADB shell am force-stop "$PKG"; $ADB shell am start -W -n "$ACT" ;;
  stop)       # تحذير: force-stop يلغي منبّهات التطبيق كلها في أندرويد؛ لاختبار
              # التذكيرات استعمل bg بدلًا منه
    $ADB shell am force-stop "$PKG" ;;
  bg)         # إلى الخلفية ثم قتل العملية كما يفعل النظام؛ المنبّهات تبقى
    $ADB shell input keyevent KEYCODE_HOME; sleep 1; $ADB shell am kill "$PKG" ;;
  kill)       # قتل العملية كما يفعل النظام عند نقص الذاكرة (يحفظ الحالة)
    $ADB shell am kill "$PKG" ;;
  clear)      # تحذير: يمسح كل البيانات (يبدأ التطبيق كأنه جديد)
    $ADB shell pm clear "$PKG" ;;
  link)       # link <uri>  مثال: nabd://editor  nabd://garden  nabd://calendar
    $ADB shell am start -a android.intent.action.VIEW -d "${2:?uri}" "$PKG" ;;
  shot)       # shot <name>
    f="$OUT/${2:-shot}-$(date +%H%M%S).png"
    $ADB exec-out screencap -p > "$f" && echo "$f" ;;
  record)     # record <name> [seconds]  (افتراضي 20 ث)
    $ADB shell screenrecord --time-limit "${3:-20}" /sdcard/nabd.mp4
    $ADB pull /sdcard/nabd.mp4 "$OUT/${2:-rec}-$(date +%H%M%S).mp4" >/dev/null
    $ADB shell rm /sdcard/nabd.mp4 ;;
  ui)         # يفرّغ شجرة الواجهة (نصوص وإحداثيات الأزرار) لتحديد مكان النقر
    $ADB shell uiautomator dump /sdcard/ui.xml >/dev/null
    $ADB exec-out cat /sdcard/ui.xml > "$OUT/ui.xml"
    # awk, not python: Git Bash on Windows has awk but often no python3.
    tr '\n' ' ' < "$OUT/ui.xml" | sed 's/<node /\n<node /g' | awk '
      function attr(name,   m) {
        if (match($0, name "=\"[^\"]*\"")) {
          m = substr($0, RSTART + length(name) + 2, RLENGTH - length(name) - 3)
          return m
        }
        return ""
      }
      /^<node / {
        text = attr("text"); desc = attr("content-desc")
        click = index($0, "clickable=\"true\"") > 0
        b = attr("bounds")
        if ((text == "" && desc == "" && !click) || b == "") next
        gsub(/[\[\]]/, " ", b); gsub(/,/, " ", b)
        split(b, v, " ")
        label = (text != "" ? text : desc)
        printf "(%4d,%4d) %s%s\n", (v[1]+v[3])/2, (v[2]+v[4])/2, (click ? "[btn] " : ""), substr(label, 1, 60)
      }'
    ;;
  tap)        $ADB shell input tap "${2:?x}" "${3:?y}" ;;
  swipe)      $ADB shell input swipe "$2" "$3" "$4" "$5" "${6:-300}" ;;
  text)       # نص لاتيني فقط؛ adb لا يكتب العربية (استعمل الحافظة أو لوحة المفاتيح)
    $ADB shell input text "$(printf '%s' "${2:?text}" | sed 's/ /%s/g')" ;;
  key)        $ADB shell input keyevent "${2:?keycode e.g. KEYCODE_BACK}" ;;
  back)       $ADB shell input keyevent KEYCODE_BACK ;;
  home)       $ADB shell input keyevent KEYCODE_HOME ;;
  recents)    $ADB shell input keyevent KEYCODE_APP_SWITCH ;;
  log)        # log [seconds] — سجل التطبيق فقط
    p=$(pid); [ -z "$p" ] && { echo "app not running"; exit 1; }
    timeout "${2:-30}" $ADB logcat --pid="$p" -v time | tee "$OUT/logcat-$(date +%H%M%S).txt" || true ;;
  errors)     # أخطاء Flutter/Dart والأعطال منذ آخر مسح للسجل
    $ADB logcat -d -v time | grep -E "flutter|AndroidRuntime|FATAL|E/$PKG|Exception" | tail -n "${2:-80}" ;;
  logclear)   $ADB logcat -c ;;
  alarms)     # التذكيرات المجدولة (الإشعار اليومي والأسبوعي والرسائل)
    $ADB shell dumpsys alarm | grep -A4 "$PKG" | head -60 ;;
  notifs)     $ADB shell dumpsys notification --noredact | grep -A12 "pkg=$PKG" | head -80 ;;
  perm-notif) $ADB shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS ;;
  revoke-notif) $ADB shell pm revoke "$PKG" android.permission.POST_NOTIFICATIONS ;;
  time)       $ADB shell date ;;
  files)      # ملفات التطبيق (تعمل لأن النسخة debuggable)
    $ADB shell run-as "$PKG" find . -maxdepth 4 -type f -exec ls -la {} \; ;;
  peek)       # peek <path> — أول بايتات ملف داخل التطبيق (للتأكد أن الوسائط مشفرة)
    $ADB shell run-as "$PKG" head -c 64 "${2:?relative path}" | xxd | head -4 ;;
  pull-backup) # يسحب ملفات .nabd التي صُدّرت إلى التنزيلات
    $ADB shell ls -la /sdcard/Download/ | grep -i nabd || true
    for f in $($ADB shell ls /sdcard/Download/ | tr -d '\r' | grep -i '\.nabd$'); do
      $ADB pull "/sdcard/Download/$f" "$OUT/" ; done ;;
  mem)        $ADB shell dumpsys meminfo "$PKG" | sed -n '1,30p' ;;
  gfx)        # gfx — إحصاءات الإطارات (jank) منذ آخر reset
    $ADB shell dumpsys gfxinfo "$PKG" | grep -E "Total frames|Janky|percentile" ;;
  gfx-reset)  $ADB shell dumpsys gfxinfo "$PKG" reset >/dev/null ;;
  locale)     # locale ar|en — افتح الإعدادات لتغيير لغة النظام
    $ADB shell am start -a android.settings.LOCALE_SETTINGS ;;
  dark)       $ADB shell cmd uimode night "${2:-yes}" ;;
  font)       # font 1.3 — حجم خط النظام (1.0 للعودة)
    $ADB shell settings put system font_scale "${2:-1.0}" ;;
  reboot)     $ADB reboot && $ADB wait-for-device && echo "device back" ;;
  *)
    sed -n '2,4p' "$0"
    grep -E '^  [a-z-]+\)' "$0" | sed 's/).*#/  —/; s/)//' ;;
esac
