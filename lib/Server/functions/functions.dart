import 'dart:async';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/city-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/history-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FunctionsAPI {
  String customJsonEncode(Map<String, dynamic> data) {
    return json.encode(data, toEncodable: (value) {
      if (value == null) {
        return null;
      }
      return value;
    });
  }

  Future<Map<String, dynamic>> getRequest(String API_URL,
      {Map<String, dynamic>? jsonData, int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Clone headers to add conditional token
    var requestHeaders = {
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    // Append page parameter to the URL if provided
    if (page != null) {
      API_URL = '$API_URL?page=$page';
    }

    var response;
    try {
      if (jsonData != null) {
        final request = http.Request('GET', Uri.parse(API_URL));
        request.headers.addAll(requestHeaders);
        request.body = customJsonEncode(jsonData);

        // Apply timeout to the send and stream operations
        var streamedResponse =
            await request.send().timeout(Duration(milliseconds: 150000000));
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Apply timeout to the get operation
        response = await http
            .get(Uri.parse(API_URL), headers: requestHeaders)
            .timeout(Duration(milliseconds: 150000000));
      }

      // Decode the response body
      var res = jsonDecode(response.body);
      return res;
    } catch (e) {
      // Handle timeout and other errors
      print("Error during getRequest: $e");
      throw Exception('Request failed: $e');
    }
  }
}

sendSMS(
    {String senderName = "",
    String phoneNumber = "",
    String message = ""}) async {
  final response = await http.get(
    Uri.parse(
        'http://sms.htd.ps/API/SendSMS.aspx?id=604076732bb8dd6b6af738d27669d773&sender=$senderName&to=$phoneNumber&msg=$message'),
  );

  if (response.statusCode == 200) {
    // SMS sent successfully
    print('SMS sent successfully');
  } else {
    // Error occurred while sending SMS
    print('Failed to send SMS');
  }
}

addHistory(
  customerID,
  fCode,
) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? company_id = prefs.getInt('company_id');
  int? salesman_id = prefs.getInt('salesman_id');
  var url =
      '${AppLink.addHistory}/${customerID}/${fCode}/${company_id.toString()}/${salesman_id.toString()}';
  final response = await http.post(Uri.parse(url));
  jsonDecode(response.body);
}

Future<void> sendShipmentDynamic({
  required String email,
  required String password,
  required String orderNumber,
  required String receiverName,
  required String receiverPhone,
  String? receiverPhone2,
  required String addressLine1,
  required String description,
  required int cityId,
  required int qty,
  String notes = "NTE Delivery",
  double cod = 0,
  double weight = 1.0,
}) async {
  print("start shipment");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? passwordAPI = await prefs.getString('passwordAPI');
  String? emailAPI = await prefs.getString('emailAPI');
  String? senderPhone = await prefs.getString('senderPhone');
  String? businessSenderName = await prefs.getString('businessSenderName');
  String? senderName = await prefs.getString('senderName');
  String? apiCompanyID = await prefs.getString('api_company_id');

  final url =
      Uri.parse('https://apisv2.logestechs.com/api/ship/request/by-email');

  final headers = {
    'company-id': apiCompanyID.toString(),
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    "email": emailAPI.toString(),
    "password": passwordAPI.toString(),
    "pkg": {
      "cod": cod.toString(),
      "notes": notes,
      "invoiceNumber": orderNumber,
      "senderName": senderName.toString(),
      "businessSenderName": businessSenderName.toString(),
      "senderPhone": senderPhone.toString(),
      "receiverName": receiverName,
      "receiverPhone": receiverPhone,
      "receiverPhone2": receiverPhone2 ?? "",
      "weight": weight,
      "serviceType": "STANDARD",
      "shipmentType": "COD",
      "quantity": qty,
      "description": description
    },
    "destinationAddress": {"addressLine1": addressLine1, "cityId": cityId},
    "originAddress": {
      "addressLine1": "الشارع ٢",
      "addressLine2": "",
      "cityId": 8
    }
  });

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("shipment response: $data");

      // ✅ NEW: persist shipment.id into fawaters.logestice_id
      final String logesticsId = (data['barcode'] ?? '').toString();
      if (logesticsId.isNotEmpty && orderNumber.isNotEmpty) {
        await _persistLogesticsIdOnServer(
          orderId: orderNumber,
          logesticeId: logesticsId,
        );
      }

      Fluttertoast.showToast(
        msg: "تم انشاء البوليصة بنجاح ✅",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      print(response.body);
      Fluttertoast.showToast(
        msg: "❌ Failed (${response.statusCode})",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  } catch (e) {
    print(e);
    Fluttertoast.showToast(
      msg: "⚠️ Error: $e",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}

Future<void> _persistLogesticsIdOnServer({
  required String orderId, // fatora id
  required String logesticeId, // shipment.id from LogesTechs
}) async {
  final uri = Uri.parse(
      'https://yaghm.com/admin/api/fawater/$orderId/set-logestics-id');
  final body = jsonEncode({'logestice_id': logesticeId});

  try {
    final r = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: body,
    );
    if (r.statusCode != 200) {
      print('set-logestics-id failed: ${r.statusCode} -> ${r.body}');
    } else {
      print('set-logestics-id OK for order $orderId => $logesticeId');
    }
  } catch (e) {
    print('set-logestics-id exception: $e');
  }
}

updatePrintedValue(
  vansaleFatoraID,
  printed,
) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? company_id = prefs.getInt('company_id');
  var url =
      '${AppLink.updatePrintedValue}/${vansaleFatoraID}/${printed}/${company_id.toString()}';
  final response = await http.get(Uri.parse(url));
  jsonDecode(response.body);
}

updateCatchReceiptPrintedValue(
  catchReceiptID,
  printed,
) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? company_id = prefs.getInt('company_id');
  var url =
      '${AppLink.updateCatchReceiptPrintedValue}/${catchReceiptID}/${printed}/${company_id.toString()}';
  final response = await http.get(Uri.parse(url));
  jsonDecode(response.body);
}

NavigatorFunction(BuildContext context, Widget Widget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => Widget));
}

Future<void> syncData(BuildContext context) async {
  print("11.00");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? companyId = prefs.getInt('company_id');
  int? salesmanId = prefs.getInt('salesman_id');
  String? storeId = prefs.getString('store_id');
  String? deviceId = prefs.getString('device_id');

  final dbHelper = CartDatabaseHelper();
  List<CatchModel> receipts = await dbHelper.getUnuploadedCatchReceipts();
  List<HistoryModel> histories = await dbHelper.getHistoriesRecords();
  List<CatchVansaleModel> receiptsVansale =
      await dbHelper.getUnuploadedCatchReceiptsVansale();

  List<Map<String, dynamic>> localOrders = await dbHelper.getUnUploadedOrders();

  List<Map<String, dynamic>> localOrdersVansale =
      await dbHelper.getPendingOrdersVansale();
  print("histories");
  print(histories);

  if (receipts.isEmpty &&
      receiptsVansale.isEmpty &&
      histories.isEmpty &&
      localOrders.isEmpty &&
      localOrdersVansale.isEmpty) {
    Fluttertoast.showToast(msg: "✅ لا يوجد بيانات تحتاج للمزامنة.");
    return;
  }

  // Progress Dialog
  ValueNotifier<String> message = ValueNotifier<String>("بدء المزامنة...");
  ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  showProgressDialog(context, message, progress);

  int totalItems = receipts.length +
      receiptsVansale.length +
      localOrders.length +
      localOrdersVansale.length;
  int uploadedCount = 0;

  // ✅ Format Receipts Quds for API
  List<Map<String, dynamic>> formattedReceipts = [];
  for (var receipt in receipts) {
    List<Map<String, dynamic>> checkData =
        await dbHelper.getCheckDataByReceiptId(receipt.id!);
    formattedReceipts.add({
      "store_id": int.tryParse(storeId.toString()) ?? 0,
      "customer_id": receipt.customerID.toString(),
      "company_id": int.tryParse(companyId.toString()) ?? 0,
      "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
      "discount": receipt.discount ?? 0,
      "cash": receipt.cashAmount ?? 0,
      "notes": receipt.notes ?? "",
      "q_date": receipt.date ?? "",
      "q_time": receipt.time ?? "",
      "q_type": receipt.qType ?? "qabd",
      "isUploaded": receipt.isUploaded.toString(),
      "chk_no": checkData.map((c) => c["checkNumber"] ?? "").toList(),
      "chk_value": checkData.map((c) => c["checkValue"] ?? 0).toList(),
      "chk_date": checkData.map((c) => c["checkDate"] ?? "").toList(),
      "account_no": checkData.map((c) => c["accountNumber"] ?? "").toList(),
      "bank_no": checkData.map((c) => c["bankNumber"] ?? "").toList(),
      "bank_branch": checkData.map((c) => c["bank_branch"] ?? "").toList(),
    });

    uploadedCount++;
    progress.value = uploadedCount / totalItems;
    message.value = "رفع الإيصالات ${uploadedCount} من $totalItems...";
  }
  List<Map<String, dynamic>> formattedHistories = [];
  for (var history in histories) {
    formattedHistories.add({
      "created_at": history.created_at.toString(),
      "customer_id": history.customer_id.toString(),
      "company_id": int.tryParse(companyId.toString()) ?? 0,
      "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
      "h_code": history.h_code.toString(),
    });
  }
  // ✅ Format Receipts Vansale for API
  List<Map<String, dynamic>> formattedReceiptsVansale = [];
  for (var receipt in receiptsVansale) {
    List<Map<String, dynamic>> checkData =
        await dbHelper.getCheckDataByReceiptIdVansale(receipt.id!);
    formattedReceiptsVansale.add({
      "store_id": int.tryParse(storeId.toString()) ?? 0,
      "customer_id": receipt.customerID.toString(),
      "company_id": int.tryParse(companyId.toString()) ?? 0,
      "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
      "discount": receipt.discount ?? 0,
      "cash": receipt.cashAmount ?? 0,
      "notes": receipt.notes ?? "",
      "q_date": receipt.date ?? "",
      "q_time": receipt.time ?? "",
      "q_type": receipt.qType ?? "qabd",
      "isUploaded": receipt.isUploaded.toString(),
      "chk_no": checkData.map((c) => c["checkNumber"] ?? "").toList(),
      "chk_value": checkData.map((c) => c["checkValue"] ?? 0).toList(),
      "chk_date": checkData.map((c) => c["checkDate"] ?? "").toList(),
      "account_no": checkData.map((c) => c["accountNumber"] ?? "").toList(),
      "bank_no": checkData.map((c) => c["bankNumber"] ?? "").toList(),
      "bank_branch": checkData.map((c) => c["bank_branch"] ?? "").toList(),
    });

    uploadedCount++;
    progress.value = uploadedCount / totalItems;
    message.value = "رفع الإيصالات ${uploadedCount} من $totalItems...";
  }

  List<Map<String, dynamic>> orderAllItems = await dbHelper.getAllOrderItems();
  // ✅ Format Orders for API
  List<Map<String, dynamic>> formattedOrders = [];
  for (var order in localOrders) {
    List<Map<String, dynamic>> orderItems = await dbHelper.getOrderItems(
        order['fatora_number'].toString() == "null"
            ? 0
            : int.parse(order['fatora_number'].toString()));

    List<Map<String, dynamic>> formattedProducts = orderItems
        .map((item) => {
              "product_id": item['product_id'].toString(),
              "product_name": item['product_name'] ?? "Unknown",
              "isUploaded": order['isUploaded'].toString(),
              "p_quantity": item['quantity'] ?? 1,
              "p_price": item['price'] ?? 0.0,
              "bonus1": item['bonus1'] ?? 0,
              "bonus2": item['bonus2'] ?? 0,
              "discount": item['discount'] ?? 0.0,
              "total": (item['quantity'] ?? 1) * (item['price'] ?? 0.0),
              "notes": item['notes'] is List ? item['notes'] : [],
              "color_name": item['color'] ?? "",
            })
        .toList();

    formattedOrders.add({
      "f_date": order['order_date'] ?? "",
      "f_value": order['total_amount'] ?? 0.0,
      "customer_id": order['customer_id'].toString() ?? "0",
      "fatora_id": order['fatora_number'].toString() ?? "1",
      "f_code": "1",
      "company_id": int.tryParse(companyId.toString()) ?? 0,
      "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
      "f_discount": order['discount'] ?? 0.0,
      "store_id": int.tryParse(storeId.toString()) ?? 0,
      "notes": order['notes'] ?? "",
      "f_time": order['order_time'] ?? "",
      "delivery_date": order['deliveryDate'] ?? "",
      "user_id": order['user_id'] ?? "0",
      "isUploaded": order['isUploaded'].toString(),
      "products": formattedProducts,
    });

    uploadedCount++;
    progress.value = uploadedCount / totalItems;
    message.value = "رفع الطلبات ${uploadedCount} من $totalItems...";
  }

  List<Map<String, dynamic>> orderAllItemsVansale =
      await dbHelper.getAllOrderItemsVansale();
  // ✅ Format Orders for API
  List<Map<String, dynamic>> formattedOrdersVansale = [];
  for (var order in localOrdersVansale) {
    List<Map<String, dynamic>> orderItemsVansale = await dbHelper
        .getOrderItemsVansale(int.parse(order['fatora_number'].toString()));

    List<Map<String, dynamic>> formattedProductsVansale = orderItemsVansale
        .map((item) => {
              "product_id": item['product_id'].toString(),
              "product_name": item['product_name'] ?? "Unknown",
              "p_quantity": item['quantity'] ?? 1,
              "p_price": item['price'] ?? 0.0,
              "bonus1": item['bonus1'] ?? 0,
              "bonus2": item['bonus2'] ?? 0,
              "discount": item['discount'] ?? 0.0,
              "total": (item['quantity'] ?? 1) * (item['price'] ?? 0.0),
              "notes": item['notes'] is List
                  ? item['notes']
                  : [], // ✅ Convert notes to an array
              "color_name": item['color'] ?? "",
            })
        .toList();

    formattedOrdersVansale.add({
      "f_date": order['order_date'] ?? "",
      "f_value": order['total_amount'] ?? 0.0,
      "cash": order['cash'],
      "fatora_number": order['fatora_number'],
      "customer_id": int.tryParse(order['customer_id'].toString()) ?? 0,
      "f_code": "1",
      "lattiude": _parseDouble(order['latitude'] ?? 0.0),
      "longitude": _parseDouble(order['longitude'] ?? 0.0),
      "company_id": int.tryParse(companyId.toString()) ?? 0,
      "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
      "f_discount": order['discount'] ?? 0.0,
      "device_id": deviceId.toString(),
      "store_id": int.tryParse(storeId.toString()) ?? 0,
      "notes": order['notes'] ?? "",
      "f_time": order['order_time'] ?? "",
      "delivery_date": order['deliveryDate'] ?? "",
      "user_id": order['user_id'] ?? "0",
      "printed": order['printed'] ?? "0",
      "isUploaded": order['isUploaded'] ?? "1",
      "products": formattedProductsVansale,
    });

    uploadedCount++;
    progress.value = uploadedCount / totalItems;
    message.value = "رفع الفواتير ${uploadedCount} من $totalItems...";
  }
  var receiptsUrl = Uri.parse(AppLink.addMultipleCatchReceiptQuds);
  var receiptsVansaleUrl = Uri.parse(AppLink.addMultipleCatchReceiptVansale);
  var ordersUrl = Uri.parse(AppLink.addMultipleOrders);
  var ordersVansaleUrl = Uri.parse(AppLink.addMultipleOrderVansale);
  var HistoriesUrl = Uri.parse(AppLink.addMultipleHistories);
  var receiptsResponse = await http.post(
    receiptsUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"receipts": formattedReceipts}),
  );
  var HistoriesResponse = await http.post(
    HistoriesUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"histories": formattedHistories}),
  );
  var receiptsVansaleResponse = await http.post(
    receiptsVansaleUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"receipts": formattedReceiptsVansale}),
  );

  debugPrint(jsonEncode({"orders": formattedOrders}));

  var ordersResponse = await http.post(
    ordersUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"orders": formattedOrders}),
  );
  var ordersVansaleResponse = await http.post(
    ordersVansaleUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"orders": formattedOrdersVansale}),
  );

  print("receiptsResponse: ${receiptsResponse.body}");
  print("receiptsVansaleResponse: ${receiptsVansaleResponse.body}");
  print("ordersResponse: ${ordersResponse.body}");
  print("ordersVansaleResponse: ${ordersVansaleResponse.body}");
  print("HistoriesResponse: ${HistoriesResponse.body}");

  bool receiptsSuccess = receiptsResponse.statusCode == 201;
  bool receiptsVansaleSuccess = receiptsVansaleResponse.statusCode == 201;
  bool ordersSuccess = ordersResponse.statusCode == 201;
  bool ordersVansaleSuccess = ordersVansaleResponse.statusCode == 201;
  bool historiesSuccess = HistoriesResponse.statusCode == 201;

  if (receiptsSuccess) {
    await dbHelper.clearCatchReceipts();
    Fluttertoast.showToast(msg: "✅ تمت مزامنة الإيصالات بنجاح!");
  } else {
    // Fluttertoast.showToast(msg: "❌ فشل في مزامنة الإيصالات.");
  }
  if (historiesSuccess) {
    await dbHelper.clearHistoriesTable();
    print("histories uploaded successfully");
  } else {
    print("histories didnt uploaded successfully");
  }

  if (receiptsVansaleSuccess) {
    await dbHelper.clearCatchReceiptsVansale();
    Fluttertoast.showToast(msg: "✅ تمت مزامنة الإيصالات بنجاح!");
  } else {
    // Fluttertoast.showToast(msg: "❌ فشل في مزامنة الإيصالات.");
  }

  if (ordersSuccess) {
    await dbHelper.clearOrders();
    Fluttertoast.showToast(msg: "✅ تمت مزامنة الطلبات بنجاح!");
  } else {
    // Fluttertoast.showToast(msg: "❌ فشل في مزامنة الطلبات.");
  }

  if (ordersVansaleSuccess) {
    await dbHelper.clearOrdersVansale();
    Fluttertoast.showToast(msg: "✅ تمت مزامنة الفواتير بنجاح!");
  } else {
    // Fluttertoast.showToast(msg: "❌ فشل في مزامنة الفواتير.");
  }

  // ✅ Close Progress Dialog
  if (Navigator.canPop(context)) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

void printFullResponse(String text) {
  final pattern = RegExp('.{1,800}'); // Split long string into 800-char chunks
  for (final match in pattern.allMatches(text)) {
    print(match.group(0));
  }
}

void showProgressDialog(BuildContext context, ValueNotifier<String> message,
    ValueNotifier<double> progress) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, progressValue, child) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: progressValue),
                  SizedBox(height: 15),
                  Text("${(progressValue * 100).toInt()}%",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: message,
                    builder: (context, value, child) {
                      return Text(value,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

double? _parseDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null; // or provide a default value like 0.0
  }
  try {
    return double.parse(value.toString());
  } catch (e) {
    return null; // Handle error case, maybe log it
  }
}
