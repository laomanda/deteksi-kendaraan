# RideCare — Standardized Asset Pack Specification

> **Single Source of Truth (SSOT) untuk Penataan File Asset RideCare**  
> Untuk panduan konsep, filosofi, dan palet warna lengkap, baca dokumen **[ASSET_DESIGN_GUIDELINES.md](file:///c:/Users/jakkob/Desktop/RideCare/ASSET_DESIGN_GUIDELINES.md)**.

---

## 1. Ringkasan Arsitektur Direktori (5 Kategori Standar)

```
assets/
├── branding/
│   ├── app_launcher_icon.png
│   ├── app_launcher_icon.svg
│   └── app_logo_emblem.svg
├── icons/
│   ├── maintenance/
│   │   ├── battery.svg
│   │   ├── brake.svg
│   │   ├── chain.svg
│   │   ├── coolant.svg
│   │   ├── cvt.svg
│   │   ├── filter.svg
│   │   ├── gear_oil.svg
│   │   ├── oil.svg
│   │   ├── spark_plug.svg
│   │   └── tire.svg
│   ├── tracking/
│   │   ├── marker_trip_finish.svg
│   │   ├── marker_trip_start.svg
│   │   └── marker_user_location.svg
│   └── vehicle/
│       ├── car.svg
│       ├── motorcycle_manual.svg
│       ├── scooter_cvt.svg
│       └── sport_motorcycle.svg
└── illustrations/
    ├── badge_distance.svg
    ├── badge_health.svg
    ├── empty_garage.svg
    ├── empty_history.svg
    ├── empty_tracking.svg
    ├── onboarding_service.svg
    ├── onboarding_telemetry.svg
    └── onboarding_tracking.svg
```

---

## 2. Deklarasi di `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/branding/
    - assets/icons/maintenance/
    - assets/icons/vehicle/
    - assets/icons/tracking/
    - assets/illustrations/
```

---

## 3. Resolusi Programatis dalam Kode Flutter

1. **Siluet Kendaraan**: Di-resolve melalui [`VehicleAssetResolver`](file:///c:/Users/jakkob/Desktop/RideCare/lib/core/constants/vehicle_asset_resolver.dart):
   ```dart
   final svgPath = VehicleAssetResolver.getSilhouetteAsset(vehicle);
   ```
2. **Ikon Komponen Maintenance**: Di-resolve melalui [`VehiclePartVisualInfo`](file:///c:/Users/jakkob/Desktop/RideCare/lib/features/maintenance/presentation/widgets/vehicle_part_icon_badge.dart):
   ```dart
   final svgPath = VehiclePartVisualInfo.resolveSvgAsset(componentName, category: category);
   ```
