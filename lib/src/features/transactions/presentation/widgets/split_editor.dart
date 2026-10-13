import 'package:flutter/material.dart';
import 'package:spend_sync/src/core/l10n/enum_labels.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../groups/domain/group_member.dart';
import '../../domain/transaction.dart';

/// Trạng thái chia tiền của một khoản chi trong nhóm.
class SplitState {
  const SplitState({
    required this.mode,
    required this.participants,
    required this.rawValues,
  });

  final SplitMode mode;

  /// userId của những người được chia.
  final Set<String> participants;

  /// Giá trị người dùng nhập, ý nghĩa tuỳ [mode]:
  /// `exact` = số tiền, `percent` = phần trăm, `shares` = số phần.
  final Map<String, double> rawValues;

  static const none = SplitState(
    mode: SplitMode.none,
    participants: {},
    rawValues: {},
  );

  SplitState copyWith({
    SplitMode? mode,
    Set<String>? participants,
    Map<String, double>? rawValues,
  }) {
    return SplitState(
      mode: mode ?? this.mode,
      participants: participants ?? this.participants,
      rawValues: rawValues ?? this.rawValues,
    );
  }

  /// Quy đổi ra danh sách phần chia bằng tiền.
  ///
  /// Chế độ `equal` và `percent` phân bổ phần dư của phép chia cho những người
  /// đầu danh sách, để tổng phần chia luôn khớp đúng số tiền giao dịch — nếu
  /// không, RPC sẽ từ chối vì lệch quá 1 đơn vị.
  List<TransactionSplit> resolve(double amount) {
    if (mode == SplitMode.none || participants.isEmpty || amount <= 0) {
      return const [];
    }
    final ids = participants.toList()..sort();

    switch (mode) {
      case SplitMode.none:
        return const [];

      case SplitMode.equal:
        return _distribute(amount, {for (final id in ids) id: 1});

      case SplitMode.shares:
        final weights = {
          for (final id in ids)
            id: (rawValues[id] ?? 1).clamp(0, 1000).toDouble(),
        };
        return _distribute(amount, weights);

      case SplitMode.percent:
        final weights = {for (final id in ids) id: rawValues[id] ?? 0};
        return _distribute(amount, weights);

      case SplitMode.exact:
        return [
          for (final id in ids)
            TransactionSplit(userId: id, shareAmount: rawValues[id] ?? 0),
        ];
    }
  }

  /// Chia [amount] theo trọng số, phần lẻ dồn cho người đầu tiên.
  static List<TransactionSplit> _distribute(
    double amount,
    Map<String, double> weights,
  ) {
    final totalWeight = weights.values.fold<double>(0, (s, w) => s + w);
    if (totalWeight <= 0) return const [];

    final ids = weights.keys.toList();
    final result = <TransactionSplit>[];
    var allocated = 0.0;

    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      double share;
      if (i == ids.length - 1) {
        share = amount - allocated; // người cuối nhận phần còn lại
      } else {
        share = (amount * weights[id]! / totalWeight).roundToDouble();
        allocated += share;
      }
      result.add(TransactionSplit(userId: id, shareAmount: share));
    }
    return result;
  }

  /// Tổng phần chia hiện tại — dùng để cảnh báo lệch trước khi lưu.
  double totalFor(double amount) =>
      resolve(amount).fold<double>(0, (s, x) => s + x.shareAmount);

  /// Lỗi cấu hình chia nếu chưa hợp lệ, null nếu ổn.
  ///
  /// Trả về [SplitIssue] có cấu trúc thay vì chuỗi, để UI tra bản dịch
  /// vi/en qua [SplitIssueL10n.localized].
  SplitIssue? validate(double amount) {
    if (mode == SplitMode.none) return null;
    if (participants.isEmpty) {
      return const SplitIssue(SplitIssueKind.needParticipant);
    }
    if (amount <= 0) return null;

    if (mode == SplitMode.percent) {
      final sum = participants.fold<double>(
        0,
        (s, id) => s + (rawValues[id] ?? 0),
      );
      if ((sum - 100).abs() > 0.5) {
        return SplitIssue(SplitIssueKind.percentTotal, sum.toStringAsFixed(0));
      }
    }
    if (mode == SplitMode.exact) {
      final sum = participants.fold<double>(
        0,
        (s, id) => s + (rawValues[id] ?? 0),
      );
      if ((sum - amount).abs() > 1) {
        final diff = amount - sum;
        return diff > 0
            ? SplitIssue(SplitIssueKind.shortBy, FormatHelpers.currency(diff))
            : SplitIssue(
                SplitIssueKind.excessBy,
                FormatHelpers.currency(-diff),
              );
      }
    }
    if (mode == SplitMode.shares) {
      final sum = participants.fold<double>(
        0,
        (s, id) => s + (rawValues[id] ?? 0),
      );
      if (sum <= 0) return const SplitIssue(SplitIssueKind.needShares);
    }
    return null;
  }
}

enum SplitIssueKind {
  needParticipant,
  percentTotal,
  shortBy,
  excessBy,
  needShares,
}

/// Lỗi chia tiền dạng cấu trúc: loại lỗi + giá trị chèn vào thông điệp
/// ("70" cho phần trăm, "20.000 ₫" cho chênh lệch).
class SplitIssue {
  const SplitIssue(this.kind, [this.arg]);

  final SplitIssueKind kind;
  final String? arg;
}

extension SplitIssueL10n on SplitIssue {
  String localized(AppLocalizations l10n) => switch (kind) {
    SplitIssueKind.needParticipant => l10n.splitNeedParticipant,
    SplitIssueKind.percentTotal => l10n.splitPercentTotal(arg ?? ''),
    SplitIssueKind.shortBy => l10n.splitShortBy(arg ?? ''),
    SplitIssueKind.excessBy => l10n.splitExcessBy(arg ?? ''),
    SplitIssueKind.needShares => l10n.splitNeedShares,
  };
}

/// Bảng chia tiền: chọn người trả, chọn người gánh, chọn cách chia.
class SplitEditor extends StatelessWidget {
  const SplitEditor({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.paidBy,
    required this.amount,
    required this.state,
    required this.onPaidByChanged,
    required this.onStateChanged,
  });

  final List<GroupMember> members;
  final String? currentUserId;
  final String? paidBy;
  final double amount;
  final SplitState state;
  final ValueChanged<String> onPaidByChanged;
  final ValueChanged<SplitState> onStateChanged;

  String _nameOf(BuildContext context, GroupMember m) {
    if (m.userId == currentUserId) return context.l10n.splitYou;
    final full = m.user?.fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final username = m.user?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    return context.l10n.splitMember;
  }

  void _toggleParticipant(String userId) {
    final next = Set<String>.from(state.participants);
    if (!next.remove(userId)) next.add(userId);
    onStateChanged(state.copyWith(participants: next));
  }

  void _setMode(SplitMode mode) {
    if (mode == SplitMode.none) {
      onStateChanged(SplitState.none);
      return;
    }
    // Bật chia lần đầu: mặc định chia đều cho tất cả thành viên.
    final participants = state.participants.isEmpty
        ? members.map((m) => m.userId).toSet()
        : state.participants;

    var raw = state.rawValues;
    if (mode == SplitMode.percent && raw.isEmpty && participants.isNotEmpty) {
      final even = 100 / participants.length;
      raw = {for (final id in participants) id: even};
    }
    if (mode == SplitMode.shares && raw.isEmpty) {
      raw = {for (final id in participants) id: 1};
    }
    onStateChanged(
      state.copyWith(mode: mode, participants: participants, rawValues: raw),
    );
  }

  void _setRaw(String userId, double value) {
    final raw = Map<String, double>.from(state.rawValues)..[userId] = value;
    onStateChanged(state.copyWith(rawValues: raw));
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final resolved = {
      for (final s in state.resolve(amount)) s.userId: s.shareAmount,
    };
    final error = state.validate(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Người trả ---
        DropdownButtonFormField<String>(
          initialValue: paidBy ?? currentUserId,
          decoration: InputDecoration(labelText: context.l10n.splitPaidByLabel),
          dropdownColor: context.colors.surface,
          items: [
            for (final m in members)
              DropdownMenuItem(
                value: m.userId,
                child: Text(_nameOf(context, m)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onPaidByChanged(v);
          },
        ),
        const SizedBox(height: 16),

        // --- Cách chia ---
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mode in SplitMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(mode.localizedLabel(context)),
                      selected: state.mode == mode,
                      onSelected: (_) => _setMode(mode),
                      backgroundColor: context.colors.surfaceVariant,
                      selectedColor: context.colors.primary.withValues(
                        alpha: 0.25,
                      ),
                      labelStyle: TextStyle(
                        color: state.mode == mode
                            ? context.colors.primary
                            : context.colors.textSecondary,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: state.mode == mode
                            ? context.colors.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (state.mode.isSplit) ...[
          const SizedBox(height: 8),
          ...members.map((m) {
            final selected = state.participants.contains(m.userId);
            return _SplitRow(
              name: _nameOf(context, m),
              selected: selected,
              mode: state.mode,
              rawValue: state.rawValues[m.userId],
              resolvedShare: resolved[m.userId] ?? 0,
              onToggle: () => _toggleParticipant(m.userId),
              onRawChanged: (v) => _setRaw(m.userId, v),
            );
          }),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: context.colors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error.localized(context.l10n),
                      style: TextStyle(
                        color: context.colors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.name,
    required this.selected,
    required this.mode,
    required this.rawValue,
    required this.resolvedShare,
    required this.onToggle,
    required this.onRawChanged,
  });

  final String name;
  final bool selected;
  final SplitMode mode;
  final double? rawValue;
  final double resolvedShare;
  final VoidCallback onToggle;
  final ValueChanged<double> onRawChanged;

  bool get _needsInput =>
      selected && mode != SplitMode.equal && mode != SplitMode.none;

  String _suffixText(BuildContext context) => switch (mode) {
    SplitMode.percent => '%',
    SplitMode.shares => context.l10n.splitSharesSuffix,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final suffix = _suffixText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onToggle(),
            activeColor: context.colors.primary,
            checkColor: context.colors.onPrimary,
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: selected
                    ? context.colors.textPrimary
                    : context.colors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
          if (_needsInput)
            SizedBox(
              width: 96,
              child: TextFormField(
                initialValue: rawValue == null
                    ? ''
                    : (rawValue! % 1 == 0
                          ? rawValue!.toStringAsFixed(0)
                          : rawValue!.toStringAsFixed(2)),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixText: suffix.isEmpty ? null : suffix,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.divider),
                  ),
                ),
                onChanged: (v) =>
                    onRawChanged(FormatHelpers.parseAmount(v) ?? 0),
              ),
            ),
          if (selected && !_needsInput)
            Text(
              FormatHelpers.currency(resolvedShare),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          if (selected && _needsInput) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: Text(
                FormatHelpers.currency(resolvedShare),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
