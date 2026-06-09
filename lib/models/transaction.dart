import 'package:uuid/uuid.dart';

enum TransactionType { debit, credit }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String merchant;
  final DateTime date;
  final String accountLast4;
  final String bankName;
  final String rawText;
  final String category;
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.amount,
    required this.type,
    required this.merchant,
    required this.date,
    this.accountLast4 = '',
    this.bankName = '',
    required this.rawText,
    this.category = 'Other',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    double? amount,
    TransactionType? type,
    String? merchant,
    DateTime? date,
    String? accountLast4,
    String? bankName,
    String? category,
  }) =>
      Transaction(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        merchant: merchant ?? this.merchant,
        date: date ?? this.date,
        accountLast4: accountLast4 ?? this.accountLast4,
        bankName: bankName ?? this.bankName,
        rawText: rawText,
        category: category ?? this.category,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'merchant': merchant,
        'date': date.toIso8601String(),
        'accountLast4': accountLast4,
        'bankName': bankName,
        'rawText': rawText,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TransactionType.debit,
        ),
        merchant: json['merchant'] as String,
        date: DateTime.parse(json['date'] as String),
        accountLast4: json['accountLast4'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        rawText: json['rawText'] as String,
        category: json['category'] as String? ?? 'Other',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
