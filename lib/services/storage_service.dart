import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/transaction.dart';

class StorageService {
  static const _fileName = 'transactions.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Transaction>> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Transaction> transactions) async {
    final file = await _file;
    await file.writeAsString(
      json.encode(transactions.map((t) => t.toJson()).toList()),
    );
  }
}
