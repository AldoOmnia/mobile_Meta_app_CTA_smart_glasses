# GitHub Setup & Xcode Instructions

## Part 1: Create the GitHub Repo and Push

### Option A: Using GitHub Website (recommended)

1. **Create a new repository on GitHub**
   - Go to [github.com/new](https://github.com/new)
   - Repository name: `cta-transit-assistant` (or your preferred name)
   - Description: "Hands-free CTA 'L' train arrival info on Meta AI Glasses"
   - Choose **Public**
   - Do **not** initialize with README, .gitignore, or license (we already have these)

2. **Push your local code**

   Open Terminal and run:

   ```bash
   cd /Users/aldopetruzzelli/mobile_Meta_app_CTA_smart_glasses
   git init
   git add .
   git commit -m "Initial commit: CTA Transit Assistant iOS app"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/cta-transit-assistant.git
   git push -u origin main
   ```

   Replace `YOUR_USERNAME` with your GitHub username and `cta-transit-assistant` with your repo name if different.

### Option B: Using GitHub CLI (`gh`)

```bash
cd /Users/aldopetruzzelli/mobile_Meta_app_CTA_smart_glasses
git init
git add .
git commit -m "Initial commit: CTA Transit Assistant iOS app"
git branch -M main
gh repo create cta-transit-assistant --public --source=. --remote=origin --push
```

---

## Part 2: Pull the Repo and Open in Xcode

### Step 1: Clone the repository

1. Open **Terminal**
2. Go to where you want the project (e.g. `~/Projects`):

   ```bash
   mkdir -p ~/Projects
   cd ~/Projects
   ```

3. Clone the repo:

   ```bash
   git clone https://github.com/YOUR_USERNAME/cta-transit-assistant.git
   cd cta-transit-assistant
   ```

### Step 2: Create the Xcode project

Since this repo contains **source files only** (no `.xcodeproj`), you need to create the Xcode project once:

1. Open **Xcode**
2. **File → New → Project**
3. Choose **iOS → App**
4. Click **Next**
5. Fill in:
   - Product Name: `CTA Transit Assistant`
   - Team: (your team)
   - Organization Identifier: `com.yourdomain` (e.g. `com.yourname`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Uncheck **Include Tests**
6. Click **Next**
7. Save **inside** the cloned repo folder:  
   `~/Projects/cta-transit-assistant`  
   (This way the Xcode project lives in the repo.)

### Step 3: Add source files to the project

1. In Xcode, right-click the **CTA Transit Assistant** group (blue folder) in the Project Navigator
2. Choose **Delete** for the default `ContentView.swift` and `CTA Transit AssistantApp.swift` (or whatever Xcode created)
3. Right-click the project again → **Add Files to "CTA Transit Assistant"...**
4. Navigate to and select the **CTATransitAssistant** folder
5. Ensure:
   - **Create groups** is selected
   - **Add to targets:** CTA Transit Assistant is checked
6. Click **Add**

### Step 4: Configure the app target

1. Select the project in the navigator
2. Select the **CTA Transit Assistant** target
3. **Signing & Capabilities** tab:
   - Click **+ Capability**
   - Add **Location When In Use**
   - Add **Background Modes** → check **Location updates** and **Bluetooth LE accessories** (or as needed for Meta DAT)

4. **Info** tab (or Info.plist):
   - Add `NSLocationWhenInUseUsageDescription`: *"CTA Transit Assistant uses your location to find the nearest CTA 'L' station."*
   - Add `NSBluetoothAlwaysUsageDescription`: *"Used to pair with Meta AI Glasses for hands-free audio."*

### Step 5: Add Meta DAT package

1. **File → Add Package Dependencies...**
2. Enter: `https://github.com/facebook/meta-wearables-dat-ios`
3. Add to target: **CTA Transit Assistant**

### Step 6: Build and run

- Choose a simulator or device
- **Product → Run** (or ⌘R)

---

## Quick Reference: Clone + Open

After the repo exists and you’ve cloned it elsewhere:

```bash
cd ~/Projects  # or your preferred directory
git clone https://github.com/YOUR_USERNAME/cta-transit-assistant.git
cd cta-transit-assistant
open .
```

Then open the `.xcodeproj` file in Xcode (or create it as above if it’s the first time).
