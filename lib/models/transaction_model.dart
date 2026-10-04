/// Model cho 1 giao dịch (thu hoặc chi).
class TransactionModel {
  final int? id;
  final int categoryId;
  final int amount; // số tiền, luôn lưu dạng số dương
  final String type; // 'expense' hoặc 'income'
  final DateTime date;
  final String note;

  TransactionModel({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      amount: map['amount'] as int,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}
