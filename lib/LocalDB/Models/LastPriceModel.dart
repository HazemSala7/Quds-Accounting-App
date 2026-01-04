class LastPrice {
  final int id;
  final String companyId;
  final String productId;
  final String customerId;
  final double price;

  LastPrice({
    required this.id,
    required this.companyId,
    required this.productId,
    required this.customerId,
    required this.price,
  });

  factory LastPrice.fromJson(Map<String, dynamic> json) {
    return LastPrice(
      id: int.tryParse(json['id'].toString()) ?? 0,
      companyId: json['company_id'].toString() ?? "0",
      productId: json['product_id'].toString() ?? "0",
      customerId: json['customer_id'].toString() ?? "0",
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'product_id': productId,
      'customer_id': customerId,
      'price': price,
    };
  }
}
