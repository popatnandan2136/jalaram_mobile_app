class ShopBalance {
  final String? id;
  final double amount;
  final DateTime timestamp;
  final String app; // 'VDPAYS', 'Master Pay', 'Leo Recharge', 'Cash/Other'
  final String? description;

  ShopBalance({
    this.id,
    required this.amount,
    required this.timestamp,
    this.app = 'Cash/Other',
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'app': app,
      'description': description,
    };
  }

  factory ShopBalance.fromMap(Map<String, dynamic> map) {
    return ShopBalance(
      id: map['id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      app: (map['app'] as String?) ?? 'Cash/Other',
      description: map['description'] as String?,
    );
  }
}
