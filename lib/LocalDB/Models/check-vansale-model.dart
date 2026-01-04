class CheckVansaleModel {
  int? id;
  int receiptId; // Foreign key to link checks to a receipt
  String checkNumber;
  double checkValue;
  String checkDate;
  String bankNumber;
  String accountNumber;

  CheckVansaleModel({
    this.id,
    required this.receiptId,
    required this.checkNumber,
    required this.checkValue,
    required this.checkDate,
    required this.bankNumber,
    required this.accountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptId': receiptId,
      'checkNumber': checkNumber,
      'checkValue': checkValue,
      'checkDate': checkDate,
      'bankNumber': bankNumber,
      'accountNumber': accountNumber,
    };
  }

  factory CheckVansaleModel.fromJson(Map<String, dynamic> json) {
    return CheckVansaleModel(
      id: json['id'],
      receiptId: json['receiptId'],
      checkNumber: json['checkNumber'],
      checkValue: json['checkValue'],
      checkDate: json['checkDate'],
      bankNumber: json['bankNumber'],
      accountNumber: json['accountNumber'],
    );
  }
}
