import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';

/// Chính sách quyền riêng tư.
///
/// Bắt buộc phải có khi đưa lên store vì app thu thập dữ liệu tài chính.
/// Bản này mô tả đúng những gì code thực sự làm — sửa cả hai nơi nếu hành vi
/// của app thay đổi.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.settingsPrivacyTitle),
        leading: IconButton(
          tooltip: context.l10n.settingsBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      // Chừa vùng cử chỉ hệ thống ở đáy để dòng cuối không bị che.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Updated(context.l10n.settingsPrivacyUpdated),

            _Heading(context.l10n.settingsPrivacyHeadingDataStored),
            _Body(context.l10n.settingsPrivacyDataAccount),
            _Body(context.l10n.settingsPrivacyDataFinancial),
            _Body(context.l10n.settingsPrivacyDataGroup),
            _Body(context.l10n.settingsPrivacyDataSocialFriends),

            _Heading(context.l10n.settingsPrivacyHeadingWhoSees),
            _Body(context.l10n.settingsPrivacyWhoPersonal),
            _Body(context.l10n.settingsPrivacyWhoShared),
            _Body(context.l10n.settingsPrivacyWhoBalances),
            _Body(context.l10n.settingsPrivacyWhoReceipts),

            _Heading(context.l10n.settingsPrivacyHeadingWhereStored),
            _Body(context.l10n.settingsPrivacyWhereDatabase),
            _Body(context.l10n.settingsPrivacyWhereLocal),

            _Heading(context.l10n.settingsPrivacyHeadingWeDont),
            _Body(context.l10n.settingsPrivacyDontSell),
            _Body(context.l10n.settingsPrivacyDontAds),
            _Body(context.l10n.settingsPrivacyDontBank),

            _Heading(context.l10n.settingsPrivacyHeadingYourRights),
            _Body(context.l10n.settingsPrivacyRightsExport),
            _Body(context.l10n.settingsPrivacyRightsDelete),
            _Body(context.l10n.settingsPrivacyRightsDeleteException),

            _Heading(context.l10n.settingsPrivacyHeadingSecurity),
            _Body(context.l10n.settingsPrivacySecurityHttps),
            _Body(context.l10n.settingsPrivacySecurityBiometric),

            _Heading(context.l10n.settingsPrivacyHeadingContact),
            _Body(context.l10n.settingsPrivacyContactBody),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Updated extends StatelessWidget {
  const _Updated(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}
