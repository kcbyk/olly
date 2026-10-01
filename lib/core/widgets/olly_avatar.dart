import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

/// Yüksek kaliteli, story ring ve canlı durum destekli sosyal avatar.
class OllyAvatar extends StatelessWidget {
  const OllyAvatar({
    required this.size,
    this.imageUrl,
    this.name,
    this.isOnline = false,
    this.isSpeaking = false,
    this.hasActiveStory = false,
    this.statusColor,
    this.borderWidth,
    super.key,
  });

  final double size;
  final String? imageUrl;
  final String? name;
  final bool isOnline;
  final bool isSpeaking;
  final bool hasActiveStory;
  final Color? statusColor;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size;
    final ringPadding = (hasActiveStory || isSpeaking) ? 3.0 : 0.0;

    return Container(
      width: effectiveSize + (ringPadding * 2),
      height: effectiveSize + (ringPadding * 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSpeaking
            ? const LinearGradient(
                colors: [AppColors.speaking, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : hasActiveStory
                ? AppColors.primaryGradient
                : null,
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AppColors.speaking.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.all(ringPadding),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: effectiveSize,
            height: effectiveSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (hasActiveStory || isSpeaking)
                    ? AppColors.background
                    : (borderWidth != null
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.transparent),
                width: (hasActiveStory || isSpeaking) ? 2 : (borderWidth ?? 0),
              ),
            ),
            child: ClipOval(
              child: _buildAvatar(context, effectiveSize),
            ),
          ),
          if (isOnline || statusColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: effectiveSize * 0.28,
                height: effectiveSize * 0.28,
                decoration: BoxDecoration(
                  color: statusColor ?? AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (statusColor ?? AppColors.online).withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, double size) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => _shimmerPlaceholder(size),
        errorWidget: (ctx, url, error) => _initialsAvatar(context, size),
      );
    }
    return _initialsAvatar(context, size);
  }

  Widget _initialsAvatar(BuildContext context, double size) {
    final initials = _getInitials(name ?? '?');
    // Renk varyasyonu için name hash
    final hash = (name ?? 'user').hashCode.abs();
    final gradient = _avatarGradients[hash % _avatarGradients.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder(double size) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surfaceVariant,
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceElevated,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static const _avatarGradients = [
    LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
    LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
    LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
    LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
    LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
  ];
}
