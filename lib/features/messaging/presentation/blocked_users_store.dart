import 'package:flutter/foundation.dart';

class BlockedUser {
  const BlockedUser(this.id, this.name);
  final String id;
  final String name;
}

final blockedUsers = ValueNotifier<List<BlockedUser>>([
  const BlockedUser('b1', 'Caner Yılmaz'),
  const BlockedUser('b2', 'Derya Akın'),
]);

void unblockUser(BlockedUser user) {
  blockedUsers.value =
      blockedUsers.value.where((item) => item.id != user.id).toList();
}

void blockUser(BlockedUser user) {
  if (blockedUsers.value.any((item) => item.id == user.id)) return;
  blockedUsers.value = [...blockedUsers.value, user];
}
