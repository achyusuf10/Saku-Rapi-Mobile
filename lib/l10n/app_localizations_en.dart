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
  String get contactPickerTitle => 'Select Contact';

  @override
  String get contactPickerFromPhonebook => 'From Phonebook';

  @override
  String get contactPickerSaved => 'Saved Contacts';

  @override
  String get contactPickerSearch => 'Search contacts...';

  @override
  String get contactPickerEmpty => 'No saved contacts yet';

  @override
  String get contactPickerPhonePermissionDenied => 'Contacts permission denied';

  @override
  String get contactPickerNoPhone => 'No phone number';

  @override
  String get contactPickerSelected => 'Contact';

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
  String get transactionEditTitle => 'Edit Transaction';

  @override
  String get transactionSettleDebt => 'Settle Debt';

  @override
  String get transactionSettleLoan => 'Collect Loan';

  @override
  String get transactionSettleAmount => 'Settlement Amount';

  @override
  String get transactionSettleSuccess => 'Settlement saved successfully';

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
  String dashboardGreeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get dashboardEmptyWallets => 'No wallets yet';

  @override
  String get dashboardMonthlyIncome => 'This Month\'s Income';

  @override
  String get dashboardMonthlyExpense => 'This Month\'s Expense';

  @override
  String get dashboardChartTitle => 'Income vs Expense';

  @override
  String get dashboardThisMonth => 'This Month';

  @override
  String get dashboardLastMonth => 'Last Month';

  @override
  String get dashboardThisWeek => 'This Week';

  @override
  String get dashboardLastWeek => 'Last Week';

  @override
  String get dashboardMonthlyMode => 'Monthly';

  @override
  String get dashboardWeeklyMode => 'Weekly';

  @override
  String get dashboardQuickAdd => 'Quick Add';

  @override
  String get dashboardNetFlow => 'Net';

  @override
  String get dashboardNoChange => 'No change';

  @override
  String dashboardVsPrevious(String period) {
    return 'vs $period';
  }

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
  String get historyDaily => 'Daily';

  @override
  String get historyWeekly => 'Weekly';

  @override
  String get historyMonthly => 'Monthly';

  @override
  String get historyQuarterly => 'Quarterly';

  @override
  String get historyYearly => 'Yearly';

  @override
  String get historyCustomRange => 'Custom';

  @override
  String get historyGroupByDate => 'By Date';

  @override
  String get historyGroupByCategory => 'By Category';

  @override
  String get historyAllTypes => 'All Types';

  @override
  String get historySelectType => 'Transaction Type';

  @override
  String get historyPeriod => 'Period';

  @override
  String get historyLoadMore => 'Load more';

  @override
  String historyTransactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get historyFilterEmpty => 'No transactions matching this filter';

  @override
  String get historyDeleteSuccess => 'Transaction deleted successfully';

  @override
  String get historyDeleteConfirm => 'Delete Transaction';

  @override
  String get historyDeleteConfirmMessage =>
      'Are you sure you want to delete this transaction? Wallet balance will be reversed.';

  @override
  String get historySelectDateRange => 'Select Date Range';

  @override
  String get historyStartDate => 'Start Date';

  @override
  String get historyEndDate => 'End Date';

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
  String get budgetFilterAll => 'All Wallets';

  @override
  String get budgetCompletedTitle => 'Completed Budgets';

  @override
  String get budgetCompletedEmpty => 'No completed budgets yet';

  @override
  String get budgetCompleted => 'Completed';

  @override
  String get budgetDuplicateTitle => 'Budget Already Exists';

  @override
  String budgetDuplicateMessage(String category, String wallet) {
    return 'An active budget for \"$category\" in $wallet already exists. Replace with new one?';
  }

  @override
  String get budgetDuplicateReplace => 'Replace';

  @override
  String get budgetDuplicateKeep => 'Cancel';

  @override
  String get budgetTabWeekly => 'Weekly';

  @override
  String get budgetTabMonthly => 'Monthly';

  @override
  String get budgetTabQuarterly => 'Quarterly';

  @override
  String get budgetTabYearly => 'Yearly';

  @override
  String get budgetTabCustom => 'Custom';

  @override
  String get budgetDetailTitle => 'Budget Detail';

  @override
  String get budgetDetailSpent => 'Spent';

  @override
  String get budgetDetailRemaining => 'Remaining';

  @override
  String get budgetDetailPeriod => 'Period';

  @override
  String get budgetDetailDaysLeft => 'Days Left';

  @override
  String get budgetDetailWallet => 'Wallet';

  @override
  String get budgetDetailDailyRecommended => 'Daily Recommended';

  @override
  String get budgetDetailProjectedSpend => 'Projected Spend';

  @override
  String get budgetDetailActualDaily => 'Actual Daily';

  @override
  String get budgetDetailTransactions => 'Transactions';

  @override
  String get budgetDetailTransactionsEmpty => 'No transactions yet';

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
  String get investmentTotalUnits => 'Total Holdings';

  @override
  String get investmentGram => 'gram';

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
  String get profileThemeSystem => 'Follow System';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeTitle => 'App Theme';

  @override
  String get profileLanguageIndonesian => 'Indonesia';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLanguageTitle => 'Select Language';

  @override
  String get profileEntryPoint => 'Default Transaction Entry';

  @override
  String get profileEntryManual => 'Manual Form';

  @override
  String get profileEntryVoice => 'Voice Input';

  @override
  String get profileEntryScan => 'Scan Receipt';

  @override
  String get profileEntryPointTitle => 'Default Transaction Entry';

  @override
  String get profileExportImport => 'Export / Import';

  @override
  String get profileComingSoon => 'Coming Soon';

  @override
  String get profileAppVersion => 'App Version';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileSectionData => 'Data';

  @override
  String get profileSectionOther => 'Others';

  @override
  String get pickerChooseIcon => 'Choose Icon';

  @override
  String get pickerChooseColor => 'Choose Color';

  @override
  String get pickerSearchCategory => 'Search category...';

  @override
  String get voiceInitializing => 'Preparing microphone...';

  @override
  String get voiceAnalyzingAi => 'Analyzing with AI...';

  @override
  String get voiceDoneButton => 'Done';

  @override
  String get voicePleaseWait => 'Please wait...';

  @override
  String get voiceNoSpeech => 'No speech detected';

  @override
  String get voiceOpenSettings => 'Open Settings';

  @override
  String get voicePermissionExplainer =>
      'Microphone permission is required for voice input. Please enable it in settings.';

  @override
  String get voiceParseFailed =>
      'Analysis failed, data filled manually from voice';

  @override
  String get voiceAiBusy => 'AI is busy, using local parser';

  @override
  String get voiceTapToSpeak => 'Press & hold to speak';

  @override
  String get voiceTranscript => 'Heard text';

  @override
  String get ocrExtractingText => 'Reading text from receipt...';

  @override
  String get ocrAnalyzingAi => 'Analyzing with AI...';

  @override
  String get ocrPickerTitle => 'Scan Shopping Receipt';

  @override
  String get ocrCropToolbar => 'Select Receipt Area';

  @override
  String get ocrErrorGeneric => 'Failed to process image';

  @override
  String get ocrPermissionDenied => 'Camera permission denied';

  @override
  String get ocrPermissionExplainer =>
      'Camera permission is required for receipt scanning. Please enable it in settings.';

  @override
  String get ocrAiBusy => 'AI is busy, using local parser';

  @override
  String get ocrPartialResult => 'Partial data extracted';

  @override
  String ocrTotalMismatch(String itemsTotal, String receiptTotal) {
    return 'Items total ($itemsTotal) does not match receipt total ($receiptTotal)';
  }

  @override
  String get ocrDate => 'Date';

  @override
  String get ocrItemsSection => 'Item List';

  @override
  String get ocrProcessing => 'Processing...';

  @override
  String get ocrImageBlurry => 'Image is unreadable, try taking another photo';

  @override
  String get ocrUseResult => 'Use Result';

  @override
  String get transactionListTitle => 'Transactions';

  @override
  String get transactionRangeTitle => 'Select Time Range';

  @override
  String get transactionRangeHari => 'Today';

  @override
  String get transactionRangeMinggu => 'This Week';

  @override
  String get transactionRangeBulan => 'This Month';

  @override
  String get transactionRangeKuartal => 'This Quarter';

  @override
  String get transactionRangeTahun => 'This Year';

  @override
  String get transactionRangeSemua => 'All';

  @override
  String get transactionRangeSesuaikan => 'Custom';

  @override
  String get transactionViewByCategory => 'View by Category';

  @override
  String get transactionViewByTransaction => 'View by Transaction';

  @override
  String get transactionTransferMoney => 'Transfer Money';

  @override
  String get transactionDetailTitle => 'Transaction Detail';

  @override
  String get transactionDuplicate => 'Duplicate';

  @override
  String get transactionShareDetail => 'Share';

  @override
  String get transactionDeleteSuccess => 'Transaction deleted successfully';

  @override
  String get transactionItemQty => 'Quantity';

  @override
  String get transactionItemUnitPrice => 'Unit Price';

  @override
  String get transactionItemSubtotal => 'Subtotal';

  @override
  String get transactionItemName => 'Item Name';

  @override
  String get transactionItemNameHint => 'e.g. Coffee, Fried Rice';

  @override
  String get transactionTotalMismatch =>
      'Items total does not match transaction total';

  @override
  String get transactionReorderHint => 'Drag to reorder';

  @override
  String get transactionRemoveItem => 'Remove Item';

  @override
  String get transactionItemNote => 'Item note';

  @override
  String get dashboardExpenseReport => 'Expense Report';

  @override
  String get dashboardTrendReport => 'Trend Report';

  @override
  String get dashboardTotalExpenseLabel => 'Total expense';

  @override
  String get dashboardTotalIncomeLabel => 'Total income';

  @override
  String get dashboardThisMonthCumulative => 'This month';

  @override
  String get dashboardAvg3MonthLabel => 'Avg. last 3 months';

  @override
  String get dashboardPrevMonthLabel => 'Last month';

  @override
  String dashboardInsightExpenseDown(
    String period,
    String percent,
    String prevPeriod,
  ) {
    return 'Your spending this $period is $percent% lower than $prevPeriod. Great, keep it up!';
  }

  @override
  String dashboardInsightExpenseUp(
    String period,
    String percent,
    String prevPeriod,
  ) {
    return 'Your spending this $period is $percent% higher than $prevPeriod. Try to cut back on unnecessary spending.';
  }

  @override
  String dashboardInsightExpenseSame(String prevPeriod) {
    return 'Your spending is stable compared to $prevPeriod.';
  }

  @override
  String get dashboardInsightTrendBelowAvg =>
      'Your spending is below the 3-month average. You\'re on the right track!';

  @override
  String get dashboardInsightTrendAboveAvg =>
      'Your spending is above the 3-month average. Watch your expenses.';

  @override
  String get dashboardInsightNoData =>
      'Start recording transactions to see insights.';

  @override
  String get reportTitle => 'Reports';

  @override
  String get reportNet => 'Net Balance';

  @override
  String get reportIncome => 'Income';

  @override
  String get reportExpense => 'Expense';

  @override
  String get reportPeriodWeekly => 'Weekly';

  @override
  String get reportPeriodMonthly => 'Monthly';

  @override
  String get reportPeriodQuarterly => 'Quarterly';

  @override
  String get reportPeriodYearly => 'Yearly';

  @override
  String get reportAllWallets => 'All Wallets';

  @override
  String get reportCategoryBreakdown => 'Category Breakdown';

  @override
  String get reportDailyTrend => 'Daily Trend';

  @override
  String get reportNoCategory => 'No category data yet.';

  @override
  String get reportNoTrendData => 'No trend data yet.';

  @override
  String get reportEmptyTitle => 'No Data Yet';

  @override
  String get reportEmptyMessage =>
      'Start recording transactions to see your full report.';

  @override
  String get reportErrorGeneric => 'Failed to load report. Try again.';

  @override
  String reportInsightExpenseDown(String percent) {
    return 'Your spending decreased by $percent% compared to last period. Great job!';
  }

  @override
  String reportInsightExpenseUp(String percent) {
    return 'Your spending increased by $percent% compared to last period. Stay alert.';
  }

  @override
  String get reportInsightStable =>
      'Your spending is relatively stable compared to the previous period.';

  @override
  String get reportInsightNoData =>
      'Start recording transactions to see report insights.';

  @override
  String get reportSeeFullReport => 'See Full Report';

  @override
  String get thisQuarter => 'This Quarter';

  @override
  String get transactionDeleteConfirmTitle => 'Delete Transaction?';

  @override
  String get transactionDeleteConfirmMessage =>
      'This transaction will be permanently deleted and wallet balance will be adjusted.';

  @override
  String get transactionTransferToAsset => 'Transfer to Asset';

  @override
  String transactionItemCount(int count) {
    return '$count item';
  }

  @override
  String get reportOthersCategory => 'Others';

  @override
  String get ocrBalanceItem => 'Other items';

  @override
  String get ocrDiscountItem => 'Discount/deduction';

  @override
  String get validationAmountPositive => 'Amount must be greater than 0';

  @override
  String get validationTransferNeedsDest =>
      'Transfer requires a destination wallet';

  @override
  String get validationMinOneItem => 'Transaction must have at least 1 item';

  @override
  String validationItemsTotalMismatch(String itemsSum, String totalAmount) {
    return 'Items total ($itemsSum) doesn\'t match transaction total ($totalAmount)';
  }

  @override
  String get validationCategoryRequired =>
      'Category must be selected for each item';

  @override
  String get validationBudgetAmountPositive =>
      'Budget amount must be greater than 0';

  @override
  String get validationEndBeforeStart => 'End date cannot be before start date';

  @override
  String get validationBudgetDuplicate =>
      'An active budget already exists for the same category and period';

  @override
  String get validationDeleteOldBudgetFailed => 'Failed to delete old budget';

  @override
  String get validationWalletNameEmpty => 'Wallet name cannot be empty';

  @override
  String get validationInitialBalanceNegative =>
      'Initial balance cannot be negative';

  @override
  String get validationWalletNameDuplicate => 'Wallet name already in use';

  @override
  String get validationWalletHasTransactions =>
      'Cannot delete wallet with existing transactions. Delete transactions first.';

  @override
  String get investmentFormSymbol => 'Symbol';

  @override
  String get investmentFormSymbolHint => 'TSLA, AAPL, etc.';

  @override
  String get assetTypeTitle => 'Manage Asset Types';

  @override
  String get assetTypeAdd => 'Add Asset Type';

  @override
  String get assetTypeEdit => 'Edit Asset Type';

  @override
  String get assetTypeEmpty => 'No asset types yet';

  @override
  String get assetTypeEmptyHint => 'Tap + to create your first asset type';

  @override
  String get assetTypeFormName => 'Asset Name';

  @override
  String get assetTypeFormNameHint => 'e.g., BCA Stock, Land, Bonds';

  @override
  String get assetTypeFormSymbol => 'Symbol';

  @override
  String get assetTypeFormSymbolHint => 'e.g., BBCA, OBL';

  @override
  String get assetTypeFormCurrentPrice => 'Current Price (IDR)';

  @override
  String get assetTypeFormCurrentPriceHint => 'Price per unit right now';

  @override
  String get assetTypeSave => 'Save Asset Type';

  @override
  String get assetTypeSuccessAdd => 'Asset type added successfully';

  @override
  String get assetTypeSuccessEdit => 'Asset type updated successfully';

  @override
  String get assetTypeSuccessDelete => 'Asset type deleted successfully';

  @override
  String get assetTypeErrorAdd => 'Failed to add asset type';

  @override
  String get assetTypeErrorEdit => 'Failed to update asset type';

  @override
  String get assetTypeErrorDelete => 'Failed to delete asset type';

  @override
  String get assetTypeDeleteConfirmTitle => 'Delete Asset Type?';

  @override
  String assetTypeDeleteConfirmMessage(String name) {
    return '\"$name\" and all investments using this asset type will be hidden.';
  }

  @override
  String assetTypeErrorDuplicateName(String name) {
    return 'Asset type name \"$name\" already exists';
  }

  @override
  String get investmentFormAssetType => 'Asset Type';

  @override
  String get investmentFormAssetTypeHint => 'Select asset type';

  @override
  String get investmentFormAssetTypeEmpty =>
      'No asset types available. Create one first.';

  @override
  String get investmentManageAssetTypes => 'Manage Asset Types';

  @override
  String get investmentFormCreateAssetType => 'Create New Asset Type';

  @override
  String get investmentFilterTitle => 'Filter & Sort';

  @override
  String get investmentFilterSort => 'Sort By';

  @override
  String get investmentFilterSortNewest => 'Newest';

  @override
  String get investmentFilterSortOldest => 'Oldest';

  @override
  String get investmentFilterSortHighest => 'Highest Value';

  @override
  String get investmentFilterSortLowest => 'Lowest Value';

  @override
  String get investmentFilterType => 'Type';

  @override
  String get investmentFilterAll => 'All';

  @override
  String get investmentFilterSearch => 'Search by name...';

  @override
  String get investmentFilterApply => 'Apply Filter';

  @override
  String get investmentFilterReset => 'Reset';

  @override
  String get debtLoanTitle => 'Debt & Loan';

  @override
  String get debtLoanTabToPay => 'To Pay';

  @override
  String get debtLoanTabToReceive => 'To Receive';

  @override
  String get debtLoanUnpaid => 'UNPAID';

  @override
  String get debtLoanPaid => 'PAID';

  @override
  String get debtLoanAllWallets => 'All Wallets';

  @override
  String debtLoanTransactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get debtLoanRemaining => 'remaining';

  @override
  String get debtLoanSettled => 'settled';

  @override
  String get debtLoanPersonTitle => 'Transaction List';

  @override
  String debtLoanPersonResult(int count) {
    return '$count results';
  }

  @override
  String get debtLoanPersonIncome => 'Income';

  @override
  String get debtLoanPersonExpense => 'Expense';

  @override
  String get debtLoanSettlementTitle => 'Settlement';

  @override
  String get debtLoanSettlementAmount => 'Settlement Amount';

  @override
  String get debtLoanSettlementWallet => 'Payment Wallet';

  @override
  String get debtLoanSettlementNote => 'Note (optional)';

  @override
  String get debtLoanSettlementSubmit => 'Submit Settlement';

  @override
  String get debtLoanSettlementSuccess => 'Settlement saved successfully';

  @override
  String debtLoanSettlementRemainder(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get debtLoanPayDebt => 'Pay Debt';

  @override
  String get debtLoanCollectLoan => 'Receive Payment';

  @override
  String get debtLoanSettlementHistory => 'TRANSACTION LIST';

  @override
  String get debtLoanLender => 'Lender';

  @override
  String get debtLoanBorrower => 'Borrower';

  @override
  String get debtLoanStatusPaid => 'Paid';

  @override
  String get debtLoanStatusRemaining => 'Remaining';

  @override
  String debtLoanDebtPaymentDesc(String person) {
    return 'Debt paid to $person';
  }

  @override
  String debtLoanLoanCollectionDesc(String person) {
    return 'Loan received from $person';
  }

  @override
  String get debtLoanRepayment => 'Repayment';

  @override
  String get debtLoanCollection => 'Collection';

  @override
  String get debtLoanEmpty => 'No debt or loan records';

  @override
  String get debtLoanEmptyPerson => 'No transactions found';

  @override
  String get debtLoanSomeone => 'Someone';

  @override
  String get debtLoanExcludedFromReport =>
      'This transaction is excluded from reports';

  @override
  String get debtLoanSettlementHistoryTitle => 'Settlement History';

  @override
  String debtLoanTitleDebt(String person) {
    return 'Debt to $person';
  }

  @override
  String debtLoanTitleLoan(String person) {
    return 'Loan to $person';
  }

  @override
  String debtLoanTitlePayment(String person) {
    return 'Payment to $person';
  }

  @override
  String debtLoanTitleReceipt(String person) {
    return 'Receipt from $person';
  }

  @override
  String get profileDebtLoan => 'Debt & Loan';

  @override
  String get debtLoanFormSubCategory => 'Category';

  @override
  String get debtLoanFormPickTransaction => 'Pick Transaction';

  @override
  String get debtLoanFormNoUnpaidDebt => 'No outstanding debts found';

  @override
  String get debtLoanFormNoUnpaidLoan => 'No outstanding loans found';

  @override
  String debtLoanFormAmountExceedsRemaining(String amount) {
    return 'Amount exceeds remaining $amount';
  }

  @override
  String get debtLoanFormTabLabel => 'Debt/Loan';

  @override
  String get debtLoanFormSelectedTransaction => 'Selected Transaction';

  @override
  String debtLoanFormRemainingAmount(String amount) {
    return 'Remaining: $amount';
  }
}
