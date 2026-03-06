#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_DISPLAY_NAME="CutCopy"
APP_BUNDLE_NAME="${APP_DISPLAY_NAME}.app"
APP_EXECUTABLE_NAME="${APP_DISPLAY_NAME}"
PRODUCT_EXECUTABLE_NAME="CutCopyApp"
DIST_DIR="${PROJECT_ROOT}/dist"
APP_DIR="${DIST_DIR}/${APP_BUNDLE_NAME}"
INSTALL_DIR="${HOME}/Applications"

install_after_build=false
if [[ "${1:-}" == "--install" ]]; then
  install_after_build=true
fi

cd "${PROJECT_ROOT}"

echo "[1/4] Building release binary..."
swift build -c release --product "${PRODUCT_EXECUTABLE_NAME}" >/dev/null
BIN_DIR="$(swift build -c release --show-bin-path)"
PRODUCT_BIN_PATH="${BIN_DIR}/${PRODUCT_EXECUTABLE_NAME}"

if [[ ! -x "${PRODUCT_BIN_PATH}" ]]; then
  echo "Release binary not found: ${PRODUCT_BIN_PATH}" >&2
  exit 1
fi

echo "[2/4] Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${PRODUCT_BIN_PATH}" "${APP_DIR}/Contents/MacOS/${APP_EXECUTABLE_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_EXECUTABLE_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>CutCopy</string>
  <key>CFBundleExecutable</key>
  <string>CutCopy</string>
  <key>CFBundleIdentifier</key>
  <string>com.zhaowenhao.cutcopy</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>CutCopy</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "[3/4] Codesigning (ad-hoc)..."
if ! codesign --force --deep --sign - "${APP_DIR}" >/dev/null 2>&1; then
  echo "Warning: ad-hoc codesign failed, app may still run locally." >&2
fi

if [[ "${install_after_build}" == "true" ]]; then
  echo "[4/4] Installing to ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_DIR}"
  rm -rf "${INSTALL_DIR}/${APP_BUNDLE_NAME}"
  cp -R "${APP_DIR}" "${INSTALL_DIR}/${APP_BUNDLE_NAME}"
  echo "Done: ${INSTALL_DIR}/${APP_BUNDLE_NAME}"
else
  echo "[4/4] Skipping install (pass --install to copy into ~/Applications)."
  echo "Done: ${APP_DIR}"
fi
