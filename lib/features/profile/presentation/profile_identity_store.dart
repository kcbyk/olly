import 'package:flutter/foundation.dart';

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

/// Kullanıcı kimliği
final profileIdentity = ValueNotifier<ProfileIdentity>(
  const ProfileIdentity(
    name: 'Senol O.',
    about:
        'Geliştirici & tasarımcı. Olly üzerinde yeni sesli odalar ve topluluklar keşfediyor.',
    id: 'OL-1001',
    username: '@senol',
  ),
);
