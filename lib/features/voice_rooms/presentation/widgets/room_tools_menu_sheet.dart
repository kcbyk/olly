import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../voice_rooms_store.dart';

class RoomToolsMenuSheet extends StatelessWidget {
  const RoomToolsMenuSheet({
    required this.room,
    required this.onLeave,
    super.key,
  });

  final VoiceRoom room;
  final VoidCallback onLeave;

  static void show(
    BuildContext context, {
    required VoiceRoom room,
    required VoidCallback onLeave,
  }) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RoomToolsMenuSheet(
        room: room,
        onLeave: onLeave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHost = isVoiceRoomHost(room);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDFE4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Oda Menüsü',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ID: ${room.displayId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const Gap(16),

              // ─── Oda İşlemleri ──────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF1E1E1E),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Oda ID’sini Kopyala',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                subtitle: Text(
                  'ID: ${room.displayId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFBBBBBB),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: room.displayId));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Oda ID’si kopyalandı'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Gap(6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHost
                        ? Icons.cancel_presentation_rounded
                        : Icons.logout_rounded,
                    color: const Color(0xFFFF3358),
                    size: 22,
                  ),
                ),
                title: Text(
                  isHost ? 'Odayı Kapat' : 'Odadan Ayrıl',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF3358),
                  ),
                ),
                subtitle: Text(
                  isHost
                      ? 'Odayı tüm kullanıcılar için kapat'
                      : 'Mevcut odadan çıkış yap',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFBBBBBB),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLeave();
                },
              ),
              const Gap(10),
            ],
          ),
        ),
      ),
    );
  }
}
