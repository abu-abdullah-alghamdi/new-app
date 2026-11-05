#!/usr/bin/env bash
# =============================================================
#  عيادتي — تشغيل التطبيق وتحديثه على Xcode
#
#  ./scripts/dev.sh run     تجهيز المشروع وفتحه في Xcode وتشغيله
#  ./scripts/dev.sh update  سحب آخر نسخة من GitHub ثم إعادة البناء والتشغيل
#  ./scripts/dev.sh watch   مراقبة GitHub: أي تحديث جديد يُسحب ويُشغّل تلقائياً
#  ./scripts/dev.sh sim     تشغيل سريع على المحاكي من الطرفية (مع Hot Reload)
# =============================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="عيادتي"
WATCH_EVERY="${WATCH_EVERY:-30}"   # كل كم ثانية يتحقق من وجود تحديث
IOS_MIN="${IOS_MIN:-17.0}"         # أقل إصدار iOS (Xcode الجديد ما يدعم 13)

say()  { printf "\n\033[1;32m▶ %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m! %s\033[0m\n" "$*"; }
die()  { printf "\n\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

check_tools() {
  [[ "$(uname)" == "Darwin" ]] || die "هذا السكربت يشتغل على جهاز ماك فقط."
  command -v flutter >/dev/null || die "Flutter غير مثبت. ثبّته من flutter.dev ثم أعد المحاولة."
  command -v xcodebuild >/dev/null || die "Xcode غير مثبت. ثبّته من App Store."
  command -v pod >/dev/null || die "CocoaPods غير مثبت. شغّل: sudo gem install cocoapods  (أو brew install cocoapods)"
}

# يولّد مجلد iOS أول مرة ويضبط اسم التطبيق والعربية
ensure_ios() {
  # إذا مجلد iOS ناقص (مثلاً ملف مشروع Xcode مفقود) يكمّل الملفات الناقصة بدون ما يمسح شي
  if [[ ! -f ios/Runner.xcodeproj/project.pbxproj || ! -f ios/Runner/Info.plist || ! -d ios/Runner.xcworkspace ]]; then
    say "تجهيز مشروع iOS (إنشاء الملفات الناقصة)"
    flutter create --platforms=ios --org com.areem --project-name areem_clinics .
  fi
  local plist="ios/Runner/Info.plist"
  if [[ -f "$plist" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$plist" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDevelopmentRegion ar" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Delete :CFBundleLocalizations" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations array" "$plist"
    /usr/libexec/PlistBuddy -c "Add :CFBundleLocalizations:0 string ar" "$plist"
  fi
}

# يرفع أقل إصدار iOS في المشروع والمكتبات (Xcode الحديث يرفض iOS 13)
detect_ios_min() {
  local sdk_min
  sdk_min=$(plutil -extract SupportedTargets.iphoneos.MinimumDeploymentTarget raw "$(xcrun --sdk iphoneos --show-sdk-path)/SDKSettings.plist" 2>/dev/null || echo "$IOS_MIN")
  IOS_MIN=$(awk -v a="$sdk_min" -v b="$IOS_MIN" 'BEGIN{split(a,x,".");split(b,y,"."); if (x[1]+0 > y[1]+0) print a; else print b}')
}

fix_deployment_target() {
  local pbx="ios/Runner.xcodeproj/project.pbxproj"
  [[ -f "$pbx" ]] || die "ملف مشروع Xcode مفقود ($pbx). شغّل: flutter create --platforms=ios --org com.areem --project-name areem_clinics ."
  sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = $IOS_MIN;/g" "$pbx"
  /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion $IOS_MIN" ios/Flutter/AppFrameworkInfo.plist 2>/dev/null || true
  if [[ -f ios/Podfile ]]; then
    sed -i '' -E "s/^#? *platform :ios.*/platform :ios, '$IOS_MIN'/" ios/Podfile
    sed -i '' -E "s/(\[.IPHONEOS_DEPLOYMENT_TARGET.\] = )['\"][0-9.]+['\"]/\1\"$IOS_MIN\"/" ios/Podfile
    grep -q 'build_configurations.each' ios/Podfile || perl -0pi -e "s/flutter_additional_ios_build_settings\(target\)\n/flutter_additional_ios_build_settings(target)\n    target.build_configurations.each { |c| c.build_settings[\"IPHONEOS_DEPLOYMENT_TARGET\"] = \"$IOS_MIN\" }\n/" ios/Podfile
  fi
}

prepare() {
  ensure_ios
  detect_ios_min
  fix_deployment_target
  say "تحميل الحزم"
  flutter pub get
  say "تجهيز إعدادات Xcode و Pods"
  flutter build ios --config-only --debug --no-codesign
  fix_deployment_target
  if [[ -f ios/Podfile ]]; then
    (cd ios && pod install)
    sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = $IOS_MIN;/g" ios/Pods/Pods.xcodeproj/project.pbxproj 2>/dev/null || true
  fi
}

boot_simulator() {
  open -a Simulator || true
  # يشغّل أول آيفون متاح إذا ما فيه محاكي شغال
  if ! xcrun simctl list devices booted | grep -q "Booted"; then
    local dev
    dev="$(xcrun simctl list devices available | grep -E 'iPhone' | head -n1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
    [[ -n "$dev" ]] && xcrun simctl boot "$dev" 2>/dev/null || true
  fi
}

# يفتح المشروع في Xcode ويضغط Run (يوقف التشغيل السابق أول)
xcode_run() {
  say "فتح المشروع في Xcode"
  open "ios/Runner.xcworkspace"
  boot_simulator
  say "تشغيل التطبيق داخل Xcode"
  osascript <<'OSA' || warn "ما قدرت أضغط Run تلقائياً. اضغط ▶ في Xcode (أو Cmd+R)."
tell application "Xcode"
  activate
  set ws to missing value
  repeat 60 times
    try
      set ws to workspace document "Runner.xcworkspace"
      if loaded of ws is true then exit repeat
    end try
    delay 1
  end repeat
  if ws is missing value then error "Xcode workspace not ready"
  try
    stop ws
  end try
  delay 1
  run ws
end tell
OSA
  say "تم. لو Xcode طلب جهاز، اختر iPhone من القائمة اللي فوق مرة وحدة وبيتذكره."
}

has_remote() { git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; }

pull_latest() {
  has_remote || die "المشروع مو مربوط بمستودع GitHub. شوف ملف README (خطوة الربط)."
  say "سحب آخر نسخة"
  if ! git diff --quiet || ! git diff --cached --quiet; then
    warn "عندك تعديلات محلية، بحفظها مؤقتاً (git stash) قبل السحب."
    git stash push -u -m "auto-stash $(date '+%F %T')" >/dev/null
  fi
  git pull --ff-only
}

is_behind() {
  git fetch --quiet
  [[ "$(git rev-parse HEAD)" != "$(git rev-parse '@{u}')" ]]
}

cmd_run()    { check_tools; prepare; xcode_run; }
cmd_update() { check_tools; pull_latest; prepare; xcode_run; }
cmd_sim() {
  check_tools; prepare; boot_simulator
  local udid
  udid="$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -n1)"
  [[ -n "$udid" ]] || die "ما لقيت محاكي شغال. افتح Simulator وشغّل أي iPhone."
  flutter run -d "$udid"
}

cmd_watch() {
  check_tools
  has_remote || die "المشروع مو مربوط بمستودع GitHub. شوف ملف README (خطوة الربط)."
  say "وضع المراقبة شغال: أي تحديث يُرفع على GitHub بيُسحب ويتشغل تلقائياً (Ctrl+C للإيقاف)"
  cmd_run
  while true; do
    sleep "$WATCH_EVERY"
    if is_behind; then
      say "وصل تحديث جديد: $(git log --oneline -1 '@{u}')"
      pull_latest
      prepare
      xcode_run
      command -v osascript >/dev/null && osascript -e "display notification \"تم تحديث التطبيق وتشغيله\" with title \"$APP_NAME\"" || true
    fi
  done
}

case "${1:-run}" in
  run)    cmd_run ;;
  update) cmd_update ;;
  watch)  cmd_watch ;;
  sim)    cmd_sim ;;
  *) echo "الاستخدام: $0 [run|update|watch|sim]"; exit 1 ;;
esac
