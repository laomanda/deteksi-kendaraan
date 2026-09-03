# RideCare — Professional Mobile Application Asset Pack

## Design System Overview
- **Philosophy**: Modern Automotive Minimalism & Calm Technology
- **Inspirations**: Apple Health simplicity, Tesla vehicle companion, Strava tracking clarity, Material Design consistency
- **Format**: Production-ready SVG vector assets (100% scalable, transparent backgrounds, pixel-crisp)

---

## Core Color Palette
| Token | Hex | Role |
| :--- | :--- | :--- |
| **Primary Blue** | `#2563EB` | Core brand identity, active journey lines, primary action accents |
| **Secondary Teal** | `#14B8A6` | Diagnostic telemetry, route transitions, secondary badges |
| **Health Green** | `#10B981` | Optimal status, Start location marker, verified health checks |
| **Health Critical** | `#EF4444` | Destination marker, overdue alerts, urgent indicators |
| **Dark Slate** | `#0F172A` | High-contrast typography, tire rubber, cabin tint |
| **Border Subtle** | `#E2E8F0` | Clean dividers, card borders, architectural outlines |
| **Background / Surface** | `#F8FAFC` | Calm off-white cards and canvas backdrop |

---

## Asset Catalog & File Manifest

### 1. RideCare App Logo
- **File**: [app_logo.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/icons/app_logo.svg)
- **ViewBox**: `0 0 512 512`
- **Concept**: Aerodynamic vehicle roofline combined with a smooth journey route curve (`#14B8A6` to `#10B981`) and a floating protective health monitor shield (`#10B981` with ECG pulse line).
- **Usage**: Android app launcher icon, splash screen, high-res marketing icon.

```dart
SvgPicture.asset(
  'assets/icons/app_logo.svg',
  width: 96,
  height: 96,
)
```

---

### 2. Vehicle Illustration Set
#### A. Motorcycle Illustration
- **File**: [motorcycle.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/motorcycle.svg)
- **ViewBox**: `0 0 400 300`
- **Concept**: Clean, modern roadster commuter with tubular frame, monoshock suspension in `#14B8A6`, aerodynamic blue power tank, circular mirror, LED headlight profile, and subtle floating health indicator. Generic, friendly, zero racing decals.

#### B. Car Illustration
- **File**: [car.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/car.svg)
- **ViewBox**: `0 0 400 300`
- **Concept**: Aerodynamic EV/crossover silhouette in `#2563EB`, dark tinted glasshouse, minimalist wheels with teal calipers, flush handles, LED light bar, and companion status node.

```dart
// Example usage in Onboarding & Garage Vehicle Type Picker:
SvgPicture.asset(
  isCar ? 'assets/illustrations/car.svg' : 'assets/illustrations/motorcycle.svg',
  height: 180,
  fit: BoxFit.contain,
)
```

---

### 3. Onboarding Illustration Set
#### Illustration 1: Vehicle Health
- **File**: [onboarding_health.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/onboarding_health.svg)
- **ViewBox**: `0 0 400 320`
- **Scene**: Modern vehicle enveloped in concentric calm health monitoring arcs with 3 diagnostic sensor nodes (Heartbeat/Overall score, Engine/Oil droplet, Battery/Electrical) and floating status checklist.

#### Illustration 2: Smart Maintenance
- **File**: [onboarding_maintenance.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/onboarding_maintenance.svg)
- **ViewBox**: `0 0 400 320`
- **Scene**: Vehicle backdrop with floating smart maintenance checklist card, calendar header, verified component checks in `#10B981`, and modern minimalist wrench/spanner badge in `#2563EB`.

#### Illustration 3: Ride Tracking
- **File**: [onboarding_tracking.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/onboarding_tracking.svg)
- **ViewBox**: `0 0 400 320`
- **Scene**: Perspective map grid plane with a vibrant S-curve journey polyline, green Start radar ripple, red Destination pin, and vehicle in smooth transit with live telemetry pulse badge.

---

### 4. Empty State Illustration ("No Vehicle Added")
- **File**: [empty_garage.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/illustrations/empty_garage.svg)
- **ViewBox**: `0 0 400 320`
- **Scene**: Architectural pedestal with subtle dashed blueprint outline of a vehicle, halo background, and friendly glowing **`+`** badge in `#2563EB`.
- **Mood**: Calm, inviting, spacious, encouraging user action.

```dart
SvgPicture.asset(
  'assets/illustrations/empty_garage.svg',
  width: 260,
  height: 200,
)
```

---

### 5. Map Marker Icon Set
| Marker | File | Size | Visual Elements |
| :--- | :--- | :--- | :--- |
| **Current Vehicle** | [marker_vehicle.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/markers/marker_vehicle.svg) | `64×64` | Accuracy ripple ring, compass heading wedge, top-down vehicle icon |
| **Start Location (A)** | [marker_start.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/markers/marker_start.svg) | `64×80` | Green pin (`#10B981`), drop shadow, bold "A" glyph |
| **Finish Location (B)** | [marker_finish.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/markers/marker_finish.svg) | `64×80` | Red pin (`#EF4444`), drop shadow, bold "B" glyph |

---

### 6. Ride Share Card Supporting Elements
| Element | File | Size | Role |
| :--- | :--- | :--- | :--- |
| **Route Line Decoration** | [route_decoration.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/share_card/route_decoration.svg) | `240×48` | S-curve route wave with start/end & waypoint nodes |
| **Vehicle Badge** | [badge_vehicle.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/share_card/badge_vehicle.svg) | `64×64` | Squircle badge with car silhouette & verified check |
| **Distance Badge** | [badge_distance.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/share_card/badge_distance.svg) | `64×64` | Perspective road milestone & journey odometer |
| **Achievement Badge** | [badge_achievement.svg](file:///c:/Users/jakkob/Desktop/RideCare/assets/share_card/badge_achievement.svg) | `64×64` | Subtle gold medal (`#F59E0B`) with calm ribbon tails |
