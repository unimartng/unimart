class University {
  final int id;
  final String name;
  final String? code;
  final DateTime createdAt;

  University({
    required this.id,
    required this.name,
    this.code,
    required this.createdAt,
  });

  factory University.fromMap(Map<String, dynamic> map) {
    return University(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      code: map['code'],
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
