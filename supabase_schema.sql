-- ==============================================================================
-- OLLY SUPABASE ŞEMASI
-- Supabase Dashboard -> SQL Editor -> Run
-- Bu dosya yeni kurulumda da, mevcut kurulumda tekrar çalıştırıldığında da
-- güvenli olacak şekilde yazılmıştır.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. PROFİLLER
CREATE TABLE IF NOT EXISTS public.profiles (
  id TEXT PRIMARY KEY,
  olly_id TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  bio TEXT DEFAULT 'Olly topluluğunda yeni bağlantılar kuruyor.',
  status_note TEXT DEFAULT 'Çevrimiçi',
  location TEXT DEFAULT 'Türkiye',
  is_online BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  avatar_url TEXT,
  interests TEXT[] DEFAULT ARRAY['Sohbet', 'Müzik'],
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. ARKADAŞLIKLAR
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  friend_id TEXT NOT NULL,
  status TEXT DEFAULT 'accepted' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, friend_id)
);

-- 3. TAKİP
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id TEXT NOT NULL,
  following_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(follower_id, following_id)
);

-- 4. BİREBİR MESAJLAR
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id TEXT NOT NULL,
  receiver_id TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. SESLİ ODALAR
CREATE TABLE IF NOT EXISTS public.voice_rooms (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  host_name TEXT NOT NULL,
  host_id TEXT NOT NULL,
  category TEXT DEFAULT 'Sohbet' NOT NULL,
  display_id TEXT NOT NULL,
  announcement TEXT DEFAULT 'Hoş geldin! Birlikte sohbet edelim.',
  seats JSONB DEFAULT '[]'::jsonb NOT NULL,
  extra_listeners INTEGER DEFAULT 0 NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  last_notice TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. ODA MESAJLARI (gelecekte JSON yerine ayrı feed için hazır)
CREATE TABLE IF NOT EXISTS public.voice_room_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT REFERENCES public.voice_rooms(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS messages_receiver_created_idx
  ON public.messages (receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS messages_sender_created_idx
  ON public.messages (sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS friendships_user_status_idx
  ON public.friendships (user_id, status);
CREATE INDEX IF NOT EXISTS friendships_friend_status_idx
  ON public.friendships (friend_id, status);
CREATE INDEX IF NOT EXISTS follows_follower_idx
  ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS follows_following_idx
  ON public.follows (following_id);

-- ─── REALTIME ────────────────────────────────────────────────────────────────
-- Daha önce eklenmişse tekrar çalıştırıldığında hata vermesin.
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_rooms;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_room_messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

-- ─── RLS ─────────────────────────────────────────────────────────────────────
-- Olly'nin mevcut istemci mimarisi Supabase Auth kullanmadığı için ID'ler
-- uygulama tarafından taşınıyor. Üretimde Auth'a geçildiğinde bu politikalar
-- kullanıcı bazlı politikalarla daraltılmalıdır.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_room_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Herkes profilleri görebilir ve düzenleyebilir" ON public.profiles;
CREATE POLICY "Herkes profilleri görebilir ve düzenleyebilir"
  ON public.profiles FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Herkes arkadaşlık oluşturabilir ve okuyabilir" ON public.friendships;
CREATE POLICY "Herkes arkadaşlık oluşturabilir ve okuyabilir"
  ON public.friendships FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Herkes takip edebilir ve okuyabilir" ON public.follows;
CREATE POLICY "Herkes takip edebilir ve okuyabilir"
  ON public.follows FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Herkes mesaj yazabilir ve okuyabilir" ON public.messages;
CREATE POLICY "Herkes mesaj yazabilir ve okuyabilir"
  ON public.messages FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Herkes sesli odaları görebilir ve yönetebilir" ON public.voice_rooms;
CREATE POLICY "Herkes sesli odaları görebilir ve yönetebilir"
  ON public.voice_rooms FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Herkes oda mesajlarını görebilir ve yazabilir" ON public.voice_room_messages;
CREATE POLICY "Herkes oda mesajlarını görebilir ve yazabilir"
  ON public.voice_room_messages FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);
