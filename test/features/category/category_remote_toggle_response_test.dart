import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Memastikan parsing hasil [toggle_category_hidden] (List satu baris vs Map) konsisten
/// tanpa panggil Supabase.
void main() {
  final sampleRow = <String, dynamic>{
    'id': 'a0ee0000-0000-0000-0000-000000000001',
    'user_id': null,
    'name': 'Global',
    'icon': 'icon',
    'color': '#111',
    'type': 'expense',
    'parent_id': null,
    'is_default': true,
    'is_hidden': true,
    'sort_order': 0,
    'created_at': '2025-01-01T00:00:00.000Z',
    'updated_at': '2025-01-01T00:00:00.000Z',
  };

  test('mengekstrak baris dari respon List (PostgREST SETOF satu baris)', () {
    final res = <dynamic>[sampleRow];
    final Object row;
    if (res is List && res.isNotEmpty) {
      row = res.first;
    } else if (res is Map) {
      row = res;
    } else {
      throw Exception('unexpected');
    }
    final category = CategoryModel.fromMap(
      Map<String, dynamic>.from(row as Map),
    );
    expect(category.id, sampleRow['id']);
    expect(category.userId, isNull);
    expect(category.isHidden, isTrue);
  });

  test('mengekstrak baris dari respon Map tunggal (cabang elses)', () {
    final res = Map<String, dynamic>.from(sampleRow);
    final Object row;
    if (res is List && res.isNotEmpty) {
      row = (res as List<dynamic>).first;
    } else if (res is Map) {
      row = res;
    } else {
      throw Exception('toggle_category_hidden: respon tak terduga: $res');
    }
    final category = CategoryModel.fromMap(
      Map<String, dynamic>.from(row as Map),
    );
    expect(category.isHidden, isTrue);
  });
}
