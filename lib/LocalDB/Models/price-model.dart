class Price {
  int? id; // If you need an ID for local storage
  String productId;
  String priceCode;
  String price;
  int companyId;

  Price({
    this.id,
    required this.productId,
    required this.priceCode,
    required this.price,
    required this.companyId,
  });

  // Convert a Price object into a Map object for storing in the database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'price_code': priceCode,
      'price': price,
      'company_id': companyId,
    };
  }

  // Create a Price object from a Map object
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: json['id'],
      productId: json['product_id'],
      priceCode: json['price_code'],
      price: json['price'],
      companyId: json['company_id'],
    );
  }
}
