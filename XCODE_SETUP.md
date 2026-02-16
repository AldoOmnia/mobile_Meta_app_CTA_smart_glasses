# Xcode Setup — Open the Project Correctly

Your clone is at: **`~/Documents/mobile_Meta_app_CTA_smart_glasses/`**

Empty folders (`CTATransitAssistant 2`, `.git 2`) have been removed.

---

## Create & Open the Xcode Project (one-time setup)

### 1. Create the Xcode project

1. Open **Xcode**
2. **File → New → Project**
3. Choose **iOS → App** → Next
4. Fill in:
   - **Product Name:** `CTA Transit Assistant`
   - **Team:** (your team)
   - **Organization Identifier:** `com.aldoomnia` (or yours)
   - **Interface:** SwiftUI | **Language:** Swift
5. Click **Next**
6. **Important:** Save inside the clone folder:
   ```
   /Users/aldopetruzzelli/Documents/mobile_Meta_app_CTA_smart_glasses
   ```
   Do **not** create a new subfolder — save in the existing `mobile_Meta_app_CTA_smart_glasses` folder.

### 2. Add the source files

1. Delete Xcode's default `ContentView.swift` and `CTA Transit AssistantApp.swift`
2. Right-click the project (blue icon) → **Add Files to "CTA Transit Assistant"...**
3. Go to the `CTATransitAssistant` folder in the same directory
4. Select the **CTATransitAssistant** folder (the one with Models, Screens, Services)
5. Ensure **Create groups** is selected
6. Click **Add**

### 3. Configure target

- **Signing & Capabilities:** Add Location When In Use, Background Modes
- **Info:** Add `NSLocationWhenInUseUsageDescription` and `NSBluetoothAlwaysUsageDescription`
- **Package Dependencies:** Add `https://github.com/facebook/meta-wearables-dat-ios`

### 4. Remove duplicate Info.plist from Copy Bundle Resources

- **Build Phases** → **Copy Bundle Resources** → remove `Info.plist` if present

---

## Opening the project later

Open this file in Xcode:

```
~/Documents/mobile_Meta_app_CTA_smart_glasses/CTA Transit Assistant.xcodeproj
```

(It will exist after you create the project in step 1.)
