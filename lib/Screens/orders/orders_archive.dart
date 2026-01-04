import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class OrdersArchivePage extends StatefulWidget {
  @override
  _OrdersArchivePageState createState() => _OrdersArchivePageState();
}

class _OrdersArchivePageState extends State<OrdersArchivePage> {
  Database? db;
  List<Map<String, dynamic>> archivedOrders = [];

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  /// ✅ **Initialize the local database and fetch orders**
  Future<void> initDatabase() async {
    db = await CartDatabaseHelper().database;
    fetchArchivedOrders();
  }

  Future<void> fetchArchivedOrders() async {
    if (db == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? type = prefs.getString('type') ?? "quds";

    final String ordersTable =
        type == "quds" ? 'orders_archive' : 'orders_vansale_archive';
    final String orderItemsTable =
        type == "quds" ? 'order_items_archive' : 'order_items_vansale_archive';

    final List<Map<String, dynamic>> orders = (await db!.query(ordersTable))
        .map((order) => Map<String, dynamic>.from(order))
        .toList();

    for (var order in orders) {
      final List<Map<String, dynamic>> items = type.toString() == "quds"
          ? await db!.query(
              orderItemsTable,
              where: 'order_id = ?',
              whereArgs: [order['id']],
            )
          : await db!.query(
              orderItemsTable,
              where: 'order_id = ?',
              whereArgs: [order['fatora_number']],
            );
      order['items'] = items;
    }

    setState(() {
      archivedOrders = orders;
    });
  }

  Future<void> deleteAllArchivedOrders() async {
    if (db == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? type = prefs.getString('type') ?? "quds";

    final String ordersTable =
        type == "quds" ? 'orders_archive' : 'orders_vansale_archive';
    final String orderItemsTable =
        type == "quds" ? 'order_items_archive' : 'order_items_vansale_archive';

    // Delete all items first, then orders
    await db!.delete(orderItemsTable);
    await db!.delete(ordersTable);

    // Refresh UI
    fetchArchivedOrders();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("تم حذف جميع الطلبيات المؤرشفة بنجاح"),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> restoreOrder(Map<String, dynamic> order) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? type = prefs.getString('type');
      String? _deviceId = prefs.getString('device_id') ?? "";
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');

      if (type == null || company_id == null || salesman_id == null) {
        print("Error: Missing essential SharedPreferences values.");
        throw Exception("Missing essential SharedPreferences values.");
      }

      var now = DateTime.now();
      var formatterDate = DateFormat('yy-MM-dd');
      var formatterTime = DateFormat('kk:mm:ss');
      String actualDate = formatterDate.format(now);
      String actualTime = formatterTime.format(now);

      var url =
          type == "quds" ? AppLink.addOrderQuds : AppLink.restoreOrderVansale;

      var request = http.MultipartRequest("POST", Uri.parse(url));

      // Validate and process items
      List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(order['items'] ?? []);
      if (items.isEmpty) {
        print("Error: No items in the order.");
        throw Exception("No items in the order.");
      }

      List<String> ProductsIDarray = [];
      List<String> colorArray = [];
      List<String> ProductsNamearray = [];
      List<String> priceArray = [];
      List<String> qtyArray = [];
      List<String> productBarcodeArray = [];
      List<String> ponus1Array = [];
      List<String> ponus2Array = [];
      List<String> discountArray = [];
      List<String> notesArray = [];

      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        try {
          ProductsIDarray.add(item['product_id'].toString());
          colorArray.add(item['color'].toString());
          ProductsNamearray.add(item['product_name'].toString());
          priceArray.add(item['price'].toString());
          qtyArray.add(item['quantity'].toString());
          productBarcodeArray.add(item['barcode'].toString());
          ponus1Array.add(item['bonus1'].toString());
          ponus2Array.add(item['bonus2'].toString());
          discountArray.add(item['discount'].toString());
          notesArray.add("-");
        } catch (e) {
          print("Error processing item at index $i: $e");
        }
      }

      // Add all fields to request
      try {
        for (int i = 0; i < ProductsIDarray.length; i++) {
          request.fields['product_id[$i]'] = ProductsIDarray[i];
          request.fields['color_name[$i]'] = colorArray[i];
          request.fields['product_name[$i]'] = ProductsNamearray[i];
          request.fields['p_price[$i]'] = priceArray[i];
          request.fields['p_quantity[$i]'] = qtyArray[i];
          request.fields['product_barcode[$i]'] = productBarcodeArray[i];
          request.fields['bonus1[$i]'] = ponus1Array[i];
          request.fields['bonus2[$i]'] = ponus2Array[i];
          request.fields['discount[$i]'] = discountArray[i];
          request.fields['notes[$i]'] = notesArray[i];
        }
      } catch (e) {
        print("Error while adding product fields: $e");
      }

      // Add other fields
      try {
        if (type != "quds") {
          request.fields['fatora_number'] = order['fatora_number'].toString();
        }

        request.fields['f_date'] = actualDate;
        request.fields['f_value'] = order['total_amount'].toString();
        request.fields['device_id'] = _deviceId;
        request.fields['customer_id'] = order['customer_id'].toString();
        request.fields['company_id'] = company_id.toString();
        request.fields['salesman_id'] = salesman_id.toString();
        request.fields['lattiude'] = "0.0";
        request.fields['longitude'] = "0.0";
        request.fields['cash'] = "true";
        request.fields['f_code'] = "1";
        request.fields['f_discount'] = order['discount'].toString();
        request.fields['store_id'] = order['store_id'].toString();
        request.fields['delivery_date'] = order['deliveryDate'].toString();
        request.fields['user_id'] = order['user_id'].toString();
        request.fields['f_time'] = actualTime;
        request.fields['note'] = "";
      } catch (e) {
        print("Error while setting additional order fields: $e");
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Order restored successfully.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("تم استرجاع الطلب بنجاح!"),
          backgroundColor: Colors.green,
        ));
      } else {
        print("Failed to restore order. Status code: ${response.statusCode}");
        String errorResponse = await response.stream.bytesToString();
        print("Response body: $errorResponse");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("فشل استرجاع الطلب!"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e, stack) {
      print("Unhandled error in restoreOrder: $e");
      print("Stack trace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("حدث خطأ أثناء استرجاع الطلب"),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Format currency
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'ar', symbol: "₪");
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(83, 89, 219, 1),
                Color.fromRGBO(32, 39, 160, 0.6),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: BackButton(),
            title: Text(
              "الأرشيف",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                ),
                tooltip: 'حذف الكل',
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("تأكيد الحذف"),
                      content: Text(
                          "هل أنت متأكد أنك تريد حذف جميع الطلبيات المؤرشفة؟"),
                      actions: [
                        TextButton(
                          child: Text("لا"),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: Text("نعم"),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    deleteAllArchivedOrders();
                  }
                },
              )
            ],
          ),
        ),
      ),
      body: archivedOrders.isEmpty
          ? Center(
              child: Text("لا يوجد طلبيات مأرشفة",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: archivedOrders.length,
              itemBuilder: (context, index) {
                var order = archivedOrders[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading:
                        Icon(Icons.archive, color: Colors.orange, size: 32),
                    title: Text("طلب #${order['id']}",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("المبلغ: ${formatCurrency(order['total_amount'])}",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        Text("تاريخ: ${order['order_date']}",
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: List.generate(order['items'].length, (i) {
                            var item = order['items'][i];
                            return ListTile(
                              leading:
                                  Icon(Icons.fastfood, color: Colors.grey[700]),
                              title: Text(
                                  item['product_name'] ?? "منتج غير معروف"),
                              subtitle: Text("الكمية: ${item['quantity']}"),
                              trailing: Text(formatCurrency(
                                  item['price'] * item['quantity'])),
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: ElevatedButton.icon(
                          onPressed: () => restoreOrder(order),
                          icon: Icon(Icons.restore),
                          label: Text("استرجاع الطلب"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
