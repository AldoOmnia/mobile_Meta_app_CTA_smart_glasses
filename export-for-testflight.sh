#!/bin/bash
# Export CTA Transit Assistant for TestFlight (skips dSYM upload to avoid Meta DAT errors)
# Run after: Product → Archive in Xcode
#
# Usage:
#   ./export-for-testflight.sh                    # uses latest archive
#   ./export-for-testflight.sh /path/to/archive.xcarchive

set -e
cd "$(dirname "$0")"

if [ -n "$1" ]; then
  ARCHIVE="$1"
else
  # Find most recent CTAAssistant archive
  ARCHIVES_DIR=~/Library/Developer/Xcode/Archives
  ARCHIVE=$(find "$ARCHIVES_DIR" -name "*.xcarchive" -path "*CTAAssistant*" -print0 2>/dev/null | xargs -0 ls -td 2>/dev/null | head -1)
  if [ -z "$ARCHIVE" ]; then
    echo "No CTAAssistant archive found in $ARCHIVES_DIR"
    echo "Run Product → Archive in Xcode first, then:"
    echo "  ./export-for-testflight.sh"
    echo "Or pass the archive path:"
    echo "  ./export-for-testflight.sh /path/to/archive.xcarchive"
    exit 1
  fi
  echo "Using archive: $ARCHIVE"
fi

EXPORT_DIR="./TestFlightExport"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

echo "Exporting (uploadSymbols=false to skip MWDAT dSYM errors)..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist ExportOptions-TestFlight.plist

IPA=$(find "$EXPORT_DIR" -name "*.ipa" | head -1)
echo ""
echo "✓ Export complete: $IPA"
echo ""
echo "Next: Open Transporter and drag this file to upload to App Store Connect."
echo "      (Transporter skips dSYM upload, so no MWDAT errors.)"
open -R "$IPA"
