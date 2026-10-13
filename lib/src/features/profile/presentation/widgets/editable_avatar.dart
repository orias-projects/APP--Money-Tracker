import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/presentation/widgets/receipt_field.dart';

/// Ảnh đại diện chạm để đổi — dùng ở màn Tôi và màn Tài khoản.
///
/// Tự chọn ảnh, tải lên Storage, ghi URL vào hồ sơ và làm mới
/// `currentUserProvider`; màn cha không phải làm gì thêm.
class EditableAvatar extends ConsumerStatefulWidget {
  const EditableAvatar({super.key, required this.user, this.radius = 34});

  final AppUser? user;
  final double radius;

  @override
  ConsumerState<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends ConsumerState<EditableAvatar> {
  bool _uploading = false;

  String get _initial {
    final full = widget.user?.fullName?.trim();
    if (full != null && full.isNotEmpty) return full.characters.first;
    final username = widget.user?.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username.characters.first;
    }
    return context.l10n.profileDefaultUserName.characters.first;
  }

  Future<void> _change() async {
    final service = ref.read(storageServiceProvider);
    try {
      final file = await service.pickImage(fromCamera: false);
      if (file == null || !mounted) return;

      setState(() => _uploading = true);
      final uploaded = await service.uploadAvatar(file);
      if (!mounted) return;

      if (uploaded.isErr) {
        setState(() => _uploading = false);
        showResultSnackBar(
          context,
          message: uploaded.localizedErrorOrNull(context.l10n)!,
          isError: true,
        );
        return;
      }

      final saved = await ref
          .read(authRepositoryProvider)
          .updateAvatar(uploaded.valueOrNull);
      if (!mounted) return;
      setState(() => _uploading = false);

      if (saved.isErr) {
        showResultSnackBar(
          context,
          message: saved.localizedErrorOrNull(context.l10n)!,
          isError: true,
        );
        return;
      }
      ref.invalidate(currentUserProvider);
      showResultSnackBar(context, message: context.l10n.profileAvatarUpdated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showResultSnackBar(
        context,
        message: context.l10n.profileAvatarPickError,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.user?.avatarUrl;
    final hasImage = avatarUrl != null && avatarUrl.isNotEmpty;
    final r = widget.radius;

    return Semantics(
      button: true,
      label: context.l10n.profileChangeAvatar,
      child: GestureDetector(
        onTap: _uploading ? null : _change,
        child: Stack(
          children: [
            CircleAvatar(
              radius: r,
              backgroundColor: context.colors.surfaceVariant,
              // Giới hạn kích thước ảnh giải mã theo đúng cỡ hiển thị (x2 cho
              // màn hình mật độ cao).
              backgroundImage: hasImage
                  ? ResizeImage(NetworkImage(avatarUrl), width: (r * 4).round())
                  : null,
              child: hasImage
                  ? null
                  : Text(
                      _initial.toUpperCase(),
                      style: TextStyle(
                        fontSize: r * 0.76,
                        color: context.colors.primary,
                      ),
                    ),
            ),
            if (_uploading)
              Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 12,
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
