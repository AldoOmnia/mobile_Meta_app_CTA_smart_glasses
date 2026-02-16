#!/bin/bash
# Creates a new Xcode project and adds CTA Transit Assistant source files.
# Run from the mobile_Meta_app_CTA_smart_glasses directory.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "CTA Transit Assistant - Xcode Project Setup"
echo "==========================================="
echo ""

# Check for Xcode
if ! command -v xcodebuild &>/dev/null; then
    echo "Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "Manual setup steps:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Choose: iOS → App"
echo "4. Product Name: CTA Transit Assistant"
echo "5. Interface: SwiftUI | Language: Swift | Minimum: iOS 15.2"
echo "6. Save in: $PROJECT_ROOT"
echo ""
echo "7. Delete the default ContentView.swift and [AppName]App.swift"
echo "8. Right-click the project → Add Files to 'CTA Transit Assistant'"
echo "9. Select the CTATransitAssistant folder"
echo "10. Ensure 'Create groups' is selected"
echo ""
echo "11. File → Add Package Dependencies"
echo "    URL: https://github.com/facebook/meta-wearables-dat-ios"
echo ""
echo "12. In Signing & Capabilities, add:"
echo "    - Location (When In Use)"
echo "    - Bluetooth"
echo ""
echo "13. Merge Info.plist keys from CTATransitAssistant/Info.plist"
echo ""
echo "Done! See README.md for full details."
