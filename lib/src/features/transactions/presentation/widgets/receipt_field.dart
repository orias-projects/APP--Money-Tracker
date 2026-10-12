import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/services/storage_service.dart';
import '../../../shared/presentation/widgets/async_states.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Link xem ảnh hoá đơn — bucket private nên phải ký link có hạn.
///
/// `autoDispose`: trước đây mỗi ảnh từng mở bị cache VĨNH VIỄN, và vì link ký
/// hết hạn sau 1 giờ nên thumbnail chết 403 âm thầm. Giờ link được thả khi
/// không còn ai xem và tự làm mới trước khi hết hạn.
final receiptUrlProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  path,
) async {
  if (path.isEmpty) return null;
  // Ký lại trước hạn 1 giờ của createSignedUrl (storage_service.dart).
  final refreshTimer = Timer(const Duration(minutes: 50), ref.invalidateSelf);
  ref.onDispose(refreshTimer.cancel);
  final result = await ref.read(storageServiceProvider).signedReceiptUrl(path);
  // Ném lỗi thay vì nuốt thành null — để UI phân biệt "lỗi mạng, thử lại được"
  // với "không có ảnh".
  return result.when(ok: (url) => url, err: (e) => throw e);
});

/// Đính kèm ảnh hoá đơn cho một giao dịch.
class ReceiptField extends ConsumerStatefulWidget {
  const ReceiptField({super.key, required this.path, required this.onChanged});

  /// Đường dẫn trong bucket `receipts`, null nếu chưa có ảnh.
  final String? path;

  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<ReceiptField> createState() => _ReceiptFieldState();
}

class _ReceiptFieldState extends ConsumerState<ReceiptField> {
  bool _uploading = false;

  Future<void> _pick({required bool fromCamera}) async {
    final service = ref.read(storageServiceProvider);
    try {
      final file = await service.pickImage(fromCamera: fromCamera);
      if (file == null || !mounted) return;

      setState(() => _uploading = true);
      final result = await service.uploadReceipt(file);
      if (!mounted) return;
      setState(() => _uploading = false);

      if (result.isErr) {
        showResultSnackBar(
          context,
          message: result.errorOrNull ?? context.l10n.receiptUploadFailed,
          isError: true,
        );
        return;
      }
      widget.onChanged(result.valueOrNull);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showResultSnackBar(
        context,
        message: context.l10n.receiptPickerError,
        isError: true,
      );
    }
  }

  Future<void> _showSourceSheet() async {
    if (!StorageService.supportsCamera) {
      await _pick(fromCamera: false);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.l10n.receiptTakePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.receiptChooseFromLibrary),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _remove() {
    final path = widget.path;
    widget.onChanged(null);
    // Xoá file trên storage ở nền; nếu lỗi cũng không chặn người dùng.
    if (path != null) {
      ref.read(storageServiceProvider).deleteReceipt(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(context.l10n.receiptUploading),
      );
    }

    if (widget.path == null) {
      return OutlinedButton.icon(
        onPressed: _showSourceSheet,
        icon: const Icon(Icons.receipt_long, size: 18),
        label: Text(context.l10n.receiptAttach),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.textSecondary,
          side: BorderSide(color: context.colors.divider),
          minimumSize: const Size(0, 48),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: ReceiptThumbnail(path: widget.path!)),
        IconButton(
          onPressed: _remove,
          icon: Icon(Icons.delete_outline, color: context.colors.expense),
          tooltip: context.l10n.receiptRemove,
        ),
      ],
    );
  }
}

/// Ảnh hoá đơn thu nhỏ, chạm để xem to.
class ReceiptThumbnail extends ConsumerWidget {
  const ReceiptThumbnail({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(receiptUrlProvider(path));

    return urlAsync.when(
      loading: () => Container(
        height: 72,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.receiptLoadFailed,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(receiptUrlProvider(path)),
            child: Text(context.l10n.actionRetry),
          ),
        ],
      ),
      data: (url) {
        if (url == null) {
          return Text(
            context.l10n.receiptLoadFailed,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          );
        }
        // Decode đúng cỡ hiển thị — ảnh gốc 1600px cho ô 72px sẽ chiếm
        // ~7.7MB RAM mỗi tấm trong ImageCache nếu decode nguyên bản.
        final cacheWidth =
            (MediaQuery.sizeOf(context).width *
                    MediaQuery.devicePixelRatioOf(context))
                .round();
        return Semantics(
          button: true,
          label: context.l10n.receiptViewFull,
          child: GestureDetector(
            onTap: () => _showFullScreen(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                height: 72,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                errorBuilder: (_, _, _) => Container(
                  height: 72,
                  color: context.colors.surfaceVariant,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: context.l10n.actionClose,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
