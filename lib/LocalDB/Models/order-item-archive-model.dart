class OrderItemArchiveModel {
  int? id;
  int orderId;
  String productId;
  String productName;
  String bonus1;
  String bonus2;
  double quantity;
  double price;
  double discount;
  double total;
  String color;
  String barcode;

  OrderItemArchiveModel({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.bonus1,
    required this.bonus2,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
    required this.color,
    required this.barcode,
  });

  // Convert OrderItemArchiveModel to JSON (for API & SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'bonus1': bonus1,
      'bonus2': bonus2,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
      'color': color,
      'barcode': barcode,
    };
  }

  // Convert JSON to OrderItemArchiveModel (for fetching data)
  factory OrderItemArchiveModel.fromJson(Map<String, dynamic> json) {
    return OrderItemArchiveModel(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      bonus1: json['bonus1'],
      bonus2: json['bonus2'],
      quantity: json['quantity'],
      price: json['price'],
      discount: json['discount'],
      total: json['total'],
      color: json['color'],
      barcode: json['barcode'],
    );
  }
}
