#!/usr/bin/env bash
# Import Distribution cert + provisioning profile on GitHub Actions macOS runner.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

: "${IOS_DIST_P12_BASE64:?IOS_DIST_P12_BASE64 is required}"
: "${IOS_DIST_P12_PASSWORD:?IOS_DIST_P12_PASSWORD is required}"
: "${IOS_PROVISION_PROFILE_BASE64:?IOS_PROVISION_PROFILE_BASE64 is required}"
: "${IOS_TEAM_ID:?IOS_TEAM_ID is required}"
: "${IOS_PROVISIONING_PROFILE_NAME:?IOS_PROVISIONING_PROFILE_NAME is required}"

PROFILE_NAME="$IOS_PROVISIONING_PROFILE_NAME"
KEYCHAIN_NAME="${IOS_KEYCHAIN_NAME:-build.keychain-db}"
KEYCHAIN_PATH="$HOME/Library/Keychains/$KEYCHAIN_NAME"
KEYCHAIN_PASSWORD="${IOS_KEYCHAIN_PASSWORD:-$(openssl rand -base64 32)}"

WORKDIR="${RUNNER_TEMP:-/tmp}/ios-sign"
mkdir -p "$WORKDIR"
P12_PATH="$WORKDIR/dist.p12"
PROFILE_PATH="$WORKDIR/profile.mobileprovision"

decode_base64_to_file() {
  local data="$1" out="$2"
  printf '%s' "$data" | tr -d ' \t\r\n' | base64 -D >"$out"
}

P12_PASSWORD="$(printf '%s' "$IOS_DIST_P12_PASSWORD" | tr -d '\r\n')"

decode_base64_to_file "$IOS_DIST_P12_BASE64" "$P12_PATH"
decode_base64_to_file "$IOS_PROVISION_PROFILE_BASE64" "$PROFILE_PATH"

if ! openssl pkcs12 -in "$P12_PATH" -noout -passin "pass:${P12_PASSWORD}" 2>/dev/null; then
  echo "error: p12 does not match IOS_DIST_P12_PASSWORD (check base64 and password secret)"
  exit 1
fi
echo "p12 password OK ($(wc -c <"$P12_PATH" | tr -d ' ') bytes)"

P12_APPLE="$WORKDIR/dist-apple.p12"
openssl pkcs12 -in "$P12_PATH" -passin "pass:${P12_PASSWORD}" -nocerts -nodes -out "$WORKDIR/key.pem"
openssl pkcs12 -in "$P12_PATH" -passin "pass:${P12_PASSWORD}" -clcerts -nokeys -out "$WORKDIR/cert.pem"
openssl pkcs12 -export -legacy -inkey "$WORKDIR/key.pem" -in "$WORKDIR/cert.pem" \
  -passout "pass:${P12_PASSWORD}" -out "$P12_APPLE"
P12_PATH="$P12_APPLE"
echo "repacked p12 for macOS keychain ($(wc -c <"$P12_PATH" | tr -d ' ') bytes)"

WWDR_PATH="$WORKDIR/AppleWWDRCAG3.cer"
curl -fsSL "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer" -o "$WWDR_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain-db
security default-keychain -s "$KEYCHAIN_PATH"

security import "$WWDR_PATH" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security
security import "$P12_PATH" -k "$KEYCHAIN_PATH" -P "$P12_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/xcodebuild
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" || true

PROFILE_UUID="$(
  security cms -D -i "$PROFILE_PATH" 2>/dev/null | plutil -extract UUID raw -o - -
)"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
cp "$PROFILE_PATH" "$PROFILE_DIR/${PROFILE_UUID}.mobileprovision"

BUNDLE_ID="luozhilin.com.trans.transaction"
export IOS_TEAM_ID PROFILE_NAME BUNDLE_ID
python3 - <<'PY'
import os
from pathlib import Path

team = os.environ["IOS_TEAM_ID"]
profile = os.environ["PROFILE_NAME"]
bundle = os.environ["BUNDLE_ID"]
path = Path("transaction.xcodeproj/project.pbxproj")
text = path.read_text()
marker = f"PRODUCT_BUNDLE_IDENTIFIER = {bundle};"
blocks = text.split("buildSettings = {")
if len(blocks) < 2:
    raise SystemExit("no build settings in project")
rewritten = [blocks[0]]
patched = 0
for block in blocks[1:]:
    if marker in block.split("name = ", 1)[0]:
        block = block.replace("CODE_SIGN_STYLE = Automatic;", "CODE_SIGN_STYLE = Manual;", 1)
        block = block.replace("DEVELOPMENT_TEAM = 3FA7WCR8G7;", f"DEVELOPMENT_TEAM = {team};", 1)
        identity = '\t\t\t\tCODE_SIGN_IDENTITY = "Apple Distribution";\n\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";\n'
        specifier = f'\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{profile}";\n'
        block = block.replace(marker, identity + specifier + marker, 1)
        patched += 1
    rewritten.append("buildSettings = {" + block)
if patched != 2:
    raise SystemExit(f"expected 2 app signing configs, patched {patched}")
path.write_text("".join(rewritten))
PY

EXPORT_PLIST="ios/ExportOptions.ci.plist"
mkdir -p ios
cat >"$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>${IOS_TEAM_ID}</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>${BUNDLE_ID}</key>
    <string>${PROFILE_NAME}</string>
  </dict>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

printf '%s' "$KEYCHAIN_PASSWORD" >"${RUNNER_TEMP}/ios_keychain_password"
printf '%s' "$KEYCHAIN_PATH" >"${RUNNER_TEMP}/ios_keychain_path"
chmod 600 "${RUNNER_TEMP}/ios_keychain_password" "${RUNNER_TEMP}/ios_keychain_path"

echo "Keychain: $KEYCHAIN_NAME"
echo "Profile: $PROFILE_NAME (UUID $PROFILE_UUID)"
echo "Bundle ID: $BUNDLE_ID"
security find-identity -v -p codesigning "$KEYCHAIN_PATH" || true
