import 'dart:async';
import 'dart:convert';

import 'package:app_saku_rapi/utils/packages/graphify/controller/js_methods.dart';
import 'package:app_saku_rapi/utils/packages/graphify/utils/uid.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Model sederhana untuk fungsi JavaScript
class JsFunctionModel {
  final String function;

  const JsFunctionModel(this.function);

  @override
  String toString() => function;
}

class GraphifyController {
  late final WebViewController _connector;

  /// Creates a new instance of [GraphifyController] with a unique identifier.
  GraphifyController() : uid = UID.generate();

  /// Unique identifier for the chart instance.
  final String uid;
  set connector(WebViewController connector) => _connector = connector;

  String get _quotedUid => '"$uid"';

  Future<void> update(Map<String, dynamic>? options) async {
    if (options == null) {
      return _eval(JsMethods.updateChart, [_quotedUid, '{}']);
    }

    // Proses options untuk menangani JsFunction
    final processedJson = _convertOptionsToJs(options);
    return _eval(JsMethods.updateChart, [_quotedUid, processedJson]);
    // return _eval(
    //   JsMethods.updateChart,
    //   [_quotedUid, jsonEncode(options ?? {})],
    // );
  }

  Future<void> dispose() async => _eval(JsMethods.disposeChart, [_quotedUid]);

  Future<void> _eval(String method, List<String> args) async {
    final res = _buildJsMethod(method, args);
    return _connector.runJavaScript(res);
  }

  // Fungsi untuk mengonversi options ke JavaScript
  String _convertOptionsToJs(Map<String, dynamic> options) {
    // Encode ke JSON terlebih dahulu
    final String jsonString = jsonEncode(options, toEncodable: _customEncode);

    // Cari placeholder JsFunction dan ganti dengan fungsi asli
    final RegExp placeholderPattern = RegExp(r'"__js_function__(\d+)__"');

    return jsonString.replaceAllMapped(placeholderPattern, (match) {
      final int index = int.parse(match.group(1)!);
      return _jsFunctions[index];
    });
  }

  // Daftar untuk menyimpan fungsi JavaScript
  final List<String> _jsFunctions = [];

  // Fungsi untuk encoding kustom yang menangani JsFunction
  dynamic _customEncode(dynamic item) {
    if (item is JsFunctionModel) {
      // Simpan fungsi JavaScript dan buat placeholder
      final int index = _jsFunctions.length;
      _jsFunctions.add(item.function);
      return '__js_function__${index}__';
    }
    return item;
  }

  String _buildJsMethod(String method, List<String> args) {
    return 'window.$method(${args.map((String arg) => arg).join(', ')})';
  }
}
