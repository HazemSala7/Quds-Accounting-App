import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';

class MaxFatoraNumberModel {
  int? id;
  String maxFatoraNumber;

  MaxFatoraNumberModel({
    this.id,
    required this.maxFatoraNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maxFatoraNumber': maxFatoraNumber,
    };
  }

  factory MaxFatoraNumberModel.fromDatabaseJson(Map<String, dynamic> json) {
    return MaxFatoraNumberModel(
      id: json['id'],
      maxFatoraNumber: json['maxFatoraNumber']?.toString() ?? '',
    );
  }
}
