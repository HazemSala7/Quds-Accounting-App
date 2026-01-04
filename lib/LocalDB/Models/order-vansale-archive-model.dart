class OrderVansaleArchiveModel {
  int? id;
  String customerId;
  String fatora_number;
  String user_id;
  String storeId;
  String latitude;
  String longitude;
  double totalAmount;
  double discount;
  double cashPaid;
  String orderDate;
  String orderTime;
  String deliveryDate;
  String status;

  OrderVansaleArchiveModel({
    this.id,
    required this.customerId,
    required this.fatora_number,
    required this.user_id,
    required this.latitude,
    required this.longitude,
    required this.storeId,
    required this.totalAmount,
    required this.discount,
    required this.cashPaid,
    required this.orderDate,
    required this.orderTime,
    required this.deliveryDate,
    this.status = "pending",
  });

  // Convert OrderVansaleArchiveModel to JSON (for API & SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'fatora_number': fatora_number,
      'user_id': user_id,
      'store_id': storeId,
      'latitude': latitude,
      'longitude': longitude,
      'total_amount': totalAmount,
      'discount': discount,
      'cash_paid': cashPaid,
      'order_date': orderDate,
      'order_time': orderTime,
      'deliveryDate': deliveryDate,
      'status': status,
    };
  }

  // Convert JSON to OrderVansaleArchiveModel (for fetching data)
  factory OrderVansaleArchiveModel.fromJson(Map<String, dynamic> json) {
    return OrderVansaleArchiveModel(
      id: json['id'],
      customerId: json['customer_id'],
      fatora_number: json['fatora_number'],
      user_id: json['user_id'],
      storeId: json['store_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
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
