import 'package:flutter/material.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../domain/social_provider.dart';

/// Tên thương hiệu — không dịch.
String socialProviderLabel(SocialProvider p) => switch (p) {
  SocialProvider.google => 'Google',
  SocialProvider.facebook => 'Facebook',
  SocialProvider.twitter => 'X',
};

/// Biểu tượng chữ cái theo màu thương hiệu. Không có asset logo nên vẽ
/// monogram — đủ nhận diện và không vướng điều khoản dùng logo.
class SocialProviderIcon extends StatelessWidget {
  const SocialProviderIcon(this.provider, {super.key, this.size = 24});

  final SocialProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String letter) = switch (provider) {
      SocialProvider.google => (Colors.white, const Color(0xFF4285F4), 'G'),
      SocialProvider.facebook => (const Color(0xFF1877F2), Colors.white, 'f'),
      SocialProvider.twitter => (Colors.black, Colors.white, 'X'),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.divider),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

/// Các nút đăng nhập ngoài dùng chung cho Đăng nhập và Đăng ký.
///
/// Chỉ vẽ provider đang bật ([SocialProvider.enabled]); không provider nào
/// bật thì cả khối (kể cả dòng kẻ "hoặc tiếp tục với") biến mất.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    required this.onPressed,
    this.busy,
    this.enabled = true,
  });

  final void Function(SocialProvider provider) onPressed;

  /// Provider đang xử lý — nút đó hiện vòng xoay, các nút khác bị khoá.
  final SocialProvider? busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const providers = SocialProvider.enabled;
    if (providers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.authOrContinueWith,
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        for (final p in providers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SocialButton(
              provider: p,
              loading: busy == p,
              onPressed: enabled && busy == null ? () => onPressed(p) : null,
            ),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.provider,
    required this.loading,
    required this.onPressed,
  });

  final SocialProvider provider;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (provider) {
      SocialProvider.google => context.l10n.authContinueWithGoogle,
      SocialProvider.facebook => context.l10n.authContinueWithFacebook,
      SocialProvider.twitter => context.l10n.authContinueWithX,
    };
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            SocialProviderIcon(provider, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
