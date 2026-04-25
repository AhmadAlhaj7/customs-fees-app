class Product {
  int? id;
  String itemNumber;
  String itemName;
  String description;
  double importFee;
  double serviceFee;
  double totalFee;
  String commercialName;
  String? imagePath;

  Product({
    this.id,
    required this.itemNumber,
    required this.itemName,
    required this.description,
    required this.importFee,
    required this.serviceFee,
    required this.totalFee,
    required this.commercialName,
    this.imagePath,
  });

  // Convert a Product into a Map (for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemNumber': itemNumber,
      'itemName': itemName,
      'description': description,
      'importFee': importFee,
      'serviceFee': serviceFee,
      'totalFee': totalFee,
      'commercialName': commercialName,
      'imagePath': imagePath,
    };
  }

  // Convert a Map into a Product (for reading from database)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      itemNumber: map['itemNumber'],
      itemName: map['itemName'],
      description: map['description'],
      importFee: map['importFee'],
      serviceFee: map['serviceFee'],
      totalFee: map['totalFee'],
      commercialName: map['commercialName'],
      imagePath: map['imagePath'],
    );
  }
}