# CTA Transit Assistant

**Hands-free CTA 'L' train arrival info on Meta AI Glasses.**

A companion iOS app for pairing with Meta AI Glasses, station selection, real-time arrivals from the CTA Train Tracker API, and optional Follow This Train and Operator modes.

---

## Quick Start (Clone & Open in Xcode)

See **[GITHUB_SETUP.md](GITHUB_SETUP.md)** for:
- Creating the GitHub repo and pushing
- Cloning the repo and opening in Xcode step-by-step

---

## Overview

| Component | Purpose |
|-----------|---------|
| **Riders** | Hear "Red Line to Howard, 2 minutes" hands-free while walking through stations |
| **Operators** | Get schedule and delay info spoken on glasses without stopping to check screens |
| **Accessibility** | Audio-first design for low-vision and mobility-impaired users |

---

## Technical Stack

- **Platform:** iOS 15.2+ (Swift 6, SwiftUI)
- **Wearables:** [Meta Wearables Device Access Toolkit (DAT)](https://github.com/facebook/meta-wearables-dat-ios)
- **CTA Data:** [CTA Train Tracker API](https://www.transitchicago.com/developers/ttdocs/) — `ttarrivals.aspx`, `ttfollow.aspx`
- **Location:** Core Location for nearest station detection

---

## Project Structure

```
CTATransitAssistant/
├── CTATransitAssistantApp.swift   # App entry
├── RootView.swift                 # Root navigation
├── Models/
│   ├── AppState.swift
│   ├── CTAStation.swift
│   ├── CTAArrival.swift
│   └── CTAFollowStop.swift
├── Screens/
│   ├── PairingView.swift         # 1. Pair glasses via Meta DAT
│   ├── StationSelectView.swift   # 2. Auto-detect or manual station pick
│   ├── ArrivalsView.swift        # 3. Live arrivals; push to glasses
│   ├── StationArrivalsTab.swift  # Combines 2 + 3
│   ├── FollowTrainView.swift     # 4. Follow This Train
│   ├── SettingsView.swift        # 5. Notifications, operator toggle
│   └── OperatorModeView.swift   # 6. Line/run, schedule
├── Services/
│   ├── CTAService.swift          # CTA API integration
│   ├── LocationService.swift     # Core Location
│   ├── MetaDATService.swift      # Meta DAT (pairing, audio)
│   └── CTAStationsRepository.swift
└── Info.plist
```

---

## Setup (Xcode)

1. **Create a new iOS App project**
   - Xcode → File → New → Project → App
   - Product Name: `CTA Transit Assistant`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 15.2

2. **Add project files**
   - Drag the `CTATransitAssistant` folder into the project navigator
   - Ensure "Copy items if needed" is unchecked if files are already in the project directory
   - Add `Info.plist` keys to your target (or merge into existing Info.plist):
     - `NSLocationWhenInUseUsageDescription`
     - `NSBluetoothAlwaysUsageDescription`
     - `UIBackgroundModes` with `bluetooth-central`

3. **Add Meta DAT dependency**
   - File → Add Package Dependencies...
   - URL: `https://github.com/facebook/meta-wearables-dat-ios`
   - Add package to your app target

4. **Wire Meta DAT into `MetaDATService`**
   - See `MetaDATService.swift` for TODO comments
   - Replace stubs with actual DAT SDK calls for pairing and audio push

---

## Prototype Checklist

- [ ] Meta DAT integration (pairing, audio push)
- [x] CTA Arrivals API integration
- [x] Station list + location-based nearest
- [x] Basic UI: station pick, arrivals display
- [ ] Audio push to glasses (requires Meta DAT implementation)
- [ ] Optional: Follow This Train flow (API wired; UI ready)
- [ ] Optional: Operator mode (API wired; UI ready)

---

## CTA API Key

The app uses the CTA Train Tracker API key provided in the grant materials.  
To use your own key, update `CTAService.swift`:

```swift
private let apiKey = "YOUR_API_KEY"
```

Apply for a key: [CTA Train Tracker API Application](https://www.transitchicago.com/developers/traintrackerapply/)

---

## License & Acknowledgments

- CTA Train Tracker API: Subject to CTA Developer License Agreement  
- Meta DAT: [Meta Wearables Developer Terms](https://wearables.developer.meta.com/terms)  
- Chicago 2026 transit and accessibility priorities
