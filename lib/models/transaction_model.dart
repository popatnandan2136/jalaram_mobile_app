class TransactionModel {
  final String? id;
  final String retailerId;
  final String type; // 'debit' (sent / fund transfer) or 'credit' (received money)
  final double amount;
  final String? app; // 'VDPAYS', 'Master Pay', or null
  final DateTime timestamp;
  final String? notes;

  TransactionModel({
    this.id,
    required this.retailerId,
    required this.type,
    required this.amount,
    this.app,
    required this.timestamp,
    this.notes,
  });

  bool get isDebit => type == 'debit';
  bool get isCredit => type == 'credit';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'retailerId': retailerId,
      'type': type,
      'amount': amount,
      'app': app,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      retailerId: (map['retailerId'] ?? map['retailer_id']) as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      app: map['app'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: map['notes'] as String?,
    );
  }
}
