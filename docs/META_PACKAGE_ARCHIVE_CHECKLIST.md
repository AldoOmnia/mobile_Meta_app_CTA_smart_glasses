# Meta DAT Package in Archive – Checklist & Troubleshooting

Your CTO asked whether the Meta package is being installed in the archive. This doc walks through how to verify inclusion and fix common exclusion issues.

---

## 1. Current Status: Package *Is* Included

Evidence from your last successful export:

- **DistributionSummary.plist** lists: `MWDATCamera.framework`, `MWDATCore.framework`, `MWDATMockDevice.framework`
- **Packaging.log** shows the frameworks copied into the app bundle during export
- **project.pbxproj** correctly links all three packages to the CTAAssistant target

So the Meta package **is** being archived. If you're seeing "0 builds available" or Invalid Binary, that is likely due to **Apple processing** (e.g. ITMS-91061 privacy manifest), not missing frameworks.

---

## 2. Build Settings to Verify (Xcode)

Open the project in Xcode and check the following.

### 2.1 Package Dependencies

1. Select the **CTAAssistant** project (blue icon) in the navigator.
2. Select the **CTAAssistant** target.
3. Open the **General** tab → **Frameworks, Libraries, and Embedded Content**.
4. Confirm: `MWDATCamera`, `MWDATCore`, `MWDATMockDevice` are listed.
5. For each: status should be **Embed & Sign** (or **Embed Without Signing** if you use manual signing; embedding is required for dynamic frameworks).

**Alternative path:** **Package Dependencies** (project level) → `meta-wearables-dat-ios` → ensure it resolves to a valid version (e.g. 0.4.0).

### 2.2 Build Phases

1. Select **CTAAssistant** target → **Build Phases**.
2. In **Link Binary With Libraries**, confirm:
   - MWDATCamera  
   - MWDATCore  
   - MWDATMockDevice  

If any are missing, use **+** and add them from the package.

3. In **Embed Frameworks** (or **Embed App Extensions** if present):
   - The MWDAT frameworks should appear here if they’re dynamic.
   - If the section is missing and the app runs on device, Xcode may be handling embedding automatically via SPM.

### 2.3 Build Configuration

1. **Product → Scheme → Edit Scheme** (or ⌘<).
2. Under **Archive**, set **Build Configuration** to **Release** (not Debug).
3. Ensure **Reveal Archive in Organizer** is checked.

### 2.4 Configuration-Specific Checks

1. Select the **CTAAssistant** target → **Build Settings**.
2. Ensure **Show: All** and **Combined**.
3. Search for:
   - **ONLY_ACTIVE_ARCH**: For Release/Archive this should typically be **No** (so all device architectures are built).
   - **EXCLUDED_ARCHS**: Should be empty for `iphoneos` when archiving for device.
   - **ENABLE_BITCODE**: Deprecated; can be ignored.
   - **BUILD_LIBRARY_FOR_DISTRIBUTION**: Optional; not required for the Meta package.

---

## 3. Steps to Force Package Inclusion on Archive

If a clean archive ever omits the package, run:

### 3.1 Reset SPM and Derived Data

```bash
# Quit Xcode first

# Clear derived data for this project
rm -rf ~/Library/Developer/Xcode/DerivedData/*CTAAssistant*

# Clear SPM cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reopen project and let Xcode resolve packages
```

### 3.2 Resolve Packages Before Archiving

1. **File → Packages → Reset Package Caches** (or **Resolve Package Versions**).
2. Wait until resolution completes (spinner in navigator).
3. Then: **Product → Archive**.

### 3.3 Archive via Command Line (Explicit Resolution)

```bash
cd /path/to/mobile_Meta_app_CTA_smart_glasses/CTATransitAssistant/CTAAssistant

# Resolve packages first
xcodebuild -resolvePackageDependencies -project CTAAssistant.xcodeproj -scheme CTAAssistant

# Archive (use same scheme and project)
xcodebuild archive \
  -project CTAAssistant.xcodeproj \
  -scheme CTAAssistant \
  -archivePath ~/Desktop/CTAAssistant.xcarchive \
  -configuration Release
```

---

## 4. Verify Package Is in the Archive

After **Product → Archive**:

1. **Window → Organizer**.
2. Select the newest archive.
3. Right‑click → **Show in Finder**.
4. Right‑click the `.xcarchive` → **Show Package Contents**.
5. Open: `Products/Applications/CTAAssistant.app/Frameworks/`.
6. Confirm presence of:
   - `MWDATCamera.framework`
   - `MWDATCore.framework`
   - `MWDATMockDevice.framework`

---

## 5. Things That Can Exclude SPM Packages from Archive

| Cause | Fix |
|-------|-----|
| Package resolution fails (network, auth) | Resolve packages while online; check GitHub access. |
| Archive uses Debug config | Use Release for Archive. |
| ONLY_ACTIVE_ARCH = YES in Release | Set to NO for Release. |
| Archiving for wrong platform | Use "Any iOS Device" (not Simulator). |
| Corrupt SPM cache | Clear derived data and SPM cache (see 3.1). |
| Package not linked to target | Add to **Link Binary With Libraries** for CTAAssistant. |

---

## 6. If You Still See "Invalid Binary" or "0 Builds"

That is usually **not** about the package being missing from the archive. Common causes:

- **ITMS-91061**: Third-party SDK (e.g. MWDAT) lacks a privacy manifest. See your email to Meta about `PrivacyInfo.xcprivacy`.
- **dSYM issues**: Use `uploadSymbols: false` in `ExportOptions-TestFlight.plist` and upload via Transporter, as in TESTFLIGHT.md.

---

## 7. PrivacyInfo.xcprivacy Checklist

### App-level manifest (CTA Transit Assistant)

A `PrivacyInfo.xcprivacy` file has been added at:

```
CTAAssistant/CTAAssistant/PrivacyInfo.xcprivacy
```

It declares **UserDefaults** (CA92.1) for app preferences and recording consent.

**Verify in Xcode:**
1. In Project Navigator, `PrivacyInfo.xcprivacy` should appear under CTAAssistant.
2. Select the file → **File Inspector** (right panel) → **Target Membership** → ensure **CTAAssistant** is checked.
3. **Build Phases** → **Copy Bundle Resources** → `PrivacyInfo.xcprivacy` must be listed. If missing, drag it in.

### Meta DAT (MWDAT) – Cannot fix in-app

The **meta-wearables-dat-ios** package ships **XCFrameworks** (binary). Privacy manifests must live **inside** each framework bundle. Apple’s ITMS-91061 flags MWDAT because those frameworks have no `PrivacyInfo.xcprivacy`.

- **Who fixes it:** Meta (the SDK vendor) must add manifests to MWDATCamera, MWDATCore, MWDATMockDevice.
- **What you can do:** Keep the CTO email to Meta asking for dSYMs and `PrivacyInfo.xcprivacy`.

---

## 8. Quick Summary for Your CTO

- The Meta DAT package **is** linked and embedded; frameworks appear in the archive and export logs.
- The app now has a **PrivacyInfo.xcprivacy** declaring UserDefaults (CA92.1). Ensure it's in **Copy Bundle Resources**.
- If a new machine or clean build omits them: reset SPM/derived data, resolve packages, then archive.
- Invalid Binary / 0 builds are likely due to Apple’s processing (privacy manifest, dSYMs), not missing frameworks.
