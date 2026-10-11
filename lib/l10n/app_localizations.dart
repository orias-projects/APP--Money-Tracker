import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @catBeauty.
  ///
  /// In vi, this message translates to:
  /// **'Làm đẹp'**
  String get catBeauty;

  /// No description provided for @catBonus.
  ///
  /// In vi, this message translates to:
  /// **'Thưởng'**
  String get catBonus;

  /// No description provided for @catCar.
  ///
  /// In vi, this message translates to:
  /// **'Ô tô'**
  String get catCar;

  /// No description provided for @catClothing.
  ///
  /// In vi, this message translates to:
  /// **'Quần áo'**
  String get catClothing;

  /// No description provided for @catDonations.
  ///
  /// In vi, this message translates to:
  /// **'Từ thiện'**
  String get catDonations;

  /// No description provided for @catEducation.
  ///
  /// In vi, this message translates to:
  /// **'Học hành'**
  String get catEducation;

  /// No description provided for @categoryUncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get categoryUncategorized;

  /// No description provided for @catElectronics.
  ///
  /// In vi, this message translates to:
  /// **'Đồ điện tử'**
  String get catElectronics;

  /// No description provided for @catEntertainment.
  ///
  /// In vi, this message translates to:
  /// **'Giải trí'**
  String get catEntertainment;

  /// No description provided for @catFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get catFamily;

  /// No description provided for @catFoodDining.
  ///
  /// In vi, this message translates to:
  /// **'Ăn uống'**
  String get catFoodDining;

  /// No description provided for @catFreelance.
  ///
  /// In vi, this message translates to:
  /// **'Làm tự do'**
  String get catFreelance;

  /// No description provided for @catGifts.
  ///
  /// In vi, this message translates to:
  /// **'Quà tặng'**
  String get catGifts;

  /// No description provided for @catGiftsReceived.
  ///
  /// In vi, this message translates to:
  /// **'Quà nhận được'**
  String get catGiftsReceived;

  /// No description provided for @catHealth.
  ///
  /// In vi, this message translates to:
  /// **'Sức khoẻ'**
  String get catHealth;

  /// No description provided for @catHousing.
  ///
  /// In vi, this message translates to:
  /// **'Nhà cửa'**
  String get catHousing;

  /// No description provided for @catInvestment.
  ///
  /// In vi, this message translates to:
  /// **'Đầu tư'**
  String get catInvestment;

  /// No description provided for @catJob.
  ///
  /// In vi, this message translates to:
  /// **'Công việc'**
  String get catJob;

  /// No description provided for @catOthers.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get catOthers;

  /// No description provided for @catPets.
  ///
  /// In vi, this message translates to:
  /// **'Thú cưng'**
  String get catPets;

  /// No description provided for @catSalary.
  ///
  /// In vi, this message translates to:
  /// **'Lương'**
  String get catSalary;

  /// No description provided for @catShopping.
  ///
  /// In vi, this message translates to:
  /// **'Mua sắm'**
  String get catShopping;

  /// No description provided for @catSocial.
  ///
  /// In vi, this message translates to:
  /// **'Giao lưu'**
  String get catSocial;

  /// No description provided for @catSports.
  ///
  /// In vi, this message translates to:
  /// **'Thể thao'**
  String get catSports;

  /// No description provided for @catTransportation.
  ///
  /// In vi, this message translates to:
  /// **'Đi lại'**
  String get catTransportation;

  /// No description provided for @catTravel.
  ///
  /// In vi, this message translates to:
  /// **'Du lịch'**
  String get catTravel;

  /// No description provided for @txCategoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get txCategoryLabel;

  /// No description provided for @accountAvatarTapToChange.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào ảnh để đổi'**
  String get accountAvatarTapToChange;

  /// No description provided for @accountBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get accountBack;

  /// No description provided for @accountChangePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get accountChangePassword;

  /// No description provided for @accountConfirmNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get accountConfirmNewPassword;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get accountCurrentPassword;

  /// No description provided for @accountDisplayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get accountDisplayName;

  /// No description provided for @accountDisplayNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Hiện với thành viên nhóm. Không cần duy nhất.'**
  String get accountDisplayNameHint;

  /// No description provided for @accountEditUsernameTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên đăng nhập'**
  String get accountEditUsernameTitle;

  /// No description provided for @accountEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountEmailAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm email'**
  String get accountEmailAdd;

  /// No description provided for @accountEmailChange.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get accountEmailChange;

  /// No description provided for @accountEmailDialogHint.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi sẽ gửi liên kết xác minh tới địa chỉ này. Sau khi xác minh, email cũng dùng được để đăng nhập.'**
  String get accountEmailDialogHint;

  /// No description provided for @accountEmailNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có email'**
  String get accountEmailNone;

  /// No description provided for @accountEmailPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác minh: {email}'**
  String accountEmailPending(String email);

  /// No description provided for @accountEmailPendingHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở liên kết đã gửi tới địa chỉ đó để hoàn tất.'**
  String get accountEmailPendingHint;

  /// No description provided for @accountEmailResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get accountEmailResend;

  /// No description provided for @accountEmailResent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lại email xác minh.'**
  String get accountEmailResent;

  /// No description provided for @accountEmailSaved.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra {email} và mở liên kết xác minh.'**
  String accountEmailSaved(String email);

  /// No description provided for @accountEmailUnverified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác minh'**
  String get accountEmailUnverified;

  /// No description provided for @accountEmailVerified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác minh'**
  String get accountEmailVerified;

  /// No description provided for @accountLink.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết'**
  String get accountLink;

  /// No description provided for @accountLinkBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất trong trình duyệt rồi quay lại đây.'**
  String get accountLinkBrowser;

  /// No description provided for @accountLinkHint.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập nhanh hơn và tìm bạn bè từ các tài khoản này.'**
  String get accountLinkHint;

  /// No description provided for @accountNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get accountNewPassword;

  /// No description provided for @accountNotLinked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa liên kết'**
  String get accountNotLinked;

  /// No description provided for @accountNotSet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt'**
  String get accountNotSet;

  /// No description provided for @accountPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get accountPassword;

  /// No description provided for @accountPasswordChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật mật khẩu.'**
  String get accountPasswordChanged;

  /// No description provided for @accountPasswordNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mật khẩu — bạn đăng nhập bằng tài khoản liên kết.'**
  String get accountPasswordNone;

  /// No description provided for @accountPasswordSet.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt mật khẩu'**
  String get accountPasswordSet;

  /// No description provided for @accountSectionLinked.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản liên kết'**
  String get accountSectionLinked;

  /// No description provided for @accountSectionLogin.
  ///
  /// In vi, this message translates to:
  /// **'Cách đăng nhập'**
  String get accountSectionLogin;

  /// No description provided for @accountSectionProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get accountSectionProfile;

  /// No description provided for @accountSelAmountOwed.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền đang nợ'**
  String get accountSelAmountOwed;

  /// No description provided for @accountSelCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví'**
  String get accountSelCreate;

  /// No description provided for @accountSelCreateAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get accountSelCreateAction;

  /// No description provided for @accountSelCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví mới'**
  String get accountSelCreateNew;

  /// No description provided for @accountSelCurrentBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư hiện có'**
  String get accountSelCurrentBalance;

  /// No description provided for @accountSelEnterName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên ví.'**
  String get accountSelEnterName;

  /// No description provided for @accountSelNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Tiền mặt'**
  String get accountSelNameHint;

  /// No description provided for @accountSelOwedHelper.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số dương — số tiền bạn đang nợ.'**
  String get accountSelOwedHelper;

  /// No description provided for @accountSelSharedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mọi thành viên nhóm \"{name}\" đều xem và ghi được.'**
  String accountSelSharedSubtitle(String name);

  /// No description provided for @accountSelSharedWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví dùng chung'**
  String get accountSelSharedWallet;

  /// No description provided for @accountSelTypeLiability.
  ///
  /// In vi, this message translates to:
  /// **'Nợ / Thẻ'**
  String get accountSelTypeLiability;

  /// No description provided for @accountSetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mật khẩu'**
  String get accountSetPassword;

  /// No description provided for @accountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accountTitle;

  /// No description provided for @accountUnlink.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ liên kết'**
  String get accountUnlink;

  /// No description provided for @accountUnlinkBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đặt mật khẩu hoặc liên kết tài khoản khác trước.'**
  String get accountUnlinkBlocked;

  /// No description provided for @accountUnlinkConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ không đăng nhập được bằng tài khoản này nữa.'**
  String get accountUnlinkConfirmBody;

  /// No description provided for @accountUnlinkConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ liên kết {provider}?'**
  String accountUnlinkConfirmTitle(String provider);

  /// No description provided for @accountUnlinked.
  ///
  /// In vi, this message translates to:
  /// **'Đã gỡ liên kết {provider}.'**
  String accountUnlinked(String provider);

  /// No description provided for @accountUsername.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập'**
  String get accountUsername;

  /// No description provided for @accountUsernameHint.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để đăng nhập. Chữ thường, số, dấu chấm, gạch dưới.'**
  String get accountUsernameHint;

  /// No description provided for @accountUsernameSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật tên đăng nhập.'**
  String get accountUsernameSaved;

  /// No description provided for @accountsActualBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư thực tế'**
  String get accountsActualBalance;

  /// No description provided for @accountsAddWallet.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ví'**
  String get accountsAddWallet;

  /// No description provided for @accountsAdjustBalance.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh số dư'**
  String get accountsAdjustBalance;

  /// No description provided for @accountsAdjustBalanceSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi một giao dịch điều chỉnh, không sửa sổ cũ'**
  String get accountsAdjustBalanceSubtitle;

  /// No description provided for @accountsAdjustNote.
  ///
  /// In vi, this message translates to:
  /// **'Chênh lệch được ghi thành một giao dịch điều chỉnh để sổ cái và số dư luôn khớp nhau.'**
  String get accountsAdjustNote;

  /// No description provided for @accountsAdjustmentRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi giao dịch điều chỉnh.'**
  String get accountsAdjustmentRecorded;

  /// No description provided for @accountsArchive.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ ví'**
  String get accountsArchive;

  /// No description provided for @accountsArchiveSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn khỏi danh sách, giữ nguyên lịch sử giao dịch'**
  String get accountsArchiveSubtitle;

  /// No description provided for @accountsArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ ví.'**
  String get accountsArchived;

  /// No description provided for @accountsBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get accountsBack;

  /// No description provided for @accountsBadgeExcluded.
  ///
  /// In vi, this message translates to:
  /// **'Không tính'**
  String get accountsBadgeExcluded;

  /// No description provided for @accountsBadgeShared.
  ///
  /// In vi, this message translates to:
  /// **'Chung'**
  String get accountsBadgeShared;

  /// No description provided for @accountsCreditLeft.
  ///
  /// In vi, this message translates to:
  /// **'còn {amount}'**
  String accountsCreditLeft(String amount);

  /// No description provided for @accountsCreditLimitLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức tín dụng'**
  String get accountsCreditLimitLabel;

  /// No description provided for @accountsCurrencyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tiền tệ'**
  String get accountsCurrencyLabel;

  /// No description provided for @accountsCurrentBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư hiện tại: {amount}'**
  String accountsCurrentBalance(String amount);

  /// No description provided for @accountsEditWallet.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ví'**
  String get accountsEditWallet;

  /// No description provided for @accountsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví đầu tiên để bắt đầu ghi chép.'**
  String get accountsEmptyMessage;

  /// No description provided for @accountsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào'**
  String get accountsEmptyTitle;

  /// No description provided for @accountsGroupArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get accountsGroupArchived;

  /// No description provided for @accountsGroupAssets.
  ///
  /// In vi, this message translates to:
  /// **'Tài sản'**
  String get accountsGroupAssets;

  /// No description provided for @accountsGroupLiabilities.
  ///
  /// In vi, this message translates to:
  /// **'Nợ và thẻ tín dụng'**
  String get accountsGroupLiabilities;

  /// No description provided for @accountsIncludeNetWorth.
  ///
  /// In vi, this message translates to:
  /// **'Tính vào tài sản ròng'**
  String get accountsIncludeNetWorth;

  /// No description provided for @accountsInvalidBalance.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số dư hợp lệ.'**
  String get accountsInvalidBalance;

  /// No description provided for @accountsMoreActions.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn'**
  String get accountsMoreActions;

  /// No description provided for @accountsNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví *'**
  String get accountsNameLabel;

  /// No description provided for @accountsNoGroup.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn nhóm.'**
  String get accountsNoGroup;

  /// No description provided for @accountsPayDay.
  ///
  /// In vi, this message translates to:
  /// **'trả ngày {day}'**
  String accountsPayDay(int day);

  /// No description provided for @accountsPaymentDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thanh toán'**
  String get accountsPaymentDay;

  /// No description provided for @accountsReconcile.
  ///
  /// In vi, this message translates to:
  /// **'Đối soát ví này'**
  String get accountsReconcile;

  /// No description provided for @accountsReconcileResult.
  ///
  /// In vi, this message translates to:
  /// **'Số dư sau đối soát: {amount}'**
  String accountsReconcileResult(String amount);

  /// No description provided for @accountsRecordAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Ghi điều chỉnh'**
  String get accountsRecordAdjustment;

  /// No description provided for @accountsRestore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục ví'**
  String get accountsRestore;

  /// No description provided for @accountsRestored.
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục ví.'**
  String get accountsRestored;

  /// No description provided for @accountsStatementDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sao kê'**
  String get accountsStatementDay;

  /// No description provided for @accountsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví'**
  String get accountsTitle;

  /// No description provided for @accountsWillRecordExpense.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ ghi một khoản CHI {amount}'**
  String accountsWillRecordExpense(String amount);

  /// No description provided for @accountsWillRecordIncome.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ ghi một khoản THU {amount}'**
  String accountsWillRecordIncome(String amount);

  /// No description provided for @actionAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get actionAdd;

  /// No description provided for @actionCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get actionConfirm;

  /// No description provided for @actionDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get actionDone;

  /// No description provided for @actionEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get actionEdit;

  /// No description provided for @actionRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get actionSave;

  /// No description provided for @appLockLocked.
  ///
  /// In vi, this message translates to:
  /// **'Coinsort đang khoá'**
  String get appLockLocked;

  /// No description provided for @appLockReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để mở Coinsort'**
  String get appLockReason;

  /// No description provided for @appLockUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Mở khoá'**
  String get appLockUnlock;

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Coinsort'**
  String get appTitle;

  /// No description provided for @authBackToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đăng nhập'**
  String get authBackToLogin;

  /// No description provided for @authBrowserWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đăng nhập trong trình duyệt rồi quay lại đây.'**
  String get authBrowserWaiting;

  /// No description provided for @authCodeSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã gửi đến {email}'**
  String authCodeSentTo(String email);

  /// No description provided for @authConfirmNewPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới *'**
  String get authConfirmNewPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get authConfirmPasswordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu *'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập xác nhận mật khẩu'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authContinueWithFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Facebook'**
  String get authContinueWithFacebook;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithX.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với X'**
  String get authContinueWithX;

  /// No description provided for @authEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'email@vd.com'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get authEmailInvalid;

  /// No description provided for @authEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email *'**
  String get authEmailLabel;

  /// No description provided for @authEmailReadOnlyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get authEmailReadOnlyLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email'**
  String get authEmailRequired;

  /// No description provided for @authEnterAllSixDigits.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ 6 số từ email'**
  String get authEnterAllSixDigits;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get authForgotPasswordLink;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đăng ký để nhận mã 6 số.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mật khẩu'**
  String get authForgotPasswordTitle;

  /// No description provided for @authFullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nguyễn Văn A'**
  String get authFullNameHint;

  /// No description provided for @authFullNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên'**
  String get authFullNameLabel;

  /// No description provided for @authHaveAccountLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get authHaveAccountLogin;

  /// No description provided for @authHidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get authHidePassword;

  /// No description provided for @authIdentifierHint.
  ///
  /// In vi, this message translates to:
  /// **'email@vd.com hoặc tên đăng nhập'**
  String get authIdentifierHint;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc tên đăng nhập *'**
  String get authIdentifierLabel;

  /// No description provided for @authIdentifierRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email hoặc tên đăng nhập'**
  String get authIdentifierRequired;

  /// No description provided for @authLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLoginTitle;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới *'**
  String get authNewPasswordLabel;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? Đăng ký'**
  String get authNoAccountRegister;

  /// No description provided for @authOrContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'hoặc tiếp tục với'**
  String get authOrContinueWith;

  /// No description provided for @authPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu'**
  String get authPasswordHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu *'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordMinHint.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu 6 ký tự'**
  String get authPasswordMinHint;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối thiểu 6 ký tự'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu không trùng khớp'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu'**
  String get authPasswordRequired;

  /// No description provided for @authRecoverCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác nhận'**
  String get authRecoverCodeTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ cần tên đăng nhập và mật khẩu. Email có thể thêm sau trong Tài khoản.'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get authRegisterTitle;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get authResetPasswordTitle;

  /// No description provided for @authSendRecoveryCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã khôi phục'**
  String get authSendRecoveryCode;

  /// No description provided for @authShowPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get authShowPassword;

  /// No description provided for @authUpdatePassword.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mật khẩu'**
  String get authUpdatePassword;

  /// No description provided for @authUsernameHint.
  ///
  /// In vi, this message translates to:
  /// **'tên đăng nhập'**
  String get authUsernameHint;

  /// No description provided for @authUsernameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập *'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên đăng nhập'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameRules.
  ///
  /// In vi, this message translates to:
  /// **'3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới'**
  String get authUsernameRules;

  /// No description provided for @authVerificationCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác nhận *'**
  String get authVerificationCodeLabel;

  /// No description provided for @budgetsBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get budgetsBack;

  /// No description provided for @budgetsCategoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục *'**
  String get budgetsCategoryLabel;

  /// No description provided for @budgetsChooseCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn danh mục.'**
  String get budgetsChooseCategory;

  /// No description provided for @budgetsDaysLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String budgetsDaysLeft(int days);

  /// No description provided for @budgetsDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hạn mức cho \"{category}\"?'**
  String budgetsDeleteConfirm(String category);

  /// No description provided for @budgetsDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ngân sách'**
  String get budgetsDeleteTitle;

  /// No description provided for @budgetsDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá ngân sách.'**
  String get budgetsDeleted;

  /// No description provided for @budgetsEditLimit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hạn mức'**
  String get budgetsEditLimit;

  /// No description provided for @budgetsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đặt hạn mức cho một danh mục để biết khi nào tiêu quá tay.'**
  String get budgetsEmptyMessage;

  /// No description provided for @budgetsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt ngân sách nào'**
  String get budgetsEmptyTitle;

  /// No description provided for @budgetsInvalidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Nhập hạn mức lớn hơn 0.'**
  String get budgetsInvalidAmount;

  /// No description provided for @budgetsLimitLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức *'**
  String get budgetsLimitLabel;

  /// No description provided for @budgetsOverBy.
  ///
  /// In vi, this message translates to:
  /// **'Vượt {amount}'**
  String budgetsOverBy(String amount);

  /// No description provided for @budgetsPastPeriods.
  ///
  /// In vi, this message translates to:
  /// **'KỲ ĐÃ QUA'**
  String get budgetsPastPeriods;

  /// No description provided for @budgetsPeriodLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chu kỳ'**
  String get budgetsPeriodLabel;

  /// No description provided for @budgetsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount}'**
  String budgetsRemaining(String amount);

  /// No description provided for @budgetsSetLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đặt hạn mức'**
  String get budgetsSetLimit;

  /// No description provided for @budgetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get budgetsTitle;

  /// No description provided for @budgetsTotalActive.
  ///
  /// In vi, this message translates to:
  /// **'Tổng hạn mức đang chạy'**
  String get budgetsTotalActive;

  /// No description provided for @categoriesAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục'**
  String get categoriesAdd;

  /// No description provided for @categoriesColorLabel.
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get categoriesColorLabel;

  /// No description provided for @categoriesDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá \"{name}\"? Giao dịch đã dùng danh mục này vẫn giữ nguyên nhãn cũ trong lịch sử.'**
  String categoriesDeleteConfirm(String name);

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá danh mục'**
  String get categoriesDeleteTitle;

  /// No description provided for @categoriesDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá danh mục.'**
  String get categoriesDeleted;

  /// No description provided for @categoriesDragHandle.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để sắp xếp'**
  String get categoriesDragHandle;

  /// No description provided for @categoriesEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get categoriesEditTitle;

  /// No description provided for @categoriesEmptyMessageExpense.
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục đầu tiên cho khoản chi.'**
  String get categoriesEmptyMessageExpense;

  /// No description provided for @categoriesEmptyMessageIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục đầu tiên cho khoản thu.'**
  String get categoriesEmptyMessageIncome;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesIconLabel.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get categoriesIconLabel;

  /// No description provided for @categoriesManageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục'**
  String get categoriesManageTitle;

  /// No description provided for @categoriesNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Cà phê'**
  String get categoriesNameHint;

  /// No description provided for @categoriesNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục *'**
  String get categoriesNameLabel;

  /// No description provided for @categoriesNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên danh mục.'**
  String get categoriesNameRequired;

  /// No description provided for @categoriesNotEditable.
  ///
  /// In vi, this message translates to:
  /// **'Không sửa được'**
  String get categoriesNotEditable;

  /// No description provided for @categoriesReorderFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được thứ tự.'**
  String get categoriesReorderFailed;

  /// No description provided for @categoriesSectionSystem.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục hệ thống'**
  String get categoriesSectionSystem;

  /// No description provided for @categoriesSectionYours.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục của bạn — kéo để sắp xếp'**
  String get categoriesSectionYours;

  /// No description provided for @categoriesTabExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get categoriesTabExpense;

  /// No description provided for @categoriesTabIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get categoriesTabIncome;

  /// No description provided for @chartsDateRangeSuffix.
  ///
  /// In vi, this message translates to:
  /// **'\n(từ {start} đến {end})'**
  String chartsDateRangeSuffix(String start, String end);

  /// No description provided for @chartsError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String chartsError(String error);

  /// No description provided for @chartsExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get chartsExpense;

  /// No description provided for @chartsIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get chartsIncome;

  /// No description provided for @chartsNoData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get chartsNoData;

  /// No description provided for @chartsNoTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch'**
  String get chartsNoTransactions;

  /// No description provided for @chartsOthers.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get chartsOthers;

  /// No description provided for @chartsOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan Thu / Chi'**
  String get chartsOverviewTitle;

  /// No description provided for @chartsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get chartsRemaining;

  /// No description provided for @chartsTabExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get chartsTabExpense;

  /// No description provided for @chartsTabIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get chartsTabIncome;

  /// No description provided for @chartsTabOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get chartsTabOverview;

  /// No description provided for @chartsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ'**
  String get chartsTitle;

  /// No description provided for @chartsTopExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi cao nhất gần đây'**
  String get chartsTopExpense;

  /// No description provided for @chartsTopIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu cao nhất gần đây'**
  String get chartsTopIncome;

  /// No description provided for @chartsTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get chartsTotal;

  /// No description provided for @commonAddTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giao dịch'**
  String get commonAddTransaction;

  /// No description provided for @commonBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get commonBack;

  /// No description provided for @commonNavCharts.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ'**
  String get commonNavCharts;

  /// No description provided for @commonNavProfile.
  ///
  /// In vi, this message translates to:
  /// **'Tôi'**
  String get commonNavProfile;

  /// No description provided for @commonNavReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get commonNavReports;

  /// No description provided for @commonNavTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get commonNavTransactions;

  /// No description provided for @commonOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get commonOther;

  /// No description provided for @commonPaidBy.
  ///
  /// In vi, this message translates to:
  /// **'Trả bởi {name}'**
  String commonPaidBy(String name);

  /// No description provided for @commonTabExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get commonTabExpense;

  /// No description provided for @commonTabIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get commonTabIncome;

  /// No description provided for @commonTabTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển'**
  String get commonTabTransfer;

  /// No description provided for @csvHeaderAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get csvHeaderAmount;

  /// No description provided for @csvHeaderCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get csvHeaderCategory;

  /// No description provided for @csvHeaderCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị'**
  String get csvHeaderCurrency;

  /// No description provided for @csvHeaderDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get csvHeaderDate;

  /// No description provided for @csvHeaderMyShare.
  ///
  /// In vi, this message translates to:
  /// **'Phần của tôi'**
  String get csvHeaderMyShare;

  /// No description provided for @csvHeaderNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get csvHeaderNote;

  /// No description provided for @csvHeaderPayer.
  ///
  /// In vi, this message translates to:
  /// **'Người trả'**
  String get csvHeaderPayer;

  /// No description provided for @csvHeaderPlace.
  ///
  /// In vi, this message translates to:
  /// **'Nơi chi'**
  String get csvHeaderPlace;

  /// No description provided for @csvHeaderSplitMode.
  ///
  /// In vi, this message translates to:
  /// **'Cách chia'**
  String get csvHeaderSplitMode;

  /// No description provided for @csvHeaderTargetWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví đích'**
  String get csvHeaderTargetWallet;

  /// No description provided for @csvHeaderType.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get csvHeaderType;

  /// No description provided for @csvHeaderWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get csvHeaderWallet;

  /// No description provided for @csvTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get csvTransfer;

  /// No description provided for @csvUncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get csvUncategorized;

  /// No description provided for @dayToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get dayYesterday;

  /// No description provided for @deleteConfirmPhrase.
  ///
  /// In vi, this message translates to:
  /// **'XOA TAI KHOAN'**
  String get deleteConfirmPhrase;

  /// No description provided for @errAmountInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền phải lớn hơn 0.'**
  String get errAmountInvalid;

  /// No description provided for @errBalanceUnchanged.
  ///
  /// In vi, this message translates to:
  /// **'Số dư mới trùng số dư hiện tại.'**
  String get errBalanceUnchanged;

  /// No description provided for @errBudgetAmountInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức phải lớn hơn 0.'**
  String get errBudgetAmountInvalid;

  /// No description provided for @errCategoryNameEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục không được để trống.'**
  String get errCategoryNameEmpty;

  /// No description provided for @errCodeExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã đã hết hạn. Hãy yêu cầu mã mới.'**
  String get errCodeExpired;

  /// No description provided for @errCurrentPasswordWrong.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại không đúng.'**
  String get errCurrentPasswordWrong;

  /// No description provided for @errDeleteTransactionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Không xoá được giao dịch. Có thể bạn không còn ở trong nhóm này.'**
  String get errDeleteTransactionDenied;

  /// No description provided for @errDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu này đã tồn tại.'**
  String get errDuplicate;

  /// No description provided for @errEmailAlreadyRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng Quên mật khẩu.'**
  String get errEmailAlreadyRegistered;

  /// No description provided for @errEmailExists.
  ///
  /// In vi, this message translates to:
  /// **'Email này đã được dùng cho tài khoản khác.'**
  String get errEmailExists;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác nhận email trước khi đăng nhập. Kiểm tra hộp thư và thư mục spam.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errGoogleNotConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Bản dựng này chưa được cấu hình đăng nhập Google.'**
  String get errGoogleNotConfigured;

  /// No description provided for @errGroupCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được nhóm.'**
  String get errGroupCreateFailed;

  /// No description provided for @errGroupNameEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm không được để trống.'**
  String get errGroupNameEmpty;

  /// No description provided for @errIdentityAlreadyLinked.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đã được liên kết với một người dùng Coinsort khác.'**
  String get errIdentityAlreadyLinked;

  /// No description provided for @errImageTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh lớn hơn 5MB. Hãy chụp lại ở chất lượng thấp hơn.'**
  String get errImageTooLarge;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc mật khẩu không đúng.'**
  String get errInvalidCredentials;

  /// No description provided for @errInvalidData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu không hợp lệ. Kiểm tra lại số tiền và các trường bắt buộc.'**
  String get errInvalidData;

  /// No description provided for @errInvalidReference.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu liên kết không hợp lệ hoặc đã bị xoá.'**
  String get errInvalidReference;

  /// No description provided for @errLastLoginMethod.
  ///
  /// In vi, this message translates to:
  /// **'Đây là cách đăng nhập duy nhất của bạn. Hãy đặt mật khẩu hoặc liên kết tài khoản khác trước khi gỡ.'**
  String get errLastLoginMethod;

  /// No description provided for @errLoginIdentifierEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email hoặc tên đăng nhập.'**
  String get errLoginIdentifierEmpty;

  /// No description provided for @errManualLinkingDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa bật tính năng liên kết tài khoản.'**
  String get errManualLinkingDisabled;

  /// No description provided for @errNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.'**
  String get errNetwork;

  /// No description provided for @errNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dữ liệu.'**
  String get errNotFound;

  /// No description provided for @errNotLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập. Vui lòng đăng nhập lại.'**
  String get errNotLoggedIn;

  /// No description provided for @errNothingToSave.
  ///
  /// In vi, this message translates to:
  /// **'Không có thay đổi nào để lưu.'**
  String get errNothingToSave;

  /// No description provided for @errOauthCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã huỷ đăng nhập.'**
  String get errOauthCancelled;

  /// No description provided for @errOauthFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được bằng tài khoản này. Thử lại sau.'**
  String get errOauthFailed;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu quá ngắn. Dùng ít nhất 6 ký tự.'**
  String get errPasswordTooShort;

  /// No description provided for @errPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này.'**
  String get errPermissionDenied;

  /// No description provided for @errProfileLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công nhưng không lấy được hồ sơ. Thử lại sau ít phút.'**
  String get errProfileLoadFailed;

  /// No description provided for @errProviderTokenMissing.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối lại Facebook để đồng bộ bạn bè.'**
  String get errProviderTokenMissing;

  /// No description provided for @errProviderDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Cách đăng nhập này đang tạm ngưng.'**
  String get errProviderDisabled;

  /// No description provided for @errRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thử quá nhiều lần. Đợi một lát rồi thử lại.'**
  String get errRateLimited;

  /// No description provided for @errRegisterConfirmEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công. Kiểm tra email để xác nhận rồi đăng nhập.'**
  String get errRegisterConfirmEmail;

  /// No description provided for @errServerError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả về lỗi.'**
  String get errServerError;

  /// No description provided for @errServerNotSetup.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa được cài đặt đầy đủ. Vui lòng liên hệ hỗ trợ.'**
  String get errServerNotSetup;

  /// No description provided for @errSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'**
  String get errSessionExpired;

  /// No description provided for @errShareUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không hỗ trợ chia sẻ file.'**
  String get errShareUnsupported;

  /// No description provided for @errTransactionNotReturned.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không trả về giao dịch vừa ghi.'**
  String get errTransactionNotReturned;

  /// No description provided for @errUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Thử lại sau ít phút.'**
  String get errUnknown;

  /// No description provided for @errUsernameInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập gồm 3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.'**
  String get errUsernameInvalid;

  /// No description provided for @errUsernameNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tài khoản với tên đăng nhập này.'**
  String get errUsernameNotFound;

  /// No description provided for @errUsernameRequiredForPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đặt tên đăng nhập hoặc thêm email trước để có thể đăng nhập bằng mật khẩu.'**
  String get errUsernameRequiredForPassword;

  /// No description provided for @errUsernameTaken.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập này đã có người dùng.'**
  String get errUsernameTaken;

  /// No description provided for @exportShareSubject.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu giao dịch Coinsort'**
  String get exportShareSubject;

  /// No description provided for @filterAccountsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get filterAccountsLabel;

  /// No description provided for @filterApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get filterApply;

  /// No description provided for @filterClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get filterClear;

  /// No description provided for @filterDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Từ {start} đến {end}'**
  String filterDateRange(String start, String end);

  /// No description provided for @filterMax90Days.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ được chọn tối đa 90 ngày'**
  String get filterMax90Days;

  /// No description provided for @filterTime30Days.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày qua'**
  String get filterTime30Days;

  /// No description provided for @filterTime7Days.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày qua'**
  String get filterTime7Days;

  /// No description provided for @filterTimeAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterTimeAll;

  /// No description provided for @filterTimeCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn'**
  String get filterTimeCustom;

  /// No description provided for @filterTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get filterTimeLabel;

  /// No description provided for @filterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get filterTitle;

  /// No description provided for @freqDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hàng ngày'**
  String get freqDaily;

  /// No description provided for @freqMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tháng'**
  String get freqMonthly;

  /// No description provided for @freqWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tuần'**
  String get freqWeekly;

  /// No description provided for @freqYearly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng năm'**
  String get freqYearly;

  /// No description provided for @groupsAllBalanced.
  ///
  /// In vi, this message translates to:
  /// **'Mọi khoản chi có chia đều đã cân.'**
  String get groupsAllBalanced;

  /// No description provided for @groupsCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã mời.'**
  String get groupsCodeCopied;

  /// No description provided for @groupsConfirmPaymentBody.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận bạn đã chuyển {amount} cho {name}?\n\nViệc này chỉ ghi nhận công nợ, không tự trừ tiền trong ví. Nếu muốn ghi cả dòng tiền, hãy tạo thêm một giao dịch chuyển khoản.'**
  String groupsConfirmPaymentBody(String amount, String name);

  /// No description provided for @groupsCopyCodeTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get groupsCopyCodeTooltip;

  /// No description provided for @groupsCreateButton.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm'**
  String get groupsCreateButton;

  /// No description provided for @groupsCreateNew.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm mới'**
  String get groupsCreateNew;

  /// No description provided for @groupsDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xoá được nhóm.'**
  String get groupsDeleteFailed;

  /// No description provided for @groupsDeleteGroup.
  ///
  /// In vi, this message translates to:
  /// **'Xóa nhóm'**
  String get groupsDeleteGroup;

  /// No description provided for @groupsDeleteGroupConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa nhóm \"{name}\"? Thành viên sẽ mất quyền truy cập. Không hoàn tác được.'**
  String groupsDeleteGroupConfirm(String name);

  /// No description provided for @groupsEditGroupName.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên nhóm'**
  String get groupsEditGroupName;

  /// No description provided for @groupsEditNameTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên'**
  String get groupsEditNameTooltip;

  /// No description provided for @groupsEmptyList.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhóm. Tạo hoặc tham gia nhóm bên dưới.'**
  String get groupsEmptyList;

  /// No description provided for @groupsEnterGroupName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên nhóm'**
  String get groupsEnterGroupName;

  /// No description provided for @groupsEnterInviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời'**
  String get groupsEnterInviteCode;

  /// No description provided for @groupsError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String groupsError(String error);

  /// No description provided for @groupsErrorShort.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get groupsErrorShort;

  /// No description provided for @groupsFromTo.
  ///
  /// In vi, this message translates to:
  /// **'{from} → {to}'**
  String groupsFromTo(String from, String to);

  /// No description provided for @groupsGroupDebts.
  ///
  /// In vi, this message translates to:
  /// **'Công nợ nhóm'**
  String get groupsGroupDebts;

  /// No description provided for @groupsGroupDebtsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ai đang nợ ai và cần chuyển bao nhiêu'**
  String get groupsGroupDebtsSubtitle;

  /// No description provided for @groupsGroupDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa nhóm'**
  String get groupsGroupDeleted;

  /// No description provided for @groupsGroupNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Chi tiêu gia đình'**
  String get groupsGroupNameHint;

  /// No description provided for @groupsGroupNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm *'**
  String get groupsGroupNameLabel;

  /// No description provided for @groupsGroupNameUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật tên nhóm'**
  String get groupsGroupNameUpdated;

  /// No description provided for @groupsInviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời'**
  String get groupsInviteCode;

  /// No description provided for @groupsInviteCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: K7QM2XPD'**
  String get groupsInviteCodeHint;

  /// No description provided for @groupsInviteCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời *'**
  String get groupsInviteCodeLabel;

  /// No description provided for @groupsInviteCodeSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời {code}'**
  String groupsInviteCodeSemantics(String code);

  /// No description provided for @groupsJoinButton.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia nhóm'**
  String get groupsJoinButton;

  /// No description provided for @groupsJoinByCodeHeader.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia bằng mã mời'**
  String get groupsJoinByCodeHeader;

  /// No description provided for @groupsJoinedGroup.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia nhóm'**
  String get groupsJoinedGroup;

  /// No description provided for @groupsLeaveGroup.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get groupsLeaveGroup;

  /// No description provided for @groupsLeaveGroupConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn rời nhóm \"{name}\"?'**
  String groupsLeaveGroupConfirm(String name);

  /// No description provided for @groupsLoadListFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách nhóm.'**
  String get groupsLoadListFailed;

  /// No description provided for @groupsLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get groupsLoading;

  /// No description provided for @groupsManageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo & tham gia nhóm'**
  String get groupsManageTitle;

  /// No description provided for @groupsMarkPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả'**
  String get groupsMarkPaid;

  /// No description provided for @groupsMemberLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get groupsMemberLabel;

  /// No description provided for @groupsMyGroups.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm của tôi'**
  String get groupsMyGroups;

  /// No description provided for @groupsNameYou.
  ///
  /// In vi, this message translates to:
  /// **'{name} (bạn)'**
  String groupsNameYou(String name);

  /// No description provided for @groupsNewCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mới: {code}'**
  String groupsNewCode(String code);

  /// No description provided for @groupsNoMembers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên'**
  String get groupsNoMembers;

  /// No description provided for @groupsNoSettlements.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyết toán nào'**
  String get groupsNoSettlements;

  /// No description provided for @groupsNobodyOwes.
  ///
  /// In vi, this message translates to:
  /// **'Không ai nợ ai'**
  String get groupsNobodyOwes;

  /// No description provided for @groupsPaidShare.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả {paid} · phần gánh {owed}'**
  String groupsPaidShare(String paid, String owed);

  /// No description provided for @groupsPaymentRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận thanh toán.'**
  String get groupsPaymentRecorded;

  /// No description provided for @groupsPerPersonDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết từng người'**
  String get groupsPerPersonDetail;

  /// No description provided for @groupsPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get groupsPersonal;

  /// No description provided for @groupsRecordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi nhận được.'**
  String get groupsRecordFailed;

  /// No description provided for @groupsRecordPayment.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận đã trả'**
  String get groupsRecordPayment;

  /// No description provided for @groupsRemoveFromGroup.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi nhóm'**
  String get groupsRemoveFromGroup;

  /// No description provided for @groupsRemoveMemberConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa \"{name}\" khỏi nhóm \"{groupName}\"?'**
  String groupsRemoveMemberConfirm(String name, String groupName);

  /// No description provided for @groupsRenameFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không sửa được tên nhóm.'**
  String get groupsRenameFailed;

  /// No description provided for @groupsRoleAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Admin'**
  String get groupsRoleAdmin;

  /// No description provided for @groupsRotateCodeTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã mới'**
  String get groupsRotateCodeTooltip;

  /// No description provided for @groupsSettled.
  ///
  /// In vi, this message translates to:
  /// **'Đã cân'**
  String get groupsSettled;

  /// No description provided for @groupsSettlementHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử quyết toán'**
  String get groupsSettlementHistory;

  /// No description provided for @groupsSettlementsEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Các lần trả nợ đã ghi nhận sẽ hiện ở đây.'**
  String get groupsSettlementsEmptyHint;

  /// No description provided for @groupsStillOwes.
  ///
  /// In vi, this message translates to:
  /// **'còn nợ {amount}'**
  String groupsStillOwes(String amount);

  /// No description provided for @groupsToReceive.
  ///
  /// In vi, this message translates to:
  /// **'được nhận {amount}'**
  String groupsToReceive(String amount);

  /// No description provided for @groupsToTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Cần chuyển'**
  String get groupsToTransfer;

  /// No description provided for @groupsToTransferSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Số lần chuyển ít nhất để mọi người về 0'**
  String get groupsToTransferSubtitle;

  /// No description provided for @groupsYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get groupsYou;

  /// No description provided for @memberFallback.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get memberFallback;

  /// No description provided for @notifAccept.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get notifAccept;

  /// No description provided for @notifBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get notifBack;

  /// No description provided for @notifDecline.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get notifDecline;

  /// No description provided for @notifDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời.'**
  String get notifDeclined;

  /// No description provided for @notifEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào.'**
  String get notifEmpty;

  /// No description provided for @notifError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String notifError(String error);

  /// No description provided for @notifInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} mời bạn vào nhóm'**
  String notifInviteTitle(String inviter);

  /// No description provided for @notifJoinError.
  ///
  /// In vi, this message translates to:
  /// **'Không tham gia được nhóm.'**
  String get notifJoinError;

  /// No description provided for @notifJoinedGroup.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia nhóm {group}.'**
  String notifJoinedGroup(String group);

  /// No description provided for @notifSomeone.
  ///
  /// In vi, this message translates to:
  /// **'Ai đó'**
  String get notifSomeone;

  /// No description provided for @notifTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifTitle;

  /// No description provided for @periodCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn'**
  String get periodCustom;

  /// No description provided for @profileAccountDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập, email, mật khẩu, tài khoản liên kết'**
  String get profileAccountDesc;

  /// No description provided for @profileAvatarPickError.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được thư viện ảnh.'**
  String get profileAvatarPickError;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh đại diện.'**
  String get profileAvatarUpdated;

  /// No description provided for @profileBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get profileBack;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get profileChangeAvatar;

  /// No description provided for @profileChooseGroupToInvite.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhóm để mời vào'**
  String get profileChooseGroupToInvite;

  /// No description provided for @profileConnectFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết Facebook'**
  String get profileConnectFacebook;

  /// No description provided for @profileCreateOrJoinGroup.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hoặc tham gia nhóm'**
  String get profileCreateOrJoinGroup;

  /// No description provided for @profileDefaultUserName.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get profileDefaultUserName;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileEditNameTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên hiển thị'**
  String get profileEditNameTitle;

  /// No description provided for @profileFindFriends.
  ///
  /// In vi, this message translates to:
  /// **'Tìm bạn'**
  String get profileFindFriends;

  /// No description provided for @profileGroupActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn'**
  String get profileGroupActive;

  /// No description provided for @profileInviteFriendsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời bạn vào nhóm'**
  String get profileInviteFriendsTitle;

  /// No description provided for @profileInviteSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời {name} vào nhóm.'**
  String profileInviteSuccess(String name);

  /// No description provided for @profileInviteTo.
  ///
  /// In vi, this message translates to:
  /// **'Mời vào {group}'**
  String profileInviteTo(String group);

  /// No description provided for @profileInviting.
  ///
  /// In vi, this message translates to:
  /// **'Đang mời...'**
  String get profileInviting;

  /// No description provided for @profileMe.
  ///
  /// In vi, this message translates to:
  /// **'Tôi'**
  String get profileMe;

  /// No description provided for @profileMemberFallback.
  ///
  /// In vi, this message translates to:
  /// **'thành viên'**
  String get profileMemberFallback;

  /// No description provided for @profileMemberTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get profileMemberTitle;

  /// No description provided for @profileNoResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy ai phù hợp.'**
  String get profileNoResults;

  /// No description provided for @profileNoSharedGroups.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhóm chung. Vào Quản lý nhóm → Thêm nhóm → Tạo nhóm mới.'**
  String get profileNoSharedGroups;

  /// No description provided for @profileReconnectFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối lại Facebook'**
  String get profileReconnectFacebook;

  /// No description provided for @profileSearchButton.
  ///
  /// In vi, this message translates to:
  /// **'Tìm'**
  String get profileSearchButton;

  /// No description provided for @profileSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Username hoặc họ tên (tối thiểu 2 ký tự)'**
  String get profileSearchHint;

  /// No description provided for @profileSearchPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ khóa và bấm Tìm để tìm bạn.'**
  String get profileSearchPrompt;

  /// No description provided for @profileSectionGroups.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get profileSectionGroups;

  /// No description provided for @profileSectionTools.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ'**
  String get profileSectionTools;

  /// No description provided for @profileSelectGroup.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhóm'**
  String get profileSelectGroup;

  /// No description provided for @profileSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profileSettings;

  /// No description provided for @profileSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get profileSignOut;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn đăng xuất?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileSuggestionSourceFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Bạn Facebook'**
  String get profileSuggestionSourceFacebook;

  /// No description provided for @profileSuggestionSourceGroup.
  ///
  /// In vi, this message translates to:
  /// **'Cùng nhóm với bạn'**
  String get profileSuggestionSourceGroup;

  /// No description provided for @profileSuggestionSourceX.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi trên X'**
  String get profileSuggestionSourceX;

  /// No description provided for @profileSuggestionsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gợi ý. Liên kết Facebook trong Tài khoản hoặc tham gia một nhóm chung.'**
  String get profileSuggestionsEmpty;

  /// No description provided for @profileSuggestionsEmptyNoSocial.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gợi ý. Tham gia một nhóm chung để thấy người bạn có thể mời.'**
  String get profileSuggestionsEmptyNoSocial;

  /// No description provided for @profileSuggestionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get profileSuggestionsTitle;

  /// No description provided for @profileSyncFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ bạn Facebook'**
  String get profileSyncFacebook;

  /// No description provided for @profileSyncFacebookDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ {count} bạn Facebook có dùng Coinsort.'**
  String profileSyncFacebookDone(int count);

  /// No description provided for @profileSyncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ…'**
  String get profileSyncing;

  /// No description provided for @profileToolAccounts.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví'**
  String get profileToolAccounts;

  /// No description provided for @profileToolBudgets.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get profileToolBudgets;

  /// No description provided for @profileToolCategories.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục'**
  String get profileToolCategories;

  /// No description provided for @profileToolFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get profileToolFriends;

  /// No description provided for @profileToolRecurring.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch định kỳ'**
  String get profileToolRecurring;

  /// No description provided for @profileToolSearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giao dịch'**
  String get profileToolSearch;

  /// No description provided for @profileUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật hồ sơ.'**
  String get profileUpdated;

  /// No description provided for @receiptAttach.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm hoá đơn'**
  String get receiptAttach;

  /// No description provided for @receiptChooseFromLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get receiptChooseFromLibrary;

  /// No description provided for @receiptLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh hoá đơn.'**
  String get receiptLoadFailed;

  /// No description provided for @receiptPickerError.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được thư viện ảnh.'**
  String get receiptPickerError;

  /// No description provided for @receiptRemove.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ ảnh'**
  String get receiptRemove;

  /// No description provided for @receiptTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get receiptTakePhoto;

  /// No description provided for @receiptUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh.'**
  String get receiptUploadFailed;

  /// No description provided for @receiptUploading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh lên…'**
  String get receiptUploading;

  /// No description provided for @receiptViewFull.
  ///
  /// In vi, this message translates to:
  /// **'Xem hoá đơn'**
  String get receiptViewFull;

  /// No description provided for @recordsAllShown.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiện hết {count} giao dịch'**
  String recordsAllShown(int count);

  /// No description provided for @recordsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn nút + ở giữa thanh dưới để ghi khoản đầu tiên.'**
  String get recordsEmptyMessage;

  /// No description provided for @recordsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch'**
  String get recordsEmptyTitle;

  /// No description provided for @recordsExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get recordsExpense;

  /// No description provided for @recordsGroupOwesYou.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đang nợ bạn {amount}'**
  String recordsGroupOwesYou(String amount);

  /// No description provided for @recordsIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get recordsIncome;

  /// No description provided for @recordsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get recordsRemaining;

  /// No description provided for @recordsTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get recordsTransfer;

  /// No description provided for @recordsUncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get recordsUncategorized;

  /// No description provided for @recordsYou.
  ///
  /// In vi, this message translates to:
  /// **'bạn'**
  String get recordsYou;

  /// No description provided for @recordsYouOweGroup.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang nợ nhóm {amount}'**
  String recordsYouOweGroup(String amount);

  /// No description provided for @recordsYourShare.
  ///
  /// In vi, this message translates to:
  /// **'Phần bạn: {amount}'**
  String recordsYourShare(String amount);

  /// No description provided for @recurringAccountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ví *'**
  String get recurringAccountLabel;

  /// No description provided for @recurringAddTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản định kỳ'**
  String get recurringAddTitle;

  /// No description provided for @recurringAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền *'**
  String get recurringAmountLabel;

  /// No description provided for @recurringAmountMustBePositive.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền lớn hơn 0.'**
  String get recurringAmountMustBePositive;

  /// No description provided for @recurringBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get recurringBack;

  /// No description provided for @recurringCategoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get recurringCategoryLabel;

  /// No description provided for @recurringCreatedDue.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo {count} giao dịch tới hạn.'**
  String recurringCreatedDue(int count);

  /// No description provided for @recurringDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Các giao dịch đã sinh ra từ trước vẫn được giữ nguyên.'**
  String get recurringDeleteConfirm;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá khoản định kỳ'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá.'**
  String get recurringDeleted;

  /// No description provided for @recurringDeletedAccount.
  ///
  /// In vi, this message translates to:
  /// **'Ví đã xoá'**
  String get recurringDeletedAccount;

  /// No description provided for @recurringDue.
  ///
  /// In vi, this message translates to:
  /// **'Đã tới hạn'**
  String get recurringDue;

  /// No description provided for @recurringEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm những khoản lặp lại đều đặn như tiền nhà, lương hay gói đăng ký để không phải nhập lại mỗi kỳ.'**
  String get recurringEmptyMessage;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch định kỳ'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringExpense.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi'**
  String get recurringExpense;

  /// No description provided for @recurringExpenseSegment.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get recurringExpenseSegment;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringInDays.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String recurringInDays(int days);

  /// No description provided for @recurringIncome.
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu'**
  String get recurringIncome;

  /// No description provided for @recurringIncomeSegment.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get recurringIncomeSegment;

  /// No description provided for @recurringNextDate.
  ///
  /// In vi, this message translates to:
  /// **'Lần kế tiếp'**
  String get recurringNextDate;

  /// No description provided for @recurringNoneDue.
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch nào tới hạn.'**
  String get recurringNoneDue;

  /// No description provided for @recurringNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get recurringNote;

  /// No description provided for @recurringOverdueCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} khoản đã tới hạn nhưng chưa được ghi.}}'**
  String recurringOverdueCount(int count);

  /// No description provided for @recurringRunDueTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Chạy các khoản tới hạn'**
  String get recurringRunDueTooltip;

  /// No description provided for @recurringRunFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không chạy được.'**
  String get recurringRunFailed;

  /// No description provided for @recurringRunNow.
  ///
  /// In vi, this message translates to:
  /// **'Chạy ngay'**
  String get recurringRunNow;

  /// No description provided for @recurringSelectAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví.'**
  String get recurringSelectAccount;

  /// No description provided for @recurringTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch định kỳ'**
  String get recurringTitle;

  /// No description provided for @recurringToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get recurringToday;

  /// No description provided for @recurringTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get recurringTomorrow;

  /// No description provided for @reportsAddWallet.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ví'**
  String get reportsAddWallet;

  /// No description provided for @reportsAssets.
  ///
  /// In vi, this message translates to:
  /// **'Tài sản'**
  String get reportsAssets;

  /// No description provided for @reportsCreditLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount} hạn mức'**
  String reportsCreditLeft(String amount);

  /// No description provided for @reportsDebt.
  ///
  /// In vi, this message translates to:
  /// **'Nợ'**
  String get reportsDebt;

  /// No description provided for @reportsLiabilitiesSection.
  ///
  /// In vi, this message translates to:
  /// **'Nợ và thẻ tín dụng'**
  String get reportsLiabilitiesSection;

  /// No description provided for @reportsManageWallets.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví'**
  String get reportsManageWallets;

  /// No description provided for @reportsMultiCurrencyNote.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi đơn vị tiền tệ được tính riêng. App không quy đổi tỉ giá.'**
  String get reportsMultiCurrencyNote;

  /// No description provided for @reportsNetWorth.
  ///
  /// In vi, this message translates to:
  /// **'Tài sản ròng'**
  String get reportsNetWorth;

  /// No description provided for @reportsNoWalletsMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ví để theo dõi tài sản ròng của bạn.'**
  String get reportsNoWalletsMessage;

  /// No description provided for @reportsNoWalletsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào'**
  String get reportsNoWalletsTitle;

  /// No description provided for @reportsNotCountedInNetWorth.
  ///
  /// In vi, this message translates to:
  /// **'Không tính vào tài sản ròng'**
  String get reportsNotCountedInNetWorth;

  /// No description provided for @reportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get reportsTitle;

  /// No description provided for @routeErrorBody.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được \"{location}\".'**
  String routeErrorBody(String location);

  /// No description provided for @routeErrorGoHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chính'**
  String get routeErrorGoHome;

  /// No description provided for @routeErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trang'**
  String get routeErrorTitle;

  /// No description provided for @searchAmountFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get searchAmountFrom;

  /// No description provided for @searchAmountTo.
  ///
  /// In vi, this message translates to:
  /// **'Đến'**
  String get searchAmountTo;

  /// No description provided for @searchBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get searchBack;

  /// No description provided for @searchClear.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get searchClear;

  /// No description provided for @searchClearAll.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hết'**
  String get searchClearAll;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ khoá, hoặc mở bộ lọc để tìm theo danh mục, số tiền và khoảng thời gian.'**
  String get searchEmptyMessage;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giao dịch'**
  String get searchEmptyTitle;

  /// No description provided for @searchFilters.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get searchFilters;

  /// No description provided for @searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm ghi chú, nơi chi…'**
  String get searchHint;

  /// No description provided for @searchNetSpending.
  ///
  /// In vi, this message translates to:
  /// **'Chi ròng {amount}'**
  String searchNetSpending(String amount);

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thử bớt điều kiện lọc hoặc đổi từ khoá.'**
  String get searchNoResultsMessage;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giao dịch'**
  String get searchNoResultsTitle;

  /// No description provided for @searchPickDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng thời gian'**
  String get searchPickDateRange;

  /// No description provided for @searchResultCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String searchResultCount(int count);

  /// No description provided for @searchTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản'**
  String get searchTransfer;

  /// No description provided for @searchTypeExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get searchTypeExpense;

  /// No description provided for @searchTypeIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get searchTypeIncome;

  /// No description provided for @searchTypeTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển'**
  String get searchTypeTransfer;

  /// No description provided for @searchUncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get searchUncategorized;

  /// No description provided for @settingsBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get settingsBack;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In vi, this message translates to:
  /// **'Khoá ứng dụng'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricLockDesc.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu vân tay hoặc Face ID khi mở app'**
  String get settingsBiometricLockDesc;

  /// No description provided for @settingsBudgets.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get settingsBudgets;

  /// No description provided for @settingsCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị tiền tệ'**
  String get settingsCurrency;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn tài khoản và toàn bộ dữ liệu'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsDeleteBulletInvites.
  ///
  /// In vi, this message translates to:
  /// **'Mọi lời mời vào nhóm liên quan đến bạn'**
  String get settingsDeleteBulletInvites;

  /// No description provided for @settingsDeleteBulletPersonalTx.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ giao dịch trong nhóm cá nhân của bạn'**
  String get settingsDeleteBulletPersonalTx;

  /// No description provided for @settingsDeleteBulletProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ, tên hiển thị và ảnh đại diện'**
  String get settingsDeleteBulletProfile;

  /// No description provided for @settingsDeleteBulletSharedTx.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch bạn đã ghi trong các nhóm CHUNG — xoá đi sẽ làm sai công nợ của những thành viên còn lại. Các giao dịch này không còn gắn với hồ sơ của bạn nữa.'**
  String get settingsDeleteBulletSharedTx;

  /// No description provided for @settingsDeleteBulletWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví, danh mục riêng, ngân sách, giao dịch định kỳ'**
  String get settingsDeleteBulletWallets;

  /// No description provided for @settingsDeleteConfirmButton.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn'**
  String get settingsDeleteConfirmButton;

  /// No description provided for @settingsDeleteConfirmPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Gõ \"{phrase}\" để xác nhận'**
  String settingsDeleteConfirmPrompt(String phrase);

  /// No description provided for @settingsDeleteDialogBody.
  ///
  /// In vi, this message translates to:
  /// **'Đây là bước cuối. Sau khi xoá, dữ liệu cá nhân của bạn không khôi phục được.'**
  String get settingsDeleteDialogBody;

  /// No description provided for @settingsDeleteDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn?'**
  String get settingsDeleteDialogTitle;

  /// No description provided for @settingsDeleteKeepAccount.
  ///
  /// In vi, this message translates to:
  /// **'Giữ tài khoản'**
  String get settingsDeleteKeepAccount;

  /// No description provided for @settingsDeleteMyAccountButton.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản của tôi'**
  String get settingsDeleteMyAccountButton;

  /// No description provided for @settingsDeleteSharedTxNote.
  ///
  /// In vi, this message translates to:
  /// **'Muốn xoá sạch cả những giao dịch đó? Hãy tự xoá chúng, hoặc rời nhóm trước khi xoá tài khoản.'**
  String get settingsDeleteSharedTxNote;

  /// No description provided for @settingsDeleteSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã được xoá.'**
  String get settingsDeleteSuccess;

  /// No description provided for @settingsDeleteWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không hoàn tác được.'**
  String get settingsDeleteWarning;

  /// No description provided for @settingsDeleteWhatKept.
  ///
  /// In vi, this message translates to:
  /// **'Những gì được giữ lại'**
  String get settingsDeleteWhatKept;

  /// No description provided for @settingsDeleteWhatRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Những gì sẽ bị xoá'**
  String get settingsDeleteWhatRemoved;

  /// No description provided for @settingsExportAllHistory.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ lịch sử'**
  String get settingsExportAllHistory;

  /// No description provided for @settingsExportClearRange.
  ///
  /// In vi, this message translates to:
  /// **'Xoá khoảng thời gian'**
  String get settingsExportClearRange;

  /// No description provided for @settingsExportCsvDesc.
  ///
  /// In vi, this message translates to:
  /// **'File CSV mở được bằng Excel, Google Sheets hay Numbers. Gồm ngày, loại, danh mục, số tiền, ví, ghi chú và phần chia trong nhóm.'**
  String get settingsExportCsvDesc;

  /// No description provided for @settingsExportCsvTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất CSV'**
  String get settingsExportCsvTitle;

  /// No description provided for @settingsExportCurrencyWarning.
  ///
  /// In vi, this message translates to:
  /// **'Ví của bạn dùng {count} đơn vị tiền tệ ({list}). Cột \"Số tiền\" giữ nguyên đơn vị gốc của từng ví — đừng cộng thẳng cả cột.'**
  String settingsExportCurrencyWarning(int count, String list);

  /// No description provided for @settingsExportData.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get settingsExportData;

  /// No description provided for @settingsExportDataDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tải toàn bộ giao dịch dạng CSV'**
  String get settingsExportDataDesc;

  /// No description provided for @settingsExportDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian'**
  String get settingsExportDateRange;

  /// No description provided for @settingsExportGroupLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm: {name}'**
  String settingsExportGroupLabel(String name);

  /// No description provided for @settingsExportMaxRowsNote.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 5.000 giao dịch mỗi lần xuất. Nếu lịch sử dài hơn, hãy xuất theo từng khoảng thời gian.'**
  String get settingsExportMaxRowsNote;

  /// No description provided for @settingsExportNoGroup.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn nhóm.'**
  String get settingsExportNoGroup;

  /// No description provided for @settingsExportPreparing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị…'**
  String get settingsExportPreparing;

  /// No description provided for @settingsExportShare.
  ///
  /// In vi, this message translates to:
  /// **'Xuất và chia sẻ'**
  String get settingsExportShare;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xuất {count} giao dịch.'**
  String settingsExportSuccess(int count);

  /// No description provided for @settingsFirstDayOfMonth.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu tháng'**
  String get settingsFirstDayOfMonth;

  /// No description provided for @settingsFirstDayOfMonthDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day} — dùng khi lương về giữa tháng'**
  String settingsFirstDayOfMonthDesc(int day);

  /// No description provided for @settingsHideAmounts.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số tiền'**
  String get settingsHideAmounts;

  /// No description provided for @settingsHideAmountsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Che số tiền khi dùng nơi đông người'**
  String get settingsHideAmountsDesc;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsManageCategories.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý danh mục'**
  String get settingsManageCategories;

  /// No description provided for @settingsManageWallets.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý ví'**
  String get settingsManageWallets;

  /// No description provided for @settingsPrivacyContactBody.
  ///
  /// In vi, this message translates to:
  /// **'Có câu hỏi về dữ liệu của bạn? Liên hệ qua địa chỉ hỗ trợ ghi trên trang cửa hàng ứng dụng.'**
  String get settingsPrivacyContactBody;

  /// No description provided for @settingsPrivacyDataAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn: tên đăng nhập, tên hiển thị, ảnh đại diện nếu bạn tải lên, và email nếu bạn thêm. Khi đăng nhập bằng Google, Facebook hoặc X, chúng tôi nhận tên, email và ảnh đại diện mà nhà cung cấp đó chia sẻ, cùng ID tài khoản của họ để nhận ra liên kết.'**
  String get settingsPrivacyDataAccount;

  /// No description provided for @settingsPrivacyDataFinancial.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu tài chính bạn tự nhập: giao dịch, số tiền, danh mục, ghi chú, tên ví, số dư, ngân sách, và ảnh hoá đơn nếu bạn đính kèm.'**
  String get settingsPrivacyDataFinancial;

  /// No description provided for @settingsPrivacyDataGroup.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu nhóm: tên nhóm, danh sách thành viên, phần chia của từng khoản chi và các lần quyết toán.'**
  String get settingsPrivacyDataGroup;

  /// No description provided for @settingsPrivacyDataSocialFriends.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn liên kết Facebook, chúng tôi lưu ID những bạn Facebook cũng dùng Coinsort, chỉ để gợi ý người bạn có thể mời vào nhóm. Không đăng gì lên tài khoản mạng xã hội của bạn.'**
  String get settingsPrivacyDataSocialFriends;

  /// No description provided for @settingsPrivacyDontAds.
  ///
  /// In vi, this message translates to:
  /// **'Không hiển thị quảng cáo và không gắn mã theo dõi quảng cáo.'**
  String get settingsPrivacyDontAds;

  /// No description provided for @settingsPrivacyDontBank.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối với ngân hàng và không đọc sao kê của bạn.'**
  String get settingsPrivacyDontBank;

  /// No description provided for @settingsPrivacyDontSell.
  ///
  /// In vi, this message translates to:
  /// **'Không bán hay chia sẻ dữ liệu của bạn cho bên thứ ba.'**
  String get settingsPrivacyDontSell;

  /// No description provided for @settingsPrivacyHeadingContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get settingsPrivacyHeadingContact;

  /// No description provided for @settingsPrivacyHeadingDataStored.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu chúng tôi lưu'**
  String get settingsPrivacyHeadingDataStored;

  /// No description provided for @settingsPrivacyHeadingSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get settingsPrivacyHeadingSecurity;

  /// No description provided for @settingsPrivacyHeadingWeDont.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi KHÔNG làm'**
  String get settingsPrivacyHeadingWeDont;

  /// No description provided for @settingsPrivacyHeadingWhereStored.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ở đâu'**
  String get settingsPrivacyHeadingWhereStored;

  /// No description provided for @settingsPrivacyHeadingWhoSees.
  ///
  /// In vi, this message translates to:
  /// **'Ai xem được'**
  String get settingsPrivacyHeadingWhoSees;

  /// No description provided for @settingsPrivacyHeadingYourRights.
  ///
  /// In vi, this message translates to:
  /// **'Quyền của bạn'**
  String get settingsPrivacyHeadingYourRights;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách quyền riêng tư'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyRightsDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản: Cài đặt → Xoá tài khoản. Hồ sơ, dữ liệu cá nhân, ví, danh mục và ngân sách của bạn sẽ bị xoá.'**
  String get settingsPrivacyRightsDelete;

  /// No description provided for @settingsPrivacyRightsDeleteException.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại lệ khi xoá: những giao dịch bạn đã ghi trong nhóm CHUNG được giữ lại, vì xoá đi sẽ làm sai công nợ của các thành viên còn lại. Chúng không còn gắn với hồ sơ của bạn nữa. Muốn xoá cả phần này, hãy xoá thủ công hoặc rời nhóm trước.'**
  String get settingsPrivacyRightsDeleteException;

  /// No description provided for @settingsPrivacyRightsExport.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu: Cài đặt → Xuất dữ liệu, tải toàn bộ giao dịch dạng CSV bất cứ lúc nào.'**
  String get settingsPrivacyRightsExport;

  /// No description provided for @settingsPrivacySecurityBiometric.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể bật khoá bằng vân tay hoặc Face ID trong Cài đặt để thêm một lớp bảo vệ trên thiết bị.'**
  String get settingsPrivacySecurityBiometric;

  /// No description provided for @settingsPrivacySecurityHttps.
  ///
  /// In vi, this message translates to:
  /// **'Mọi kết nối đều qua HTTPS. Mật khẩu do Supabase Auth quản lý và không bao giờ được lưu trong ứng dụng.'**
  String get settingsPrivacySecurityHttps;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật: 01/09/2026'**
  String get settingsPrivacyUpdated;

  /// No description provided for @settingsPrivacyWhereDatabase.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu lưu trên Supabase (PostgreSQL và Storage). Truy cập được kiểm soát bằng Row Level Security ở tầng cơ sở dữ liệu, không chỉ ở tầng ứng dụng.'**
  String get settingsPrivacyWhereDatabase;

  /// No description provided for @settingsPrivacyWhereLocal.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt hiển thị (đơn vị tiền tệ, ngôn ngữ, giao diện) lưu trên chính thiết bị của bạn, không gửi lên máy chủ.'**
  String get settingsPrivacyWhereLocal;

  /// No description provided for @settingsPrivacyWhoBalances.
  ///
  /// In vi, this message translates to:
  /// **'Số dư ví CÁ NHÂN của bạn không hiển thị cho thành viên khác. Ví dùng chung của nhóm thì cả nhóm xem được.'**
  String get settingsPrivacyWhoBalances;

  /// No description provided for @settingsPrivacyWhoPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trong nhóm cá nhân chỉ mình bạn xem được.'**
  String get settingsPrivacyWhoPersonal;

  /// No description provided for @settingsPrivacyWhoReceipts.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hoá đơn lưu ở kho riêng tư, chỉ tài khoản đã tải lên mới đọc được.'**
  String get settingsPrivacyWhoReceipts;

  /// No description provided for @settingsPrivacyWhoShared.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trong nhóm chung hiển thị với mọi thành viên đang hoạt động của nhóm đó — bao gồm số tiền, danh mục, ghi chú và người trả.'**
  String get settingsPrivacyWhoShared;

  /// No description provided for @settingsRecalcAllMatch.
  ///
  /// In vi, this message translates to:
  /// **'Số dư mọi ví đều khớp sổ giao dịch.'**
  String get settingsRecalcAllMatch;

  /// No description provided for @settingsRecalcDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dựng lại số dư mọi ví từ sổ giao dịch'**
  String get settingsRecalcDesc;

  /// No description provided for @settingsRecalcFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đối soát được.'**
  String get settingsRecalcFailed;

  /// No description provided for @settingsRecalcFixedCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã sửa {count} ví'**
  String settingsRecalcFixedCount(int count);

  /// No description provided for @settingsRecalcMoreWallets.
  ///
  /// In vi, this message translates to:
  /// **'và {count} ví khác…'**
  String settingsRecalcMoreWallets(int count);

  /// No description provided for @settingsRecalcTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đối soát số dư'**
  String get settingsRecalcTitle;

  /// No description provided for @settingsRecurring.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch định kỳ'**
  String get settingsRecurring;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionCheck.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra'**
  String get settingsSectionCheck;

  /// No description provided for @settingsSectionData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsSectionPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ tài chính'**
  String get settingsSectionPeriod;

  /// No description provided for @settingsTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @shellFilterTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get shellFilterTooltip;

  /// No description provided for @shellFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get shellFriends;

  /// No description provided for @shellNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get shellNotifications;

  /// No description provided for @shellSearchTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giao dịch'**
  String get shellSearchTooltip;

  /// No description provided for @splitExcessBy.
  ///
  /// In vi, this message translates to:
  /// **'Thừa {amount}.'**
  String splitExcessBy(String amount);

  /// No description provided for @splitMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get splitMember;

  /// No description provided for @splitModeEqual.
  ///
  /// In vi, this message translates to:
  /// **'Chia đều'**
  String get splitModeEqual;

  /// No description provided for @splitModeExact.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền cụ thể'**
  String get splitModeExact;

  /// No description provided for @splitModeNone.
  ///
  /// In vi, this message translates to:
  /// **'Không chia'**
  String get splitModeNone;

  /// No description provided for @splitModePercent.
  ///
  /// In vi, this message translates to:
  /// **'Theo phần trăm'**
  String get splitModePercent;

  /// No description provided for @splitModeShares.
  ///
  /// In vi, this message translates to:
  /// **'Theo số phần'**
  String get splitModeShares;

  /// No description provided for @splitNeedParticipant.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất một người để chia.'**
  String get splitNeedParticipant;

  /// No description provided for @splitNeedShares.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số phần cho ít nhất một người.'**
  String get splitNeedShares;

  /// No description provided for @splitPaidByLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ai trả khoản này *'**
  String get splitPaidByLabel;

  /// No description provided for @splitPercentTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng phần trăm đang là {percent}%, cần đủ 100%.'**
  String splitPercentTotal(String percent);

  /// No description provided for @splitSharesSuffix.
  ///
  /// In vi, this message translates to:
  /// **'phần'**
  String get splitSharesSuffix;

  /// No description provided for @splitShortBy.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu {amount}.'**
  String splitShortBy(String amount);

  /// No description provided for @splitYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get splitYou;

  /// No description provided for @txAccountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ví *'**
  String get txAccountLabel;

  /// No description provided for @txAccountsMustDiffer.
  ///
  /// In vi, this message translates to:
  /// **'Ví nguồn và ví đích phải khác nhau.'**
  String get txAccountsMustDiffer;

  /// No description provided for @txAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền *'**
  String get txAmountLabel;

  /// No description provided for @txAmountMustBePositive.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền lớn hơn 0.'**
  String get txAmountMustBePositive;

  /// No description provided for @txChangesSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thay đổi.'**
  String get txChangesSaved;

  /// No description provided for @txCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi được giao dịch.'**
  String get txCreateFailed;

  /// No description provided for @txDeleteCategory.
  ///
  /// In vi, this message translates to:
  /// **'Xoá danh mục'**
  String get txDeleteCategory;

  /// No description provided for @txDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xoá được giao dịch.'**
  String get txDeleteFailed;

  /// No description provided for @txDeleteTransactionConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá giao dịch này? Số dư ví sẽ được hoàn lại tương ứng.'**
  String get txDeleteTransactionConfirm;

  /// No description provided for @txDeleteTransactionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá giao dịch'**
  String get txDeleteTransactionTitle;

  /// No description provided for @txEditCategory.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get txEditCategory;

  /// No description provided for @txEditExpenseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản chi'**
  String get txEditExpenseTitle;

  /// No description provided for @txEditIncomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản thu'**
  String get txEditIncomeTitle;

  /// No description provided for @txEditTransferTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa chuyển khoản'**
  String get txEditTransferTitle;

  /// No description provided for @txFromAccountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Từ ví *'**
  String get txFromAccountLabel;

  /// No description provided for @txNoGroupSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn nhóm. Kéo xuống để tải lại.'**
  String get txNoGroupSelected;

  /// No description provided for @txNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get txNote;

  /// No description provided for @txPayeeExpenseHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Highlands'**
  String get txPayeeExpenseHint;

  /// No description provided for @txPayeeExpenseLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nơi chi'**
  String get txPayeeExpenseLabel;

  /// No description provided for @txPayeeIncomeHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Công ty'**
  String get txPayeeIncomeHint;

  /// No description provided for @txPayeeIncomeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn thu'**
  String get txPayeeIncomeLabel;

  /// No description provided for @txRecordedBy.
  ///
  /// In vi, this message translates to:
  /// **'Ghi bởi {name} · {date}'**
  String txRecordedBy(String name, String date);

  /// No description provided for @txSelectAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví.'**
  String get txSelectAccount;

  /// No description provided for @txSelectBothAccounts.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cả ví nguồn và ví đích.'**
  String get txSelectBothAccounts;

  /// No description provided for @txToAccountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đến ví *'**
  String get txToAccountLabel;

  /// No description provided for @txTransactionDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày giao dịch'**
  String get txTransactionDate;

  /// No description provided for @txTransactionDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá giao dịch.'**
  String get txTransactionDeleted;

  /// No description provided for @txUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không cập nhật được giao dịch.'**
  String get txUpdateFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
