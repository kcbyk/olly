import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_service.dart';

class ProfileIdentity {
  const ProfileIdentity({
    required this.name,
    required this.about,
    required this.id,
    required this.username,
  });

  final String name;
  final String about;
  final String id;
  final String username;

  ProfileIdentity copyWith({String? name, String? about, String? username}) =>
      ProfileIdentity(
        name: name ?? this.name,
        about: about ?? this.about,
        id: id,
        username: username ?? this.username,
      );
}

const _kPrefId = 'olly_user_id';
const _kPrefName = 'olly_user_name';
const _kPrefUsername = 'olly_user_username';
const _kPrefAbout = 'olly_user_about';
const _kPrefSetup = 'olly_setup_done';

/// Kullanıcı kimliği — uygulama başlangıcında SharedPreferences'dan yüklenir
final profileIdentity = ValueNotifier<ProfileIdentity>(
  const ProfileIdentity(
    name: 'Kullanıcı',
    about: 'Olly topluluğunda yeni bağlantılar kuruyor.',
    id: 'OL-0000',
    username: '@kullanici',
  ),
);

/// true → onboarding tamamlanmış
bool profileSetupDone = false;

/// Uygulama başlangıcında çağrılır — kaydedilmiş kimliği yükler
Future<void> loadProfileIdentity() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kPrefSetup) ?? false;
    profileSetupDone = done;
    if (!done) return;

    final id = prefs.getString(_kPrefId) ?? _generateId();
    final name = prefs.getString(_kPrefName) ?? 'Kullanıcı';
    final username = prefs.getString(_kPrefUsername) ?? '@kullanici';
    final about = prefs.getString(_kPrefAbout) ??
        'Olly topluluğunda yeni bağlantılar kuruyor.';

    profileIdentity.value = ProfileIdentity(
      id: id,
      name: name,
      username: username,
      about: about,
    );
  } catch (e) {
    debugPrint('[Profile] load error: $e');
  }
}

/// Onboarding tamamlandığında çağrılır — kaydeder + Supabase'e yazar
Future<void> saveProfileIdentity({
  required String name,
  required String username,
  String? about,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Mevcut ID'yi koru ya da yeni üret
    final existingId = prefs.getString(_kPrefId);
    final id = (existingId != null && existingId.isNotEmpty)
        ? existingId
        : _generateId();

    final cleanUsername =
        username.startsWith('@') ? username : '@$username';
    final effectiveAbout =
        about ?? 'Olly topluluğunda yeni bağlantılar kuruyor.';

    await prefs.setString(_kPrefId, id);
    await prefs.setString(_kPrefName, name.trim());
    await prefs.setString(_kPrefUsername, cleanUsername.toLowerCase().trim());
    await prefs.setString(_kPrefAbout, effectiveAbout);
    await prefs.setBool(_kPrefSetup, true);

    profileIdentity.value = ProfileIdentity(
      id: id,
      name: name.trim(),
      username: cleanUsername.toLowerCase().trim(),
      about: effectiveAbout,
    );
    profileSetupDone = true;

    // Supabase profiles tablosuna yaz
    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.client.from('profiles').upsert({
          'id': id,
          'olly_id': id,
          'username': cleanUsername.toLowerCase().trim(),
          'name': name.trim(),
          'bio': effectiveAbout,
          'status_note': 'Çevrimiçi',
          'is_online': true,
        });
      } catch (e) {
        debugPrint('[Profile] Supabase upsert error: $e');
      }
    }
  } catch (e) {
    debugPrint('[Profile] save error: $e');
  }
}

String _generateId() {
  final short = const Uuid().v4().replaceAll('-', '').substring(0, 6).toUpperCase();
  return 'OL-$short';
}
