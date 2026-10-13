import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../domain/group.dart';
import '../providers/active_group_provider.dart';

/// Padding và font nhỏ cho dropdown nhóm (thu gọn ~40% chiều cao).
const _kCompactPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
const _kCompactFontSize = 12.0;
const _kCompactBorderRadius = 12.0;

class GroupSwitcher extends ConsumerWidget {
  const GroupSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final groupsAsync = ref.watch(userGroupsListProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              contentPadding: _kCompactPadding,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(_kCompactBorderRadius),
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(_kCompactBorderRadius),
                ),
              ),
              filled: true,
              fillColor: context.colors.surface,
            ),
            child: Text(
              activeGroup?.name ?? '—',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: _kCompactFontSize,
              ),
            ),
          );
        }
        AppGroup selected;
        try {
          selected =
              activeGroup != null && groups.any((g) => g.id == activeGroup.id)
              ? groups.firstWhere((g) => g.id == activeGroup.id)
              : groups.first;
        } catch (_) {
          selected = groups.first;
        }
        return DropdownButtonFormField<AppGroup>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: _kCompactPadding,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(_kCompactBorderRadius),
              ),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(_kCompactBorderRadius),
              ),
            ),
            filled: true,
            fillColor: context.colors.surface,
          ),
          dropdownColor: context.colors.surface,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: _kCompactFontSize,
          ),
          items: groups
              .map(
                (g) => DropdownMenuItem<AppGroup>(
                  value: g,
                  child: Text(
                    g.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: _kCompactFontSize),
                  ),
                ),
              )
              .toList(),
          onChanged: (g) {
            if (g != null) {
              ref.read(activeGroupProvider.notifier).setActiveGroup(g);
            }
          },
        );
      },
      loading: () => InputDecorator(
        decoration: InputDecoration(
          contentPadding: _kCompactPadding,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(_kCompactBorderRadius),
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(_kCompactBorderRadius),
            ),
          ),
          filled: true,
          fillColor: context.colors.surface,
        ),
        child: Text(
          activeGroup?.name ?? context.l10n.groupsLoading,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: _kCompactFontSize,
          ),
        ),
      ),
      // Không thu gọn im lặng khi lỗi: giữ khung cũ nhưng thêm biểu tượng lỗi
      // kèm tooltip để người dùng biết danh sách nhóm chưa tải được.
      error: (e, _) => InputDecorator(
        decoration: InputDecoration(
          contentPadding: _kCompactPadding,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(_kCompactBorderRadius),
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(_kCompactBorderRadius),
            ),
          ),
          filled: true,
          fillColor: context.colors.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                activeGroup?.name ?? context.l10n.groupsErrorShort,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: _kCompactFontSize,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: localizedError(context.l10n, e),
              triggerMode: TooltipTriggerMode.tap,
              child: Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: context.colors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
