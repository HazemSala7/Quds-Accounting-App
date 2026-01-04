// lib/LocalDB/sync_uploader.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncUploader {
  /// Set [silent]=true to avoid any UI during DB upgrades.
  static Future<void> run({BuildContext? context, bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? companyId = prefs.getInt('company_id');
    final int? salesmanId = prefs.getInt('salesman_id');
    final String? storeId = prefs.getString('store_id');
    final String? deviceId = prefs.getString('device_id');

    final dbHelper = CartDatabaseHelper();
    final receipts = await dbHelper.getUnuploadedCatchReceipts();
    final receiptsVansale = await dbHelper.getUnuploadedCatchReceiptsVansale();
    final localOrders = await dbHelper.getUnUploadedOrders();
    final localOrdersVansale = await dbHelper.getPendingOrdersVansale();

    // Nothing to sync
    if (receipts.isEmpty &&
        receiptsVansale.isEmpty &&
        localOrders.isEmpty &&
        localOrdersVansale.isEmpty) {
      if (!silent) {
        Fluttertoast.showToast(msg: "✅ لا يوجد بيانات تحتاج للمزامنة.");
      }
      return;
    }

    // Optional progress UI (skipped in silent mode)
    ValueNotifier<String>? message;
    ValueNotifier<double>? progress;
    if (!silent && context != null) {
      message = ValueNotifier<String>("بدء المزامنة...");
      progress = ValueNotifier<double>(0.0);
      showProgressDialog(context, message!, progress!);
    }

    int totalItems = receipts.length +
        receiptsVansale.length +
        localOrders.length +
        localOrdersVansale.length;
    int uploadedCount = 0;

    // ---------- Format Receipts (Quds) ----------
    final List<Map<String, dynamic>> formattedReceipts = [];
    for (var receipt in receipts) {
      final checkData = await dbHelper.getCheckDataByReceiptId(receipt.id!);
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
      if (progress != null) {
        progress.value = uploadedCount / totalItems;
        message!.value = "رفع الإيصالات $uploadedCount من $totalItems...";
      }
    }

    // ---------- Format Receipts (Vansale) ----------
    final List<Map<String, dynamic>> formattedReceiptsVansale = [];
    for (var receipt in receiptsVansale) {
      final checkData =
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
      if (progress != null) {
        progress.value = uploadedCount / totalItems;
        message!.value = "رفع الإيصالات $uploadedCount من $totalItems...";
      }
    }

    // ---------- Format Orders (Quds) ----------
    final List<Map<String, dynamic>> formattedOrders = [];
    for (var order in localOrders) {
      final fatoraNumStr = order['fatora_number']?.toString();
      final orderIdForItems = (fatoraNumStr == null || fatoraNumStr == "null")
          ? 0
          : int.tryParse(fatoraNumStr) ?? 0;

      final orderItems = await dbHelper.getOrderItems(orderIdForItems);

      final formattedProducts = orderItems.map((item) {
        return {
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
        };
      }).toList();

      formattedOrders.add({
        "f_date": order['order_date'] ?? "",
        "f_value": order['total_amount'] ?? 0.0,
        "customer_id": order['customer_id']?.toString() ?? "0",
        "fatora_id": order['fatora_number']?.toString() ?? "1",
        "f_code": "1",
        "company_id": int.tryParse(companyId.toString()) ?? 0,
        "salesman_id": int.tryParse(salesmanId.toString()) ?? 0,
        "f_discount": order['discount'] ?? 0.0,
        "store_id": int.tryParse(storeId.toString()) ?? 0,
        "notes": order['notes'] ?? "",
        "f_time": order['order_time'] ?? "",
        "delivery_date": order['deliveryDate'] ?? "",
        "user_id": order['user_id'] ?? "0",
        "isUploaded": order['isUploaded']?.toString() ?? "0",
        "products": formattedProducts,
      });

      uploadedCount++;
      if (progress != null) {
        progress.value = uploadedCount / totalItems;
        message!.value = "رفع الطلبات $uploadedCount من $totalItems...";
      }
    }

    // ---------- Format Orders (Vansale) ----------
    final List<Map<String, dynamic>> formattedOrdersVansale = [];
    for (var order in localOrdersVansale) {
      final orderItemsVansale = await dbHelper.getOrderItemsVansale(
        int.tryParse(order['fatora_number']?.toString() ?? "0") ?? 0,
      );

      final formattedProductsV = orderItemsVansale.map((item) {
        return {
          "product_id": item['product_id'].toString(),
          "product_name": item['product_name'] ?? "Unknown",
          "p_quantity": item['quantity'] ?? 1,
          "p_price": item['price'] ?? 0.0,
          "bonus1": item['bonus1'] ?? 0,
          "bonus2": item['bonus2'] ?? 0,
          "discount": item['discount'] ?? 0.0,
          "total": (item['quantity'] ?? 1) * (item['price'] ?? 0.0),
          "notes": item['notes'] is List ? item['notes'] : [],
          "color_name": item['color'] ?? "",
        };
      }).toList();

      double _parseDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      formattedOrdersVansale.add({
        "f_date": order['order_date'] ?? "",
        "f_value": order['total_amount'] ?? 0.0,
        "cash": order['cash'],
        "fatora_number": order['fatora_number'],
        "customer_id":
            int.tryParse(order['customer_id']?.toString() ?? "0") ?? 0,
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
        "isUploaded": order['isUploaded']?.toString() ?? "1",
        "products": formattedProductsV,
      });

      uploadedCount++;
      if (progress != null) {
        progress.value = uploadedCount / totalItems;
        message!.value = "رفع الفواتير $uploadedCount من $totalItems...";
      }
    }

    // ---------- Send ----------
    final receiptsResp = await http.post(
      Uri.parse(AppLink.addMultipleCatchReceiptQuds),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"receipts": formattedReceipts}),
    );

    final receiptsVansaleResp = await http.post(
      Uri.parse(AppLink.addMultipleCatchReceiptVansale),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"receipts": formattedReceiptsVansale}),
    );

    final ordersResp = await http.post(
      Uri.parse(AppLink.addMultipleOrders),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"orders": formattedOrders}),
    );

    final ordersVansaleResp = await http.post(
      Uri.parse(AppLink.addMultipleOrderVansale),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"orders": formattedOrdersVansale}),
    );

    if (kDebugMode) {
      print("receiptsResponse: ${receiptsResp.body}");
      print("receiptsVansaleResponse: ${receiptsVansaleResp.body}");
      print("ordersResponse: ${ordersResp.body}");
      print("ordersVansaleResponse: ${ordersVansaleResp.body}");
    }

    final receiptsOk = receiptsResp.statusCode == 201;
    final receiptsVansaleOk = receiptsVansaleResp.statusCode == 201;
    final ordersOk = ordersResp.statusCode == 201;
    final ordersVansaleOk = ordersVansaleResp.statusCode == 201;

    // Clear only on success (same as your current behavior)
    if (receiptsOk) {
      await dbHelper.clearCatchReceipts();
      if (!silent) Fluttertoast.showToast(msg: "✅ تمت مزامنة الإيصالات بنجاح!");
    }
    if (receiptsVansaleOk) {
      await dbHelper.clearCatchReceiptsVansale();
      if (!silent) Fluttertoast.showToast(msg: "✅ تمت مزامنة الإيصالات بنجاح!");
    }
    if (ordersOk) {
      await dbHelper.clearOrders();
      if (!silent) Fluttertoast.showToast(msg: "✅ تمت مزامنة الطلبات بنجاح!");
    }
    if (ordersVansaleOk) {
      await dbHelper.clearOrdersVansale();
      if (!silent) Fluttertoast.showToast(msg: "✅ تمت مزامنة الفواتير بنجاح!");
    }

    // Close the dialog if it was shown
    if (!silent && context != null && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
