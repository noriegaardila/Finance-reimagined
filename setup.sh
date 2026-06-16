#!/usr/bin/env bash
# Finance Reimagined — one-time project setup
# Run this after cloning the repo on a Mac with Flutter installed.
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

check() { command -v "$1" &>/dev/null; }

echo ""
echo "======================================"
echo "  Finance Reimagined — setup"
echo "======================================"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────────────────

if ! check flutter; then
  echo -e "${RED}✗ Flutter not found.${NC}"
  echo "  Install it from https://docs.flutter.dev/get-started/install/macos"
  exit 1
fi
echo -e "${GREEN}✓ Flutter found${NC}: $(flutter --version --machine 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["flutterVersion"])' 2>/dev/null || flutter --version | head -1)"

if ! check xcodebuild; then
  echo -e "${RED}✗ Xcode not found.${NC}"
  echo "  Install Xcode from the Mac App Store, then run:"
  echo "    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi
echo -e "${GREEN}✓ Xcode found${NC}: $(xcodebuild -version | head -1)"

# ── Scaffold missing iOS/Android platform files ────────────────────────────────
# flutter create in an existing directory only ADDS missing files;
# it will not overwrite lib/, pubspec.yaml, or existing iOS files.

echo ""
echo "Scaffolding missing platform files (ios/, android/)..."
flutter create \
  --org com.noriegaardila \
  --project-name finance_reimagined \
  --platforms ios,android \
  . 2>&1 | grep -v "^  •"

# ── Restore our custom Info.plist (flutter create may have overwritten it) ──────

PLIST_BACKUP="ios/Runner/Info.plist"
if ! grep -q "fintrack" "$PLIST_BACKUP" 2>/dev/null; then
  echo ""
  echo -e "${YELLOW}Restoring custom Info.plist (URL scheme registration)...${NC}"
  cat > ios/Runner/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Finance</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>finance_reimagined</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.noriegaardila.fintrack</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>fintrack</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
PLIST
  echo -e "${GREEN}✓ Info.plist restored${NC}"
fi

# ── Install packages ────────────────────────────────────────────────────────────

echo ""
echo "Installing Flutter packages..."
flutter pub get

# ── CocoaPods ──────────────────────────────────────────────────────────────────

if check pod; then
  echo ""
  echo "Installing CocoaPods dependencies..."
  (cd ios && pod install --silent)
  echo -e "${GREEN}✓ Pods installed${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠ CocoaPods not found. Install it with:${NC}"
  echo "    sudo gem install cocoapods"
  echo "  Then run: cd ios && pod install"
fi

# ── Done ───────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}======================================"
echo "  Setup complete!"
echo -e "======================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Open Xcode:  open ios/Runner.xcworkspace"
echo "  2. In Xcode → Signing & Capabilities → select your Apple ID team"
echo "  3. Connect your iPhone via USB and trust this Mac on the phone"
echo "  4. Back in terminal: flutter run"
echo ""
echo "Or skip Xcode and run directly:"
echo "  flutter run -d <your-device-id>"
echo "  (list devices with: flutter devices)"
echo ""
