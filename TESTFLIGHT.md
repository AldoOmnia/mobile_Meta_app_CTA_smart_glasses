# TestFlight Build Guide

**Meta Wearables docs:** [Build integration (iOS)](https://wearables.developer.meta.com/docs/build-integration-ios) | [Develop](https://wearables.developer.meta.com/docs/develop/)

## 1. Use a Supported Xcode Version

**"Unsupported SDK or Xcode version"** means you built with a beta or unsupported Xcode.

- **For App Store & TestFlight submission:** Use the latest **Release Candidate** (not beta).
- Check: [Apple Developer Releases](https://developer.apple.com/news/releases/)
- As of Feb 2026: Use **Xcode 26.3 Release Candidate** for submission.
- Do **not** use Xcode 26.4 beta for App Store submission (beta is for TestFlight internal testing only).

**Fix:** Download Xcode 26.3 RC from [developer.apple.com/download](https://developer.apple.com/download/applications), set it as the active developer directory, and rebuild:

```bash
sudo xcode-select -s /Applications/Xcode-26.3-RC.app/Contents/Developer
```

---

## 2. Meta DAT dSYM / Upload Symbols Failed

The Meta Wearables DAT frameworks (MWDATCamera, MWDATCore, MWDATMockDevice) do not ship with dSYM files. Xcode reports:

> "The archive did not include a dSYM for MWDAT*.framework with the UUIDs [...]"

**Fix:** Do **not** use Xcode’s "Distribute App → App Store Connect" (it always tries to upload symbols). Instead, export with symbols disabled and upload via **Transporter**.

---

### Step-by-step: export IPA without dSYM upload

**Important:** Do **not** click "Distribute App" in Xcode. That uploads a build first (which can use your build number) and then fails on dSYM. If you do that, you'll get "Redundant Binary Upload" when you later use Transporter—and you'll need to bump the build number again. Use **only** the flow below.

#### 1. Archive in Xcode
- **Product → Archive**
- Wait for the archive to finish.
- **Do not click "Distribute App"** — close the Organizer or cancel.

#### 2. Export with the custom plist (Terminal)

Open Terminal, `cd` to your project folder, then run:

```bash
# Replace with your actual archive path (find it in Xcode Organizer)
ARCHIVE=~/Library/Developer/Xcode/Archives/2026-02-16/CTAAssistant\ 16-2-26,\ 11.00.xcarchive

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath ./TestFlightExport \
  -exportOptionsPlist ExportOptions-TestFlight.plist
```

To find your archive path:
- Open **Window → Organizer** in Xcode.
- Right‑click your archive → **Show in Finder**.
- Drag the archive into Terminal to paste its path.

#### 3. Upload with Transporter
- Open **Transporter** (install from Mac App Store if needed).
- Drag `TestFlightExport/CTAAssistant.ipa` into Transporter.
- Click **Deliver**.

The IPA will upload to App Store Connect without the dSYM step, so you won’t see the MWDAT symbols errors.

---

---

## 3. Summary

| Issue | Fix |
|-------|-----|
| Unsupported SDK/Xcode | Use Xcode 26.3 RC (or latest RC) for submission |
| MWDAT dSYM / Upload Symbols Failed | Archive → export via Terminal script → upload via Transporter only. Never click "Distribute App". |
| Redundant Binary Upload | Build number already used (e.g. by a failed Xcode upload). Bump `CURRENT_PROJECT_VERSION` and re-archive. |
