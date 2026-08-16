#!/bin/bash
# Builds the OTA install page (dist/) from the exported IPA.
set -euo pipefail

BASE_URL="https://solec0der.github.io/timewallet"
BUNDLE_ID="com.solecoder.timewallet"
IPA="$(ls build/export/*.ipa | head -1)"

mkdir -p dist
cp "$IPA" dist/TimeWallet.ipa

cat > dist/manifest.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key><string>software-package</string>
          <key>url</key><string>${BASE_URL}/TimeWallet.ipa</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key><string>${BUNDLE_ID}</string>
        <key>bundle-version</key><string>1.3</string>
        <key>kind</key><string>software</string>
        <key>title</key><string>TimeWallet</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
EOF

cat > dist/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TimeWallet — install</title>
<style>
  body { font-family: -apple-system, sans-serif; display: flex; flex-direction: column;
         align-items: center; justify-content: center; min-height: 90vh; gap: 1.5rem;
         background: #0d1117; color: #e6edf3; text-align: center; padding: 1rem; }
  a.btn { background: #2da44e; color: #fff; text-decoration: none; font-size: 1.4rem;
          padding: 1rem 2.5rem; border-radius: 14px; font-weight: 600; }
  p { color: #8b949e; max-width: 28rem; }
</style>
</head>
<body>
  <h1>⏳ TimeWallet</h1>
  <a class="btn" href="itms-services://?action=download-manifest&amp;url=${BASE_URL}/manifest.plist">Install on iPhone</a>
  <p>Open this page in Safari on the registered iPhone, tap install, then confirm
     in Settings if prompted. Dev-signed build — valid for 1 year.</p>
</body>
</html>
EOF

echo "dist/ ready: $(ls -lh dist)"
