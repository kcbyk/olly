import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/olly_button.dart';
import '../../../profile/presentation/profile_identity_store.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await saveProfileIdentity(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
      );
      if (mounted) context.go(AppRoutes.friends);
    } catch (e) {
      setState(() => _errorText = 'Bir hata oluştu, tekrar dene.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3),

                const SizedBox(height: AppSizes.xl),

                Text(
                  'Olly\'a hoş geldin! 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                const SizedBox(height: AppSizes.sm),

                Text(
                  'Başlamadan önce kendini tanıt.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: AppSizes.xl * 1.5),

                // İsim alanı
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Adın',
                    hintText: 'örn. Ahmet Yılmaz',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Adını gir';
                    if (v.trim().length < 2) return 'En az 2 karakter olmalı';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: AppSizes.md),

                // Kullanıcı adı alanı
                TextFormField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı adı',
                    hintText: 'örn. ahmetyilmaz',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kullanıcı adını gir';
                    }
                    final clean =
                        v.trim().replaceAll('@', '').toLowerCase();
                    if (clean.length < 3) return 'En az 3 karakter olmalı';
                    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(clean)) {
                      return 'Sadece harf, rakam, nokta ve alt çizgi';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                if (_errorText != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    _errorText!,
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                ],

                const SizedBox(height: AppSizes.xl),

                OllyButton(
                  label: 'Başla',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                const SizedBox(height: AppSizes.xl),

                Center(
                  child: Text(
                    'Kullanıcı adın diğer kişilerin seni bulmasını sağlar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textTertiary,
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
