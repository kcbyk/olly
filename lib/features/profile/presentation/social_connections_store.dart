import 'package:flutter/foundation.dart';

class SocialConnection {
  const SocialConnection(this.id, this.name, {this.online = false});
  final String id;
  final String name;
  final bool online;
}

final followingConnections = ValueNotifier<List<SocialConnection>>([]);

final friendConnections = ValueNotifier<List<SocialConnection>>([]);

const incomingFollowerIds = <String>{};

bool isFollowing(String id) =>
    followingConnections.value.any((item) => item.id == id);

void followConnection(SocialConnection person) {
  if (!isFollowing(person.id)) {
    followingConnections.value = [...followingConnections.value, person];
  }
  if (incomingFollowerIds.contains(person.id) &&
      !friendConnections.value.any((item) => item.id == person.id)) {
    friendConnections.value = [...friendConnections.value, person];
  }
}
