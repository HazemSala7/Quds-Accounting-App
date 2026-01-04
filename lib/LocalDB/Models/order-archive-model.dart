class OrderArchiveModel {
  int? id;
  String customerId;
  String user_id;
  String storeId;
  double totalAmount;
  double discount;
  double cashPaid;
  String orderDate;
  String orderTime;
  String deliveryDate;
  String status;

  OrderArchiveModel({
    this.id,
    required this.customerId,
    required this.user_id,
    required this.storeId,
    required this.totalAmount,
    required this.discount,
    required this.cashPaid,
    required this.orderDate,
    required this.orderTime,
    required this.deliveryDate,
    this.status = "pending",
  });

  // Convert OrderModel to JSON (for API & SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': user_id,
      'store_id': storeId,
      'total_amount': totalAmount,
      'discount': discount,
      'cash_paid': cashPaid,
      'order_date': orderDate,
      'order_time': orderTime,
      'deliveryDate': deliveryDate,
      'status': status,
    };
  }

  // Convert JSON to OrderModel (for fetching data)
  factory OrderArchiveModel.fromJson(Map<String, dynamic> json) {
    return OrderArchiveModel(
      id: json['id'],
      customerId: json['customer_id'],
      user_id: json['user_id'],
      storeId: json['store_id'],
      totalAmount: json['total_amount'],
      discount: json['discount'],
      cashPaid: json['cash_paid'],
      orderDate: json['order_date'],
      orderTime: json['order_time'],
      deliveryDate: json['deliveryDate'],
      status: json['status'] ?? "pending",
    );
  }
}
