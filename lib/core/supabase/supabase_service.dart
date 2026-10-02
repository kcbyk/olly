import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client and service provider.
///
/// The publishable/anon key is safe to ship in a Flutter client. A Supabase
/// secret/service-role key is deliberately never read here: it must only be
/// used from a trusted server.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  // This is the project URL already used by the build workflow. It is not a
  // credential and lets a local build work even when .env is not checked in.
  static const _defaultUrl = 'https://mteznqxhksgyzetqclmi.supabase.co';

  // Supabase publishable keys are intended for client applications. Prefer an
  // environment value in deployments, but keep the app usable from a fresh
  // checkout as well. Never put SUPABASE_SECRET_KEY here.
  static const _defaultPublishableKey =
      'sb_publishable_93VYIjYFm5KHOwd6n4WraA_hHZZst3O';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient get client => Supabase.instance.client;

  /// Initializes Supabase.
  ///
  /// `SUPABASE_PUBLISHABLE_KEY` is the new Supabase variable name;
  /// `SUPABASE_ANON_KEY` remains supported for older CI builds.
  Future<void> initialize() async {
    final envUrl = dotenv.env['SUPABASE_URL']?.trim();
    final envKey = (dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
            dotenv.env['SUPABASE_ANON_KEY'])
        ?.trim();
    const compileTimeUrl = String.fromEnvironment('SUPABASE_URL');
    const compileTimeKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    final configuredUrl = envUrl != null &&
            envUrl.isNotEmpty &&
            !envUrl.contains('your-supabase-project')
        ? envUrl
        : null;
    final configuredKey = envKey != null &&
            envKey.isNotEmpty &&
            !envKey.contains('your_client_key') &&
            !envKey.contains('your-anon-key')
        ? envKey
        : null;
    final supabaseUrl = configuredUrl ??
        (compileTimeUrl.isNotEmpty ? compileTimeUrl : _defaultUrl);
    final supabaseKey = configuredKey ??
        (compileTimeKey.isNotEmpty ? compileTimeKey : _defaultPublishableKey);

    if (supabaseUrl.isEmpty ||
        supabaseKey.isEmpty ||
        supabaseUrl.contains('your-supabase-project')) {
      debugPrint(
        '⚠️ [Supabase] URL veya publishable key bulunamadı. Çevrimdışı mod devrede.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
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
