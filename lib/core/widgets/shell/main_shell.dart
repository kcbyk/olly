import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../../features/voice_rooms/presentation/voice_rooms_store.dart';
import '../../../features/voice_rooms/presentation/widgets/voice_mini_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void _go(int index) {
    HapticFeedback.selectionClick();
    widget.shell
        .goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return wide
        ? _DesktopFrame(shell: widget.shell, onSelect: _go)
        : _MobileFrame(shell: widget.shell, onSelect: _go);
  }
}

class _DesktopFrame extends StatelessWidget {
  const _DesktopFrame({required this.shell, required this.onSelect});
  final StatefulNavigationShell shell;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final path = GoRouterState.of(context).uri.path;
    final showMini = !isVoiceRoomDetailPath(path);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _SideRail(currentIndex: shell.currentIndex, onSelect: onSelect),
          const SizedBox(width: 16),
          Expanded(
              child: Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child:
                    ColoredBox(color: colors.background, child: shell)),
            if (showMini)
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: VoiceMiniBar(),
              ),
          ])),
          const SizedBox(width: 16),
          const _NowPanel(),
        ]),
      )),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.currentIndex, required this.onSelect});
  final int currentIndex;
  final ValueChanged<int> onSelect;
  static const _items = [
    (Icons.explore_outlined, Icons.explore, 'Keşfet'),
    (Icons.forum_outlined, Icons.forum, 'Mesajlar'),
    (Icons.graphic_eq_outlined, Icons.graphic_eq, 'Odalar'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.glassBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 30),
            child: Row(children: [
              const _Mark(),
              const SizedBox(width: 10),
              Text('olly',
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                      color: colors.primary)),
            ])),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          final selected = index == currentIndex;
          return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Semantics(
                selected: selected,
                button: true,
                label: item.$3,
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                        color: selected
                            ? colors.pillActiveBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11)),
                    child: Row(children: [
                      Icon(selected ? item.$2 : item.$1,
                          size: 20,
                          color: selected
                              ? (colors.isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF1E1E24))
                              : (colors.isDark
                                  ? const Color(0xFFA8A8A8)
                                  : colors.textSecondary)),
                      const SizedBox(width: 12),
                      Text(item.$3,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? (colors.isDark
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF1E1E24))
                                  : (colors.isDark
                                      ? const Color(0xFFA8A8A8)
                                      : colors.textSecondary))),
                    ]),
                  ),
                ),
              ));
        }),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            CircleAvatar(
                radius: 15,
                backgroundColor: colors.primary,
                child: const Text('S',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700))),
            const SizedBox(width: 9),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Senol O.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                  Text('Çevrimiçi',
                      style: TextStyle(fontSize: 11, color: colors.online))
                ])),
            Icon(Icons.more_horiz, size: 18, color: colors.textTertiary),
          ]),
        ),
      ]),
    );
  }
}

class _NowPanel extends StatelessWidget {
  const _NowPanel();
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.glassBorder)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ŞİMDİ',
                  style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Text('Çevrende olanlar',
                  style: TextStyle(
                      fontSize: 18,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  'Arkadaşların aktif olduğunda, burası sana doğal bir başlangıç noktası verir.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: colors.textSecondary)),
              const SizedBox(height: 24),
              _PresenceLine(
                  name: 'Zeynep',
                  detail: 'Akşam Odası’nda',
                  color: colors.online),
              const SizedBox(height: 14),
              _PresenceLine(
                  name: 'Mert',
                  detail: 'Bir şeyler dinliyor',
                  color: colors.idle),
              const SizedBox(height: 14),
              _PresenceLine(
                  name: 'Elif',
                  detail: 'Şimdi çevrimiçi',
                  color: colors.online),
            ]),
      ),
    );
  }
}

class _PresenceLine extends StatelessWidget {
  const _PresenceLine(
      {required this.name, required this.detail, required this.color});
  final String name;
  final String detail;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 9),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary)),
        Text(detail,
            style: TextStyle(fontSize: 11, color: colors.textTertiary))
      ])),
    ]);
  }
}

class _MobileFrame extends StatelessWidget {
  const _MobileFrame({required this.shell, required this.onSelect});
  final StatefulNavigationShell shell;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final path = GoRouterState.of(context).uri.path;
    final isTopLevel =
        const {'/friends', '/messages', '/rooms', '/profile'}.contains(path);
    final inRoomDetail = isVoiceRoomDetailPath(path);

    return Scaffold(
      backgroundColor: colors.background,
      body: shell,
      bottomNavigationBar: ValueListenableBuilder<VoiceRoomsSnapshot>(
        valueListenable: voiceRooms,
        builder: (context, snapshot, _) {
          final showMini = snapshot.joinedRoom != null && !inRoomDetail;
          if (!isTopLevel && !showMini) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showMini) const VoiceMiniBar(),
              if (isTopLevel)
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? const Color(0xFF141216)
                          : const Color(0xFFFAF5FE),
                      border: Border(
                        top: BorderSide(
                          color: colors.isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFEDE4F2),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: shell.currentIndex,
                      onTap: onSelect,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      selectedItemColor: colors.isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1E1E24),
                      unselectedItemColor: colors.isDark
                          ? const Color(0xFFA8A8A8)
                          : const Color(0xFF8E8895),
                      selectedFontSize: 10.5,
                      unselectedFontSize: 10.5,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 10.5,
                      ),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.explore_outlined),
                          activeIcon: Icon(Icons.explore),
                          label: 'Keşfet',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.send_outlined),
                          activeIcon: Icon(Icons.send),
                          label: 'Mesajlar',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.graphic_eq_outlined),
                          activeIcon: Icon(Icons.graphic_eq),
                          label: 'Odalar',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: 'Profil',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: colors.secondary, borderRadius: BorderRadius.circular(9)),
      child: const Center(
          child: Text('o',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: .9))),
    );
  }
}
