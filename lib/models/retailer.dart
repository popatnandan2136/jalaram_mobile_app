class Retailer {
  final String? id;
  final String name;
  final String mobile;
  final DateTime createdAt;
  final String type; // 'retailer' or 'customer'

  Retailer({
    this.id,
    required this.name,
    required this.mobile,
    required this.createdAt,
    this.type = 'retailer',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory Retailer.fromMap(Map<String, dynamic> map) {
    return Retailer(
      id: map['id'] as String?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      type: (map['type'] as String?) ?? 'retailer',
    );
  }
}
