import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_store.dart';
import '../profile_cover_store.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _messageNotifications = true;
  bool _roomNotifications = true;
  bool _noiseReduction = true;
  bool _privateProfile = false;

  Future<void> _changeCoverPhoto() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (image == null) return;
    profileCoverImage.value = await image.readAsBytes();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeMode,
        builder: (context, currentThemeMode, _) {
          final isDark = currentThemeMode == ThemeMode.dark;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                  tooltip: 'Geri'),
              title: const Text('Ayarlar'),
              bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
            ),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                children: [
                  const Text('Hesabını ve deneyimini buradan yönetebilirsin.',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  const _SettingsHeading('Görünüm ve Tema'),
                  const SizedBox(height: 10),
                  _SettingsPanel(children: [
                    _SettingsSwitch(
                      icon: Icons.dark_mode_outlined,
                      title: 'Koyu tema',
                      subtitle: 'Göz yormayan karanlık mod',
                      value: isDark,
                      onChanged: (value) => toggleTheme(value),
                    ),
                    const Divider(indent: 60, height: 1),
                    _SettingsLink(
                      icon: Icons.photo_outlined,
                      title: 'Kapak fotoğrafını değiştir',
                      subtitle: 'Profilinin üst görselini güncelle',
                      onTap: _changeCoverPhoto,
                    ),
                  ]),
                  const SizedBox(height: 26),
                  const _SettingsHeading('Bildirimler'),
                  const SizedBox(height: 10),
                  _SettingsPanel(children: [
                    _SettingsSwitch(
                        icon: Icons.forum_outlined,
                        title: 'Mesaj bildirimleri',
                        subtitle: 'Yeni mesaj aldığında haber ver',
                        value: _messageNotifications,
                        onChanged: (value) =>
                            setState(() => _messageNotifications = value)),
                    const Divider(indent: 60, height: 1),
                    _SettingsSwitch(
                        icon: Icons.headset_mic_outlined,
                        title: 'Oda davetleri',
                        subtitle: 'Arkadaşların odaya çağırdığında',
                        value: _roomNotifications,
                        onChanged: (value) =>
                            setState(() => _roomNotifications = value)),
                  ]),
                  const SizedBox(height: 26),
                  const _SettingsHeading('Ses'),
                  const SizedBox(height: 10),
                  _SettingsPanel(children: [
                    _SettingsSwitch(
                        icon: Icons.mic_none_rounded,
                        title: 'Gürültü engelleme',
                        subtitle: 'Arka plan seslerini azalt',
                        value: _noiseReduction,
                        onChanged: (value) =>
                            setState(() => _noiseReduction = value)),
                    const Divider(indent: 60, height: 1),
                    _SettingsLink(
                        icon: Icons.volume_up_outlined,
                        title: 'Ses kalitesi',
                        subtitle: 'Otomatik',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 26),
                  const _SettingsHeading('Gizlilik'),
                  const SizedBox(height: 10),
                  _SettingsPanel(children: [
                    _SettingsSwitch(
                        icon: Icons.lock_outline_rounded,
                        title: 'Gizli profil',
                        subtitle: 'Profilini yalnızca arkadaşların görsün',
                        value: _privateProfile,
                        onChanged: (value) =>
                            setState(() => _privateProfile = value)),
                    const Divider(indent: 60, height: 1),
                    _SettingsLink(
                        icon: Icons.block_outlined,
                        title: 'Engellenen hesaplar',
                        subtitle: 'Engellediğin kişileri yönet',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 26),
                  _SettingsPanel(children: [
                    _SettingsLink(
                        icon: Icons.help_outline_rounded,
                        title: 'Yardım ve geri bildirim',
                        subtitle: 'Bir sorun bildir veya destek al',
                        onTap: () {}),
                    const Divider(indent: 60, height: 1),
                    _SettingsLink(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış yap',
                        subtitle: 'Oturumu bu cihazdan kapat',
                        destructive: true,
                        onTap: () => context.go(AppRoutes.login)),
                  ]),
                ]),
          );
        },
      );
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder)),
      child: Column(children: children));
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _SettingsIcon(icon: icon),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      );
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.destructive = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _SettingsIcon(icon: icon, destructive: destructive),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: destructive ? AppColors.muted : AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
        trailing: destructive
            ? null
            : const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
      );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.destructive = false});
  final IconData icon;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color:
              destructive ? const Color(0x14B94E4E) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon,
          size: 19, color: destructive ? AppColors.muted : AppColors.primary));
}
