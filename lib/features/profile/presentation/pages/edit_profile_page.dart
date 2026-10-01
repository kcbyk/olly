import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_button.dart';
import '../profile_identity_store.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _aboutController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final identity = profileIdentity.value;
    _nameController = TextEditingController(text: identity.name);
    _aboutController = TextEditingController(text: identity.about);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    profileIdentity.value = profileIdentity.value
        .copyWith(name: name, about: _aboutController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              tooltip: 'Geri'),
          title: const Text('Profili düzenle'),
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        ),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const Text('İnsanların seni tanıyacağı temel bilgileri güncelle.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45)),
              const SizedBox(height: 26),
              TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı',
                      hintText: 'Adını yaz',
                      prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(
                  controller: _aboutController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 220,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Hakkımda',
                      hintText: 'Kendinden kısaca bahset',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined))),
              const SizedBox(height: 12),
              ValueListenableBuilder<ProfileIdentity>(
                valueListenable: profileIdentity,
                builder: (context, identity, _) => InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: identity.id));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Olly ID kopyalandı'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.fingerprint_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Olly ID',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(identity.id,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary))
                          ])),
                      const Icon(Icons.copy_rounded,
                          size: 17, color: AppColors.textSecondary),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              OllyButton(
                  label: 'Değişiklikleri kaydet',
                  onPressed: _saving ? null : _save,
                  isLoading: _saving),
            ]),
      );
}
