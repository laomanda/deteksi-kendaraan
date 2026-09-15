-- ================================================================
-- RIDECARE: VEHICLE INTELLIGENCE LAYER MIGRATION
-- Migration: 20260915_vehicle_intelligence_layer.sql
-- ================================================================

-- 1. Create Table: vehicle_categories
CREATE TABLE IF NOT EXISTS vehicle_categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('motorcycle', 'car')),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Table: maintenance_templates
CREATE TABLE IF NOT EXISTS maintenance_templates (
    id VARCHAR(100) PRIMARY KEY,
    category_id VARCHAR(50) NOT NULL REFERENCES vehicle_categories(id) ON DELETE CASCADE,
    component_key VARCHAR(50) NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    description TEXT,
    interval_km INT NOT NULL DEFAULT 0,
    interval_month INT NOT NULL DEFAULT 0,
    estimated_cost_min INT NOT NULL DEFAULT 0,
    estimated_cost_max INT NOT NULL DEFAULT 0,
    priority INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add vehicle_category_id to vehicles table if not present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vehicles' AND column_name = 'vehicle_category_id'
    ) THEN
        ALTER TABLE vehicles ADD COLUMN vehicle_category_id VARCHAR(50) REFERENCES vehicle_categories(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 4. Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_vehicle_categories_type ON vehicle_categories(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_templates_category ON maintenance_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_category_id ON vehicles(vehicle_category_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE vehicle_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_templates ENABLE ROW LEVEL SECURITY;

-- Public/Authenticated read policies for templates and categories
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vehicle_categories' AND policyname = 'Allow read access to vehicle_categories') THEN
        CREATE POLICY "Allow read access to vehicle_categories" ON vehicle_categories FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_templates' AND policyname = 'Allow read access to maintenance_templates') THEN
        CREATE POLICY "Allow read access to maintenance_templates" ON maintenance_templates FOR SELECT USING (true);
    END IF;
END $$;

-- 6. Master Dataset Seeding: vehicle_categories
INSERT INTO vehicle_categories (id, name, vehicle_type, description) VALUES
    ('scooter_cvt', 'Motor Matic (CVT)', 'motorcycle', 'Sepeda motor transmisi otomatis dengan v-belt dan roller CVT'),
    ('motorcycle_manual', 'Motor Manual', 'motorcycle', 'Sepeda motor bebek atau komuter dengan rantai dan kopling manual/sentrifugal'),
    ('sport_motorcycle', 'Motor Sport', 'motorcycle', 'Sepeda motor sport performa tinggi dengan kopling manual, rantai, dan pendingin cairan'),
    ('car_automatic', 'Mobil Otomatis (AT / CVT)', 'car', 'Mobil penumpang transmisi otomatis konvensional AT, CVT, atau e-CVT'),
    ('car_manual', 'Mobil Manual', 'car', 'Mobil penumpang transmisi manual dengan pedal dan kampas kopling manual'),
    ('car_diesel', 'Mobil Diesel', 'car', 'Mobil bermesin diesel (common rail / konvensional) yang memerlukan perawatan filter bahan bakar khusus'),
    ('car_hybrid', 'Mobil Hybrid (HEV / PHEV)', 'car', 'Mobil bermesin kombinasi bensin dan motor listrik dengan sistem pendingin inverter')
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    vehicle_type = EXCLUDED.vehicle_type,
    description = EXCLUDED.description;

-- 7. Master Dataset Seeding: maintenance_templates
-- Category: scooter_cvt (Vario, Beat, NMAX, Aerox, PCX, Scoopy, Mio, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-sc-engine-oil', 'scooter_cvt', 'engine_oil', 'Oli Mesin Matic', 'Pelumasan mesin skuter matic (viskositas 10W-30 / 10W-40 JASO MB)', 3000, 3, 55000, 120000, 1),
    ('tmpl-sc-gear-oil', 'scooter_cvt', 'gear_oil', 'Oli Gardan (Gear Oil)', 'Pelumasan rasio gigi transmisi akhir skuter matic', 8000, 6, 20000, 45000, 2),
    ('tmpl-sc-cvt-roller', 'scooter_cvt', 'cvt_roller', 'Roller & Slider CVT', 'Pembersihan dan penggantian roller pemberat pulley primer', 12000, 12, 60000, 130000, 3),
    ('tmpl-sc-cvt-belt', 'scooter_cvt', 'cvt_belt', 'CVT Belt (V-Belt)', 'Pemeriksaan keretakan dan penggantian sabuk penggerak CVT', 24000, 24, 120000, 250000, 4),
    ('tmpl-sc-brake-pad', 'scooter_cvt', 'brake_pad', 'Kampas Rem Depan/Belakang', 'Pemeriksaan ketebalan kampas rem cakram dan tromol', 12000, 12, 45000, 110000, 5),
    ('tmpl-sc-air-filter', 'scooter_cvt', 'air_filter', 'Filter Udara', 'Pembersihan/penggantian saringan udara intake mesin', 12000, 12, 45000, 85000, 6),
    ('tmpl-sc-spark-plug', 'scooter_cvt', 'spark_plug', 'Busi', 'Penggantian busi pengapian untuk performa bakar optimal', 8000, 8, 25000, 50000, 7),
    ('tmpl-sc-battery', 'scooter_cvt', 'battery', 'Aki Motor', 'Pengecekan tegangan sel baterai dan starter elektrik', 0, 24, 220000, 350000, 8),
    ('tmpl-sc-tires', 'scooter_cvt', 'tires', 'Ban Depan & Belakang', 'Pemeriksaan batas keausan TWI dan kompon ban', 18000, 24, 250000, 600000, 9)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: motorcycle_manual (Supra, Revo, Jupiter, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-mm-engine-oil', 'motorcycle_manual', 'engine_oil', 'Oli Mesin Manual', 'Pelumasan mesin dan kopling basah (JASO MA/MA2)', 3000, 3, 50000, 110000, 1),
    ('tmpl-mm-drive-chain', 'motorcycle_manual', 'drive_chain', 'Rantai Roda', 'Penyetelan ketegangan dan pelumasan rantai roda', 15000, 12, 90000, 180000, 2),
    ('tmpl-mm-sprocket', 'motorcycle_manual', 'sprocket', 'Gir Depan & Belakang (Sprocket)', 'Pemeriksaan keausan mata gir depan dan gir belakang', 20000, 18, 70000, 150000, 3),
    ('tmpl-mm-clutch-plate', 'motorcycle_manual', 'clutch_plate', 'Kampas Kopling Manual', 'Pemeriksaan selip dan penggantian plat kopling', 25000, 24, 150000, 300000, 4),
    ('tmpl-mm-brake-pad', 'motorcycle_manual', 'brake_pad', 'Kampas Rem Depan/Belakang', 'Pemeriksaan ketebalan kampas rem cakram/tromol', 12000, 12, 40000, 100000, 5),
    ('tmpl-mm-air-filter', 'motorcycle_manual', 'air_filter', 'Filter Udara', 'Saringan udara intake mesin', 12000, 12, 40000, 75000, 6),
    ('tmpl-mm-spark-plug', 'motorcycle_manual', 'spark_plug', 'Busi', 'Penggantian busi pengapian', 8000, 8, 25000, 50000, 7),
    ('tmpl-mm-battery', 'motorcycle_manual', 'battery', 'Aki Motor', 'Pengecekan tegangan sel baterai', 0, 24, 200000, 320000, 8),
    ('tmpl-mm-tires', 'motorcycle_manual', 'tires', 'Ban Depan & Belakang', 'Pemeriksaan keausan alur ban', 18000, 24, 240000, 550000, 9)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: sport_motorcycle (CB150R, CBR, Ninja, R15, GSX, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-sp-engine-oil', 'sport_motorcycle', 'engine_oil', 'Oli Mesin Fully Synthetic', 'Pelumasan mesin sport putaran tinggi (JASO MA2)', 3000, 3, 90000, 220000, 1),
    ('tmpl-sp-drive-chain', 'sport_motorcycle', 'drive_chain', 'Rantai Roda O-Ring', 'Perawatan dan pelumasan rantai seal O-Ring performa tinggi', 15000, 12, 180000, 450000, 2),
    ('tmpl-sp-sprocket', 'sport_motorcycle', 'sprocket', 'Gir Depan & Belakang (Sprocket Set)', 'Pemeriksaan ketajaman mata gir depan dan belakang sport', 20000, 18, 120000, 280000, 3),
    ('tmpl-sp-clutch-plate', 'sport_motorcycle', 'clutch_plate', 'Kampas & Plat Kopling Manual', 'Pemeriksaan ketebalan kampas kopling manual performa tinggi', 24000, 24, 200000, 450000, 4),
    ('tmpl-sp-coolant', 'sport_motorcycle', 'radiator_coolant', 'Radiator Coolant', 'Pengurasan dan pengisian cairan pendingin mesin radiator', 12000, 12, 45000, 100000, 5),
    ('tmpl-sp-brake-pad', 'sport_motorcycle', 'brake_pad', 'Kampas Rem Performa', 'Kampas rem cakram depan ganda/belakang', 10000, 12, 80000, 250000, 6),
    ('tmpl-sp-air-filter', 'sport_motorcycle', 'air_filter', 'Filter Udara Performa', 'Penggantian filter udara mesin sport', 12000, 12, 60000, 150000, 7),
    ('tmpl-sp-spark-plug', 'sport_motorcycle', 'spark_plug', 'Busi Iridium', 'Busi laser/iridium performa tinggi', 10000, 12, 45000, 120000, 8),
    ('tmpl-sp-battery', 'sport_motorcycle', 'battery', 'Aki Motor', 'Pengecekan voltase aki MF', 0, 24, 250000, 400000, 9),
    ('tmpl-sp-tires', 'sport_motorcycle', 'tires', 'Ban Tubeless Sport', 'Pemeriksaan kompon karet dan tapak ban sport', 15000, 18, 500000, 1400000, 10)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: car_automatic (Avanza AT, Brio CVT, Innova AT, Xpander, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-ca-engine-oil', 'car_automatic', 'engine_oil', 'Oli Mesin Mobil', 'Penggantian oli mesin mobil full sintetis', 10000, 6, 350000, 750000, 1),
    ('tmpl-ca-oil-filter', 'car_automatic', 'oil_filter', 'Filter Oli Mesin', 'Penggantian saringan oli mesin', 10000, 6, 45000, 95000, 2),
    ('tmpl-ca-at-fluid', 'car_automatic', 'at_fluid', 'Oli Transmisi Otomatis (ATF / CVTF)', 'Pengurasan/penggantian fluida transmisi otomatis atau CVT', 40000, 24, 450000, 900000, 3),
    ('tmpl-ca-brake-pad', 'car_automatic', 'brake_pad', 'Kampas Rem Mobil Depan/Belakang', 'Pemeriksaan ketebalan kampas rem cakram dan tromol', 30000, 24, 300000, 750000, 4),
    ('tmpl-ca-air-filter', 'car_automatic', 'air_filter', 'Filter Udara Mesin', 'Saringan udara ruang bakar', 20000, 12, 100000, 200000, 5),
    ('tmpl-ca-cabin-filter', 'car_automatic', 'cabin_filter', 'Filter Kabin AC', 'Saringan udara AC kabin mobil', 15000, 12, 75000, 160000, 6),
    ('tmpl-ca-spark-plug', 'car_automatic', 'spark_plug', 'Busi Mobil', 'Penggantian busi mesin 4-silinder', 40000, 24, 150000, 400000, 7),
    ('tmpl-ca-coolant', 'car_automatic', 'engine_coolant', 'Radiator Coolant Mobil', 'Penggantian cairan pendingin radiator', 40000, 24, 120000, 250000, 8),
    ('tmpl-ca-battery', 'car_automatic', 'battery', 'Aki Mobil', 'Pemeriksaan tegangan dan kapasitas aki mobil', 0, 24, 750000, 1300000, 9),
    ('tmpl-ca-wiper', 'car_automatic', 'wiper_blades', 'Karet Wiper', 'Pemeriksaan kelenturan bilah karet wiper depan/belakang', 0, 12, 80000, 200000, 10),
    ('tmpl-ca-tires', 'car_automatic', 'tires', 'Ban Mobil & Rotasi', 'Rotasi ban, balancing, dan cek ketebalan tapak', 40000, 36, 1800000, 4000000, 11)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: car_manual (Avanza MT, Brio MT, Sigra MT, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-cm-engine-oil', 'car_manual', 'engine_oil', 'Oli Mesin Mobil', 'Penggantian oli mesin mobil full sintetis', 10000, 6, 350000, 750000, 1),
    ('tmpl-cm-oil-filter', 'car_manual', 'oil_filter', 'Filter Oli Mesin', 'Penggantian saringan oli mesin', 10000, 6, 45000, 95000, 2),
    ('tmpl-cm-mt-fluid', 'car_manual', 'mt_fluid', 'Oli Transmisi Manual (MTF)', 'Penggantian oli transmisi manual & gardan', 40000, 24, 250000, 500000, 3),
    ('tmpl-cm-clutch-plate', 'car_manual', 'clutch_plate', 'Kampas Kopling Manual', 'Pemeriksaan pedal kopling, release bearing, dan kampas kopling', 50000, 36, 800000, 1800000, 4),
    ('tmpl-cm-brake-pad', 'car_manual', 'brake_pad', 'Kampas Rem Mobil', 'Pemeriksaan ketebalan kampas rem', 30000, 24, 300000, 750000, 5),
    ('tmpl-cm-air-filter', 'car_manual', 'air_filter', 'Filter Udara Mesin', 'Saringan udara ruang bakar', 20000, 12, 100000, 200000, 6),
    ('tmpl-cm-cabin-filter', 'car_manual', 'cabin_filter', 'Filter Kabin AC', 'Saringan udara AC kabin', 15000, 12, 75000, 160000, 7),
    ('tmpl-cm-coolant', 'car_manual', 'engine_coolant', 'Radiator Coolant Mobil', 'Penggantian cairan radiator', 40000, 24, 120000, 250000, 8),
    ('tmpl-cm-battery', 'car_manual', 'battery', 'Aki Mobil', 'Pemeriksaan aki mobil', 0, 24, 750000, 1300000, 9),
    ('tmpl-cm-tires', 'car_manual', 'tires', 'Ban Mobil', 'Rotasi dan cek tapak ban', 40000, 36, 1800000, 4000000, 10),
    ('tmpl-cm-wiper', 'car_manual', 'wiper_blades', 'Karet Wiper', 'Pemeriksaan kelenturan bilah karet wiper depan/belakang', 0, 12, 80000, 200000, 11)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: car_diesel (Innova Diesel, Pajero Sport, Fortuner, Panther, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-cd-engine-oil', 'car_diesel', 'engine_oil', 'Oli Mesin Diesel HD / CI-4', 'Pelumasan mesin diesel common rail / konvensional', 10000, 6, 450000, 950000, 1),
    ('tmpl-cd-oil-filter', 'car_diesel', 'oil_filter', 'Filter Oli Mesin Diesel', 'Penggantian filter oli kapasitas diesel', 10000, 6, 65000, 140000, 2),
    ('tmpl-cd-fuel-filter', 'car_diesel', 'fuel_filter', 'Filter Bahan Bakar (Solar)', 'Penyaringan sedimen air dan kotoran bahan bakar solar', 20000, 12, 150000, 350000, 3),
    ('tmpl-cd-brake-pad', 'car_diesel', 'brake_pad', 'Kampas Rem Mobil', 'Pemeriksaan kampas rem cakram/tromol', 30000, 24, 350000, 850000, 4),
    ('tmpl-cd-air-filter', 'car_diesel', 'air_filter', 'Filter Udara Diesel', 'Saringan udara turbo/mesin diesel', 20000, 12, 120000, 250000, 5),
    ('tmpl-cd-cabin-filter', 'car_diesel', 'cabin_filter', 'Filter Kabin AC', 'Saringan kabin AC', 15000, 12, 75000, 160000, 6),
    ('tmpl-cd-coolant', 'car_diesel', 'engine_coolant', 'Radiator Coolant', 'Cairan pendingin radiator mesin diesel', 40000, 24, 150000, 300000, 7),
    ('tmpl-cd-battery', 'car_diesel', 'battery', 'Aki Mobil Diesel (High CCA)', 'Aki cold-cranking amps tinggi untuk mesin diesel', 0, 24, 950000, 1700000, 8),
    ('tmpl-cd-wiper', 'car_diesel', 'wiper_blades', 'Karet Wiper', 'Pemeriksaan kelenturan bilah karet wiper depan/belakang', 0, 12, 80000, 220000, 9),
    ('tmpl-cd-tires', 'car_diesel', 'tires', 'Ban Mobil SUV / MPV Diesel', 'Pemeriksaan keausan dan rotasi ban', 40000, 36, 2200000, 5000000, 10)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;

-- Category: car_hybrid (Yaris Cross Hybrid, Corolla Cross HEV, Kicks, dsb.)
INSERT INTO maintenance_templates (id, category_id, component_key, component_name, description, interval_km, interval_month, estimated_cost_min, estimated_cost_max, priority) VALUES
    ('tmpl-ch-engine-oil', 'car_hybrid', 'engine_oil', 'Oli Mesin 0W-16 / 0W-20 Hybrid', 'Oli viskositas ultra-rendah untuk mesin siklus Atkinson', 10000, 6, 400000, 850000, 1),
    ('tmpl-ch-oil-filter', 'car_hybrid', 'oil_filter', 'Filter Oli Mesin', 'Penggantian filter oli', 10000, 6, 50000, 110000, 2),
    ('tmpl-ch-inverter-coolant', 'car_hybrid', 'inverter_coolant', 'Coolant Sistem Inverter & Baterai', 'Pendingin khusus modul inverter dan motor elektrik', 40000, 24, 150000, 350000, 3),
    ('tmpl-ch-brake-pad', 'car_hybrid', 'brake_pad', 'Kampas Rem Regeneratif', 'Pemeriksaan keausan kampas rem (awet karena pengereman regeneratif)', 40000, 36, 350000, 800000, 4),
    ('tmpl-ch-air-filter', 'car_hybrid', 'air_filter', 'Filter Udara Mesin', 'Saringan udara intake mesin', 20000, 12, 110000, 220000, 5),
    ('tmpl-ch-cabin-filter', 'car_hybrid', 'cabin_filter', 'Filter Kabin & Filter Baterai HV', 'Saringan AC kabin dan filter pendingin baterai traksi', 15000, 12, 90000, 200000, 6),
    ('tmpl-ch-aux-battery', 'car_hybrid', 'aux_battery', 'Aki Tambahan 12V (Auxiliary)', 'Aki penyuplai sistem ECU dan instrumen hybrid', 0, 36, 900000, 1600000, 7),
    ('tmpl-ch-tires', 'car_hybrid', 'tires', 'Ban Mobil EV / Low Rolling Resistance', 'Ban kompon efisiensi bahan bakar tinggi', 40000, 36, 2000000, 4500000, 8)
ON CONFLICT (id) DO UPDATE SET 
    component_name = EXCLUDED.component_name,
    interval_km = EXCLUDED.interval_km,
    interval_month = EXCLUDED.interval_month;
