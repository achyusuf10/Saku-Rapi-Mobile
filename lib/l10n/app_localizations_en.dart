// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get lastYear => 'Last Year';

  @override
  String get custom => 'Custom';

  @override
  String get yearSuffix => 'year';

  @override
  String get monthSuffix => 'month';

  @override
  String get weekSuffix => 'week';

  @override
  String get daySuffix => 'day';

  @override
  String get hourSuffix => 'hour';

  @override
  String get minuteSuffix => 'minute';

  @override
  String get agoSuffix => 'ago';

  @override
  String get justNow => 'just now';

  @override
  String get fabVoiceInput => 'Voice Input';

  @override
  String get fabScanReceipt => 'Scan Receipt';

  @override
  String get fabManualInput => 'Manual Input';

  @override
  String get appName => 'SakuRapi';

  @override
  String get loginSubtitle => 'Track your finances without the hassle.';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginErrorGeneric => 'Sign in failed. Please try again.';

  @override
  String get loginTitle => 'Welcome to SakuRapi';

  @override
  String get loginSecurityNote => 'Your data is safe & encrypted';

  @override
  String get logoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String get walletTitle => 'My Wallets';

  @override
  String get walletAdd => 'Add Wallet';

  @override
  String get walletEdit => 'Edit Wallet';

  @override
  String get walletDelete => 'Delete';

  @override
  String walletDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? All transactions in this wallet will also be deleted.';
  }

  @override
  String get walletName => 'Wallet Name';

  @override
  String get walletNameHint => 'e.g. Cash, BCA, Jago';

  @override
  String get walletNameRequired => 'Wallet name is required';

  @override
  String get walletInitialBalance => 'Initial Balance';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletBalanceRequired => 'Balance is required';

  @override
  String get walletIcon => 'Icon';

  @override
  String get walletColor => 'Color';

  @override
  String get walletExcludeFromTotal => 'Exclude from Total';

  @override
  String get walletExcludeHint =>
      'This wallet\'s balance is not included in total';

  @override
  String get walletSave => 'Save';

  @override
  String get walletTotalBalance => 'Total Balance';

  @override
  String get walletIncludedSection => 'Included in Total';

  @override
  String get walletExcludedSection => 'Excluded from Total';

  @override
  String get walletEmpty => 'No wallets yet';

  @override
  String get walletEmptyHint => 'Tap + to add a new wallet';

  @override
  String get walletAdjust => 'Adjust Balance';

  @override
  String get walletAdjustActual => 'Actual Balance';

  @override
  String get walletAdjustDiff => 'Difference';

  @override
  String get walletAdjustHint => 'Enter the real balance of this wallet';

  @override
  String walletSuccessAdd(String name) {
    return '\"$name\" successfully added';
  }

  @override
  String walletSuccessEdit(String name) {
    return '\"$name\" successfully updated';
  }

  @override
  String walletSuccessDelete(String name) {
    return '\"$name\" successfully deleted';
  }

  @override
  String get walletSuccessAdjust => 'Balance adjusted successfully';

  @override
  String get walletErrorAdd => 'Failed to add wallet';

  @override
  String get walletErrorEdit => 'Failed to update wallet';

  @override
  String get walletErrorDelete => 'Failed to delete wallet';

  @override
  String get walletErrorAdjust => 'Failed to adjust balance';

  @override
  String get walletOptionEdit => 'Edit';

  @override
  String get walletOptionDelete => 'Delete';

  @override
  String get walletOptionAdjust => 'Adjust Balance';

  @override
  String get retryButton => 'Try Again';

  @override
  String get confirmYes => 'Yes';

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get transactionExpense => 'Expense';

  @override
  String get transactionIncome => 'Income';

  @override
  String get transactionDebt => 'Debt';

  @override
  String get transactionLoan => 'Loan';

  @override
  String get transactionTransfer => 'Transfer';

  @override
  String get transactionAdjustment => 'Adjustment';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionCategory => 'Category';

  @override
  String get transactionWallet => 'Wallet';

  @override
  String get transactionDate => 'Date';

  @override
  String get transactionNote => 'Note';

  @override
  String get transactionAttachment => 'Attachment';

  @override
  String get transactionWithPerson => 'Contact Name';

  @override
  String get transactionWithPersonHint => 'e.g. Budi, Mom';

  @override
  String get transactionAddItem => '+ Add Item';

  @override
  String get transactionGrandTotal => 'Grand Total';

  @override
  String get transactionSave => 'Save';

  @override
  String get transactionSaveSuccess => 'Transaction saved successfully';

  @override
  String get transactionDeleteConfirm => 'Delete this transaction?';

  @override
  String get transactionPrefilledFromVoice => 'Pre-filled from voice';

  @override
  String get transactionPrefilledFromOcr => 'Pre-filled from receipt';

  @override
  String get transactionDebtStatus => 'Status';

  @override
  String get transactionUnpaid => 'Unpaid';

  @override
  String get transactionPaid => 'Paid';

  @override
  String get transactionDueDate => 'Due Date';

  @override
  String get transactionSourceWallet => 'Source Wallet';

  @override
  String get transactionDestWallet => 'Destination Wallet';

  @override
  String get transactionMerchant => 'Merchant Name';

  @override
  String get transactionMerchantHint => 'e.g. Indomaret, Grab';

  @override
  String get transactionWalletRequired => 'Please select a wallet';

  @override
  String get transactionAmountRequired => 'Amount is required';

  @override
  String get transactionWithPersonRequired =>
      'Contact name is required for debt/loan';

  @override
  String get transactionDestWalletRequired =>
      'Please select a destination wallet';

  @override
  String get transactionSameWalletError =>
      'Source and destination wallets must be different';

  @override
  String get transactionErrorSave => 'Failed to save transaction';

  @override
  String get transactionDebtTypeHutang => 'Debt (I owe someone)';

  @override
  String get transactionDebtTypePiutang => 'Loan (someone owes me)';

  @override
  String get transactionSelectCategory => 'Select Category';

  @override
  String get transactionSelectWallet => 'Select Wallet';

  @override
  String get transactionMultiItemToggle => 'Multiple Items';

  @override
  String get transactionNewTitle => 'New Transaction';

  @override
  String get transactionAttachmentAdd => 'Add Attachment';

  @override
  String get transactionAttachmentChange => 'Change Attachment';

  @override
  String get transactionOptionalFields => 'Optional Details';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardTotalBalance => 'Total Balance';

  @override
  String get dashboardMyWallets => 'My Wallets';

  @override
  String get dashboardSeeAll => 'See All';

  @override
  String get dashboardSnapshotTitle => 'This Month\'s Summary';

  @override
  String get dashboardTopExpenses => 'Top Expenses';

  @override
  String get dashboardRecentTransactions => 'Recent Transactions';

  @override
  String get dashboardIncomeLabel => 'Income';

  @override
  String get dashboardExpenseLabel => 'Expense';

  @override
  String get dashboardEmptyTransactions => 'No transactions yet';

  @override
  String get dashboardHideBalance => 'Hide balance';

  @override
  String get dashboardShowBalance => 'Show balance';

  @override
  String get dashboardExcludedFromTotal => 'Excluded from total';

  @override
  String dashboardWeekLabel(Object week) {
    return 'Week $week';
  }

  @override
  String get dashboardComingSoon => 'Coming Soon';

  @override
  String get historyTitle => 'History';

  @override
  String get historyTabTransactions => 'Transactions';

  @override
  String get historyTabReport => 'Report';

  @override
  String get historyNoTransactions => 'No transactions in this period';

  @override
  String get historyTotalIn => 'Income';

  @override
  String get historyTotalOut => 'Expense';

  @override
  String get historyFilter => 'Filter';

  @override
  String get historyAllWallets => 'All Wallets';

  @override
  String get historySelectWallet => 'Select Wallet';

  @override
  String get historyApplyFilter => 'Apply Filter';

  @override
  String get historyResetFilter => 'Reset';

  @override
  String get breakdownTitle => 'Expense Breakdown';

  @override
  String get breakdownVsLastMonth => 'vs Last Month';

  @override
  String get breakdownDailyAverage => 'Daily Average';

  @override
  String get breakdownSubcategories => 'Sub-categories';

  @override
  String get breakdownTransactions => 'Transactions';

  @override
  String get breakdownNoData => 'No data available';

  @override
  String get categoryTitle => 'Categories';

  @override
  String get categoryExpense => 'Expense';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categoryAdd => 'Add Category';

  @override
  String get categoryEdit => 'Edit Category';

  @override
  String get categoryDelete => 'Delete Category';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? Transactions using this category won\'t be affected.';
  }

  @override
  String get categoryDeleteDefault => 'Default categories cannot be deleted';

  @override
  String get categoryHide => 'Hide';

  @override
  String get categoryShow => 'Show';

  @override
  String get categoryHidden => 'Hidden';

  @override
  String get categoryIconPicker => 'Choose Icon';

  @override
  String get categoryColorPicker => 'Choose Color';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get categoryParent => 'Parent Category';

  @override
  String get categoryNoParent => 'No Parent (Top Level)';

  @override
  String get categorySave => 'Save';

  @override
  String categorySuccessAdd(String name) {
    return '\"$name\" successfully added';
  }

  @override
  String categorySuccessEdit(String name) {
    return '\"$name\" successfully updated';
  }

  @override
  String get categorySuccessDelete => 'Category deleted successfully';

  @override
  String get categorySuccessHide => 'Category hidden';

  @override
  String get categorySuccessShow => 'Category shown';

  @override
  String get categoryErrorSave => 'Failed to save category';

  @override
  String get categoryErrorDelete => 'Failed to delete category';

  @override
  String get categoryEmpty => 'No categories yet';

  @override
  String get categorySearchIcon => 'Search icon...';

  @override
  String categoryChildCount(int count) {
    return '$count sub-categories';
  }

  @override
  String get voiceListening => 'Listening...';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceProcessing => 'Processing voice...';

  @override
  String get voiceError => 'Could not recognize speech, please try again';

  @override
  String get voicePermissionDenied => 'Microphone permission is required';

  @override
  String voiceCountdown(int seconds) {
    return 'Stops in $seconds seconds';
  }

  @override
  String get voicePrefilledBadge => 'Filled from voice';

  @override
  String get ocrTitle => 'Scan Receipt';

  @override
  String get ocrCamera => 'Camera';

  @override
  String get ocrGallery => 'Gallery';

  @override
  String get ocrCropInstruction => 'Crop receipt area';

  @override
  String get ocrScanning => 'Reading receipt...';

  @override
  String get ocrResultTitle => 'Scan Result';

  @override
  String get ocrMerchant => 'Merchant';

  @override
  String get ocrGrandTotal => 'Total';

  @override
  String ocrItemCount(int count) {
    return '$count items detected';
  }

  @override
  String get ocrContinue => 'Continue';

  @override
  String get ocrRescan => 'Rescan';

  @override
  String get ocrAutoBalance => 'Difference added automatically';

  @override
  String get ocrNoText => 'No text detected';

  @override
  String get ocrPrefilledBadge => 'Filled from receipt scan';

  @override
  String get budgetTitle => 'Active Budgets';

  @override
  String get budgetAdd => 'Create Budget';

  @override
  String get budgetEmpty => 'No budgets yet';

  @override
  String get budgetEmptyHint =>
      'Start tracking your spending by creating your first budget';

  @override
  String get budgetActiveBudgets => 'Active Budgets';

  @override
  String get budgetSpendableLabel => 'Amount you can spend';

  @override
  String get budgetTotalBudgetLabel => 'Total Budget';

  @override
  String get budgetUsed => 'Used';

  @override
  String get budgetEndOfMonthLabel => 'End of Month';

  @override
  String budgetDaysRemaining(int days) {
    return '$days days';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Remaining $amount';
  }

  @override
  String budgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetToday => 'Today';

  @override
  String get budgetPeriodTitle => 'Select Period';

  @override
  String get budgetPeriodThisWeek => 'This week';

  @override
  String get budgetPeriodThisMonth => 'This month';

  @override
  String get budgetPeriodThisQuarter => 'This quarter';

  @override
  String get budgetPeriodThisYear => 'This year';

  @override
  String get budgetPeriodCustom => 'Custom';

  @override
  String get budgetAllWallets => 'All Wallets';

  @override
  String get budgetSpecificWallet => 'Specific Wallet';

  @override
  String get budgetFormTitleAdd => 'Add Budget';

  @override
  String get budgetFormTitleEdit => 'Edit Budget';

  @override
  String get budgetFormCategory => 'Category';

  @override
  String get budgetFormCategorySelect => 'Select category...';

  @override
  String get budgetFormCategoryError => 'Failed to load categories';

  @override
  String get budgetFormCategoryRequired => 'Please select a category';

  @override
  String get budgetFormAmount => 'Budget Amount';

  @override
  String get budgetFormAmountRequired => 'Enter budget amount';

  @override
  String get budgetFormAmountInvalid => 'Amount must be greater than 0';

  @override
  String get budgetFormPeriod => 'Period';

  @override
  String get budgetFormPeriodSelect => 'Select period...';

  @override
  String get budgetFormPeriodRequired => 'Please select a period';

  @override
  String get budgetFormWalletScope => 'Apply to';

  @override
  String get budgetFormRecurringTitle => 'Repeat this budget';

  @override
  String get budgetFormRecurringSubtitle =>
      'Budget automatically renews each period';

  @override
  String get budgetSave => 'Save';

  @override
  String get budgetCancel => 'Cancel';

  @override
  String get budgetSuccessAdd => 'Budget created successfully';

  @override
  String get budgetSuccessEdit => 'Budget updated successfully';

  @override
  String get budgetSuccessDelete => 'Budget deleted successfully';

  @override
  String get budgetErrorAdd => 'Failed to create budget';

  @override
  String get budgetErrorEdit => 'Failed to update budget';

  @override
  String get budgetErrorDelete => 'Failed to delete budget';

  @override
  String get budgetDeleteConfirmTitle => 'Delete Budget?';

  @override
  String budgetDeleteConfirmMessage(String name) {
    return 'Budget for \"$name\" will be permanently deleted.';
  }

  @override
  String get investmentTitle => 'Investments';

  @override
  String get investmentAdd => 'Add Investment';

  @override
  String get investmentEdit => 'Edit Investment';

  @override
  String get investmentDelete => 'Delete Investment';

  @override
  String get investmentPortfolio => 'Total Portfolio';

  @override
  String get investmentTotalValue => 'Current Value';

  @override
  String get investmentTotalPL => 'Total P&L';

  @override
  String get investmentTypeGold => 'Gold';

  @override
  String get investmentTypeBtc => 'Bitcoin';

  @override
  String get investmentTypeCustom => 'Custom';

  @override
  String get investmentBuyPrice => 'Buy Price';

  @override
  String get investmentCurrentPrice => 'Current Price';

  @override
  String get investmentAmount => 'Amount';

  @override
  String get investmentUnit => 'unit';

  @override
  String get investmentEmptyTitle => 'No Investments Yet';

  @override
  String get investmentEmptySubtitle => 'Tap + to add your first asset';

  @override
  String get investmentRefreshPrice => 'Refresh Prices';

  @override
  String get investmentFormTitleAdd => 'Add Investment';

  @override
  String get investmentFormTitleEdit => 'Edit Investment';

  @override
  String get investmentFormType => 'Asset Type';

  @override
  String get investmentFormName => 'Asset Name';

  @override
  String get investmentFormNameHint => 'e.g., Gold Bar, Bitcoin';

  @override
  String get investmentFormNameRequired => 'Asset name is required';

  @override
  String get investmentFormAmount => 'Amount (units)';

  @override
  String get investmentFormAmountRequired => 'Amount is required';

  @override
  String get investmentFormAmountInvalid => 'Amount must be greater than 0';

  @override
  String get investmentFormBuyPrice => 'Buy Price per Unit (IDR)';

  @override
  String get investmentFormBuyPriceRequired => 'Buy price is required';

  @override
  String get investmentFormBuyPriceInvalid =>
      'Buy price must be greater than 0';

  @override
  String get investmentFormCurrentPrice => 'Current Price (IDR)';

  @override
  String get investmentFormCurrentPriceHint => 'Optional — for custom assets';

  @override
  String get investmentFormDeductWallet => 'Deduct from Wallet';

  @override
  String get investmentFormDeductWalletSubtitle =>
      'Wallet balance will be deducted automatically';

  @override
  String get investmentFormWallet => 'Select Wallet';

  @override
  String get investmentFormWalletRequired => 'Please select a wallet';

  @override
  String get investmentFormNotes => 'Notes';

  @override
  String get investmentFormNotesHint => 'Optional';

  @override
  String get investmentFormEstimatedCost => 'Estimated Total Cost';

  @override
  String get investmentSave => 'Save Investment';

  @override
  String get investmentSuccessAdd => 'Investment added successfully';

  @override
  String get investmentSuccessEdit => 'Investment updated successfully';

  @override
  String get investmentSuccessDelete => 'Investment deleted successfully';

  @override
  String get investmentErrorAdd => 'Failed to add investment';

  @override
  String get investmentErrorEdit => 'Failed to update investment';

  @override
  String get investmentErrorDelete => 'Failed to delete investment';

  @override
  String get investmentDeleteConfirmTitle => 'Delete Investment?';

  @override
  String investmentDeleteConfirmMessage(String name) {
    return 'Asset \"$name\" will be permanently deleted.';
  }

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifReminderTitle => 'Daily Reminder';

  @override
  String get notifReminderSubtitle => 'Remind me to record transactions';

  @override
  String get notifReminderTime => 'Reminder Time';

  @override
  String get notifBudgetTitle => 'Budget Alert';

  @override
  String get notifBudgetSubtitle => 'Notify when budget reaches 80% and 100%';

  @override
  String get notifDebtTitle => 'Debt Reminder';

  @override
  String get notifDebtSubtitle => 'Remind before due date';

  @override
  String notifDebtDaysBefore(int days) {
    return 'Remind $days days before';
  }

  @override
  String notifBudgetAlert80(String category) {
    return 'Budget $category is 80% used!';
  }

  @override
  String notifBudgetAlert100(String category) {
    return 'Budget $category is fully used!';
  }

  @override
  String notifDebtDue(String person, int days) {
    return 'Debt to $person is due in $days days';
  }

  @override
  String get notifSave => 'Save Settings';

  @override
  String get notifSaveSuccess => 'Notification settings saved successfully';

  @override
  String get notifSaveError => 'Failed to save notification settings';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navHistory => 'History';

  @override
  String get navBudget => 'Budget';

  @override
  String get navInvestment => 'Investment';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditName => 'Edit Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileCategories => 'Categories';

  @override
  String get profileWallets => 'Wallets';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirmTitle => 'Logout';

  @override
  String get profileLogoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get profileDarkMode => 'Dark Mode';

  @override
  String get profileLanguage => 'Language';

  @override
  String get pickerChooseIcon => 'Choose Icon';

  @override
  String get pickerChooseColor => 'Choose Color';

  @override
  String get pickerSearchCategory => 'Search category...';
}
