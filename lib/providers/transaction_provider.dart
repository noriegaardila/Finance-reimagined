import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  final _storage = StorageService();

  List<Transaction> _transactions = [];
  bool _loaded = false;

  List<Transaction> get transactions {
    final list = List<Transaction>.from(_transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  bool get loaded => _loaded;

  // ── Stats ────────────────────────────────────────────────────────────────

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.debit &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalReceivedThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.credit &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netThisMonth => totalReceivedThisMonth - totalSpentThisMonth;

  List<Transaction> get recentTransactions => transactions.take(5).toList();

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => t.type == TransactionType.debit)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    _transactions = await _storage.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(Transaction transaction) async {
    _transactions.insert(0, transaction);
    notifyListeners();
    await _storage.save(_transactions);
  }

  Future<void> update(Transaction transaction) async {
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    if (idx == -1) return;
    _transactions[idx] = transaction;
    notifyListeners();
    await _storage.save(_transactions);
  }

  Future<void> delete(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _storage.save(_transactions);
  }
}
