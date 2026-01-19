#!/usr/bin/env bash
#!/usr/bin/env bash
# Copyright (C) 2026 ProcessLeash contributors
# Licensed under the GNU General Public License v3.0
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ProcessLeash"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
INFO_PLIST="${ROOT_DIR}/Packaging/Info.plist"
DMG_STAGING="${DIST_DIR}/dmg_root"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

# Optional signing / notarization env vars:
# CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
# APPLE_ID="appleid@example.com"
# TEAM_ID="TEAMID"
# NOTARY_PASSWORD="app-specific-password-or-keychain-item"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Warning: xcodebuild not found. Codesign/notarization may fail."
fi

echo "Building release binary…"
swift build -c release

BIN_PATH="${ROOT_DIR}/.build/release/${APP_NAME}"
if [[ ! -x "${BIN_PATH}" ]]; then
  echo "Binary not found at ${BIN_PATH}" >&2
  exit 1
fi

echo "Generating icon…"
"${ROOT_DIR}/scripts/generate_icon.sh"

echo "Staging app bundle at ${APP_DIR}"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

cp "${INFO_PLIST}" "${APP_DIR}/Contents/Info.plist"
cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
if [[ -f "${ROOT_DIR}/Packaging/AppIcon.icns" ]]; then
  cp "${ROOT_DIR}/Packaging/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi
if [[ -f "${ROOT_DIR}/Packaging/AppIcon.png" ]]; then
  cp "${ROOT_DIR}/Packaging/AppIcon.png" "${APP_DIR}/Contents/Resources/AppIcon.png"
fi
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  echo "Codesigning app with identity: ${CODESIGN_IDENTITY}"
  codesign --force --deep --options runtime --sign "${CODESIGN_IDENTITY}" "${APP_DIR}"
else
  echo "Skipping codesign: CODESIGN_IDENTITY not set"
fi

echo "Creating dmg staging at ${DMG_STAGING}"
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"
cp -R "${APP_DIR}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

echo "Creating dmg at ${DMG_PATH}"
mkdir -p "${DIST_DIR}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_STAGING}" -ov -format UDZO "${DMG_PATH}"

if [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${NOTARY_PASSWORD:-}" ]]; then
  echo "Submitting for notarization…"
  xcrun notarytool submit "${DMG_PATH}" --apple-id "${APPLE_ID}" --team-id "${TEAM_ID}" --password "${NOTARY_PASSWORD}" --wait
  echo "Stapling ticket…"
  xcrun stapler staple "${DMG_PATH}"
else
  echo "Skipping notarization: set APPLE_ID, TEAM_ID, NOTARY_PASSWORD to enable."
fi

echo "Done. DMG: ${DMG_PATH}"
