import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';

class HistoryModel {
  int? id;
  String customer_id;
  String h_code;
  String lattitude;
  String longitude;
  String created_at;

  HistoryModel({
    this.id,
    required this.customer_id,
    required this.h_code,
    required this.lattitude,
    required this.longitude,
    required this.created_at,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customer_id,
      'h_code': h_code,
      'lattitude': lattitude,
      'longitude': longitude,
      'created_at': created_at,
    };
  }

  factory HistoryModel.fromDatabaseJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'],
      customer_id: json['customer_id']?.toString() ?? '',
      h_code: json['h_code']?.toString() ?? '',
      lattitude: json['lattitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      created_at: json['created_at']?.toString() ?? '',
    );
  }
}
