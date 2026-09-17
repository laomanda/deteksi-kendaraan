# RideCare Design System

Version: 1.0  
Status: Final Design Direction

---

# 1. Product Identity

## Product Name

RideCare

## Positioning

RideCare adalah **Personal Vehicle Companion** yang membantu pengguna memahami, merawat, dan menjaga kendaraan mereka melalui pengalaman digital yang sederhana, premium, dan mudah dipahami.

RideCare bukan:

- Aplikasi bengkel
- Dashboard teknisi
- Sistem database kendaraan
- Aplikasi tracking biasa

RideCare harus terasa seperti:

> "Asisten pribadi yang memahami kendaraan pengguna."

---

# 2. Brand Personality

RideCare memiliki karakter:

## Premium

Memberikan kesan produk otomotif modern.

## Reliable

Membangun kepercayaan pengguna.

## Intelligent

Memahami kondisi kendaraan berdasarkan data.

## Simple

Kompleksitas sistem berada di belakang layar.

Pengguna hanya menerima informasi yang penting.

---

# 3. Visual Direction

## Main Concept

**Premium Automotive Digital Experience**

Referensi rasa:

- Dashboard kendaraan modern
- Apple Health dalam kesederhanaan informasi
- Google Maps dalam pengalaman perjalanan
- Automotive companion application


## Hindari

Jangan menggunakan gaya:

- Dashboard admin
- CRUD application
- Template AI dashboard
- Card berulang
- Statistik berlebihan
- Layout monoton

---

# 4. Color System

## Primary Brand

### Midnight Navy

```
#102A43
```

Digunakan untuk:

- Brand
- Hero section
- Primary button
- Header
- Navigation


---

## Secondary

### Steel Blue

```
#334E68
```

Digunakan untuk:

- Secondary action
- Supporting element
- Icon utama


---

## Accent

### Electric Cyan

```
#00A6A6
```

Digunakan untuk:

- CTA
- Active state
- Tracking
- Teknologi


---

## Background

### Warm White

```
#F7F5EF
```

Digunakan sebagai:

- Background utama
- Area konten


---

# 5. Status Color System

Status kendaraan menggunakan warna solid.

## Aman

```
#16A34A
```

Makna:

Kendaraan dalam kondisi baik.


## Perhatian

```
#F59E0B
```

Makna:

Pengguna perlu melakukan pengecekan.


## Bahaya

```
#DC2626
```

Makna:

Perawatan perlu dilakukan.


---

# 6. Color Rules

## Gunakan

✅ Solid color  
✅ Kontras tinggi  
✅ Premium automotive feeling  
✅ Visual hierarchy jelas  


## Jangan gunakan

❌ Pastel color  
❌ Soft background badge  
❌ Gradient berlebihan  
❌ Glassmorphism  
❌ Transparansi warna sebagai dekorasi  


---

# 7. Typography System

RideCare menggunakan font pairing.

---

# Primary UI Font

## Plus Jakarta Sans

Digunakan untuk:

- Body text
- Button
- Label
- Navigation
- Form
- Maintenance information
- Copywriting


Weight:

| Weight | Usage |
|---|---|
| 400 | Body |
| 500 | Secondary text |
| 600 | Label |
| 700 | Heading |
| 800 | Hero |


---

# Display Font

## Space Grotesk

Digunakan untuk:

- Brand
- Angka besar
- Kilometer
- Statistik utama
- Hero information


Contoh:

```
17.191 KM
124 KM
RideCare
```

Tujuan:

Memberikan karakter:

- Automotive
- Digital cockpit
- Modern technology


---

# Accent Font

## Manrope

Digunakan secara terbatas untuk:

- Onboarding
- Campaign
- Marketing section


Tidak digunakan untuk seluruh aplikasi.

---

# Final Typography Rule

```
Brand / Display:
Space Grotesk

Interface:
Plus Jakarta Sans

Accent:
Manrope
```

---

# 8. Language System

Semua user interface menggunakan:

# Bahasa Indonesia


Hindari:

- Istilah developer
- Bahasa database
- Copywriting robot


Contoh:


## Buruk

```
Vehicle Health Updated
Maintenance Prediction Generated
```


## Baik

```
Kondisi kendaraan sudah diperbarui.

Perawatan berikutnya diperkirakan dalam 3 bulan lagi.
```

---

# 9. Copywriting Principle

Copywriting harus:

- Jelas
- Manusiawi
- Membantu keputusan pengguna


Setiap teks harus menjawab:

"Apa yang harus saya lakukan?"

---

# 10. Validation System

Validasi harus memberikan solusi.

## Jangan:

```
Invalid Input
```

## Gunakan:

```
Kilometer servis tidak boleh lebih kecil dari catatan sebelumnya.

Silakan masukkan angka yang benar.
```

---

# 11. Layout Philosophy

## Main Principle

```
Experience First,
Information Second
```


RideCare tidak menampilkan semua data sekaligus.


---

# 12. Layout Rules

## Hero Driven Layout

Objek utama menjadi pusat perhatian.


Contoh:

```
Honda Vario 160

17.191 KM

● AMAN

Siap digunakan
```


---

## Information Layer

Urutan informasi:

```
Kondisi kendaraan

↓

Tindakan berikutnya

↓

Detail tambahan
```

---

## One Screen One Decision

Setiap halaman harus menjawab:

> "Apa yang harus dilakukan pengguna sekarang?"

---

# 13. Component Philosophy

RideCare tidak menggunakan komponen berulang tanpa alasan.


## Gunakan:

- Hero section
- Timeline
- Bottom sheet
- Floating action
- Interactive object
- Illustration
- Expandable detail


## Hindari:

- Card bertumpuk
- List panjang
- Semua halaman menggunakan layout sama
- Statistik tanpa konteks

---

# 14. Page Experience Direction

Setiap halaman memiliki karakter berbeda.


## Beranda

Tujuan:

Menjawab kondisi kendaraan hari ini.


Fokus:

- Kendaraan aktif
- Status kendaraan
- Tindakan berikutnya


---

## Garasi

Tujuan:

Menampilkan koleksi kendaraan pengguna.


Bukan:

Database kendaraan.


---

## Perawatan

Tujuan:

Membantu pengguna menjaga kendaraan.


Bukan:

Checklist teknis.


---

## Perjalanan

Tujuan:

Memberikan pengalaman perjalanan.


Bukan:

GPS tracker biasa.

---

# 15. Icon System

## Primary Icon Library

## HugeIcons

Digunakan untuk:

- Motor
- Mobil
- Mesin
- Oli
- Ban
- Rem
- Battery
- Sparepart
- Tools
- Maintenance


Tujuan:

Membuat bahasa visual otomotif yang kuat.


---

## Secondary Icon

## Lucide Icons

Digunakan untuk:

- Navigation
- UI action
- Utility icon


---

# 16. UI Library Stack

## Typography

```
google_fonts
```

---

## Icon

```
hugeicons
lucide_icons
```

---

## Animation

```
flutter_animate
animations
```

---

## Interaction

```
modal_bottom_sheet
```

---

## Layout

```
flutter_staggered_grid_view
```

---

## Illustration

```
flutter_svg
```

---

## Data Visualization

```
fl_chart
```

Digunakan secara terbatas.

---

## Loading

```
shimmer
```

Opsional.

---

# 17. Motion Principle

Animasi harus memberikan pengalaman.

Gunakan:

- Page transition
- Object transition
- Success feedback
- State change animation


Jangan:

- Animasi dekoratif berlebihan
- Efek gimmick
- Loading animation berlebihan


---

# 18. Asset Direction

Asset harus mendukung brand.


Gunakan:

- Custom illustration kendaraan
- Sparepart illustration
- Maintenance illustration
- Journey illustration
- Logo custom


Hindari:

- Stock photo random
- Icon generik
- Visual AI berlebihan


---

# 19. Final Design Rules

Sebelum membuat halaman baru, pastikan:


## UX Check

Apakah pengguna:

1. Mengerti fungsi halaman?
2. Tahu tindakan berikutnya?
3. Tidak merasa melihat database?


## UI Check

Apakah:

1. Layout memiliki karakter?
2. Tidak menggunakan komponen berulang?
3. Memiliki visual hierarchy?
4. Sesuai design system?


---

# 20. RideCare Final Identity


```
Brand:
Premium Automotive Companion


Color:
Midnight Navy
Steel Blue
Electric Cyan
Solid Status Colors


Typography:
Plus Jakarta Sans
Space Grotesk
Manrope


Layout:
Unique
Hero-driven
Interactive
Human-centered


Language:
Bahasa Indonesia


Icons:
HugeIcons


Motion:
Subtle Premium Interaction


Goal:

Membuat pengguna merasa:

"RideCare memahami kendaraan saya."
```

---

# END OF DESIGN SYSTEM
