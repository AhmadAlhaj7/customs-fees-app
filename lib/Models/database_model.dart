class DatabaseModel {
  int? id;
  String name;
  String fileName;
  DateTime createdAt;
  int itemCount;

  DatabaseModel({
    this.id,
    required this.name,
    required this.fileName,
    required this.createdAt,
    this.itemCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'itemCount': itemCount,
    };
  }

  factory DatabaseModel.fromMap(Map<String, dynamic> map) {
    return DatabaseModel(
      id: map['id'],
      name: map['name'],
      fileName: map['fileName'],
      createdAt: DateTime.parse(map['createdAt']),
      itemCount: map['itemCount'] ?? 0,
    );
  }
}