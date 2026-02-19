# Indoor / Subway Navigation Reference

> Based on [MultiSet-AI/wearable-vps-samples (iOS)](https://github.com/MultiSet-AI/wearable-vps-samples/tree/main/iOS)

This document explains how the wearable-vps-samples repo implements **indoor visual positioning** and **step-by-step voice navigation**, and how to adapt it for CTA Transit Assistant.

---

## 1. How Indoor Location Works

### Visual Positioning (VPS)

The system does **not** use GPS. Instead, it uses:

1. **Glasses camera** → captures frames (photos or video snapshots)
2. **MultiSet VPS API** → sends each image to their cloud localization endpoint
3. **Response** → 6-DOF pose: position (x, y, z) and rotation (quaternion) in **map coordinates**

**Requirement:** The indoor space (e.g. subway platform, concourse) must be **pre-mapped** by MultiSet. You provide a `mapCode` or `mapSetCode` in the request so the API knows which map to use.

---

## 2. End-to-End Flow

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│  Glasses Camera │───▶│  LocalizationService │───▶│ LocalizationResult   │
│  (Meta DAT SDK) │    │  POST image + params │    │ posePosition, poseRotation, confidence │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
                                                              │
                                                              ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  AudioNavigationService.updatePosition(position, rotation)                  │
└────────────────────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  • updatePathProgress() – advance waypoints as user moves                   │
│  • giveNavigationInstruction() – angle to target → NavigationInstruction   │
│  • checkArrival() / checkOffPath() – recalculate if needed                  │
└────────────────────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  NavigationAudioService.playInstruction(.moveForward, .turnLeft, etc.)       │
│  → MP3 files or SpeechManager.speak() fallback                               │
└────────────────────────────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  Output: Bluetooth / device speakers (AVAudioSession .allowBluetoothA2DP)   │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Key Services and Responsibilities

### LocalizationService

- Sends JPEG image + intrinsics + map info to MultiSet API
- Returns `LocalizationResult` with `posePosition`, `poseRotation`, `poseFound`, `confidence`
- Uses `mapCode` / `mapSetCode` to select the pre-mapped environment

### StreamSessionViewModel (or equivalent)

- Connects to **Meta Wearables DAT SDK** (`StreamSession`, `videoFramePublisher`)
- Captures photos via `streamSession.capturePhoto(format: .jpeg)`
- Photo listener: on photo received → `LocalizationService.sendLocalizationRequest(image:)`
- On success: `AudioNavigationService.updatePosition(position:, rotation:)`
- During navigation: periodic localization (e.g. every 200ms) via `localizeForNavigation()`

### AudioNavigationService

- Holds `lastUserPosition`, `lastUserRotation`, `currentPath`, `currentWaypointIndex`
- On `updatePosition()`:
  - Dead reckoning (velocity + latency estimate) for smoother tracking
  - Movement-based heading (preferred over quaternion when user is moving)
  - Progress along path (`updatePathProgress`), arrival check, off-path recalc
  - Computes angle to target → `.moveForward` / `.slightLeft` / `.turnLeft` / `.turnRight` / `.turnAround`
  - Cooldown/hysteresis to avoid flip-flopping instructions
- Calls `NavigationAudioService.playInstruction()`

### NavigationDataService

- Loads `{mapCode}_navigation_data.json` with:
  - **POIs** – destinations (e.g. "Platform A", "Elevator")
  - **Waypoints** – graph nodes with positions and `connectedWaypoints`
  - **Paths** – precomputed waypoint sequences, or A* at runtime

### NavigationAudioService

- Plays MP3 files per instruction (e.g. `move_forward.mp3`, `turn_left.mp3`)
- Fallback: `SpeechManager.speak(instruction.description)` for TTS
- `AVAudioSession`: `.playback`, `.voicePrompt`, `.allowBluetoothA2DP`, `.duckOthers`

### SpeechManager

- Text-to-speech fallback when MP3 files are missing

---

## 4. Navigation Instruction Logic

| Angle to Target | Instruction   |
|-----------------|---------------|
| &lt; 20°        | Move forward  |
| 20°–60°         | Slight left/right |
| 60°–150°        | Turn left/right   |
| ≥ 150°          | Turn around       |
| At destination  | Destination reached |

Hysteresis (~10°) prevents rapid switching between instructions.

---

## 5. What CTA Transit Assistant Needs

### Option A: Full Indoor Navigation (like wearable-vps-samples)

1. **MultiSet credentials** – API access and map set
2. **CTA maps** – Each CTA station (or key areas) must be mapped in MultiSet
3. **Navigation data** – JSON for each map: waypoints (platforms, stairs, elevators), POIs, paths
4. **Meta DAT SDK** – Glasses camera streaming + photo capture (you already use DAT for pairing/TTS)
5. **LocalizationService** – Adapter to MultiSet API (or equivalent VPS provider)
6. **AudioNavigationService** – Can reuse or adapt the wearable sample logic
7. **Route audio** – Either MP3s for "move forward", "turn left", etc., or `MetaDATService.speakToGlasses()` with TTS

### Option B: Hybrid – GPS + Semantics

- Use **GPS** outdoors and at street level
- Indoors (subway): use **station selection** (user picks station) plus **semantic cues** (e.g. "Walk toward the Red Line sign")
- No VPS; voice instructions based on known station layouts and user input, not real-time pose

### Option C: Minimal – Station-Level Only

- No indoor positioning
- Voice: "Your train arrives at Clark/Lake in 3 minutes. Board the Red Line toward 95th."
- Rely on CTA APIs (arrivals, alerts) + `speakToGlasses()` for announcements only

---

## 6. Audio Output to Glasses

In wearable-vps-samples:

- `NavigationAudioService` uses `AVAudioPlayer` with `AVAudioSession` set to `.allowBluetoothA2DP`
- Audio goes to the connected glasses as the default Bluetooth audio device

In CTA Transit Assistant:

- `MetaDATService.speakToGlasses()` is a stub; TODO is to use Meta DAT audio output or `AVSpeechSynthesizer` → stream to glasses
- Same pattern: configure `AVAudioSession` for Bluetooth A2DP so TTS/navigation audio routes to the glasses

---

## 7. Data Flow Summary

| Step | wearable-vps-samples | CTA Equivalent |
|------|----------------------|----------------|
| Camera frames | `StreamSession.videoFramePublisher` | Same (Meta DAT) |
| Photo for VPS | `streamSession.capturePhoto()` | Same |
| Localization | `LocalizationService.sendLocalizationRequest(image)` | MultiSet VPS or alternative |
| Map data | `NavigationDataService` + JSON | CTA station maps + JSON |
| Path | Precomputed or A* on waypoint graph | Same |
| Instructions | `AudioNavigationService` → angle thresholds | Same logic |
| Audio out | `NavigationAudioService` → Bluetooth | `MetaDATService.speakToGlasses()` |

---

## 8. References

- [wearable-vps-samples iOS](https://github.com/MultiSet-AI/wearable-vps-samples/tree/main/iOS)
- [Meta Wearables DAT SDK](https://github.com/facebook/meta-wearables-dat-ios)
- [MultiSet](https://www.multiset.ai) – VPS API and mapping
