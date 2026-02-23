// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
// import 'package:quds_yaghmour/LocalDB/Models/LastPriceModel.dart';
// import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/category-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/price-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/product-model-vansale.dart';
// import 'package:quds_yaghmour/LocalDB/Models/product-model-quds.dart';
// import 'package:quds_yaghmour/Server/domains/domains.dart';
// import 'package:quds_yaghmour/Server/functions/functions.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class DataDownloader {
//   final FunctionsAPI _functionsAPI = FunctionsAPI();

//   Future<void> _clearAllTables() async {
//     var db = await CartDatabaseHelper().database;
//     await db!.delete('orders_vansale');
//     await db.delete('order_items_vansale');
//     await db.delete('products_quds');
//     await db.delete('products_vansale');
//     await db.delete('maxFatoraNumber');
//     await db.delete('prices');
//     await db.delete('categories');
//     await db.delete('last_prices');
//     await db.delete('catch_receipts');
//     await db.delete('catch_receipt_checks');
//     await db.delete('catch_receipts_vansale');
//     await db.delete('catch_receipt_checks_vansale');
//     print("All tables cleared.");
//   }

//   Future<void> downloadAndSaveData(
//       ValueNotifier<double> progress, ValueNotifier<String> message) async {
//     await _clearAllTables();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     int? company_id = prefs.getInt('company_id');
//     int? salesman_id = prefs.getInt('salesman_id');
//     String? deviceID = prefs.getString('device_id');
//     String? type = prefs.getString('type');

//     message.value = "تنزيل المنتجات .....";
//     progress.value = 0.05; // Initial loading progress

//     var products = [];
//     int page = 1;
//     int totalPages = 1; // Default in case there's no pagination

//     // ✅ Step 1: Fetch the first response (to check pagination)
//     var firstResponse = await _functionsAPI.getRequest(type == "quds"
//         ? "${AppLink.allProductsQudsLocal}/$company_id/$salesman_id?page=1"
//         : "${AppLink.allProductsVansaleProductsLocal}/$company_id/$salesman_id?page=1");

//     if (firstResponse == null) {
//       Fluttertoast.showToast(msg: "Error: No response from server.");
//       return;
//     }

//     // ✅ Detect if the response contains pagination
//     if (firstResponse.containsKey("products")) {
//       var productsData = firstResponse["products"];

//       if (productsData is Map && productsData.containsKey("data")) {
//         // ✅ This means pagination exists
//         totalPages = productsData["last_page"] ?? 1;
//         print("📄 Detected paginated response with $totalPages pages.");

//         // ✅ Fetch products from paginated response
//         while (page <= totalPages) {
//           message.value = "Downloading products... (Page $page of $totalPages)";
//           print("📄 Fetching Page $page...");

//           var response = await _functionsAPI.getRequest(type == "quds"
//               ? "${AppLink.allProductsQudsLocal}/$company_id/$salesman_id?page=$page"
//               : "${AppLink.allProductsVansaleProductsLocal}/$company_id/$salesman_id?page=$page");

//           if (response != null &&
//               response.containsKey("products") &&
//               response["products"] is Map &&
//               response["products"].containsKey("data")) {
//             List<dynamic> newProducts = response["products"]["data"];
//             if (newProducts.isNotEmpty) {
//               products.addAll(newProducts);
//               print("✅ Added ${newProducts.length} products from page $page");
//             }
//           }

//           progress.value = 0.1 + (page / totalPages) * 0.3; // Progress update
//           page++;
//         }
//       } else if (productsData is List) {
//         // ✅ No pagination, direct product list
//         print("✅ Non-paginated response detected.");
//         products = productsData; // Directly assign products array
//       }
//     }

//     print("✅ Finished fetching all products.");
//     progress.value = 0.4; // ✅ Reset to 40% to indicate product download is done

//     // ✅ Step 2: Save all products **at once**
//     if (products.isNotEmpty) {
//       type == "quds"
//           ? await _saveProductsQuds(products)
//           : await _saveProductsVansale(products);
//     } else {
//       Fluttertoast.showToast(msg: 'No products found.');
//       return;
//     }

//     Fluttertoast.showToast(msg: 'تم تنزيل المنتجات بنجاح!');
//     message.value = "تنزيل الأسعار ....";
//     progress.value = 0.5; // ✅ Move to next section

//     // ✅ Step 3: Download prices
//     var prices =
//         await _functionsAPI.getRequest("${AppLink.prices}/$company_id");
//     if (prices != null && prices.containsKey("prices")) {
//       await _savePrices(prices["prices"]);
//       Fluttertoast.showToast(msg: 'تم تنزيل الأسعار بنجاح!');
//     }

//     message.value = "تنزيل سندات القبض ....";
//     progress.value = 0.6; // ✅ Progress for Catches

//     // ✅ Step 4: Download Catches
//     var catches = await _functionsAPI.getRequest(
//         "${type.toString() == "quds" ? AppLink.CatchesReceiptQabdQuds : AppLink.vansaleQabds}/$company_id/$salesman_id");
//     if (catches != null && catches.containsKey("qabds")) {
//       await type.toString() == "quds"
//           ? _saveCatchesQuds(catches["qabds"])
//           : _saveCatchesVansale(catches["qabds"]);
//       Fluttertoast.showToast(msg: 'تم تنزيل سندات القبض بنجاح!');
//     }
//     message.value = type.toString() == "quds"
//         ? "تنزيل طلبات القدس ...."
//         : "تنزيل فواتير الفان سيل ....";
//     await downloadAndSaveOrders(company_id!, salesman_id!);
//     message.value = type.toString() == "quds"
//         ? "تنزيل تفاصيل الطلبيات ...."
//         : "تنزيل تفاصيل الفواتير ....";
//     await downloadAndSaveOrderItems(company_id!, salesman_id!);
//     var maxFatoraResponse = await _functionsAPI.getRequest(
//         "${type.toString() == "quds" ? AppLink.getMaxFatoraNumberQuds : AppLink.getMaxFatoraNumber}/$company_id/$salesman_id/${deviceID.toString()}");

//     if (maxFatoraResponse != null &&
//         maxFatoraResponse.containsKey("max_fatora_number")) {
//       String maxNumber = maxFatoraResponse["max_fatora_number"].toString();
//       int finalMaxNumber = int.parse(maxNumber.toString()) + 1;

//       final db = await CartDatabaseHelper().database;

//       // Clear old record
//       await db!.delete('maxFatoraNumber');

//       // Insert new record
//       await db.insert('maxFatoraNumber', {
//         'maxFatoraNumber': finalMaxNumber.toString(),
//       });

//       Fluttertoast.showToast(msg: 'تم تنزيل أخر رقم للفاتورة بنجاح!');
//     }

//     message.value = "Downloading last prices...";
//     progress.value = 0.7; // ✅ Progress for last prices

//     // ✅ Step 5: Download last prices
//     var lastPrices =
//         await _functionsAPI.getRequest("${AppLink.lastPrices}/$company_id");
//     if (lastPrices != null && lastPrices.containsKey("last_prices")) {
//       await _saveLastPrices(lastPrices["last_prices"]);
//       Fluttertoast.showToast(msg: 'تم تنزيل أخر الاسعار بنجاح!');
//     }

//     message.value = "Downloading categories...";
//     progress.value = 0.9; // ✅ Progress for categories

//     // ✅ Step 5: Download categories
//     var categories =
//         await _functionsAPI.getRequest("${AppLink.categories}/$company_id");
//     if (categories != null && categories.containsKey("categories")) {
//       await _saveCategories(categories["categories"]);
//       Fluttertoast.showToast(
//           msg: "تم تنزيل جميع البيانات بنجاح!", backgroundColor: Colors.green);
//     }
//     print("done");

//     message.value = "Download Complete!";
//     progress.value = 1.0; // ✅ 100% Done!
//   }

//   Future<void> _saveProductsQuds(List<dynamic> productsData) async {
//     try {
//       var db = await CartDatabaseHelper().database;

//       for (var productData in productsData) {
//         final product = ProductQuds.fromJson(productData);

//         if (product.images.isNotEmpty && product.images.startsWith('http')) {
//           print("📷 Trying to download: ${product.images}");

//           final localPath = await downloadAndSaveImage(
//             product.images,
//             'quds_${product.id}',
//           );

//           if (localPath != null) {
//             product.images = localPath;
//           }
//         }

//         await db!.insert('products_quds', product.toJson());
//       }
//       final result = await db!.query('products_quds');
//       for (var row in result) {
//         print("🧪 ID: ${row['id']}, image: ${row['images']}");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error saving products: $e");
//     }
//   }

//   Future<String?> downloadAndSaveImage(String url, String filename) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final folder = Directory('${directory.path}/products');

//       if (!await folder.exists()) {
//         await folder.create(recursive: true);
//       }

//       final path = '${folder.path}/$filename.jpg';

//       final response = await Dio().download(
//         url,
//         path,
//         options: Options(
//           receiveTimeout: 10000, // 10 seconds in milliseconds
//           sendTimeout: 10000, // 10 seconds in milliseconds
//         ),
//       );

//       // Only return the path if it downloaded successfully
//       if (File(path).existsSync()) {
//         return path;
//       } else {
//         return null;
//       }
//     } on DioError catch (e) {
//       if (e.response?.statusCode == 404) {
//         print("🛑 Image not found (404): $url");
//       } else {
//         print("❌ Dio error downloading image: ${e.message}");
//       }
//       return null;
//     } catch (e) {
//       print("❌ Unknown error downloading image: $e");
//       return null;
//     }
//   }

//   Future<void> _saveProductsVansale(List<dynamic> productsData) async {
//     try {
//       List<ProductVansale> products = productsData
//           .map((productData) => ProductVansale.fromJson(productData))
//           .toList();
//       var db = await CartDatabaseHelper().database;
//       for (var product in products) {
//         await db!.insert('products_vansale', product.toJson());
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   Future<void> _savePrices(List<dynamic> pricesData) async {
//     List<Price> prices =
//         pricesData.map((priceData) => Price.fromJson(priceData)).toList();
//     var db = await CartDatabaseHelper().database;
//     for (var price in prices) {
//       await db!.insert('prices', price.toJson());
//     }
//   }

//   Future<void> _saveCatchesQuds(List<dynamic> catchesData) async {
//     try {
//       List<CatchModel> catchesQuds = catchesData
//           .map((catchData) => CatchModel.fromJson(catchData))
//           .toList();
//       var db = await CartDatabaseHelper().database;
//       for (var catchQuds in catchesQuds) {
//         await db!.insert('catch_receipts', catchQuds.toJson());
//       }
//     } catch (e) {
//       print("error here");
//       print("❌ Error saving catch receipts: $e");
//     }
//   }

//   Future<void> _saveCatchesVansale(List<dynamic> catchesData) async {
//     List<CatchVansaleModel> catchesVansale = catchesData
//         .map((catchData) => CatchVansaleModel.fromDatabaseJson(catchData))
//         .toList();
//     var db = await CartDatabaseHelper().database;
//     for (var catchVansale in catchesVansale) {
//       await db!.insert('catch_receipts_vansale', catchVansale.toJson());
//     }
//   }

//   Future<void> _saveCategories(List<dynamic> categoriesData) async {
//     List<Category> categories = categoriesData
//         .map((categoryData) => Category.fromJson(categoryData))
//         .toList();
//     var db = await CartDatabaseHelper().database;
//     for (var category in categories) {
//       await db!.insert('categories', category.toJson());
//     }
//   }

//   Future<void> _saveLastPrices(List<dynamic> lastPricesData) async {
//     List<LastPrice> lastPrices = lastPricesData
//         .map((lastPriceData) => LastPrice.fromJson(lastPriceData))
//         .toList();
//     var db = await CartDatabaseHelper().database;
//     for (var lastPrice in lastPrices) {
//       await db!.insert('last_prices', lastPrice.toJson());
//     }
//   }

//   Future<void> downloadAndSaveOrders(int companyId, int salesmanId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? type = prefs.getString('type');
//       final dbHelper = CartDatabaseHelper();
//       final response = await _functionsAPI.getRequest(
//           "${type.toString() == "quds" ? AppLink.orders : AppLink.ordersVansale}/$companyId/$salesmanId");

//       if (response == null ||
//           !response.containsKey("orders") ||
//           response["orders"].length == 0) {
//         Fluttertoast.showToast(msg: "فشل في تحميل الطلبات");
//         return;
//       }

//       List<dynamic> orders = response["orders"];
//       for (var orderJson in orders) {
//         String customerName = '-';
//         if (orderJson['customer'] != null &&
//             orderJson['customer'] is List &&
//             orderJson['customer'].isNotEmpty) {
//           customerName = orderJson['customer'][0]['c_name'] ?? '-';
//         }

//         if (type.toString() == "quds") {
//           final orderQuds = OrderModel(
//             customerName: customerName,
//             fatora_number: orderJson['fatora_id'].toString(),
//             isUploaded: orderJson['isUploaded'].toString(),
//             customerId: orderJson['customer_id'].toString(),
//             user_id: orderJson['user_id'].toString(),
//             storeId: orderJson['store_id'].toString(),
//             totalAmount:
//                 double.tryParse(orderJson['f_value'].toString()) ?? 0.0,
//             discount:
//                 double.tryParse(orderJson['f_discount'].toString()) ?? 0.0,
//             cashPaid: double.tryParse(orderJson['f_value'].toString()) ?? 0.0,
//             orderDate: orderJson['f_date'].toString(),
//             orderTime: orderJson['f_time'].toString(),
//             deliveryDate: orderJson['delivery_date'] ?? '',
//           );
//           await dbHelper.insertOrder(orderQuds);
//         } else {
//           final orderVansale = OrderVansaleModel(
//             isUploaded: "1",
//             customerId: orderJson['customer_id'].toString(),
//             fatora_number: orderJson['fatora_no'].toString(),
//             user_id: orderJson['user_id'].toString(),
//             customerName: customerName,
//             storeId: orderJson['store_id'].toString(),
//             latitude: orderJson['lattiude'].toString(),
//             longitude: orderJson['longitude'].toString(),
//             totalAmount:
//                 double.tryParse(orderJson['f_value'].toString()) ?? 0.0,
//             discount:
//                 double.tryParse(orderJson['f_discount'].toString()) ?? 0.0,
//             cashPaid: double.tryParse(orderJson['f_value'].toString()) ?? 0.0,
//             orderDate: orderJson['f_date'].toString(),
//             orderTime: orderJson['f_time'].toString(),
//             deliveryDate: orderJson['delivery_date'] ?? '',
//             cash: orderJson['cash'].toString(),
//             printed: orderJson['printed'].toString(),
//           );
//           await dbHelper.insertOrderVansale(orderVansale);
//         }

//         // You can optionally fetch and insert order items here if they exist
//         // await dbHelper.insertOrderItemsVansale(orderId, items);
//       }

//       Fluttertoast.showToast(msg: "تم تنزيل طلبات الفان سيل بنجاح");
//     } catch (e) {
//       print("e");
//       print(e);
//     }
//   }

//   Future<void> downloadAndSaveOrderItems(int companyId, int salesmanId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? type = prefs.getString('type');
//       final dbHelper = CartDatabaseHelper();
//       final response = await _functionsAPI.getRequest(
//           "${type.toString() == "quds" ? AppLink.allOrdersDetailsQuds : AppLink.allOrdersDetailsVansale}/$companyId/$salesmanId");
//       if (response == null ||
//           !response.containsKey("orders_details") ||
//           response["orders_details"].isEmpty) {
//         Fluttertoast.showToast(msg: "فشل في تحميل تفاصيل الطلبات");
//         return;
//       }

//       List<dynamic> items = response["orders_details"];
//       for (var item in items) {
//         try {
//           String fatoraNoQuds = item['fatora_number'].toString();
//           String fatoraNoVansale = item['fatora_id'].toString();

//           if (type.toString() == "quds") {
//             final orderItemQuds = OrderItemModel(
//               orderId: int.parse(fatoraNoQuds),
//               isUploaded: "1",
//               productId: item['product_id'].toString(),
//               productName: item['product_name'].toString(),
//               bonus1: item['bonus1'].toString(),
//               bonus2: item['bonus2'].toString(),
//               quantity: double.tryParse(item['p_quantity'].toString()) ?? 0.0,
//               price: double.tryParse(item['p_price'].toString()) ?? 0.0,
//               discount: double.tryParse(item['discount'].toString()) ?? 0.0,
//               total: double.tryParse(item['total'].toString()) ?? 0.0,
//               color: item['notes']?.toString() ?? '',
//               barcode: item['product_barcode']?.toString() ?? '',
//             );

//             await dbHelper
//                 .insertOrderItems(int.parse(fatoraNoQuds), [orderItemQuds]);
//           } else {
//             final orderItem = OrderItemVansaleModel(
//               orderId: int.parse(fatoraNoVansale),
//               isUploaded: "1",
//               productId: item['product_id'].toString(),
//               productName: item['product_name'].toString(),
//               bonus1: item['bonus1'].toString(),
//               bonus2: item['bonus2'].toString(),
//               quantity: double.tryParse(item['p_quantity'].toString()) ?? 0.0,
//               price: double.tryParse(item['p_price'].toString()) ?? 0.0,
//               discount: double.tryParse(item['discount'].toString()) ?? 0.0,
//               total: double.tryParse(item['total'].toString()) ?? 0.0,
//               color: item['notes']?.toString() ?? '',
//               barcode: item['product_barcode']?.toString() ?? '',
//             );

//             await dbHelper.insertOrderItemsVansale(
//                 int.parse(fatoraNoVansale), [orderItem]);
//           }
//         } catch (e, stacktrace) {
//           print("❌ Error processing item: $e");
//           print(stacktrace);
//         }
//       }

//       Fluttertoast.showToast(msg: "تم تنزيل تفاصيل الفواتير بنجاح");
//     } catch (e, stacktrace) {
//       print("❌ General error in downloadAndSaveOrderItems: $e");
//       print(stacktrace);
//       Fluttertoast.showToast(msg: "حدث خطأ أثناء تحميل تفاصيل الفواتير");
//     }
//   }
// }
