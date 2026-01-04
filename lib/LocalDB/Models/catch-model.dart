import 'package:quds_yaghmour/LocalDB/Models/check-model.dart';

class CatchModel {
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
  int downloaded;
  int isUploaded;
  List<CheckModel> checks;

  CatchModel({
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
    required this.downloaded,
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
      'downloaded': downloaded,
    };
  }

  /// ✅ **Existing `fromJson()` Method for API Data**
  factory CatchModel.fromJson(Map<String, dynamic> json) {
    double cash = _convertToDouble(json['cash']);
    double checks = _convertToDouble(json['chks']);
    double discount = _convertToDouble(json['discount']);

    String customerName = '-';
    if (json["customer"] is Map<String, dynamic>) {
      customerName = json["customer"]?['c_name']?.toString() ?? '-';
    }

    return CatchModel(
      id: json['id'],
      customerID: json['customer_id']?.toString() ?? '',
      customerName: customerName,
      cashAmount: cash,
      discount: discount,
      totalChecks: checks,
      finalTotal: cash + checks - discount,
      notes: json['notes']?.toString() ?? '',
      qType: json['q_type']?.toString() ?? '',
      date: json['q_date']?.toString() ?? '',
      time: json['q_time']?.toString() ?? '',
      isUploaded: json['isUploaded'],
      downloaded: json['downloaded'],
    );
  }

  /// ✅ **New `fromDatabaseJson()` Method for Local Database Data**
  factory CatchModel.fromDatabaseJson(Map<String, dynamic> json) {
    return CatchModel(
      id: json['id'],
      customerID: json['customerID']?.toString() ?? '', // ✅ Corrected key
      customerName: json['customerName']?.toString() ?? '-',
      cashAmount: _convertToDouble(json['cashAmount']),
      discount: _convertToDouble(json['discount']),
      totalChecks: _convertToDouble(json['totalChecks']),
      finalTotal: _convertToDouble(json['finalTotal']),
      notes: json['notes']?.toString() ?? '',
      qType: json['qType']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isUploaded: json['isUploaded'],
      downloaded: json['downloaded'],
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
}
