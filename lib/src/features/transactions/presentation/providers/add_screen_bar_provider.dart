import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/l10n/l10n.dart';

/// State cho thanh shell khi đang ở màn Add (Hủy + Save cùng hàng Friend/Notif).
class AddScreenBarState {
  const AddScreenBarState({this.onCancel, this.onSave, this.isLoading = false});

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool isLoading;

  /// Màn Add gọi `update` sau MỖI build; so sánh bằng để Notifier bỏ qua
  /// các lần không đổi thật — thiếu nó, mỗi phím gõ ở ô số tiền từng kéo theo
  /// một lần rebuild toàn shell (callback là tearoff ổn định nên so được).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddScreenBarState &&
          onCancel == other.onCancel &&
          onSave == other.onSave &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(onCancel, onSave, isLoading);
}

class AddScreenBarNotifier extends Notifier<AddScreenBarState> {
  @override
  AddScreenBarState build() => const AddScreenBarState();

  void update({VoidCallback? onCancel, VoidCallback? onSave, bool? isLoading}) {
    state = AddScreenBarState(
      onCancel: onCancel ?? state.onCancel,
      onSave: onSave ?? state.onSave,
      isLoading: isLoading ?? state.isLoading,
    );
  }
}

final addScreenBarProvider =
    NotifierProvider<AddScreenBarNotifier, AddScreenBarState>(
      AddScreenBarNotifier.new,
    );

/// Nội dung thanh Add cho shell: Hủy bên trái, Save giữa, cùng hàng với Friend/Notif.
class AddScreenBarContent extends ConsumerWidget {
  const AddScreenBarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bar = ref.watch(addScreenBarProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: bar.onCancel,
          icon: const Icon(Icons.close),
          tooltip: context.l10n.actionCancel,
        ),
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: bar.isLoading ? null : bar.onSave,
              child: bar.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      context.l10n.actionSave,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
