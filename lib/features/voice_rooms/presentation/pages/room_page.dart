import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../room_badge_b64.dart';
import '../voice_rooms_store.dart';
import '../widgets/room_tools_menu_sheet.dart';

// ─── Room Page ──────────────────────────────────────────────────────────────

class RoomPage extends StatefulWidget {
  const RoomPage({required this.roomId, super.key});
  final String roomId;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  bool _chatVisible = true;
  bool _roomAudioMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      joinVoiceRoom(widget.roomId);
    });
  }

  @override
  void didUpdateWidget(covariant RoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      joinVoiceRoom(widget.roomId);
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    sendRoomChat(widget.roomId, _composer.text);
    _composer.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _leave() {
    final room = voiceRoomById(widget.roomId);
    if (room != null && isVoiceRoomHost(room)) {
      closeVoiceRoom(widget.roomId);
    } else {
      leaveVoiceRoom(widget.roomId);
    }
    if (mounted) context.pop();
  }

  List<String> _getRoomParticipantAvatars(VoiceRoom room, bool joinedHere) {
    final names = <String>[];
    // Seated participants
    for (final seat in room.seats.whereType<VoiceSeatOccupant>()) {
      if (!names.contains(seat.name)) {
        names.add(seat.name);
      }
    }
    // If user is currently in the room (listening or seated), ensure their avatar appears
    if (joinedHere && !names.contains(kCurrentUserName)) {
      names.add(kCurrentUserName);
    }
    // Host if not already added
    if (!names.contains(room.hostName) && room.hostName.isNotEmpty) {
      names.insert(0, room.hostName);
    }
    // Additional listeners
    const listenerNames = [
      'Derya Akın',
      'Can Eren',
      'İrem Koç',
      'Emre Aydın',
      'Sude Yalçın',
      'Arda Uçar',
      'Lara Deniz',
      'Kaan Öz',
    ];
    final listenerCount = joinedHere && !room.iAmSeated
        ? (room.extraListeners > 1 ? room.extraListeners - 1 : 0)
        : room.extraListeners;
    for (var i = 0; i < listenerCount && names.length < 5; i++) {
      final name =
          i < listenerNames.length ? listenerNames[i] : 'Dinleyici ${i + 1}';
      if (!names.contains(name) && name != kCurrentUserName) {
        names.add(name);
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF071926),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Oda Arka Plan Asset'i (Yıldızlı Dağ / Gece Gökyüzü) ─
            Image.asset(
              'assets/images/room_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

            // ─── İçerik Katmanı ───────────────────────────────────
            SafeArea(
              child: ValueListenableBuilder<VoiceRoomsSnapshot>(
                valueListenable: voiceRooms,
                builder: (context, snapshot, _) {
                  final room = snapshot.byId(widget.roomId);
                  if (room == null) {
                    return _MissingRoom(onBack: () => context.pop());
                  }
                  final me = room.me;
                  final joinedHere = snapshot.joinedRoomId == room.id;
                  return Column(
                    children: [
                      _RoomHeader(
                        title: room.title,
                        displayId: room.displayId,
                        hostName: room.hostName,
                        avatars: _getRoomParticipantAvatars(room, joinedHere),
                        participantCount: room.participantsCount,
                        onBack: () => context.pop(),
                        onMenu: () => _showRoomMenu(context, room),
                        onParticipants: () => _showParticipants(context, room),
                        onEditTitle: () => _showEditRoomTitleSheet(context, room),
                      ),
                      if (joinedHere && !room.iAmSeated)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: _ListenerBanner(
                            extraListeners: room.extraListeners,
                          ),
                        ),
                      const Gap(4),
                      Expanded(
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              sliver: SliverToBoxAdapter(
                                child: _SeatStage(
                                  seats: room.seats,
                                  hostName: room.hostName,
                                  lockedSeats: room.lockedSeats,
                                  mutedSeats: room.mutedSeats,
                                  onSeatTap: (index) {
                                    HapticFeedback.selectionClick();
                                    _showSeatActionsSheet(context, room, index);
                                  },
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                              sliver: SliverToBoxAdapter(
                                child: _AnnouncementCard(
                                  text: room.announcement,
                                  canEdit: me?.isHost == true,
                                  onEdit: () =>
                                      _editAnnouncement(context, room),
                                ),
                              ),
                            ),
                            if (room.lastNotice != null)
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                sliver: SliverToBoxAdapter(
                                  child: _SystemNotice(text: room.lastNotice!),
                                ),
                              ),
                            if (_chatVisible)
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                sliver: SliverList.separated(
                                  itemCount: room.messages.length,
                                  separatorBuilder: (_, __) => const Gap(6),
                                  itemBuilder: (context, index) => KeyedSubtree(
                                    key: ValueKey(room.messages[index].id),
                                    child: _ChatBubble(
                                      message: room.messages[index],
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SliverToBoxAdapter(
                                  child: SizedBox(height: 24)),
                          ],
                        ),
                      ),
                      _BottomBar(
                        controller: _composer,
                        muted: snapshot.selfMuted,
                        canSpeak: room.iAmSeated,
                        roomAudioMuted: _roomAudioMuted,
                        chatVisible: _chatVisible,
                        messageCount:
                            room.messages.where((m) => !m.isMine).length,
                        onMute: joinedHere
                            ? () {
                                HapticFeedback.selectionClick();
                                toggleRoomMute(room.id);
                              }
                            : () {},
                        onToggleRoomAudio: () {
                          HapticFeedback.selectionClick();
                          setState(() => _roomAudioMuted = !_roomAudioMuted);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_roomAudioMuted
                                  ? 'Odadaki tüm sesler kapatıldı'
                                  : 'Oda sesleri açıldı'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onSend: _send,
                        onToggleChat: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chatVisible = !_chatVisible);
                        },
                        onMenu: () => _showRoomMenu(context, room),
                        onGift: () => _showGiftNotice(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomTitleSheet(BuildContext context, VoiceRoom room) {
    HapticFeedback.selectionClick();
    final me = room.me;
    final isHost = room.hostName == kCurrentUserName || me?.isHost == true;
    if (!isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sadece oda sahibi oda ismini değiştirebilir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = TextEditingController(text: room.title);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: Color(0xFF00E676),
                      ),
                      const Gap(8),
                      const Text(
                        'Oda İsmini Düzenle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF24232D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 40,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Oda adı girin...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        counterStyle:
                            TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('İptal'),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00C896),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final next = controller.text.trim();
                            if (next.isNotEmpty) {
                              updateRoomTitle(room.id, next);
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Oda ismi güncellendi.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editAnnouncement(BuildContext context, VoiceRoom room) async {
    final controller = TextEditingController(text: room.announcement);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D2838),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text(
          'Duyuruyu düzenle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF071926),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Oda duyurusu',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00C896)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kaydet',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next != null) updateRoomAnnouncement(room.id, next);
  }

  void _showRoomMenu(BuildContext context, VoiceRoom room) {
    RoomToolsMenuSheet.show(
      context,
      room: room,
      onLeave: _leave,
    );
  }

  void _showGiftNotice(BuildContext context) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hediye seçenekleri yakında burada olacak.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showParticipants(BuildContext context, VoiceRoom room) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 0.55,
        maxChildSize: 1,
        builder: (context, scrollController) => _ParticipantsSheet(
          room: room,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showSeatActionsSheet(
    BuildContext context,
    VoiceRoom room,
    int seatIndex,
  ) {
    final me = room.me;
    final isHost = room.hostName == kCurrentUserName || me?.isHost == true;
    final occupant =
        seatIndex < room.seats.length ? room.seats[seatIndex] : null;
    final isMySeat = occupant?.isMe == true;
    final isSeatedSomewhere = room.iAmSeated;
    final isSeatMuted =
        room.mutedSeats.contains(seatIndex) || (occupant?.muted == true);
    final isLocked = room.lockedSeats.contains(seatIndex);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Gap(6),

              // 1. Otur (veya Koltuktan Kalk / Koltuğa Geç)
              _MicSheetItem(
                title: isMySeat
                    ? 'Koltuktan Kalk'
                    : isSeatedSomewhere
                        ? 'Bu Koltuğa Geç'
                        : 'Otur',
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (isMySeat) {
                    leaveVoiceSeat(room.id);
                  } else {
                    final success = takeVoiceSeat(room.id, seatIndex);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Koltuk dolu veya kilitli.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(color: Color(0xFF26262B), height: 1),

              // 2. Kilit (SADECE ODA SAHİBİ İSE GÖZÜKÜR)
              if (isHost) ...[
                _MicSheetItem(
                  title: isLocked ? 'Kilidi Kaldır' : 'Kilit',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    toggleSeatLock(room.id, seatIndex);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isLocked
                              ? 'Koltuk ${seatIndex + 1} kilidi açıldı.'
                              : 'Koltuk ${seatIndex + 1} kilitlendi.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF26262B), height: 1),
              ],

              // 3. Koltuğun Mikrofonunu kapat / aç (Sadece o koltuğa etki eder)
              _MicSheetItem(
                title: isSeatMuted ? 'Mikrofonu aç' : 'Mikrofonu kapat',
                onTap: () {
                  Navigator.pop(sheetContext);
                  toggleSeatMute(room.id, seatIndex);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        occupant != null
                            ? '${occupant.name} mikrofonu ${isSeatMuted ? 'açıldı.' : 'kapatıldı.'}'
                            : 'Koltuk ${seatIndex + 1} mikrofonu ${isSeatMuted ? 'açıldı.' : 'kapatıldı.'}',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(color: Color(0xFF26262B), height: 1),

              // 4. İptal et
              _MicSheetItem(
                title: 'İptal et',
                textColor: Colors.white60,
                onTap: () => Navigator.pop(sheetContext),
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }
}

class _ListenerBanner extends StatelessWidget {
  const _ListenerBanner({required this.extraListeners});
  final int extraListeners;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        extraListeners > 1
            ? 'Dinleyici olarak katıldın. Boş bir koltuğa dokunarak sahneye çık.'
            : 'Sahne dolu. Boş koltuk açılırsa dokunarak konuşmacı olabilirsin.',
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: Color(0xFF00E5FF),
        ),
      ),
    );
  }
}

class _MissingRoom extends StatelessWidget {
  const _MissingRoom({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined,
                size: 48, color: Colors.white54),
            const Gap(16),
            const Text(
              'Bu oda artık açık değil',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            const Text(
              'Listeye dönüp canlı bir odaya katılabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Gap(20),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896)),
              onPressed: onBack,
              child: const Text('Geri dön',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.title,
    required this.displayId,
    required this.hostName,
    required this.avatars,
    required this.participantCount,
    required this.onBack,
    required this.onMenu,
    required this.onParticipants,
    this.onEditTitle,
  });
  final String title;
  final String displayId;
  final String hostName;
  final List<String> avatars;
  final int participantCount;
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final VoidCallback onParticipants;
  final VoidCallback? onEditTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: [
          // Geri butonu
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),

          // Oda sahibi avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              OllyAvatar(size: 38, name: hostName),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF071926),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),

          // Oda bilgisi
          Expanded(
            child: GestureDetector(
              onTap: onEditTitle,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MarqueeText(
                    text: title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'ID: $displayId',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _ParticipantCountButton(
            count: participantCount,
            onTap: onParticipants,
          ),
          const Gap(4),

          // Üst sağ avatar yığını
          _HeaderAvatarStack(names: avatars, onTap: onParticipants),
          const Gap(4),

          // Menü butonu
          IconButton(
            onPressed: onMenu,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
    this.gap = 28.0,
    this.speed = 30.0,
  });

  final String text;
  final TextStyle style;
  final double gap;
  final double speed;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  AnimationController? _animController;
  double _textWidth = 0;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _stopAnimation();
    }
  }

  void _stopAnimation() {
    _animController?.stop();
    _animController?.dispose();
    _animController = null;
  }

  void _startAnimation(double textWidth, double maxWidth) {
    if (!mounted) return;
    _stopAnimation();

    final totalScrollDist = textWidth + widget.gap;
    final durationMs = ((totalScrollDist / widget.speed) * 1000).toInt();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs.clamp(2500, 30000)),
    );

    _animController!.addListener(() {
      if (_scrollController.hasClients && _animController != null) {
        final offset = _animController!.value * totalScrollDist;
        _scrollController.jumpTo(offset % totalScrollDist);
      }
    });

    _animController!.repeat();
  }

  @override
  void dispose() {
    _stopAnimation();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        _textWidth = textPainter.width;
        _needsScroll = _textWidth > maxWidth && maxWidth > 0;

        if (!_needsScroll) {
          _stopAnimation();
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _needsScroll &&
              (_animController == null || !_animController!.isAnimating)) {
            _startAnimation(_textWidth, maxWidth);
          }
        });

        return SizedBox(
          width: maxWidth,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.text, style: widget.style),
                Gap(widget.gap),
                Text(widget.text, style: widget.style),
                Gap(widget.gap),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _HeaderAvatarStack extends StatelessWidget {
  const _HeaderAvatarStack({required this.names, required this.onTap});
  final List<String> names;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(3).toList();
    if (shown.isEmpty) return const SizedBox(width: 26, height: 26);
    return Semantics(
      button: true,
      label: 'Katılımcıları göster',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 16.0 * (shown.length - 1) + 26,
          height: 32,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: OllyAvatar(size: 24, name: shown[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantCountButton extends StatelessWidget {
  const _ParticipantCountButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Katılımcılar',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  color: Colors.white, size: 19),
              const Gap(4),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomParticipant {
  const _RoomParticipant({
    required this.name,
    required this.isHost,
    required this.isSpeaking,
    required this.isListener,
  });
  final String name;
  final bool isHost;
  final bool isSpeaking;
  final bool isListener;
}

class _ParticipantsSheet extends StatefulWidget {
  const _ParticipantsSheet({
    required this.room,
    required this.scrollController,
  });
  final VoiceRoom room;
  final ScrollController scrollController;

  @override
  State<_ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends State<_ParticipantsSheet> {
  var _selectedTab = 0;
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RoomParticipant> get _participants {
    final seated = widget.room.seats
        .whereType<VoiceSeatOccupant>()
        .map(
          (seat) => _RoomParticipant(
            name: seat.name,
            isHost: seat.isHost,
            isSpeaking: seat.isSpeaking,
            isListener: false,
          ),
        )
        .toList();

    final meInRoom = voiceRooms.value.joinedRoomId == widget.room.id;
    final meSeated = widget.room.iAmSeated;

    const listenerNames = [
      'Derya Akın',
      'Can Eren',
      'İrem Koç',
      'Emre Aydın',
      'Sude Yalçın',
      'Arda Uçar',
      'Lara Deniz',
      'Kaan Öz',
    ];

    final listeners = <_RoomParticipant>[];
    if (meInRoom && !meSeated) {
      listeners.add(
        _RoomParticipant(
          name: kCurrentUserName,
          isHost: widget.room.hostName == kCurrentUserName,
          isSpeaking: false,
          isListener: true,
        ),
      );
    }

    final otherCount = meInRoom && !meSeated
        ? (widget.room.extraListeners > 1 ? widget.room.extraListeners - 1 : 0)
        : widget.room.extraListeners;

    for (var index = 0; index < otherCount; index++) {
      final name = index < listenerNames.length
          ? listenerNames[index]
          : 'Dinleyici ${index + 1}';
      if (name != kCurrentUserName) {
        listeners.add(
          _RoomParticipant(
            name: name,
            isHost: false,
            isSpeaking: false,
            isListener: true,
          ),
        );
      }
    }

    return [...seated, ...listeners];
  }

  @override
  Widget build(BuildContext context) {
    final participants = _participants;
    final managers = participants.where((person) => person.isHost).toList();
    final peopleForTab = _selectedTab == 0 ? participants : managers;
    final visiblePeople = peopleForTab
        .where(
          (person) => person.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1922),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 10,
              ),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _ParticipantTab(
                      label: 'Odadaki kişiler',
                      count: participants.length,
                      selected: _selectedTab == 0,
                      onTap: () => _selectTab(0),
                    ),
                  ),
                  Expanded(
                    child: _ParticipantTab(
                      label: 'Oda yöneticileri',
                      count: managers.length,
                      selected: _selectedTab == 1,
                      onTap: () => _selectTab(1),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF24232D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
              child: SizedBox(
                height: 52,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF22212B),
                    focusColor: const Color(0xFF22212B),
                    hoverColor: const Color(0xFF22212B),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF868490),
                    ),
                    hintText: 'İsim veya ID ile ara',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9795A1),
                      fontSize: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF353440)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF353440)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF5B5968)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: visiblePeople.isEmpty
                  ? const Center(
                      child: Text(
                        'Aramana uygun kişi bulunamadı.',
                        style:
                            TextStyle(color: Color(0xFF9795A1), fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      key: ValueKey('$_selectedTab-$_query'),
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: visiblePeople.length,
                      separatorBuilder: (_, __) => const Gap(8),
                      itemBuilder: (context, index) => _ParticipantRow(
                        participant: visiblePeople[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = index);
    if (widget.scrollController.hasClients) {
      widget.scrollController.jumpTo(0);
    }
  }
}

class _ParticipantTab extends StatelessWidget {
  const _ParticipantTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count kişi',
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF7F979D),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const Gap(5),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF7F7D87),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});
  final _RoomParticipant participant;

  @override
  Widget build(BuildContext context) {
    final subtitle = participant.isHost
        ? 'Oda sahibi'
        : participant.isSpeaking
            ? 'Konuşuyor'
            : participant.isListener
                ? 'Dinliyor'
                : 'Sahnede';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1E28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              OllyAvatar(size: 42, name: participant.name),
              if (participant.isSpeaking)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1F1E28),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.mic_rounded,
                        size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (participant.isHost) ...[
                      const _RoomOwnerBadge(size: 16),
                      const Gap(4),
                    ],
                    Expanded(
                      child: Text(
                        participant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFAAB8BC),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (participant.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Yönetici',
                style: TextStyle(
                  color: Color(0xFFFFC549),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Konuşmacı Sahnesi ───────────────────────────────────────────────────────

class _SeatStage extends StatelessWidget {
  const _SeatStage({
    required this.seats,
    required this.hostName,
    required this.lockedSeats,
    required this.mutedSeats,
    required this.onSeatTap,
  });
  final List<VoiceSeatOccupant?> seats;
  final String hostName;
  final List<int> lockedSeats;
  final List<int> mutedSeats;
  final ValueChanged<int> onSeatTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => _VoiceSeat(
          number: index + 1,
          member: index < seats.length ? seats[index] : null,
          hostName: hostName,
          isLocked: lockedSeats.contains(index),
          isSeatMuted: mutedSeats.contains(index) ||
              (index < seats.length && seats[index]?.muted == true),
          onTap: () => onSeatTap(index),
        ),
      ),
    );
  }
}

class _VoiceSeat extends StatefulWidget {
  const _VoiceSeat({
    required this.number,
    this.member,
    this.hostName = '',
    this.isLocked = false,
    this.isSeatMuted = false,
    this.onTap,
  });
  final int number;
  final VoiceSeatOccupant? member;
  final String hostName;
  final bool isLocked;
  final bool isSeatMuted;
  final VoidCallback? onTap;

  @override
  State<_VoiceSeat> createState() => _VoiceSeatState();
}

class _VoiceSeatState extends State<_VoiceSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.member?.isSpeaking == true) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final speaking = widget.member?.isSpeaking == true;
    if (speaking && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!speaking && _pulseCtrl.isAnimating) {
      _pulseCtrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final isEmpty = member == null;
    final isSpeaking = member?.isSpeaking == true;
    final isMe = member?.isMe == true;
    final isMuted = widget.isSeatMuted;
    final isHost =
        !isEmpty && (member.isHost || member.name == widget.hostName);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Avatar + Dairesel Koltuk
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final glow = isSpeaking ? _pulseCtrl.value : 0.0;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.3 + 0.3 * glow),
                            blurRadius: 14 + 8 * glow,
                            spreadRadius: 2 + 3 * glow,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Koltuk dairesi (Şeffaf koyu cam)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEmpty
                            ? const Color(0xFF8BC0C7).withValues(alpha: 0.24)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSpeaking
                              ? const Color(0xFF00E676)
                              : Colors.white
                                  .withValues(alpha: isEmpty ? 0.06 : 0.3),
                          width: isSpeaking ? 2.5 : 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: isEmpty
                            ? (widget.isLocked ? _LockedSeat() : _EmptySeat())
                            : isMe
                                ? _MeSeatAvatar(name: member.name)
                                : OllyAvatar(size: 56, name: member.name),
                      ),
                    ),

                    // Mikrofon durumu badge'i
                    if (!isEmpty || widget.isSeatMuted)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: _MicBadge(muted: isMuted),
                      ),
                  ],
                ),
              );
            },
          ),

          const Gap(5),

          // Koltuk Numarası / İsim (Oda sahibi ise isminin solunda rozet)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHost) ...[
                const _RoomOwnerBadge(size: 15),
                const Gap(3),
              ],
              Flexible(
                child: Text(
                  isEmpty ? '${widget.number}' : member.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isEmpty ? Colors.white54 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomOwnerBadge extends StatelessWidget {
  const _RoomOwnerBadge({this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      kRoomOwnerBadgeBytes,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.workspace_premium_rounded,
          size: size,
          color: const Color(0xFFFFB300),
        );
      },
    );
  }
}

class _LockedSeat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

class _MicSheetItem extends StatelessWidget {
  const _MicSheetItem({
    required this.title,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final String title;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/room_empty_seat.png',
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _MeSeatAvatar extends StatelessWidget {
  const _MeSeatAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF00C896),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MicBadge extends StatelessWidget {
  const _MicBadge({required this.muted});
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFFF5277) : const Color(0xFF00E676),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF071926), width: 1.5),
      ),
      child: Icon(
        muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        size: 11,
        color: Colors.white,
      ),
    );
  }
}

// ─── Duyuru Kartı ─────────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.text,
    required this.canEdit,
    required this.onEdit,
  });
  final String text;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RoomNoticeIcon(icon: Icons.notifications_rounded),
        const Gap(8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF072D3B).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duyuru:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Gap(3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                if (canEdit) ...[
                  const Gap(8),
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF071926),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Düzenle',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sistem Notu (Fotoğraftaki Cam Baloncuk Tasarımı) ─────────────────────────

class _SystemNotice extends StatelessWidget {
  const _SystemNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _RoomNoticeIcon(icon: Icons.waving_hand_rounded),
        const Gap(8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF072D3B).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomNoticeIcon extends StatelessWidget {
  const _RoomNoticeIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF4F8B96).withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.92)),
    );
  }
}

// ─── Chat Feed (Fotoğraftaki Cam Sohbet Balonları) ───────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final VoiceChatLine message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        OllyAvatar(size: 28, name: message.name),
        const Gap(8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF082736).withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.name.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      message.time,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Modern Alt Bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.muted,
    required this.roomAudioMuted,
    required this.onMute,
    required this.onToggleRoomAudio,
    required this.onSend,
    required this.onMenu,
    required this.onGift,
    this.canSpeak = false,
    this.chatVisible = true,
    this.messageCount = 0,
    this.onToggleChat,
  });
  final TextEditingController controller;
  final bool muted;
  final bool roomAudioMuted;
  final bool canSpeak;
  final bool chatVisible;
  final int messageCount;
  final VoidCallback onMute;
  final VoidCallback onToggleRoomAudio;
  final VoidCallback onSend;
  final VoidCallback? onToggleChat;
  final VoidCallback onMenu;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── 1. Odadaki Tüm Sesleri Kapatan Hoparlör İkonu (Solid White) ──
            _BottomAction(
              label: roomAudioMuted ? 'Oda sesini aç' : 'Oda sesini kapat',
              onTap: onToggleRoomAudio,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  roomAudioMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_outlined,
                  key: ValueKey<bool>(roomAudioMuted),
                  size: 24,
                  color: roomAudioMuted ? const Color(0xFFFF5277) : Colors.white,
                ),
              ),
            ),
            const Gap(10),

            // ─── 2. Kendi Mikrofonunu Aç/Kapat (Mic Mute/Unmute - Sadece koltukta oturuyorsa) ─────────────
            if (canSpeak) ...[
              _BottomAction(
                label: muted ? 'Mikrofonu aç' : 'Mikrofonu kapat',
                onTap: onMute,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    key: ValueKey<bool>(muted),
                    size: 24,
                    color: muted ? const Color(0xFFFF5277) : Colors.white,
                  ),
                ),
              ),
              const Gap(10),
            ],

            // ─── 3. Şık, kompakt ve gönderme butonlu yazı alanı ──
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(14, 5, 6, 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF071926),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1A3A46),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onSubmitted: (_) => onSend(),
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 4,
                        cursorColor: const Color(0xFFF4F7F7),
                        style: const TextStyle(
                          color: Color(0xFFF4F7F7),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          hintText: 'Bir şey söyleyin...',
                          hintStyle: TextStyle(
                            color: Color(0xFFAAB8BC),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                    const Gap(6),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, val, _) {
                        final hasText = val.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: hasText ? onSend : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: hasText
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00F5A0),
                                        Color(0xFF00D2FF),
                                      ],
                                    )
                                  : null,
                              color: hasText
                                  ? null
                                  : const Color(0xFF0E2736),
                              border: Border.all(
                                color: hasText
                                    ? Colors.transparent
                                    : const Color(0xFF1C3F52),
                                width: 1,
                              ),
                              boxShadow: hasText
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00F5A0)
                                            .withValues(alpha: 0.40),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 17,
                                color: hasText
                                    ? const Color(0xFF041520)
                                    : const Color(0xFF5B7E90),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // ─── 3. Sağ Aksiyon Grubu (16px aralıklı) ───────────────
            // 3.1. Hediye Kutusu İkonu
            _BottomAction(
              label: 'Hediye gönder',
              onTap: onGift,
              child: Image.asset(
                'assets/images/room_gift.png',
                width: 28,
                height: 28,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Gap(16),

            // 3.2. Menü / Hamburger İkonu (En sağda, Kırmızı Noktalı)
            _BottomAction(
              label: 'Oda menüsü',
              onTap: onMenu,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.menu_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2A54),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.onTap,
    required this.child,
  });
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          containedInkWell: false,
          highlightShape: BoxShape.circle,
          splashColor: Colors.white.withValues(alpha: 0.18),
          child: SizedBox(
            width: 38,
            height: 40,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
