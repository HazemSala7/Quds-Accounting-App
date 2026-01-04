class ProductQuds {
  String? id; // If you need an ID for local storage
  String pName;
  String companyId;
  String images;
  String description;
  String categoryId;
  String productBarcode;
  String quantity;
  String productUnit;

  ProductQuds({
    this.id,
    required this.pName,
    required this.productUnit,
    required this.companyId,
    required this.images,
    required this.description,
    required this.categoryId,
    required this.productBarcode,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'p_name': pName.toString(),
      'productUnit': productUnit.toString(),
      'company_id': companyId.toString(),
      'images': images.toString(),
      'description': description.toString(),
      'category_id': categoryId.toString(),
      'product_barcode': productBarcode.toString(),
      'quantity': quantity.toString(),
    };
  }

  factory ProductQuds.fromJson(Map<String, dynamic> json) {
    return ProductQuds(
      id: json['id'] ?? "",
      pName: json['p_name'] ?? "",
      companyId: json['company_id'] ?? "",
      productUnit: json['unit'] ?? "",
      images: json['images'] ?? "",
      description: json['description'] ?? "",
      categoryId: json['category_id'] ?? "0",
      productBarcode: json['product_barcode'] ?? "",
      quantity: json['quantity'] ?? "",
    );
  }
}
