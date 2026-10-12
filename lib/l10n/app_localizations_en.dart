// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get catBeauty => 'Beauty';

  @override
  String get catBonus => 'Bonus';

  @override
  String get catCar => 'Car';

  @override
  String get catClothing => 'Clothing';

  @override
  String get catDonations => 'Donations';

  @override
  String get catEducation => 'Education';

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catFamily => 'Family';

  @override
  String get catFoodDining => 'Food & Dining';

  @override
  String get catFreelance => 'Freelance';

  @override
  String get catGifts => 'Gifts';

  @override
  String get catGiftsReceived => 'Gifts Received';

  @override
  String get catHealth => 'Health';

  @override
  String get catHousing => 'Housing';

  @override
  String get catInvestment => 'Investment';

  @override
  String get catJob => 'Job';

  @override
  String get catOthers => 'Others';

  @override
  String get catPets => 'Pets';

  @override
  String get catSalary => 'Salary';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catSocial => 'Social';

  @override
  String get catSports => 'Sports';

  @override
  String get catTransportation => 'Transportation';

  @override
  String get catTravel => 'Travel';

  @override
  String get txCategoryLabel => 'Category';

  @override
  String get accountAvatarTapToChange => 'Tap the photo to change it';

  @override
  String get accountBack => 'Back';

  @override
  String get accountChangePassword => 'Change password';

  @override
  String get accountConfirmNewPassword => 'Confirm new password';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountDisplayNameHint =>
      'Shown to group members. Doesn\'t need to be unique.';

  @override
  String get accountEditUsernameTitle => 'Set username';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountEmailAdd => 'Add email';

  @override
  String get accountEmailChange => 'Change email';

  @override
  String get accountEmailDialogHint =>
      'We\'ll send a verification link to this address. Once verified it can also be used to sign in.';

  @override
  String get accountEmailNone => 'No email yet';

  @override
  String accountEmailPending(String email) {
    return 'Waiting for verification: $email';
  }

  @override
  String get accountEmailPendingHint =>
      'Open the link we sent to that address to finish.';

  @override
  String get accountEmailResend => 'Resend';

  @override
  String get accountEmailResent => 'Verification email sent again.';

  @override
  String accountEmailSaved(String email) {
    return 'Check $email and open the verification link.';
  }

  @override
  String get accountEmailUnverified => 'Not verified';

  @override
  String get accountEmailVerified => 'Verified';

  @override
  String get accountLink => 'Link';

  @override
  String get accountLinkBrowser =>
      'Finish in your browser, then come back here.';

  @override
  String get accountLinkHint =>
      'Sign in faster and find friends from these accounts.';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountNotLinked => 'Not linked';

  @override
  String get accountNotSet => 'Not set';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordChanged => 'Password updated.';

  @override
  String get accountPasswordNone =>
      'No password yet — you sign in with a linked account.';

  @override
  String get accountPasswordSet => 'Password set';

  @override
  String get accountSectionLinked => 'Linked accounts';

  @override
  String get accountSectionLogin => 'Sign-in methods';

  @override
  String get accountSectionProfile => 'Profile';

  @override
  String get accountSelAmountOwed => 'Amount owed';

  @override
  String get accountSelCreate => 'Create wallet';

  @override
  String get accountSelCreateAction => 'Create';

  @override
  String get accountSelCreateNew => 'New wallet';

  @override
  String get accountSelCurrentBalance => 'Current balance';

  @override
  String get accountSelEnterName => 'Enter a wallet name.';

  @override
  String get accountSelNameHint => 'e.g. Cash';

  @override
  String get accountSelOwedHelper =>
      'Enter a positive number — the amount you owe.';

  @override
  String accountSelSharedSubtitle(String name) {
    return 'Every member of \"$name\" can view and record.';
  }

  @override
  String get accountSelSharedWallet => 'Shared wallet';

  @override
  String get accountSelTypeLiability => 'Debt / Card';

  @override
  String get accountSetPassword => 'Set password';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountUnlink => 'Unlink';

  @override
  String get accountUnlinkBlocked =>
      'Set a password or link another account first.';

  @override
  String get accountUnlinkConfirmBody =>
      'You won\'t be able to sign in with this account anymore.';

  @override
  String accountUnlinkConfirmTitle(String provider) {
    return 'Unlink $provider?';
  }

  @override
  String accountUnlinked(String provider) {
    return '$provider unlinked.';
  }

  @override
  String get accountUsername => 'Username';

  @override
  String get accountUsernameHint =>
      'Used to sign in. Lowercase letters, digits, dot, underscore.';

  @override
  String get accountUsernameSaved => 'Username updated.';

  @override
  String get accountsActualBalance => 'Actual balance';

  @override
  String get accountsAddWallet => 'Add wallet';

  @override
  String get accountsAdjustBalance => 'Adjust balance';

  @override
  String get accountsAdjustBalanceSubtitle =>
      'Records an adjustment transaction without editing past entries.';

  @override
  String get accountsAdjustNote =>
      'The difference is recorded as an adjustment transaction so the ledger and balance always match.';

  @override
  String get accountsAdjustmentRecorded => 'Adjustment transaction recorded.';

  @override
  String get accountsArchive => 'Archive wallet';

  @override
  String get accountsArchiveSubtitle =>
      'Hides it from the list while keeping transaction history.';

  @override
  String get accountsArchived => 'Wallet archived.';

  @override
  String get accountsBack => 'Back';

  @override
  String get accountsBadgeExcluded => 'Excluded';

  @override
  String get accountsBadgeShared => 'Shared';

  @override
  String accountsCreditLeft(String amount) {
    return '$amount left';
  }

  @override
  String get accountsCreditLimitLabel => 'Credit limit';

  @override
  String get accountsCurrencyLabel => 'Currency';

  @override
  String accountsCurrentBalance(String amount) {
    return 'Current balance: $amount';
  }

  @override
  String get accountsEditWallet => 'Edit wallet';

  @override
  String get accountsEmptyMessage =>
      'Create your first wallet to start tracking.';

  @override
  String get accountsEmptyTitle => 'No wallets yet';

  @override
  String get accountsGroupArchived => 'Archived';

  @override
  String get accountsGroupAssets => 'Assets';

  @override
  String get accountsGroupLiabilities => 'Debt & credit cards';

  @override
  String get accountsIncludeNetWorth => 'Include in net worth';

  @override
  String get accountsInvalidBalance => 'Enter a valid balance.';

  @override
  String get accountsMoreActions => 'Options';

  @override
  String get accountsNameLabel => 'Wallet name *';

  @override
  String get accountsNoGroup => 'No group selected.';

  @override
  String accountsPayDay(int day) {
    return 'due on day $day';
  }

  @override
  String get accountsPaymentDay => 'Payment day';

  @override
  String get accountsReconcile => 'Reconcile this wallet';

  @override
  String accountsReconcileResult(String amount) {
    return 'Balance after reconciliation: $amount';
  }

  @override
  String get accountsRecordAdjustment => 'Record adjustment';

  @override
  String get accountsRestore => 'Restore wallet';

  @override
  String get accountsRestored => 'Wallet restored.';

  @override
  String get accountsStatementDay => 'Statement day';

  @override
  String get accountsTitle => 'Manage wallets';

  @override
  String accountsWillRecordExpense(String amount) {
    return 'Will record an expense of $amount';
  }

  @override
  String accountsWillRecordIncome(String amount) {
    return 'Will record income of $amount';
  }

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get appLockLocked => 'Coinsort is locked';

  @override
  String get appLockReason => 'Authenticate to open Coinsort';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appTitle => 'Coinsort';

  @override
  String get authBackToLogin => 'Back to sign in';

  @override
  String get authBrowserWaiting =>
      'Finish signing in in your browser, then come back here.';

  @override
  String authCodeSentTo(String email) {
    return 'A 6-digit code was sent to $email';
  }

  @override
  String get authConfirmNewPasswordLabel => 'Confirm new password *';

  @override
  String get authConfirmPasswordHint => 'Re-enter your password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password *';

  @override
  String get authConfirmPasswordRequired => 'Confirm your password';

  @override
  String get authContinueWithFacebook => 'Continue with Facebook';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithX => 'Continue with X';

  @override
  String get authEmailHint => 'email@example.com';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authEmailLabel => 'Email *';

  @override
  String get authEmailReadOnlyLabel => 'Email';

  @override
  String get authEmailRequired => 'Enter your email';

  @override
  String get authEnterAllSixDigits => 'Enter all 6 digits from the email';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your registered email to receive a 6-digit code.';

  @override
  String get authForgotPasswordTitle => 'Recover password';

  @override
  String get authFullNameHint => 'John Doe';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authHaveAccountLogin => 'Already have an account? Sign in';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authIdentifierHint => 'email@example.com or username';

  @override
  String get authIdentifierLabel => 'Email or username *';

  @override
  String get authIdentifierRequired => 'Enter your email or username';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authNewPasswordLabel => 'New password *';

  @override
  String get authNoAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get authOrContinueWith => 'or continue with';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordLabel => 'Password *';

  @override
  String get authPasswordMinHint => 'At least 6 characters';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authRecoverCodeTitle => 'Enter verification code';

  @override
  String get authRegisterSubtitle =>
      'Just a username and a password. You can add an email later in Account.';

  @override
  String get authRegisterTitle => 'Sign up';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authSendRecoveryCode => 'Send recovery code';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authUpdatePassword => 'Update password';

  @override
  String get authUsernameHint => 'username';

  @override
  String get authUsernameLabel => 'Username *';

  @override
  String get authUsernameRequired => 'Enter a username';

  @override
  String get authUsernameRules =>
      '3–30 characters: lowercase letters, digits, dot or underscore';

  @override
  String get authVerificationCodeLabel => 'Verification code *';

  @override
  String get budgetsBack => 'Back';

  @override
  String get budgetsCategoryLabel => 'Category *';

  @override
  String get budgetsChooseCategory => 'Choose a category.';

  @override
  String budgetsDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String budgetsDeleteConfirm(String category) {
    return 'Delete the budget for \"$category\"?';
  }

  @override
  String get budgetsDeleteTitle => 'Delete budget';

  @override
  String get budgetsDeleted => 'Budget deleted.';

  @override
  String get budgetsEditLimit => 'Edit budget';

  @override
  String get budgetsEmptyMessage =>
      'Set a limit for a category to know when you\'re overspending.';

  @override
  String get budgetsEmptyTitle => 'No budgets yet';

  @override
  String get budgetsInvalidAmount => 'Enter a limit greater than 0.';

  @override
  String get budgetsLimitLabel => 'Limit *';

  @override
  String budgetsOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetsPastPeriods => 'PAST PERIODS';

  @override
  String get budgetsPeriodLabel => 'Period';

  @override
  String budgetsRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get budgetsSetLimit => 'Set budget';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsTotalActive => 'Total active budgets';

  @override
  String get categoriesAdd => 'Add category';

  @override
  String get categoriesColorLabel => 'Color';

  @override
  String categoriesDeleteConfirm(String name) {
    return 'Delete \"$name\"? Transactions that used this category keep their old label in history.';
  }

  @override
  String get categoriesDeleteTitle => 'Delete category';

  @override
  String get categoriesDeleted => 'Category deleted.';

  @override
  String get categoriesDragHandle => 'Drag to reorder';

  @override
  String get categoriesEditTitle => 'Edit category';

  @override
  String get categoriesEmptyMessageExpense =>
      'Add your first expense category.';

  @override
  String get categoriesEmptyMessageIncome => 'Add your first income category.';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesIconLabel => 'Icon';

  @override
  String get categoriesManageTitle => 'Manage categories';

  @override
  String get categoriesNameHint => 'e.g. Coffee';

  @override
  String get categoriesNameLabel => 'Category name *';

  @override
  String get categoriesNameRequired => 'Enter a category name.';

  @override
  String get categoriesNotEditable => 'Can\'t be edited';

  @override
  String get categoriesReorderFailed => 'Couldn\'t save the new order.';

  @override
  String get categoriesSectionSystem => 'System categories';

  @override
  String get categoriesSectionYours => 'Your categories — drag to reorder';

  @override
  String get categoriesTabExpense => 'Expense';

  @override
  String get categoriesTabIncome => 'Income';

  @override
  String chartsDateRangeSuffix(String start, String end) {
    return '\n(from $start to $end)';
  }

  @override
  String chartsError(String error) {
    return 'Error: $error';
  }

  @override
  String get chartsExpense => 'Expenses';

  @override
  String get chartsIncome => 'Income';

  @override
  String get chartsNoData => 'No data';

  @override
  String get chartsNoTransactions => 'No transactions yet';

  @override
  String get chartsOthers => 'Others';

  @override
  String get chartsOverviewTitle => 'Income / Expense overview';

  @override
  String get chartsRemaining => 'Remaining';

  @override
  String get chartsTabExpense => 'Expenses';

  @override
  String get chartsTabIncome => 'Income';

  @override
  String get chartsTabOverview => 'Overview';

  @override
  String get chartsTitle => 'Charts';

  @override
  String get chartsTopExpense => 'Top recent expenses';

  @override
  String get chartsTopIncome => 'Top recent income';

  @override
  String get chartsTotal => 'Total';

  @override
  String get commonAddTransaction => 'Add transaction';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNavCharts => 'Charts';

  @override
  String get commonNavProfile => 'Me';

  @override
  String get commonNavReports => 'Reports';

  @override
  String get commonNavTransactions => 'Transactions';

  @override
  String get commonOther => 'Other';

  @override
  String commonPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get commonTabExpense => 'Expense';

  @override
  String get commonTabIncome => 'Income';

  @override
  String get commonTabTransfer => 'Transfer';

  @override
  String get csvHeaderAmount => 'Amount';

  @override
  String get csvHeaderCategory => 'Category';

  @override
  String get csvHeaderCurrency => 'Currency';

  @override
  String get csvHeaderDate => 'Date';

  @override
  String get csvHeaderMyShare => 'My share';

  @override
  String get csvHeaderNote => 'Note';

  @override
  String get csvHeaderPayer => 'Paid by';

  @override
  String get csvHeaderPlace => 'Place';

  @override
  String get csvHeaderSplitMode => 'Split method';

  @override
  String get csvHeaderTargetWallet => 'Target wallet';

  @override
  String get csvHeaderType => 'Type';

  @override
  String get csvHeaderWallet => 'Wallet';

  @override
  String get csvTransfer => 'Transfer';

  @override
  String get csvUncategorized => 'Uncategorized';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get deleteConfirmPhrase => 'DELETE ACCOUNT';

  @override
  String get errAmountInvalid => 'The amount must be greater than 0.';

  @override
  String get errBalanceUnchanged =>
      'The new balance is the same as the current one.';

  @override
  String get errBudgetAmountInvalid => 'The limit must be greater than 0.';

  @override
  String get errCategoryNameEmpty => 'Category name cannot be empty.';

  @override
  String get errCodeExpired => 'The code has expired. Request a new one.';

  @override
  String get errCurrentPasswordWrong => 'Current password is incorrect.';

  @override
  String get errDeleteTransactionDenied =>
      'Couldn\'t delete the transaction. You may no longer be in this group.';

  @override
  String get errDuplicate => 'This item already exists.';

  @override
  String get errEmailAlreadyRegistered =>
      'This email is already registered. Sign in or use Forgot password.';

  @override
  String get errEmailExists => 'This email is already used by another account.';

  @override
  String get errEmailNotConfirmed =>
      'Please confirm your email before signing in. Check your inbox and spam folder.';

  @override
  String get errGoogleNotConfigured =>
      'Google sign-in isn\'t configured for this build.';

  @override
  String get errGroupCreateFailed => 'Couldn\'t create the group.';

  @override
  String get errGroupNameEmpty => 'Group name cannot be empty.';

  @override
  String get errIdentityAlreadyLinked =>
      'This account is already linked to another Coinsort user.';

  @override
  String get errImageTooLarge =>
      'The image is larger than 5MB. Retake it at a lower quality.';

  @override
  String get errInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errInvalidData =>
      'Invalid data. Check the amount and required fields.';

  @override
  String get errInvalidReference =>
      'A linked item is invalid or has been deleted.';

  @override
  String get errLastLoginMethod =>
      'This is your only way to sign in. Set a password or link another account before unlinking.';

  @override
  String get errLoginIdentifierEmpty => 'Enter your email or username.';

  @override
  String get errManualLinkingDisabled =>
      'Account linking isn\'t enabled on the server yet.';

  @override
  String get errNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errNotFound => 'Data not found.';

  @override
  String get errNotLoggedIn => 'Not signed in. Please sign in again.';

  @override
  String get errNothingToSave => 'No changes to save.';

  @override
  String get errOauthCancelled => 'Sign-in was cancelled.';

  @override
  String get errOauthFailed =>
      'Couldn\'t sign in with this account. Try again.';

  @override
  String get errPasswordTooShort =>
      'Password is too short. Use at least 6 characters.';

  @override
  String get errPermissionDenied => 'You don\'t have permission to do this.';

  @override
  String get errProfileLoadFailed =>
      'Signed in, but couldn\'t load your profile. Try again in a few minutes.';

  @override
  String get errProviderTokenMissing =>
      'Reconnect Facebook to sync your friends.';

  @override
  String get errProviderDisabled =>
      'This sign-in method is temporarily unavailable.';

  @override
  String get errRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errRegisterConfirmEmail =>
      'Registration successful. Check your email to confirm, then sign in.';

  @override
  String get errServerError => 'The server returned an error.';

  @override
  String get errServerNotSetup =>
      'The server is not fully set up. Please contact support.';

  @override
  String get errSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errShareUnsupported =>
      'This device doesn\'t support file sharing.';

  @override
  String get errTransactionNotReturned =>
      'The server didn\'t return the saved transaction.';

  @override
  String get errUnknown => 'Something went wrong. Try again in a few minutes.';

  @override
  String get errUsernameInvalid =>
      'Username must be 3–30 characters: lowercase letters, digits, dot or underscore.';

  @override
  String get errUsernameNotFound => 'No account found with this username.';

  @override
  String get errUsernameRequiredForPassword =>
      'Set a username or add an email first so you can sign in with the password.';

  @override
  String get errUsernameTaken => 'This username is already taken.';

  @override
  String get exportShareSubject => 'Coinsort transaction data';

  @override
  String get filterAccountsLabel => 'Wallets';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterClear => 'Clear filters';

  @override
  String filterDateRange(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get filterMax90Days => 'You can select at most 90 days';

  @override
  String get filterTime30Days => 'Last 30 days';

  @override
  String get filterTime7Days => 'Last 7 days';

  @override
  String get filterTimeAll => 'All';

  @override
  String get filterTimeCustom => 'Custom';

  @override
  String get filterTimeLabel => 'Time period';

  @override
  String get filterTitle => 'Filter';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get groupsAllBalanced => 'All shared expenses are settled up.';

  @override
  String get groupsCodeCopied => 'Invite code copied.';

  @override
  String groupsConfirmPaymentBody(String amount, String name) {
    return 'Confirm that you transferred $amount to $name?\n\nThis only records the repayment; it won\'t deduct money from your wallet. To record the cash flow too, add a separate transfer transaction.';
  }

  @override
  String get groupsCopyCodeTooltip => 'Copy code';

  @override
  String get groupsCreateButton => 'Create group';

  @override
  String get groupsCreateNew => 'Create a new group';

  @override
  String get groupsDeleteFailed => 'Couldn\'t delete the group.';

  @override
  String get groupsDeleteGroup => 'Delete group';

  @override
  String groupsDeleteGroupConfirm(String name) {
    return 'Delete group \"$name\"? Members will lose access. This can\'t be undone.';
  }

  @override
  String get groupsEditGroupName => 'Edit group name';

  @override
  String get groupsEditNameTooltip => 'Edit name';

  @override
  String get groupsEmptyList => 'No groups yet. Create or join one below.';

  @override
  String get groupsEnterGroupName => 'Enter a group name';

  @override
  String get groupsEnterInviteCode => 'Enter an invite code';

  @override
  String groupsError(String error) {
    return 'Error: $error';
  }

  @override
  String get groupsErrorShort => 'Error';

  @override
  String groupsFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String get groupsGroupDebts => 'Group balances';

  @override
  String get groupsGroupDebtsSubtitle =>
      'Who owes whom and how much to transfer';

  @override
  String get groupsGroupDeleted => 'Group deleted';

  @override
  String get groupsGroupNameHint => 'e.g. Family spending';

  @override
  String get groupsGroupNameLabel => 'Group name *';

  @override
  String get groupsGroupNameUpdated => 'Group name updated';

  @override
  String get groupsInviteCode => 'Invite code';

  @override
  String get groupsInviteCodeHint => 'e.g. K7QM2XPD';

  @override
  String get groupsInviteCodeLabel => 'Invite code *';

  @override
  String groupsInviteCodeSemantics(String code) {
    return 'Invite code $code';
  }

  @override
  String get groupsJoinButton => 'Join group';

  @override
  String get groupsJoinByCodeHeader => 'Join with an invite code';

  @override
  String get groupsJoinedGroup => 'Joined the group';

  @override
  String get groupsLeaveGroup => 'Leave group';

  @override
  String groupsLeaveGroupConfirm(String name) {
    return 'Are you sure you want to leave \"$name\"?';
  }

  @override
  String get groupsLoadListFailed => 'Couldn\'t load your groups.';

  @override
  String get groupsLoading => 'Loading...';

  @override
  String get groupsManageTitle => 'Create & join groups';

  @override
  String get groupsMarkPaid => 'Paid';

  @override
  String get groupsMemberLabel => 'Member';

  @override
  String get groupsMyGroups => 'My groups';

  @override
  String groupsNameYou(String name) {
    return '$name (you)';
  }

  @override
  String groupsNewCode(String code) {
    return 'New code: $code';
  }

  @override
  String get groupsNoMembers => 'No members yet';

  @override
  String get groupsNoSettlements => 'No settlements yet';

  @override
  String get groupsNobodyOwes => 'Nobody owes anyone';

  @override
  String groupsPaidShare(String paid, String owed) {
    return 'Paid $paid · share $owed';
  }

  @override
  String get groupsPaymentRecorded => 'Payment recorded.';

  @override
  String get groupsPerPersonDetail => 'Per-person detail';

  @override
  String get groupsPersonal => 'Personal';

  @override
  String get groupsRecordFailed => 'Couldn\'t record the payment.';

  @override
  String get groupsRecordPayment => 'Record payment';

  @override
  String get groupsRemoveFromGroup => 'Remove from group';

  @override
  String groupsRemoveMemberConfirm(String name, String groupName) {
    return 'Remove \"$name\" from group \"$groupName\"?';
  }

  @override
  String get groupsRenameFailed => 'Couldn\'t rename the group.';

  @override
  String get groupsRoleAdmin => 'Admin';

  @override
  String get groupsRotateCodeTooltip => 'Generate new code';

  @override
  String get groupsSettled => 'Settled';

  @override
  String get groupsSettlementHistory => 'Settlement history';

  @override
  String get groupsSettlementsEmptyHint =>
      'Recorded repayments will show up here.';

  @override
  String groupsStillOwes(String amount) {
    return 'still owes $amount';
  }

  @override
  String groupsToReceive(String amount) {
    return 'to receive $amount';
  }

  @override
  String get groupsToTransfer => 'To transfer';

  @override
  String get groupsToTransferSubtitle =>
      'The fewest transfers to settle everyone up';

  @override
  String get groupsYou => 'You';

  @override
  String get memberFallback => 'Member';

  @override
  String get notifAccept => 'Accept';

  @override
  String get notifBack => 'Back';

  @override
  String get notifDecline => 'Decline';

  @override
  String get notifDeclined => 'Invitation declined.';

  @override
  String get notifEmpty => 'No notifications yet.';

  @override
  String notifError(String error) {
    return 'Error: $error';
  }

  @override
  String notifInviteTitle(String inviter) {
    return '$inviter invites you to a group';
  }

  @override
  String get notifJoinError => 'Couldn\'t join the group.';

  @override
  String notifJoinedGroup(String group) {
    return 'Joined group $group.';
  }

  @override
  String get notifSomeone => 'Someone';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get periodCustom => 'Custom';

  @override
  String get profileAccountDesc => 'Username, email, password, linked accounts';

  @override
  String get profileAvatarPickError => 'Couldn\'t open the photo library.';

  @override
  String get profileAvatarUpdated => 'Avatar updated.';

  @override
  String get profileBack => 'Back';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileChooseGroupToInvite => 'Choose a group to invite them to';

  @override
  String get profileConnectFacebook => 'Link Facebook';

  @override
  String get profileCreateOrJoinGroup => 'Create or join a group';

  @override
  String get profileDefaultUserName => 'User';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileEditNameTitle => 'Change display name';

  @override
  String get profileFindFriends => 'Find friends';

  @override
  String get profileGroupActive => 'Active';

  @override
  String get profileInviteFriendsTitle => 'Invite friends to a group';

  @override
  String profileInviteSuccess(String name) {
    return 'Invited $name to the group.';
  }

  @override
  String profileInviteTo(String group) {
    return 'Invite to $group';
  }

  @override
  String get profileInviting => 'Inviting...';

  @override
  String get profileMe => 'Me';

  @override
  String get profileMemberFallback => 'member';

  @override
  String get profileMemberTitle => 'Member';

  @override
  String get profileNoResults => 'No matching people found.';

  @override
  String get profileNoSharedGroups =>
      'No shared groups yet. Go to Manage groups → Add group → Create a new group.';

  @override
  String get profileReconnectFacebook => 'Reconnect Facebook';

  @override
  String get profileSearchButton => 'Search';

  @override
  String get profileSearchHint =>
      'Username or full name (at least 2 characters)';

  @override
  String get profileSearchPrompt =>
      'Enter a keyword and tap Search to find friends.';

  @override
  String get profileSectionGroups => 'Groups';

  @override
  String get profileSectionTools => 'Tools';

  @override
  String get profileSelectGroup => 'Select a group';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileSuggestionSourceFacebook => 'Facebook friend';

  @override
  String get profileSuggestionSourceGroup => 'In a group with you';

  @override
  String get profileSuggestionSourceX => 'Following on X';

  @override
  String get profileSuggestionsEmpty =>
      'No suggestions yet. Link Facebook in Account or join a shared group.';

  @override
  String get profileSuggestionsEmptyNoSocial =>
      'No suggestions yet. Join a shared group to see people you can invite.';

  @override
  String get profileSuggestionsTitle => 'Suggested';

  @override
  String get profileSyncFacebook => 'Sync Facebook friends';

  @override
  String profileSyncFacebookDone(int count) {
    return 'Synced $count Facebook friends who use Coinsort.';
  }

  @override
  String get profileSyncing => 'Syncing…';

  @override
  String get profileToolAccounts => 'Manage wallets';

  @override
  String get profileToolBudgets => 'Budgets';

  @override
  String get profileToolCategories => 'Manage categories';

  @override
  String get profileToolFriends => 'Friends';

  @override
  String get profileToolRecurring => 'Recurring transactions';

  @override
  String get profileToolSearch => 'Find transactions';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get receiptAttach => 'Attach receipt';

  @override
  String get receiptChooseFromLibrary => 'Choose from library';

  @override
  String get receiptLoadFailed => 'Couldn\'t load the receipt image.';

  @override
  String get receiptPickerError => 'Couldn\'t open the photo library.';

  @override
  String get receiptRemove => 'Remove image';

  @override
  String get receiptTakePhoto => 'Take photo';

  @override
  String get receiptUploadFailed => 'Couldn\'t upload the image.';

  @override
  String get receiptUploading => 'Uploading image…';

  @override
  String get receiptViewFull => 'View receipt';

  @override
  String recordsAllShown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing all $count transactions',
      one: 'Showing 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get recordsEmptyMessage =>
      'Tap the + button in the middle of the bottom bar to add your first entry.';

  @override
  String get recordsEmptyTitle => 'No transactions yet';

  @override
  String get recordsExpense => 'Expense';

  @override
  String recordsGroupOwesYou(String amount) {
    return 'The group owes you $amount';
  }

  @override
  String get recordsIncome => 'Income';

  @override
  String get recordsRemaining => 'Remaining';

  @override
  String get recordsTransfer => 'Transfer';

  @override
  String get recordsUncategorized => 'Uncategorized';

  @override
  String get recordsYou => 'you';

  @override
  String recordsYouOweGroup(String amount) {
    return 'You owe the group $amount';
  }

  @override
  String recordsYourShare(String amount) {
    return 'Your share: $amount';
  }

  @override
  String get recurringAccountLabel => 'Wallet *';

  @override
  String get recurringAddTitle => 'Add recurring transaction';

  @override
  String get recurringAmountLabel => 'Amount *';

  @override
  String get recurringAmountMustBePositive => 'Enter an amount greater than 0.';

  @override
  String get recurringBack => 'Back';

  @override
  String get recurringCategoryLabel => 'Category';

  @override
  String recurringCreatedDue(int count) {
    return 'Created $count due transactions.';
  }

  @override
  String get recurringDeleteConfirm =>
      'Transactions already generated will be kept.';

  @override
  String get recurringDeleteTitle => 'Delete recurring transaction';

  @override
  String get recurringDeleted => 'Deleted.';

  @override
  String get recurringDeletedAccount => 'Deleted wallet';

  @override
  String get recurringDue => 'Due';

  @override
  String get recurringEmptyMessage =>
      'Add regularly repeating items like rent, salary, or subscriptions so you don\'t have to re-enter them each cycle.';

  @override
  String get recurringEmptyTitle => 'No recurring transactions yet';

  @override
  String get recurringExpense => 'Expense';

  @override
  String get recurringExpenseSegment => 'Expense';

  @override
  String get recurringFrequencyLabel => 'Repeat';

  @override
  String recurringInDays(int days) {
    return 'In $days days';
  }

  @override
  String get recurringIncome => 'Income';

  @override
  String get recurringIncomeSegment => 'Income';

  @override
  String get recurringNextDate => 'Next occurrence';

  @override
  String get recurringNoneDue => 'No transactions are due.';

  @override
  String get recurringNote => 'Note';

  @override
  String recurringOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are due but not yet recorded.',
      one: '1 item is due but not yet recorded.',
    );
    return '$_temp0';
  }

  @override
  String get recurringRunDueTooltip => 'Run due items';

  @override
  String get recurringRunFailed => 'Couldn\'t run.';

  @override
  String get recurringRunNow => 'Run now';

  @override
  String get recurringSelectAccount => 'Select a wallet.';

  @override
  String get recurringTitle => 'Recurring transactions';

  @override
  String get recurringToday => 'Today';

  @override
  String get recurringTomorrow => 'Tomorrow';

  @override
  String get reportsAddWallet => 'Add wallet';

  @override
  String get reportsAssets => 'Assets';

  @override
  String reportsCreditLeft(String amount) {
    return '$amount credit left';
  }

  @override
  String get reportsDebt => 'Debt';

  @override
  String get reportsLiabilitiesSection => 'Debt & credit cards';

  @override
  String get reportsManageWallets => 'Manage wallets';

  @override
  String get reportsMultiCurrencyNote =>
      'Each currency is totaled separately. The app doesn\'t convert exchange rates.';

  @override
  String get reportsNetWorth => 'Net worth';

  @override
  String get reportsNoWalletsMessage => 'Add a wallet to track your net worth.';

  @override
  String get reportsNoWalletsTitle => 'No wallets yet';

  @override
  String get reportsNotCountedInNetWorth => 'Not counted in net worth';

  @override
  String get reportsTitle => 'Reports';

  @override
  String routeErrorBody(String location) {
    return 'Couldn\'t open \"$location\".';
  }

  @override
  String get routeErrorGoHome => 'Go to home';

  @override
  String get routeErrorTitle => 'Couldn\'t open the page';

  @override
  String get searchAmountFrom => 'From';

  @override
  String get searchAmountTo => 'To';

  @override
  String get searchBack => 'Back';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchClearAll => 'Clear all';

  @override
  String get searchEmptyMessage =>
      'Enter a keyword, or open filters to search by category, amount, and date range.';

  @override
  String get searchEmptyTitle => 'Search transactions';

  @override
  String get searchFilters => 'Filters';

  @override
  String get searchHint => 'Search notes, places…';

  @override
  String searchNetSpending(String amount) {
    return 'Net spending $amount';
  }

  @override
  String get searchNoResultsMessage =>
      'Try fewer filters or a different keyword.';

  @override
  String get searchNoResultsTitle => 'No transactions found';

  @override
  String get searchPickDateRange => 'Pick date range';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get searchTransfer => 'Transfer';

  @override
  String get searchTypeExpense => 'Expense';

  @override
  String get searchTypeIncome => 'Income';

  @override
  String get searchTypeTransfer => 'Transfer';

  @override
  String get searchUncategorized => 'Uncategorized';

  @override
  String get settingsBack => 'Back';

  @override
  String get settingsBiometricLock => 'App lock';

  @override
  String get settingsBiometricLockDesc =>
      'Require fingerprint or Face ID to open the app';

  @override
  String get settingsBudgets => 'Budgets';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountDesc =>
      'Permanently delete your account and all data';

  @override
  String get settingsDeleteBulletInvites =>
      'All group invitations involving you';

  @override
  String get settingsDeleteBulletPersonalTx =>
      'All transactions in your personal group';

  @override
  String get settingsDeleteBulletProfile => 'Profile, display name, and avatar';

  @override
  String get settingsDeleteBulletSharedTx =>
      'Transactions you recorded in SHARED groups — deleting them would distort the remaining members\' balances. These transactions are no longer linked to your profile.';

  @override
  String get settingsDeleteBulletWallets =>
      'Wallets, personal categories, budgets, recurring transactions';

  @override
  String get settingsDeleteConfirmButton => 'Delete permanently';

  @override
  String settingsDeleteConfirmPrompt(String phrase) {
    return 'Type \"$phrase\" to confirm';
  }

  @override
  String get settingsDeleteDialogBody =>
      'This is the final step. Once deleted, your personal data cannot be recovered.';

  @override
  String get settingsDeleteDialogTitle => 'Delete permanently?';

  @override
  String get settingsDeleteKeepAccount => 'Keep account';

  @override
  String get settingsDeleteMyAccountButton => 'Delete my account';

  @override
  String get settingsDeleteSharedTxNote =>
      'Want to remove those transactions too? Delete them yourself, or leave the group before deleting your account.';

  @override
  String get settingsDeleteSuccess => 'Your account has been deleted.';

  @override
  String get settingsDeleteWarning => 'This action can\'t be undone.';

  @override
  String get settingsDeleteWhatKept => 'What will be kept';

  @override
  String get settingsDeleteWhatRemoved => 'What will be deleted';

  @override
  String get settingsExportAllHistory => 'All history';

  @override
  String get settingsExportClearRange => 'Clear date range';

  @override
  String get settingsExportCsvDesc =>
      'A CSV file opens in Excel, Google Sheets, or Numbers. It includes date, type, category, amount, wallet, note, and the group split.';

  @override
  String get settingsExportCsvTitle => 'Export CSV';

  @override
  String settingsExportCurrencyWarning(int count, String list) {
    return 'Your wallets use $count currencies ($list). The \"Amount\" column keeps each wallet\'s original currency — don\'t sum the column directly.';
  }

  @override
  String get settingsExportData => 'Export data';

  @override
  String get settingsExportDataDesc => 'Download all transactions as CSV';

  @override
  String get settingsExportDateRange => 'Date range';

  @override
  String settingsExportGroupLabel(String name) {
    return 'Group: $name';
  }

  @override
  String get settingsExportMaxRowsNote =>
      'Up to 5,000 transactions per export. If your history is longer, export it in separate date ranges.';

  @override
  String get settingsExportNoGroup => 'No group selected.';

  @override
  String get settingsExportPreparing => 'Preparing…';

  @override
  String get settingsExportShare => 'Export and share';

  @override
  String settingsExportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count transactions.',
      one: 'Exported 1 transaction.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFirstDayOfMonth => 'Month start day';

  @override
  String settingsFirstDayOfMonthDesc(int day) {
    return 'Day $day — for when your salary arrives mid-month';
  }

  @override
  String get settingsHideAmounts => 'Hide amounts';

  @override
  String get settingsHideAmountsDesc => 'Hide amounts when in a crowded place';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsManageCategories => 'Manage categories';

  @override
  String get settingsManageWallets => 'Manage wallets';

  @override
  String get settingsPrivacyContactBody =>
      'Questions about your data? Reach out via the support address listed on the app store page.';

  @override
  String get settingsPrivacyDataAccount =>
      'Your account: username, display name, avatar if you upload one, and email if you add one. If you sign in with Google, Facebook or X we receive the name, email and avatar that provider shares, plus the provider\'s account ID so we can recognise the link.';

  @override
  String get settingsPrivacyDataFinancial =>
      'Financial data you enter yourself: transactions, amounts, categories, notes, wallet names, balances, budgets, and receipt photos if you attach them.';

  @override
  String get settingsPrivacyDataGroup =>
      'Group data: group names, member lists, each expense\'s split, and settlements.';

  @override
  String get settingsPrivacyDataSocialFriends =>
      'If you link Facebook, we store the IDs of your Facebook friends who also use Coinsort, only to suggest people you can invite to a group. Nothing is posted to your social accounts.';

  @override
  String get settingsPrivacyDontAds =>
      'We don\'t show ads or embed advertising trackers.';

  @override
  String get settingsPrivacyDontBank =>
      'We don\'t connect to your bank or read your statements.';

  @override
  String get settingsPrivacyDontSell =>
      'We don\'t sell or share your data with third parties.';

  @override
  String get settingsPrivacyHeadingContact => 'Contact';

  @override
  String get settingsPrivacyHeadingDataStored => 'Data we store';

  @override
  String get settingsPrivacyHeadingSecurity => 'Security';

  @override
  String get settingsPrivacyHeadingWeDont => 'What we DON\'T do';

  @override
  String get settingsPrivacyHeadingWhereStored => 'Where it\'s stored';

  @override
  String get settingsPrivacyHeadingWhoSees => 'Who can see it';

  @override
  String get settingsPrivacyHeadingYourRights => 'Your rights';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyRightsDelete =>
      'Delete account: Settings → Delete account. Your profile, personal data, wallets, categories, and budgets will be deleted.';

  @override
  String get settingsPrivacyRightsDeleteException =>
      'Deletion exception: transactions you recorded in SHARED groups are kept, because deleting them would distort the remaining members\' balances. They are no longer linked to your profile. To remove these too, delete them manually or leave the group first.';

  @override
  String get settingsPrivacyRightsExport =>
      'Export data: Settings → Export data to download all your transactions as CSV anytime.';

  @override
  String get settingsPrivacySecurityBiometric =>
      'You can enable fingerprint or Face ID lock in Settings to add an extra layer of protection on your device.';

  @override
  String get settingsPrivacySecurityHttps =>
      'All connections use HTTPS. Passwords are managed by Supabase Auth and never stored in the app.';

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsPrivacyUpdated => 'Updated: 01/09/2026';

  @override
  String get settingsPrivacyWhereDatabase =>
      'Data is stored on Supabase (PostgreSQL and Storage). Access is controlled by Row Level Security at the database layer, not just in the app.';

  @override
  String get settingsPrivacyWhereLocal =>
      'Display settings (currency, language, appearance) are stored on your own device and not sent to the server.';

  @override
  String get settingsPrivacyWhoBalances =>
      'Your PERSONAL wallet balances are not shown to other members. A group\'s shared wallet is visible to the whole group.';

  @override
  String get settingsPrivacyWhoPersonal =>
      'Data in a personal group is visible only to you.';

  @override
  String get settingsPrivacyWhoReceipts =>
      'Receipt photos are kept in private storage, readable only by the account that uploaded them.';

  @override
  String get settingsPrivacyWhoShared =>
      'Data in a shared group is visible to every active member of that group — including amounts, categories, notes, and who paid.';

  @override
  String get settingsRecalcAllMatch => 'All wallet balances match the ledger.';

  @override
  String get settingsRecalcDesc =>
      'Rebuild all wallet balances from the ledger';

  @override
  String get settingsRecalcFailed => 'Couldn\'t reconcile balances.';

  @override
  String settingsRecalcFixedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fixed $count wallets',
      one: 'Fixed 1 wallet',
    );
    return '$_temp0';
  }

  @override
  String settingsRecalcMoreWallets(int count) {
    return 'and $count more wallets…';
  }

  @override
  String get settingsRecalcTitle => 'Reconcile balances';

  @override
  String get settingsRecurring => 'Recurring transactions';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionCheck => 'Checks';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsSectionPeriod => 'Financial period';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shellFilterTooltip => 'Filter';

  @override
  String get shellFriends => 'Friends';

  @override
  String get shellNotifications => 'Notifications';

  @override
  String get shellSearchTooltip => 'Search transactions';

  @override
  String splitExcessBy(String amount) {
    return 'Over by $amount.';
  }

  @override
  String get splitMember => 'Member';

  @override
  String get splitModeEqual => 'Split equally';

  @override
  String get splitModeExact => 'Exact amounts';

  @override
  String get splitModeNone => 'Don\'t split';

  @override
  String get splitModePercent => 'By percentage';

  @override
  String get splitModeShares => 'By shares';

  @override
  String get splitNeedParticipant =>
      'Select at least one person to split with.';

  @override
  String get splitNeedShares => 'Enter shares for at least one person.';

  @override
  String get splitPaidByLabel => 'Who paid this *';

  @override
  String splitPercentTotal(String percent) {
    return 'Percentages add up to $percent%, they must total 100%.';
  }

  @override
  String get splitSharesSuffix => 'shares';

  @override
  String splitShortBy(String amount) {
    return 'Short by $amount.';
  }

  @override
  String get splitYou => 'You';

  @override
  String get txAccountLabel => 'Wallet *';

  @override
  String get txAccountsMustDiffer =>
      'The source and destination wallets must be different.';

  @override
  String get txAmountLabel => 'Amount *';

  @override
  String get txAmountMustBePositive => 'Enter an amount greater than 0.';

  @override
  String get txChangesSaved => 'Changes saved.';

  @override
  String get txCreateFailed => 'Couldn\'t save the transaction.';

  @override
  String get txDeleteCategory => 'Delete category';

  @override
  String get txDeleteFailed => 'Couldn\'t delete the transaction.';

  @override
  String get txDeleteTransactionConfirm =>
      'Delete this transaction? The wallet balance will be adjusted back accordingly.';

  @override
  String get txDeleteTransactionTitle => 'Delete transaction';

  @override
  String get txEditCategory => 'Edit category';

  @override
  String get txEditExpenseTitle => 'Edit expense';

  @override
  String get txEditIncomeTitle => 'Edit income';

  @override
  String get txEditTransferTitle => 'Edit transfer';

  @override
  String get txFromAccountLabel => 'From wallet *';

  @override
  String get txNoGroupSelected => 'No group selected. Pull down to reload.';

  @override
  String get txNote => 'Note';

  @override
  String get txPayeeExpenseHint => 'e.g. Highlands';

  @override
  String get txPayeeExpenseLabel => 'Spent at';

  @override
  String get txPayeeIncomeHint => 'e.g. Company';

  @override
  String get txPayeeIncomeLabel => 'Income source';

  @override
  String txRecordedBy(String name, String date) {
    return 'Recorded by $name · $date';
  }

  @override
  String get txSelectAccount => 'Select a wallet.';

  @override
  String get txSelectBothAccounts =>
      'Select both the source and destination wallets.';

  @override
  String get txToAccountLabel => 'To wallet *';

  @override
  String get txTransactionDate => 'Transaction date';

  @override
  String get txTransactionDeleted => 'Transaction deleted.';

  @override
  String get txUpdateFailed => 'Couldn\'t update the transaction.';
}
