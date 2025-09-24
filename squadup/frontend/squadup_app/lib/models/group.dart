class Group {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy}';
  }
}
