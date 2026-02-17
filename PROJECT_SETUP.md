# CTA Transit Assistant – Project Setup

## Which folder does Xcode use?

**Xcode builds from:** `CTATransitAssistant/CTAAssistant/CTAAssistant/`

To open the correct project:
1. Go to `mobile_Meta_app_CTA_smart_glasses/CTATransitAssistant/CTAAssistant/`
2. Open **CTAAssistant.xcodeproj**

Or from Terminal:
```bash
cd /path/to/mobile_Meta_app_CTA_smart_glasses/CTATransitAssistant/CTAAssistant
open CTAAssistant.xcodeproj
```

## How to see the Schedules tab

1. Build and run (⌘R)
2. On the **Pairing** screen, tap **"Continue without Glasses"** (at the bottom)
3. You should see the tab bar with **Schedules**, Follow Train, Settings
4. The Schedules tab shows:
   - Safety Recording (tap to enable)
   - User profile (location, photo)
   - Departing Soon / Arrivals (after selecting a station)

## If you don't see the changes

- Ensure you're opening the project from `mobile_Meta_app_CTA_smart_glasses` (this repo)
- Pull latest: `git pull origin main`
- Clean: Product → Clean Build Folder (⇧⌘K)
- Build: Product → Run (⌘R)

## Pairing flow

- Tap **Pair Glasses** → opens "How to Pair" sheet with step-by-step instructions
- **Open Settings (then tap Bluetooth)** → opens Settings app (Apple restricts direct Bluetooth URLs)
