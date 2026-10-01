-- ==============================================================================
-- OLLY SUPABASE VERİTABANI ŞEMASI (SQL)
-- Supabase Dashboard -> SQL Editor kısmına yapıştırıp "Run" tuşuna basınız.
-- ==============================================================================

-- 1. PROFİLLER TABLOSU (Kullanıcılar)
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

-- 2. ARKADAŞLIKLAR TABLOSU
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  friend_id TEXT NOT NULL,
  status TEXT DEFAULT 'accepted' NOT NULL, -- 'accepted', 'pending'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, friend_id)
);

-- 3. TAKİP TABLOSU
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id TEXT NOT NULL,
  following_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(follower_id, following_id)
);

-- 4. MESAJLAR TABLOSU (Birebir DM)
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id TEXT NOT NULL,
  receiver_id TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. SESLİ ODALAR TABLOSU
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

-- 6. ODA İÇİ MESAJLAR TABLOSU (Canlı Oda Sohbeti)
CREATE TABLE IF NOT EXISTS public.voice_room_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT REFERENCES public.voice_rooms(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ─── REALTIME AKTİF ETME (WebSocket Yayınları) ────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_room_messages;

-- ─── RLS (Row Level Security) - Test ve Geliştirme için Açık İzinler ──────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_room_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes profilleri görebilir ve düzenleyebilir" ON public.profiles FOR ALL USING (true);
CREATE POLICY "Herkes arkadaşlık oluşturabilir ve okuyabilir" ON public.friendships FOR ALL USING (true);
CREATE POLICY "Herkes takip edebilir ve okuyabilir" ON public.follows FOR ALL USING (true);
CREATE POLICY "Herkes mesaj yazabilir ve okuyabilir" ON public.messages FOR ALL USING (true);
CREATE POLICY "Herkes sesli odaları görebilir ve yönetebilir" ON public.voice_rooms FOR ALL USING (true);
CREATE POLICY "Herkes oda mesajlarını görebilir ve yazabilir" ON public.voice_room_messages FOR ALL USING (true);
