import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/controllers/transaction_form_controller.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:app_saku_rapi/core/themes/app_themes.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_item_row.dart';
import 'package:app_saku_rapi/features/transaction/view/widgets/transaction_multi_item_section.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:app_saku_rapi/global/widgets/calculator_keyboard/calculator_keyboard.dart';
import 'package:app_saku_rapi/l10n/app_localizations.dart';
import 'package:customized_keyboard/customized_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TransactionRepository {}

class _SeededTransactionFormController extends TransactionFormController {
  _SeededTransactionFormController({
    required TransactionRepository repository,
    required TransactionFormState seed,
  }) : super(repository: repository) {
    state = seed;
  }
}

Widget _pumpHarness({
  required Widget body,
  required TransactionFormState seed,
  TransactionRepository? repo,
}) {
  const surface = Size(1200, 900);
  const designSize = Size(412, 917);
  final r = repo ?? _MockRepo();
  return MediaQuery(
    data: const MediaQueryData(size: surface),
    child: ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(r),
        transactionFormControllerProvider.overrideWith(
          (ref) => _SeededTransactionFormController(repository: r, seed: seed),
        ),
      ],
      child: Builder(
        builder: (context) {
          return ScreenUtilInit(
            designSize: designSize,
            useInheritedMediaQuery: true,
            builder: (_, __) {
              return MaterialApp(
                theme: AppThemes.lightTheme(context),
                builder: (context, child) {
                  return KeyboardWrapper(
                    keyboards: [SakuCalculatorKeyboard()],
                    child: child ?? const SizedBox(),
                  );
                },
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('id'),
                home: Scaffold(
                  body: SingleChildScrollView(child: body),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets(
    'manual multi entry single item: hanya chip tambah item (bukan TransactionItemRow)',
    (tester) async {
      const surface = Size(1200, 900);
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _MockRepo();
      final entry = ManualTransactionEntryModel(
        entryKey: 42,
        wallet: const WalletModel(
          id: 'w1',
          userId: 'u1',
          name: 'Dompet',
          icon: 'wallet',
          color: '#111',
          balance: 0,
          initialBalance: 0,
          currency: 'IDR',
          excludeFromTotal: false,
          sortOrder: 0,
        ),
        category: const CategoryModel(
          id: 'c1',
          userId: 'u1',
          name: 'Makan',
          icon: 'utensils',
          color: '#222',
          type: CategoryType.expense,
        ),
        items: const [TransactionItemModel(amount: 0, categoryId: 'c1')],
        itemKeys: const [99],
        totalAmount: 0,
        date: DateTime(2025, 6, 1),
      );

      await tester.pumpWidget(
        _pumpHarness(
          seed: TransactionFormState(
            type: TransactionTypeEnum.expense,
            isMultiManualMode: true,
            manualMultiEntries: [entry],
            date: DateTime(2025, 6, 1),
          ),
          repo: repo,
          body: const TransactionMultiItemSection(
            manualMultiEntryIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(TransactionMultiItemSection)),
      )!;
      expect(find.text(l10n.transactionAddItem), findsOneWidget);
      expect(find.byType(TransactionItemRow), findsNothing);
    },
  );
}
