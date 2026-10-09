-- ============================================
-- MUSH App — Supabase Database Schema
-- نظام: دليل الخدمات العامة - حضرموت
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================
-- 1. الأماكن (Places)
-- ============================
CREATE TABLE IF NOT EXISTS places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 2. الأقسام الرئيسية (Main Sections)
-- ============================
CREATE TABLE IF NOT EXISTS main_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  place_id UUID REFERENCES places(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 3. التصنيفات (Categories)
-- ============================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(150) NOT NULL,
  icon_url VARCHAR(500),
  main_section_id UUID REFERENCES main_sections(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 4. الملفات الشخصية للمستخدمين (User Profiles)
-- ============================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(100) NOT NULL,
  email VARCHAR(200),
  role VARCHAR(30) DEFAULT 'user' CHECK (role IN ('user', 'provider_govt', 'provider_private', 'admin')),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  avatar_url VARCHAR(500),
  is_blocked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 5. الخدمات (Services)
-- ============================
CREATE TABLE IF NOT EXISTS services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  address VARCHAR(300),
  phone VARCHAR(20),        -- ✅ String بدل int
  whatsapp VARCHAR(20),     -- ✅ String بدل int
  email VARCHAR(150),
  website VARCHAR(500),
  work_days VARCHAR(150),
  work_time VARCHAR(100),
  image_url VARCHAR(500),
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_suspended BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,  -- ✅ Soft Delete
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 6. متطلبات الخدمة (Requirements)
-- ============================
CREATE TABLE IF NOT EXISTS requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  documents TEXT,
  age VARCHAR(100),
  fees VARCHAR(150),
  gender VARCHAR(30),
  needs_immunization_record BOOLEAN DEFAULT FALSE,
  needs_personal_photo BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- 7. الإعلانات (Advertisements)
-- ============================
CREATE TABLE IF NOT EXISTS advertisements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url VARCHAR(500) NOT NULL,
  link_url VARCHAR(500),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================
-- Indexes للأداء
-- ============================
CREATE INDEX IF NOT EXISTS idx_services_category ON services(category_id);
CREATE INDEX IF NOT EXISTS idx_services_provider ON services(provider_id);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_deleted, is_suspended);
CREATE INDEX IF NOT EXISTS idx_services_name ON services USING gin(to_tsvector('arabic', name));
CREATE INDEX IF NOT EXISTS idx_categories_section ON categories(main_section_id);
CREATE INDEX IF NOT EXISTS idx_sections_place ON main_sections(place_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- ============================
-- Updated At Trigger
-- ============================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger لإنشاء ملف المستخدم تلقائياً عند التسجيل في auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, email, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.email,
    'user'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================
-- Row Level Security (RLS)
-- ============================

-- Enable RLS on all tables
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE main_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE advertisements ENABLE ROW LEVEL SECURITY;

-- دالة آمنة لفحص الأدمن تتجاوز الـ RLS وتمنع الـ Recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Places: قراءة للجميع
CREATE POLICY "places_read_all" ON places FOR SELECT TO PUBLIC USING (true);
CREATE POLICY "places_admin_manage" ON places FOR ALL TO authenticated
  USING (public.is_admin());

-- Main Sections: قراءة للجميع
CREATE POLICY "sections_read_all" ON main_sections FOR SELECT TO PUBLIC USING (true);
CREATE POLICY "sections_admin_manage" ON main_sections FOR ALL TO authenticated
  USING (public.is_admin());

-- Categories: قراءة للجميع
CREATE POLICY "categories_read_all" ON categories FOR SELECT TO PUBLIC USING (true);
CREATE POLICY "categories_admin_manage" ON categories FOR ALL TO authenticated
  USING (public.is_admin());

-- User Profiles: سياسات آمنة بدون استعلام متداخل يسبب Recursion
CREATE POLICY "profiles_read_all" ON user_profiles FOR SELECT TO public
  USING (true);
CREATE POLICY "profiles_update_own" ON user_profiles FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.is_admin());
CREATE POLICY "profiles_insert_all" ON user_profiles FOR INSERT TO public
  WITH CHECK (true);
CREATE POLICY "profiles_admin_delete" ON user_profiles FOR DELETE TO authenticated
  USING (public.is_admin());

-- Services: قراءة للجميع، كتابة للمزودين
CREATE POLICY "services_read_all" ON services FOR SELECT TO PUBLIC
  USING (is_deleted = false);
CREATE POLICY "services_provider_insert" ON services FOR INSERT TO authenticated
  WITH CHECK (provider_id = auth.uid() OR public.is_admin());
CREATE POLICY "services_provider_update" ON services FOR UPDATE TO authenticated
  USING (provider_id = auth.uid() OR public.is_admin());
CREATE POLICY "services_admin_all" ON services FOR ALL TO authenticated
  USING (public.is_admin());

-- Requirements: تبع الخدمات
CREATE POLICY "requirements_read_all" ON requirements FOR SELECT TO PUBLIC USING (true);
CREATE POLICY "requirements_manage" ON requirements FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM services WHERE id = service_id AND (provider_id = auth.uid() OR public.is_admin()))
  );

-- Advertisements: قراءة للجميع
CREATE POLICY "ads_read_active" ON advertisements FOR SELECT TO PUBLIC USING (is_active = true);
CREATE POLICY "ads_admin_all" ON advertisements FOR ALL TO authenticated
  USING (public.is_admin());

-- ============================
-- Supabase Storage Buckets
-- ============================
-- Run these in the Supabase Storage section:
-- 1. Create bucket: "service-images" (public)
-- 2. Create bucket: "avatars" (public)
-- 3. Create bucket: "advertisements" (public)

-- ============================
-- بيانات تجريبية أولية
-- ============================
INSERT INTO places (name) VALUES
  ('المكلا'), ('الشحر'), ('شبام'), ('سيئون'), ('تريم')
ON CONFLICT DO NOTHING;

-- يمكن إضافة الأقسام الرئيسية بعد إنشاء الأماكن
-- INSERT INTO main_sections (name, place_id) SELECT 'المنطقة الغربية', id FROM places WHERE name = 'المكلا';
