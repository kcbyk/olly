import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client and service provider
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient get client => Supabase.instance.client;

  /// Initializes Supabase if credentials are provided in .env
  Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        supabaseUrl.contains('your-supabase-project')) {
      debugPrint(
        '⚠️ [Supabase] SUPABASE_URL veya SUPABASE_ANON_KEY .env dosyasında tanımlı değil. Çevrimdışı/Yerel senkronizasyon modu devrede.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
        ),
      );
      _isInitialized = true;
      debugPrint('✅ [Supabase] Başarıyla bağlandı: $supabaseUrl');
    } catch (e) {
      debugPrint('❌ [Supabase] Bağlantı hatası: $e');
    }
  }
}
