import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../voice_rooms_store.dart';

class VoiceMiniBar extends StatelessWidget {
  const VoiceMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ValueListenableBuilder<VoiceRoomsSnapshot>(
      valueListenable: voiceRooms,
      builder: (context, snapshot, _) {
        final room = snapshot.joinedRoom;
        if (room == null) return const SizedBox.shrink();
        return Material(
          color: colors.surface,
          child: InkWell(
            onTap: () => context.push('/rooms/${room.id}'),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.glassBorder),
                ),
              ),
              child: Row(
                children: [
                  OllyAvatar(size: 36, name: room.hostName, isSpeaking: true),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          snapshot.selfMuted
                              ? 'Mikrofon kapalı · ${room.participantsCount} kişi'
                              : 'Bağlısın · ${room.participantsCount} kişi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: snapshot.selfMuted ? 'Sesi aç' : 'Sessize al',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      toggleRoomMute(room.id);
                    },
                    icon: Icon(
                      snapshot.selfMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      color: snapshot.selfMuted
                          ? colors.muted
                          : colors.primary,
                    ),
                  ),
                  IconButton(
                    tooltip: isVoiceRoomHost(room)
                        ? 'Odayı kapat'
                        : 'Odadan ayrıl',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (isVoiceRoomHost(room)) {
                        closeVoiceRoom(room.id);
                      } else {
                        leaveVoiceRoom(room.id);
                      }
                    },
                    icon: Icon(
                      Icons.call_end_rounded,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool isVoiceRoomDetailPath(String path) {
  if (!path.startsWith('/rooms/')) return false;
  return path != '/rooms' && path != '/rooms/';
}
