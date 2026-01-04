import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';

class CatchVansaleModel {
  int? id;
  String customerID;
  String customerName;
  double cashAmount;
  double discount;
  double totalChecks;
  double finalTotal;
  String notes;
  String qType;
  String date;
  String time;
  int isUploaded;
  List<CheckVansaleModel> checks;

  CatchVansaleModel({
    this.id,
    required this.customerID,
    required this.customerName,
    required this.cashAmount,
    required this.qType,
    required this.discount,
    required this.totalChecks,
    required this.finalTotal,
    required this.notes,
    required this.date,
    required this.time,
    required this.isUploaded,
    this.checks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerID': customerID,
      'customerName': customerName,
      'cashAmount': cashAmount,
      'discount': discount,
      'totalChecks': totalChecks,
      'qType': qType,
      'finalTotal': finalTotal,
      'notes': notes,
      'date': date,
      'time': time,
      'isUploaded': isUploaded,
    };
  }

  factory CatchVansaleModel.fromDatabaseJson(Map<String, dynamic> json) {
    return CatchVansaleModel(
      id: json['id'],
      customerID: json['customer_id']?.toString() ?? '',
      customerName: json['customer'] is Map
          ? json['customer']['c_name']?.toString() ?? '-'
          : json['customer']?.toString() ?? '-',
      cashAmount: _convertToDouble(json['cash']),
      discount: _convertToDouble(json['discount']),
      totalChecks: _convertToDouble(json['chks']),
      finalTotal: _calculateFinalTotal(json),
      notes: json['notes']?.toString() ?? '',
      qType: json['q_type']?.toString() ?? '',
      date: json['q_date']?.toString() ?? '',
      time: json['q_time']?.toString() ?? '',
      isUploaded: 1,
    );
  }

// Helper function to convert String/Int to Double safely
  static double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0; // Try parsing string to double
    }
    return 0.0; // Default fallback
  }

  static double _calculateFinalTotal(Map<String, dynamic> json) {
    final cash = _convertToDouble(json['cash']);
    final chks = _convertToDouble(json['chks']);
    return cash + chks; // or whatever your finalTotal logic is
  }
}
