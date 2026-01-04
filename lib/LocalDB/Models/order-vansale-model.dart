class OrderVansaleModel {
  int? id;
  String customerId;
  String fatora_number;
  String user_id;
  String customerName;
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
  String cash;
  String printed;
  String isUploaded;

  OrderVansaleModel({
    this.id,
    required this.customerId,
    required this.fatora_number,
    required this.user_id,
    required this.customerName,
    required this.latitude,
    required this.longitude,
    required this.storeId,
    required this.totalAmount,
    required this.discount,
    required this.cashPaid,
    required this.orderDate,
    required this.orderTime,
    required this.deliveryDate,
    required this.cash,
    required this.printed,
    required this.isUploaded,
    this.status = "pending",
  });

  // Convert OrderVansaleModel to JSON (for API & SQLite)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'fatora_number': fatora_number,
      'user_id': user_id,
      'customerName': customerName,
      'store_id': storeId,
      'latitude': latitude,
      'longitude': longitude,
      'total_amount': totalAmount,
      'discount': discount,
      'cash_paid': cashPaid,
      'order_date': orderDate,
      'order_time': orderTime,
      'deliveryDate': deliveryDate,
      'isUploaded': isUploaded,
      'cash': cash,
      'status': status,
      'printed': printed,
    };
  }

  // Convert JSON to OrderVansaleModel (for fetching data)
  factory OrderVansaleModel.fromJson(Map<String, dynamic> json) {
    return OrderVansaleModel(
      id: json['id'],
      customerId: json['customer_id'],
      fatora_number: json['fatora_number'],
      user_id: json['user_id'],
      customerName: json['customerName'],
      storeId: json['store_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      totalAmount: json['total_amount'],
      discount: json['discount'],
      cashPaid: json['cash_paid'],
      orderDate: json['order_date'],
      orderTime: json['order_time'],
      deliveryDate: json['deliveryDate'],
      cash: json['cash'],
      printed: json['printed'],
      isUploaded: json['isUploaded'],
      status: json['status'] ?? "pending",
    );
  }
}
