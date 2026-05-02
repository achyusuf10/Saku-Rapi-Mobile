import 'package:app_saku_rapi/core/enums/transaction_type_enum.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/datasource/transaction_remote_data_source.dart';
import 'package:app_saku_rapi/features/transaction/models/manual_transaction_entry_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/repositories/transaction_repository.dart';
import 'package:app_saku_rapi/features/transaction/utils/manual_multi_batch_limits.dart';
import 'package:app_saku_rapi/features/wallet/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements TransactionRemoteDataSource {}

void main() {
  group('TransactionRepository.createTransactionsBatch', () {
    const _wallet = WalletModel(
      id: 'w1',
      userId: 'u1',
      name: 'A',
      icon: 'i',
      color: '#000',
      backgroundColor: WalletModel.defaultBackgroundColorHex,
      balance: 0,
      initialBalance: 0,
      currency: 'IDR',
      excludeFromTotal: false,
      sortOrder: 0,
    );

    const _category = CategoryModel(
      id: 'c1',
      userId: 'u1',
      name: 'Food',
      icon: 'f',
      color: '#111',
      type: CategoryType.expense,
    );

    ManualTransactionEntryModel _entry(int key) {
      return ManualTransactionEntryModel(
        entryKey: key,
        wallet: _wallet,
        category: _category,
        items: const [
          TransactionItemModel(amount: 1000, categoryId: 'c1'),
        ],
        itemKeys: const [0],
        totalAmount: 1000,
      );
    }

    test('returns error when entries exceed max (no remote call)', () async {
      final remote = _MockRemote();
      final repo = TransactionRepository(remoteDataSource: remote);
      final entries = List.generate(
        kManualMultiBatchMaxTransactions + 1,
        _entry,
      );

      final result = await repo.createTransactionsBatch(
        type: TransactionTypeEnum.expense,
        entries: entries,
      );

      expect(result.isError(), isTrue);
      verifyNever(() => remote.createTransactionsBatch(any()));
    });
  });
}
