# RideCare — Asset Design System & SVG Specification

> **Dokumen Panduan Standar Desain, Filosofi, dan Spesifikasi Teknis Asset Vektor SVG RideCare**  
> *Versi*: 2.0 (Post-Audit Stabilization)  
> *Target*: Tim Desainer UI/UX, Illustrator, dan Mobile Engineer

---

## 1. Filosofi & Konsep Desain (Design Philosophy)

RideCare diposisikan sebagai **Personal Vehicle Companion** yang menghadirkan pengalaman **Digital Cockpit & Automotive Telemetry**. 

Asset visual di RideCare bukan sekadar dekorasi, melainkan instrumen komunikasi visual yang intuitif, presisi, dan premium:

1. **Digital Cockpit Aesthetics**:
   - Mengambil inspirasi dari cluster instrumen digital mobil modern, avionik, dan antarmuka telemetri balap.
   - Menggunakan garis-garis presisi (*technical vector line-art*), kurva aerodinamis, dan aksen *glowing/neon telemetry*.
2. **Clarity & Reliability**:
   - Setiap komponen teknis (CVT, oli, rem, busi, aki, dsb.) diilustrasikan dengan bentuk khas yang langsung dikenali (*high recognizable silhouette*) oleh pemilik kendaraan maupun mekanik.
   - Menghindari gaya visual yang terlalu kekanak-kanakan/kartunis atau terlalu hiper-realistis yang membebani rendering.
3. **Harmoni 2.5D & Clean Semi-Flat**:
   - Ilustrasi menggunakan perspektif isometrik / 2.5D modern dengan kedalaman layer yang halus (*subtle gradients & transparency*), bukan flat 2D polos.
4. **Automotive Scale & Proportions**:
   - Siluet kendaraan menggunakan proporsi rasio 16:9 yang ramping, agresif, dan proporsional untuk ditampilkan di header kartu dashboard tanpa memotong area bodi.

---

## 2. Palet Warna Resmi (Color System Tokens)

Semua asset SVG wajib menggunakan palet warna standar RideCare agar harmonis dengan tema aplikasi (Dark Mode Cockpit & Light Surface).

```
                      PALET WARNA RESMI RIDECARE
┌───────────────────┬───────────┬──────────────────────────────────────┐
│ Token Name        │ Hex Code  │ Peruntukan / Filosofi                │
├───────────────────┼───────────┼──────────────────────────────────────┤
│ Primary Navy      │ #102A43   │ Brand utama, hero base, chassis      │
│ Deep Space Dark   │ #0B132B   │ Background kanvas, cockpit surface   │
│ Cockpit Slate     │ #1E293B   │ Struktur bodi sekunder, plate casing │
│ Steel Blue        │ #334E68   │ Shadow layer, detail mekanis         │
│ Electric Teal/Cyan│ #00A6A6   │ Aksen utama, sensor line, highlight  │
│ Neon Sky Cyan     │ #00E5FF   │ Glow effect, pin point, digital beam │
│ Cyber Yellow      │ #F59E0B   │ Spark, electrical energy, warning    │
│ Flame Orange      │ #F97316   │ High heat, critical wear accent      │
│ Crimson Danger    │ #EF4444   │ Urgent replace, warning marker       │
│ Emerald Optimal   │ #10B981   │ Komponen sehat, start trip marker    │
│ Pure Clean White  │ #FFFFFF   │ Contrast highlight, stroke utama     │
│ Subtle Mist Glass │ #F8FAFC   │ Inner glow, translucent reflections  │
└───────────────────┴───────────┴──────────────────────────────────────┘
```

---

## 3. Standar Teknis & Grid Constraint

Untuk memastikan kompatibilitas penuh dengan engine `flutter_svg` dan performa render 60 FPS:

### A. Aturan Wajib Ekspor SVG:
- **HAPUS atribut `width` dan `height` hardcoded** pada tag `<svg ...>`.
- **WAJIB sertakan `viewBox`** sesuai kategori di bawah.
- **Konversi semua Text ke Path** (*Outline Stroke / Convert to Curves*).
- **Gunakan Hex Code standar** (hindari `rgb()` atau `hsl()` di dalam tag SVG).
- **Gunakan LinearGradient standar SVG** jika memerlukan gradasi (jangan gunakan CSS embedded `<style>`).
- **Nama file snake_case** (contoh: `sport_motorcycle.svg`, `gear_oil.svg`).

---

## 4. Spesifikasi Per Kategori Asset

### KATEGORI 1: Maintenance Icons (`assets/icons/maintenance/`)
- **Grid / ViewBox**: `0 0 48 48` (Presisi 1:1 Icon Grid)
- **Stroke Width**: `2.0px` – `2.5px` (Konsisten antar icon)
- **Padding Safe Area**: `4px` dari tepi kanvas `48x48`
- **Gaya**: Technical outline vector dengan aksen pengenal komponen.

| File Name | Komponen | Visual Elements & Filosofi |
|---|---|---|
| `oil.svg` | Oli Mesin | Botol pelumas mesin dengan tetesan oli di tengah. Melambangkan darah utama mesin dan lubrikasi mesin aktif. |
| `gear_oil.svg` | Oli Gardan / Transmisi | Roda gir interlock dengan botol penetes khusus. Melambangkan pelumasan rasio gigi gardan matic & gearbox. |
| `cvt.svg` | V-Belt & Roller CVT | Pulley ganda berbentuk konus yang dihubungkan sabuk V-Belt bergerigi. Simbol transmisi otomatis matic. |
| `brake.svg` | Sistem Pengereman | Piringan cakram dengan lubang ventilasi (rotor disc) dijepit oleh kaliper hidrolik. Simbol keselamatan & daya henti. |
| `spark_plug.svg` | Busi & Pengapian | Busi dengan elektroda pusat, insulator keramik berulir, dan percikan api listrik. Simbol pengapian mesin. |
| `filter.svg` | Filter Udara / Bensin | Kisi-kisi cartridge saringan udara dengan aliran panah udara bersih. Simbol pernapasan mesin dan induksi. |
| `battery.svg` | Aki / Baterai | Kotak baterai dengan terminal kutub positif `(+)` & negatif `(-)` serta voltase kilat. Simbol daya kelistrikan. |
| `coolant.svg` | Radiator Coolant | Kisi panel radiator sirip pendingin dengan tetesan cairan anti-boil. Simbol stabilitas suhu mesin. |
| `chain.svg` | Rantai & Gir Penggerak | Mata rantai roller chain yang melingkari gir sproket bergerigi tajam. Simbol transfer tenaga mekanis motor manual/sport. |
| `tire.svg` | Ban & Velg | Ban dengan pola tapak tapak alur cengkeram (tread pattern) dan velg alloy. Simbol traksi dan kontak aspal. |

---

### KATEGORI 2: Vehicle Silhouettes (`assets/icons/vehicle/`)
- **Grid / ViewBox**: `0 0 800 450` (Rasio Layar Lebar 16:9)
- **Orientasi**: Tampak samping aerodinamis menghadap ke arah kiri.
- **Gaya**: Siluet otomotif kontemporer dengan garis bodi tegas, aksen panel bodi neon cyan (`#00E5FF`), dan bayangan roda di permukaan jalan.

| File Name | Kategori Kendaraan | Karakteristik Visual & Target Model |
|---|---|---|
| `scooter_cvt.svg` | Motor Matic (CVT) | Dek kaki rata/step-through, bodi samping membulat modern, transmisi box CVT di roda belakang, stang santai. Cocok untuk Beat, Vario, Scoopy, NMAX, PCX. |
| `motorcycle_manual.svg` | Motor Bebek / Naked Bike | Tangki depan/underbone, stang tegak, rantai terbuka terlihat di swingarm, footstep tengah. Cocok untuk Supra X, Jupiter, CB150R, Vixion. |
| `sport_motorcycle.svg` | Motor Sport / Full Fairing | Tangki agresif meruncing, windshield visor aerodinamis, stang clip-on merunduk, single seat/split tail tajam, suspensi inverted, knalpot racing. Cocok untuk CBR150R/250RR, R15/R25, Ninja 250. |
| `car.svg` | Mobil Penumpang | Siluet aerodinamis modern 2-box / 3-box (proporsi sedan/MPV/SUV), garis jendela krom futuristik, ground clearance proporsional. Cocok untuk Avanza, Innova, Brio, HR-V, Sedan. |

---

### KATEGORI 3: Tracking Markers (`assets/icons/tracking/`)
- **Grid / ViewBox**: `0 0 32 32` s/d `0 0 48 48`
- **Gaya**: Marker GPS navigasi berdaya kontras tinggi untuk diletakkan di atas peta (Mapbox/Google Maps/OpenStreetMap) atau canvas share.

| File Name | Fungsi Navigasi | Elemen Visual |
|---|---|---|
| `marker_trip_start.svg` | Titik Mulai (Start) | Pin silinder hijau zamrud (`#10B981`) dengan simbol "Play / Start Core" dan lingkaran halo pendaran jalan. |
| `marker_trip_finish.svg` | Titik Akhir (Finish) | Pin silinder merah bendera finish (`#EF4444`) beraksen motif kotak catur / target bullseye. |
| `marker_user_location.svg` | Lokasi Realtime | Titik konsentris ganda biru cyan (`#00A6A6` / `#00E5FF`) dengan efek pulsa radar 360 derajat. |

---

### KATEGORI 4: Illustrations & Empty States (`assets/illustrations/`)
- **Grid / ViewBox**: `0 0 512 512` (Rasio Isometrik 1:1)
- **Gaya**: Isometrik 2.5D Digital Cockpit dengan piringan grid pendar sirkular (*glowing pedestal / telemetry ring*).

| File Name | Layar Penggunaan | Konsep Visual & Filosofi |
|---|---|---|
| `empty_garage.svg` | Garasi Kosong / Onboarding Dashboard | Panggung hologram kosong berputar dengan garis panduan siluet kendaraan digital dan ikon plus. Mengajak pengguna memarkirkan kendaraan pertamanya. |
| `empty_history.svg` | Riwayat Servis Kosong | Papan buku log mekanis futuristik dengan stempel centang perisai transparan. Menandakan buku servis digital siap diisi. |
| `empty_tracking.svg` | Riwayat / Live Ride Kosong | Lintasan jalan aspal berliku di atas radar GPS dengan garis putus-putus menyala. Mengundang pengendara memulai trip pertamanya. |
| `badge_distance.svg` | Pencapaian Jarak Tempuh | Lencana heksagonal emas/cyan dengan simbol spidometer kecepatan dan bintang mileage. |
| `badge_health.svg` | Pencapaian Kondisi 100% | Lencana perisai baja dengan lambang detak jantung mesin (ECG telemetry) dan daun hijau keberlanjutan kendaraan. |
| `onboarding_service.svg` | Intro: Pemantauan Servis | Kunci pas teknikal melayang di atas speedometer cerdas. Pesan: Bebas lupa jadwal ganti oli dan servis rutin. |
| `onboarding_telemetry.svg` | Intro: Telemetri Cerdas | AI chip dan diagram visual kesehatan motor multi-layer. Pesan: Analisis prediktif kesehatan komponen berbasis kilometer. |
| `onboarding_tracking.svg` | Intro: GPS Live Tracking | Smartphone menampilkan rute perjalanan satelit dengan metrik kecepatan dan durasi real-time. |

---

### KATEGORI 5: Branding Assets (`assets/branding/`)
- **Gaya**: Maskot identitas resmi RideCare.

| File Name | Karakteristik |
|---|---|
| `app_logo_emblem.svg` | Perisai proteksi (*Shield*) yang menyatu dengan lintasan jalan raya melengkung dinamis dan inisial "R" futuristik. Mewakili perlindungan menyeluruh untuk perjalanan pengguna. |
| `app_launcher_icon.svg` | Master vector untuk ikon aplikasi di Android & iOS dengan latar belakang gradien Midnight Navy (`#102A43` $\rightarrow$ `#0B132B`) berbingkai neon cyan. |

---

## 5. Panduan Bagi Rekan Desainer (Workflow Penambahan Asset Baru)

Jika Anda ingin menambahkan icon komponen atau siluet kendaraan baru, ikuti SOP berikut:

1. **Gunakan Template Grid yang Benar**:
   - Jika membuat icon part baru $\rightarrow$ buat artboard `48x48 px`.
   - Jika membuat siluet kendaraan $\rightarrow$ buat artboard `800x450 px` (16:9).
   - Jika membuat ilustrasi empty state $\rightarrow$ buat artboard `512x512 px`.
2. **Pilih Warna dari Palet RideCare**:
   - Gunakan Midnight Navy (`#102A43`), Electric Teal (`#00A6A6`), dan status color yang sesuai.
3. **Ekspor Bersih**:
   - Pastikan opsi *Responsive* aktif (tanpa hardcoded `width="..." height="..."` di root XML SVG).
   - Pastikan *Inline Styles* dimatikan (gunakan atribut presentasional seperti `fill="..."` dan `stroke="..."`).
4. **Registrasi di Kode Flutter**:
   - Daftarkan path di [`pubspec.yaml`](file:///c:/Users/jakkob/Desktop/RideCare/pubspec.yaml).
   - Hubungkan ke resolver:
     - Jika kendaraan $\rightarrow$ daftarkan di [`VehicleAssetResolver`](file:///c:/Users/jakkob/Desktop/RideCare/lib/core/constants/vehicle_asset_resolver.dart).
     - Jika komponen part $\rightarrow$ daftarkan di [`VehiclePartVisualInfo.resolveSvgAsset`](file:///c:/Users/jakkob/Desktop/RideCare/lib/features/maintenance/presentation/widgets/vehicle_part_icon_badge.dart).
5. **Jalankan Verifikasi**:
   - Jalankan `flutter analyze` dan `flutter test` untuk memastikan aset ter-render dengan sempurna.
