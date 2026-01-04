class ProductVansale {
  String? id; // If you need an ID for local storage
  String pName;
  int companyID;
  String images;
  String description;
  int salesmanID;
  String productBarcode;
  String quantity;
  String productPaidQty;
  String productUnit;

  ProductVansale({
    this.id,
    required this.pName,
    required this.salesmanID,
    required this.companyID,
    required this.images,
    required this.description,
    required this.productBarcode,
    required this.quantity,
    required this.productPaidQty,
    required this.productUnit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'p_name': pName.toString(),
      'productUnit': productUnit.toString(),
      'salesman_id': salesmanID,
      'company_id': companyID,
      'images': images.toString(),
      'description': description.toString(),
      'product_barcode': productBarcode.toString(),
      'quantity': quantity,
      'productPaidQty': productPaidQty,
    };
  }

  factory ProductVansale.fromJson(Map<String, dynamic> json) {
    return ProductVansale(
      id: json['product_id'] ?? "",
      pName: json['p_name'] ?? "",
      companyID: int.parse(json['company_id'].toString()),
      salesmanID: int.parse(json['salesman_id'].toString()),
      images: json['images'] ?? "",
      description: json['description'] ?? "",
      productBarcode: json['product_barcode'] ?? "",
      quantity: json['quantity'].toString(),
      productPaidQty: json['sold_quantity'].toString(),
      productUnit: json['unit'].toString(),
    );
  }
}
