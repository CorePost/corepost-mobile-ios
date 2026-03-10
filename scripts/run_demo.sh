#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.derived-data}"
SERVER_ADDRESS="${DEMO_SERVER_ADDRESS:-}"
ADMIN_TOKEN="${DEMO_ADMIN_TOKEN:-}"
DISPLAY_NAME="${DEMO_DISPLAY_NAME:-iPhone демо}"
VIDEO_PATH="${DEMO_VIDEO_PATH:-$ROOT_DIR/docs/demo/video/corepost-ios-demo.mp4}"
RESULT_BUNDLE_PATH="${DEMO_RESULT_BUNDLE_PATH:-$ROOT_DIR/build_artifacts/CorePostMobileIOSDemo.xcresult}"
SCREENSHOT_DIR="${DEMO_SCREENSHOT_DIR:-$ROOT_DIR/docs/demo/screenshots}"

if [[ -z "$SERVER_ADDRESS" || -z "$ADMIN_TOKEN" ]]; then
  echo "Set DEMO_SERVER_ADDRESS and DEMO_ADMIN_TOKEN before running." >&2
  exit 1
fi

mkdir -p "$SCREENSHOT_DIR" "$(dirname "$VIDEO_PATH")" "$(dirname "$RESULT_BUNDLE_PATH")"
rm -rf "$DERIVED_DATA_PATH" "$RESULT_BUNDLE_PATH"
rm -f "$VIDEO_PATH"

(
  cd "$ROOT_DIR"
  xcodegen generate
)
xcodebuild build-for-testing \
  -project "$ROOT_DIR/CorePostMobileIOS.xcodeproj" \
  -scheme CorePostMobileIOS \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME"

SIMULATOR_ID="$(xcrun simctl list devices available | awk -F '[()]' -v name="$SIMULATOR_NAME" '$1 ~ name {print $2; exit}')"

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "Simulator '$SIMULATOR_NAME' not found." >&2
  exit 1
fi

xcrun simctl boot "$SIMULATOR_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b

XCTESTRUN_PATH="$(find "$DERIVED_DATA_PATH/Build/Products" -name '*.xctestrun' | head -n 1)"
PATCHED_XCTESTRUN="$DERIVED_DATA_PATH/Build/Products/CorePostMobileIOS-demo.xctestrun"
cp "$XCTESTRUN_PATH" "$PATCHED_XCTESTRUN"

set_plist_string() {
  local key="$1"
  local value="$2"

  /usr/libexec/PlistBuddy -c "Delete :CorePostMobileIOSUITests:UITargetAppEnvironmentVariables:$key" "$PATCHED_XCTESTRUN" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :CorePostMobileIOSUITests:UITargetAppEnvironmentVariables:$key string $value" "$PATCHED_XCTESTRUN"
}

set_plist_string "DEMO_SERVER_ADDRESS" "$SERVER_ADDRESS"
set_plist_string "DEMO_ADMIN_TOKEN" "$ADMIN_TOKEN"
set_plist_string "DEMO_DISPLAY_NAME" "$DISPLAY_NAME"

xcrun simctl io "$SIMULATOR_ID" recordVideo "$VIDEO_PATH" >/tmp/corepost-ios-video.log 2>&1 &
RECORDER_PID=$!
trap 'kill -INT $RECORDER_PID >/dev/null 2>&1 || true' EXIT

xcodebuild test-without-building \
  -xctestrun "$PATCHED_XCTESTRUN" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -only-testing:CorePostMobileIOSUITests/CorePostMobileIOSUITests/testDemoFlow \
  -resultBundlePath "$RESULT_BUNDLE_PATH"

kill -INT "$RECORDER_PID" >/dev/null 2>&1 || true
wait "$RECORDER_PID" 2>/dev/null || true
trap - EXIT

rm -f "$SCREENSHOT_DIR"/*.png "$SCREENSHOT_DIR"/manifest.json
xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE_PATH" \
  --output-path "$SCREENSHOT_DIR"

if [[ -f "$SCREENSHOT_DIR/manifest.json" ]]; then
  while IFS=$'\t' read -r exported suggested; do
    clean_name="${suggested%%_0_*}"
    mv "$SCREENSHOT_DIR/$exported" "$SCREENSHOT_DIR/$clean_name.png"
  done < <(jq -r '.[].attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' "$SCREENSHOT_DIR/manifest.json")
fi

echo "Demo video: $VIDEO_PATH"
echo "Screenshots: $SCREENSHOT_DIR"
