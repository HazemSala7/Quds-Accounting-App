// import 'dart:async';
// import 'dart:io';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/category-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/check-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-archive-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-archive-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-vansale-archive-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-item-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-vansale-archive-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/order-vansale-model.dart';
// import 'package:quds_yaghmour/LocalDB/Models/product-model-vansale.dart';
// import 'package:sqflite/sqflite.dart';
// import '../Models/CartModel.dart';

// class CartDatabaseHelper {
//   static final CartDatabaseHelper _instance = CartDatabaseHelper._internal();
//   static final int dbVersion = 34;

//   factory CartDatabaseHelper() => _instance;

//   CartDatabaseHelper._internal();

//   static Database? _database;

//   Future<Database?> get database async {
//     if (_database != null) return _database;

//     _database = await _initDatabase();
//     return _database;
//   }

//   Future<CartItem?> getCartItemByProductId(int productId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'cart',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );

//     if (maps.isEmpty) {
//       return null;
//     }

//     return CartItem.fromJson(maps.first);
//   }

//   Future<ProductVansale?> getProductVansaleItemByProductId(
//       int productId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'products_vansale',
//       where: 'id = ?',
//       whereArgs: [productId],
//     );

//     if (maps.isEmpty) {
//       return null;
//     }

//     return ProductVansale.fromJson(maps.first);
//   }

//   Future<Database> _initDatabase() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, 'quds.db');

//     return await openDatabase(
//       path,
//       version: dbVersion,
//       onUpgrade: _onUpgrade,
//       onCreate: _createDb,
//     );
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     await _autoUpgradeTables(db, expectedSchemas);
//   }

//   final Map<String, Map<String, String>> expectedSchemas = {
//     'cart': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'productId': 'TEXT NOT NULL',
//       'notes': 'TEXT NOT NULL',
//       'name': 'TEXT NOT NULL',
//       'productBarcode': 'TEXT NOT NULL',
//       'image': 'TEXT NOT NULL',
//       'color': 'TEXT NOT NULL',
//       'colorsNames': 'TEXT NOT NULL',
//       'quantityexists': 'DOUBLE NOT NULL',
//       'price': 'REAL NOT NULL',
//       'quantity': 'DOUBLE NOT NULL',
//       'ponus1': 'INTEGER NOT NULL',
//       'ponus2': 'INTEGER NOT NULL',
//       'discount': 'REAL NOT NULL',
//     },
//     'maxFatoraNumber': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'maxFatoraNumber': 'TEXT NOT NULL',
//     },
//     'orders': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'customer_id': 'TEXT',
//       'customerName': 'TEXT',
//       'user_id': 'TEXT',
//       'fatora_number': 'TEXT',
//       'store_id': 'TEXT',
//       'total_amount': 'REAL',
//       'discount': 'REAL',
//       'cash_paid': 'REAL',
//       'order_date': 'TEXT',
//       'order_time': 'TEXT',
//       'deliveryDate': 'TEXT',
//       'isUploaded': 'TEXT',
//       'status': "TEXT DEFAULT 'pending'",
//     },
//     'order_items': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'order_id': 'INTEGER',
//       'product_id': 'TEXT',
//       'product_name': 'TEXT',
//       'bonus1': 'TEXT',
//       'bonus2': 'TEXT',
//       'quantity': 'REAL',
//       'price': 'REAL',
//       'discount': 'REAL',
//       'total': 'REAL',
//       'color': 'TEXT',
//       'barcode': 'TEXT',
//       'isUploaded': 'TEXT',
//     },
//     'orders_vansale': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'fatora_number': 'TEXT',
//       'customer_id': 'TEXT',
//       'user_id': 'TEXT',
//       'customerName': 'TEXT',
//       'store_id': 'TEXT',
//       'latitude': 'TEXT',
//       'longitude': 'TEXT',
//       'total_amount': 'REAL',
//       'discount': 'REAL',
//       'cash_paid': 'REAL',
//       'order_date': 'TEXT',
//       'deliveryDate': 'TEXT',
//       'order_time': 'TEXT',
//       'cash': 'TEXT',
//       'printed': 'TEXT',
//       'isUploaded': 'TEXT',
//       'status': "TEXT DEFAULT 'pending'",
//     },
//     'order_items_vansale': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'order_id': 'INTEGER',
//       'product_id': 'TEXT',
//       'product_name': 'TEXT',
//       'bonus1': 'TEXT',
//       'bonus2': 'TEXT',
//       'quantity': 'REAL',
//       'price': 'REAL',
//       'discount': 'REAL',
//       'total': 'REAL',
//       'color': 'TEXT',
//       'barcode': 'TEXT',
//       'isUploaded': 'TEXT',
//     },
//     'products_quds': {
//       'id': 'TEXT NOT NULL',
//       'p_name': 'TEXT NOT NULL',
//       'company_id': 'TEXT NOT NULL',
//       'images': 'TEXT NOT NULL',
//       'description': 'TEXT NOT NULL',
//       'quantity': 'TEXT NOT NULL',
//       'category_id': 'INTEGER NOT NULL',
//       'product_barcode': 'TEXT NOT NULL',
//       'productUnit': 'TEXT DEFAULT ""'
//     },
//     'products_vansale': {
//       'id': 'TEXT NOT NULL',
//       'p_name': 'TEXT NOT NULL',
//       'company_id': 'TEXT NOT NULL',
//       'salesman_id': 'TEXT NOT NULL',
//       'images': 'TEXT NOT NULL',
//       'description': 'TEXT NOT NULL',
//       'quantity': 'TEXT NOT NULL',
//       'productPaidQty': 'TEXT NOT NULL',
//       'product_barcode': 'TEXT NOT NULL',
//       'productUnit': 'TEXT DEFAULT ""'
//     },
//     'products_images': {
//       'id': 'TEXT NOT NULL',
//       'productImage': 'TEXT NOT NULL',
//       'company_id': 'TEXT NOT NULL'
//     },
//   };

//   Future<void> _autoUpgradeTables(
//       Database db, Map<String, Map<String, String>> schemas) async {
//     for (final table in schemas.entries) {
//       final tableName = table.key;
//       final expectedColumns = table.value;

//       final result = await db.rawQuery("PRAGMA table_info($tableName)");
//       final existingColumns =
//           result.map((row) => row['name'] as String).toSet();

//       for (final column in expectedColumns.entries) {
//         if (!existingColumns.contains(column.key)) {
//           await db.execute(
//               "ALTER TABLE $tableName ADD COLUMN ${column.key} ${column.value}");
//           print("✅ Added column `${column.key}` to table `$tableName`");
//         }
//       }
//     }
//   }

//   Future<void> _createDb(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE cart (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         productId TEXT NOT NULL,
//         notes TEXT NOT NULL,
//         name TEXT NOT NULL,
//         productBarcode TEXT NOT NULL,
//         image TEXT NOT NULL,
//         color TEXT NOT NULL,
//         colorsNames TEXT NOT NULL,
//         quantityexists DOUBLE  NOT NULL,
//         price REAL NOT NULL,
//         quantity DOUBLE  NOT NULL,
//         ponus1 INTEGER NOT NULL,
//         ponus2 INTEGER NOT NULL,
//         discount REAL NOT NULL
//       )
//     ''');
//     await db.execute('''
//       CREATE TABLE maxFatoraNumber (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         maxFatoraNumber TEXT NOT NULL
//       )
//     ''');
//     await db.execute('''
//       CREATE TABLE orders (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         customer_id TEXT,
//         customerName TEXT,
//         user_id TEXT,
//         fatora_number TEXT,
//         store_id TEXT,
//         total_amount REAL,
//         discount REAL,
//         cash_paid REAL,
//         order_date TEXT,
//         order_time TEXT,
//         deliveryDate TEXT,
//         isUploaded TEXT,
//         status TEXT DEFAULT 'pending'
//       )
//     ''');

//     // ✅ Create Order Items Table (Cart Items)
//     await db.execute('''
//       CREATE TABLE order_items (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         order_id INTEGER,
//         product_id TEXT,
//         product_name TEXT,
//         bonus1 TEXT,
//         bonus2 TEXT,
//         quantity REAL,
//         price REAL,
//         discount REAL,
//         total REAL,
//         color TEXT,
//         barcode TEXT,
//         isUploaded TEXT,
//         FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE orders_archive (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         customer_id TEXT,
//         user_id TEXT,
//         store_id TEXT,
//         total_amount REAL,
//         discount REAL,
//         cash_paid REAL,
//         order_date TEXT,
//         order_time TEXT,
//         deliveryDate TEXT,
//         status TEXT DEFAULT 'pending'
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE order_items_archive (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         order_id INTEGER,
//         product_id TEXT,
//         product_name TEXT,
//         bonus1 TEXT,
//         bonus2 TEXT,
//         quantity REAL,
//         price REAL,
//         discount REAL,
//         total REAL,
//         color TEXT,
//         barcode TEXT,
//         FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
//       )
//     ''');
//     await db.execute('''
//       CREATE TABLE orders_vansale (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         fatora_number TEXT,
//         customer_id TEXT,
//         user_id TEXT,
//         customerName TEXT,
//         store_id TEXT,
//         latitude TEXT,
//         longitude TEXT,
//         total_amount REAL,
//         discount REAL,
//         cash_paid REAL,
//         order_date TEXT,
//         deliveryDate TEXT,
//         order_time TEXT,
//         cash TEXT,
//         printed TEXT,
//         isUploaded TEXT,
//         status TEXT DEFAULT 'pending'
//       )
//     ''');

//     // ✅ Create Order Items Table (Cart Items)
//     await db.execute('''
//       CREATE TABLE order_items_vansale (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         order_id INTEGER,
//         product_id TEXT,
//         product_name TEXT,
//         bonus1 TEXT,
//         bonus2 TEXT,
//         quantity REAL,
//         price REAL,
//         discount REAL,
//         total REAL,
//         color TEXT,
//         barcode TEXT,
//         isUploaded TEXT,
//         FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
//       )
//     ''');
//     await db.execute('''
//       CREATE TABLE orders_vansale_archive (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         fatora_number TEXT,
//         customer_id TEXT,
//         user_id TEXT,
//         store_id TEXT,
//         latitude TEXT,
//         longitude TEXT,
//         total_amount REAL,
//         discount REAL,
//         cash_paid REAL,
//         order_date TEXT,
//         cash TEXT,
//         deliveryDate TEXT,
//         order_time TEXT,
//         status TEXT DEFAULT 'pending'
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE order_items_vansale_archive (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         order_id INTEGER,
//         product_id TEXT,
//         product_name TEXT,
//         bonus1 TEXT,
//         bonus2 TEXT,
//         quantity REAL,
//         price REAL,
//         discount REAL,
//         total REAL,
//         color TEXT,
//         barcode TEXT,
//         FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
//       )
//     ''');
//     await db.execute('''
//   CREATE TABLE IF NOT EXISTS catch_receipts (
//     id INTEGER PRIMARY KEY AUTOINCREMENT,
//     customerID TEXT NOT NULL,
//     customerName TEXT NOT NULL,
//     cashAmount REAL NOT NULL,
//     discount REAL NOT NULL,
//     totalChecks REAL NOT NULL,
//     finalTotal REAL NOT NULL,
//     notes TEXT NOT NULL,
//     qType TEXT NOT NULL,
//     date TEXT NOT NULL,
//     time TEXT NOT NULL,
//     downloaded INTEGER NOT NULL,
//     isUploaded INTEGER NOT NULL DEFAULT 0
//   )
// ''');
//     await db.execute('''
//   CREATE TABLE IF NOT EXISTS catch_receipt_checks (
//     id INTEGER PRIMARY KEY AUTOINCREMENT,
//     receiptId INTEGER NOT NULL,
//     checkNumber TEXT NOT NULL,
//     checkValue REAL NOT NULL,
//     checkDate TEXT NOT NULL,
//     bankNumber TEXT NOT NULL,
//     accountNumber TEXT NOT NULL,
//     FOREIGN KEY (receiptId) REFERENCES catch_receipts(id) ON DELETE CASCADE
//   )
// ''');
//     await db.execute('''
//   CREATE TABLE IF NOT EXISTS catch_receipts_vansale (
//     id INTEGER PRIMARY KEY AUTOINCREMENT,
//     customerID TEXT NOT NULL,
//     customerName TEXT NOT NULL,
//     cashAmount REAL NOT NULL,
//     discount REAL NOT NULL,
//     totalChecks REAL NOT NULL,
//     finalTotal REAL NOT NULL,
//     notes TEXT NOT NULL,
//     qType TEXT NOT NULL,
//     date TEXT NOT NULL,
//     time TEXT NOT NULL,
//     isUploaded INTEGER NOT NULL DEFAULT 0
//   )
// ''');
//     await db.execute('''
//   CREATE TABLE IF NOT EXISTS catch_receipt_checks_vansale (
//     id INTEGER PRIMARY KEY AUTOINCREMENT,
//     receiptId INTEGER NOT NULL,
//     checkNumber TEXT NOT NULL,
//     checkValue REAL NOT NULL,
//     checkDate TEXT NOT NULL,
//     bankNumber TEXT NOT NULL,
//     accountNumber TEXT NOT NULL,
//     FOREIGN KEY (receiptId) REFERENCES catch_receipts(id) ON DELETE CASCADE
//   )
// ''');

//     await db.execute('''
//       CREATE TABLE products_quds (
//         id TEXT NOT NULL,
//         p_name TEXT NOT NULL,
//         company_id TEXT NOT NULL,
//         images TEXT NOT NULL,
//         description TEXT NOT NULL,
//         quantity TEXT NOT NULL,
//         category_id INTEGER NOT NULL,
//         product_barcode TEXT NOT NULL,
//         productUnit TEXT DEFAULT ""
//       )
//   ''');
//     await db.execute('''
//       CREATE TABLE products_images (
//         id TEXT NOT NULL,
//         productImage TEXT NOT NULL,
//         company_id INTEGER NOT NULL
//       )
//   ''');

//     await db.execute('''
//       CREATE TABLE products_vansale (
//         id TEXT NOT NULL,
//         p_name TEXT NOT NULL,
//         company_id TEXT NOT NULL,
//         salesman_id TEXT NOT NULL,
//         images TEXT NOT NULL,
//         description TEXT NOT NULL,
//         quantity TEXT NOT NULL,
//         productPaidQty TEXT NOT NULL,
//         product_barcode TEXT NOT NULL,
//         productUnit TEXT DEFAULT ""
//       )
//   ''');

//     await db.execute('''
//     CREATE TABLE prices (
//       id INTEGER NOT NULL,
//       product_id TEXT NOT NULL,
//       price_code TEXT NOT NULL,
//       price TEXT NOT NULL,
//       company_id INTEGER NOT NULL
//     )
//   ''');

//     await db.execute('''
//     CREATE TABLE categories (
//       id INTEGER NOT NULL,
//       name TEXT NOT NULL,
//       company_id INTEGER NOT NULL,
//       salesman_id INTEGER NOT NULL
//     )
//   ''');

//     await db.execute('''
//     CREATE TABLE IF NOT EXISTS last_prices (
//       id INTEGER PRIMARY KEY,
//       company_id TEXT NOT NULL,
//       product_id TEXT NOT NULL,
//       customer_id TEXT NOT NULL,
//       price REAL
//   );
//   ''');
//   }

//   Future<void> updatePrintedStatusForOrderVansale(
//       int orderId, String printedStatus) async {
//     final db = await database;
//     await db!.update(
//       'orders_vansale',
//       {'printed': printedStatus},
//       where: 'id = ?',
//       whereArgs: [orderId],
//     );
//   }

//   Future<String?> getMaxFatoraNumber() async {
//     final db = await database;
//     final result = await db!.query('maxFatoraNumber', limit: 1);
//     if (result.isNotEmpty) {
//       return result.first['maxFatoraNumber']?.toString();
//     }
//     return null;
//   }

//   Future<void> updateMaxFatoraNumber(String newNumber) async {
//     final db = await database;

//     // Clear old value (if any)
//     await db!.delete('maxFatoraNumber');

//     // Insert new value
//     await db.insert('maxFatoraNumber', {
//       'maxFatoraNumber': newNumber,
//     });
//   }

//   Future<double> getProductStock(int productId) async {
//     final db = await database;
//     List<Map<String, dynamic>> result = await db!.query(
//       'products_vansale',
//       where: 'id = ?',
//       whereArgs: [productId],
//       limit: 1,
//     );

//     if (result.isNotEmpty) {
//       var rawQuantity = result.first['quantity'];

//       if (rawQuantity is num) {
//         return rawQuantity.toDouble();
//       } else if (rawQuantity is String) {
//         return double.tryParse(rawQuantity) ?? 0.0;
//       } else {
//         return 0.0;
//       }
//     } else {
//       return 0.0;
//     }
//   }

//   Future<void> updateProductStock(int productId, double newQuantity) async {
//     final db = await database;
//     await db!.update(
//       'products_vansale',
//       {'quantity': newQuantity},
//       where: 'id = ?',
//       whereArgs: [productId],
//     );
//   }

//   // ✅ Insert Order and Get order_id
//   Future<int> insertOrder(OrderModel order) async {
//     final db = await database;
//     return await db!.insert('orders', order.toJson());
//   }

//   // ✅ Insert Order Items (Cart Items) with order_id
//   Future<void> insertOrderItems(int orderId, List<OrderItemModel> items) async {
//     final db = await database;
//     for (var item in items) {
//       await db!.insert('order_items', item.toJson());
//     }
//   }

//   Future<List<Map<String, dynamic>>> getPendingOrders() async {
//     final db = await database;
//     return await db!.query('orders');
//   }

//   // ✅ Delete Order & Its Items
//   Future<int> deleteOrder(int orderId) async {
//     final db = await database;
//     return await db!.delete('orders', where: "id = ?", whereArgs: [orderId]);
//   }

//   Future<void> clearOrders() async {
//     final db = await database;
//     await db!.delete('order_items');
//     await db.delete('orders');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
//     final db = await database;
//     return await db!.query(
//       'order_items',
//       where: 'order_id = ?',
//       whereArgs: [orderId],
//     );
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItems() async {
//     final db = await database;
//     return await db!.query(
//       'order_items',
//     );
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsVansale() async {
//     final db = await database;
//     return await db!.query(
//       'order_items_vansale',
//     );
//   }

//   // For Archive Orders
//   Future<int> insertOrderArchive(OrderArchiveModel order) async {
//     final db = await database;
//     return await db!.insert('orders_archive', order.toJson());
//   }

//   // ✅ Insert Order Items (Cart Items) with order_id
//   Future<void> insertOrderItemsArchive(
//       int orderId, List<OrderItemArchiveModel> items) async {
//     final db = await database;
//     for (var item in items) {
//       item.orderId = orderId; // Assign order_id
//       await db!.insert('order_items_archive', item.toJson());
//     }
//   }

//   Future<List<Map<String, dynamic>>> getUnUploadedOrders() async {
//     final db = await database;
//     return await db!.query(
//       'orders',
//       where: 'isUploaded = ?',
//       whereArgs: [0],
//     );
//   }

//   // ✅ Delete Order & Its Items
//   Future<int> deleteOrderArchive(int orderId) async {
//     final db = await database;
//     return await db!
//         .delete('orders_archive', where: "id = ?", whereArgs: [orderId]);
//   }

//   Future<void> clearOrdersArchive() async {
//     final db = await database;
//     await db!.delete('order_items_archive');
//     await db.delete('orders_archive');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsArchive(int orderId) async {
//     final db = await database;
//     return await db!.query(
//       'order_items_archive',
//       where: 'order_id = ?',
//       whereArgs: [orderId],
//     );
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsArchive() async {
//     final db = await database;
//     return await db!.query(
//       'order_items_archive',
//     );
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsVansaleArchive() async {
//     final db = await database;
//     return await db!.query(
//       'order_items_vansale_archive',
//     );
//   }
//   // For Archive Orders

//   // ✅ Insert Order and Get order_id
//   Future<int> insertOrderVansale(OrderVansaleModel order) async {
//     final db = await database;
//     return await db!.insert('orders_vansale', order.toJson());
//   }

//   Future<int> insertOrderVansaleArchive(OrderVansaleArchiveModel order) async {
//     final db = await database;
//     return await db!.insert('orders_vansale_archive', order.toJson());
//   }

//   // ✅ Insert Order Items (Cart Items) with order_id
//   Future<void> insertOrderItemsVansale(
//       int orderId, List<OrderItemVansaleModel> items) async {
//     final db = await database;
//     for (var item in items) {
//       item.orderId = orderId;
//       await db!.insert('order_items_vansale', item.toJson());
//     }
//   }

//   Future<void> insertOrderItemsVansaleArchive(
//       int orderId, List<OrderItemVansaleArchiveModel> items) async {
//     final db = await database;
//     for (var item in items) {
//       item.orderId = orderId;
//       await db!.insert('order_items_vansale_archive', item.toJson());
//     }
//   }

//   // ✅ Fetch Orders with Their Items
//   Future<List<Map<String, dynamic>>> getPendingOrdersVansale() async {
//     final db = await database;
//     return await db!.query('orders_vansale');
//   }

//   // ✅ Delete Order & Its Items
//   Future<int> deleteOrderVansale(int orderId) async {
//     final db = await database;
//     return await db!
//         .delete('orders_vansale', where: "id = ?", whereArgs: [orderId]);
//   }

//   Future<void> clearOrdersVansale() async {
//     final db = await database;
//     await db!.delete('order_items_vansale');
//     await db.delete('orders_vansale');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsVansale(int orderId) async {
//     final db = await database;
//     return await db!.query(
//       'order_items_vansale',
//       where: 'order_id = ?',
//       whereArgs: [orderId],
//     );
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsQuds(int orderId) async {
//     final db = await database;
//     return await db!.query(
//       'order_items',
//       where: 'order_id = ?',
//       whereArgs: [orderId],
//     );
//   }

//   Future<void> insertCheck(CheckModel check) async {
//     final db = await database;
//     await db!.insert('catch_receipt_checks', check.toJson());
//   }

//   Future<void> insertCheckVansale(CheckVansaleModel check) async {
//     final db = await database;
//     await db!.insert('catch_receipt_checks_vansale', check.toJson());
//   }

//   Future<List<CheckModel>> getChecksByReceiptId(int receiptId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipt_checks',
//       where: 'receiptId = ?',
//       whereArgs: [receiptId],
//     );

//     return List.generate(maps.length, (i) => CheckModel.fromJson(maps[i]));
//   }

//   Future<List<CatchModel>> getUnuploadedCatchReceipts() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts',
//       where: 'isUploaded = ?',
//       whereArgs: [0],
//     );
//     return List.generate(maps.length, (i) {
//       return CatchModel.fromDatabaseJson(maps[i]);
//     });
//   }

//   Future<List<CatchVansaleModel>> getUnuploadedCatchReceiptsVansale() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts_vansale',
//     );
//     return List.generate(maps.length, (i) {
//       return CatchVansaleModel.fromDatabaseJson(maps[i]);
//     });
//   }

//   Future<List<CatchModel>> getAllCatchReceipts() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query('catch_receipts');
//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'],
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount']),
//         totalChecks: _convertToDouble(maps[i]['totalChecks']),
//         discount: _convertToDouble(maps[i]['discount']),
//         finalTotal: _convertToDouble(maps[i]['cashAmount']) +
//             _convertToDouble(maps[i]['totalChecks']) -
//             _convertToDouble(maps[i]['discount']),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: maps[i]['isUploaded'] ?? 0,
//         downloaded: maps[i]['downloaded'] ?? 0,
//       );
//     });
//   }

//   Future<List<CatchModel>> getCatchReceiptsByDateRange(
//       String startDate, String endDate) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts',
//       where: "date BETWEEN ? AND ?",
//       whereArgs: [startDate, endDate],
//     );

//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'],
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount'] ?? "0.0"),
//         totalChecks: _convertToDouble(maps[i]['totalChecks'] ?? "0.0"),
//         discount: _convertToDouble(maps[i]['discount'] ?? "0.0"),
//         finalTotal: _convertToDouble(maps[i]['cashAmount'] ?? "0.0") +
//             _convertToDouble(maps[i]['totalChecks'] ?? "0.0") -
//             _convertToDouble(maps[i]['discount'] ?? "0.0"),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: maps[i]['isUploaded'] ?? 0,
//         downloaded: maps[i]['downloaded'] ?? 0,
//       );
//     });
//   }

//   Future<List<CatchModel>> getCatchReceiptsSarfsByDateRange(
//       String startDate, String endDate) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts',
//       where: "date BETWEEN ? AND ? AND qType = ?",
//       whereArgs: [startDate, endDate, 'sarf'],
//     );

//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'],
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount'] ?? "0.0"),
//         totalChecks: _convertToDouble(maps[i]['totalChecks'] ?? "0.0"),
//         discount: _convertToDouble(maps[i]['discount'] ?? "0.0"),
//         finalTotal: _convertToDouble(maps[i]['cashAmount'] ?? "0.0") +
//             _convertToDouble(maps[i]['totalChecks'] ?? "0.0") -
//             _convertToDouble(maps[i]['discount'] ?? "0.0"),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: maps[i]['isUploaded'] ?? 0,
//         downloaded: maps[i]['downloaded'] ?? 0,
//       );
//     });
//   }

//   Future<List<CatchVansaleModel>> getAllCatchReceiptsVansale() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps =
//         await db!.query('catch_receipts_vansale');
//     return List.generate(maps.length, (i) {
//       return CatchVansaleModel(
//         id: maps[i]['id'],
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount']),
//         totalChecks: _convertToDouble(maps[i]['totalChecks']),
//         discount: _convertToDouble(maps[i]['discount']),
//         finalTotal: _convertToDouble(maps[i]['cashAmount']) +
//             _convertToDouble(maps[i]['totalChecks']) -
//             _convertToDouble(maps[i]['discount']),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: maps[i]['isUploaded'] ?? 0,
//       );
//     });
//   }

//   static double _convertToDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       return double.tryParse(value) ?? 0.0;
//     }
//     return 0.0;
//   }

//   Future<List<CatchModel>> getCatchReceipts() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts',
//       where: 'qType = ?',
//       whereArgs: ['qabd'],
//     );
//     return List.generate(maps.length, (i) => CatchModel.fromJson(maps[i]));
//   }

//   Future<List<CatchVansaleModel>> getCatchReceiptsVansale() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query(
//       'catch_receipts_vansale',
//       where: 'qType = ?',
//       whereArgs: ['qabd'],
//     );
//     return List.generate(
//         maps.length, (i) => CatchVansaleModel.fromDatabaseJson(maps[i]));
//   }

//   /// ✅ Get check data for a receipt Quds
//   Future<List<Map<String, dynamic>>> getCheckDataByReceiptId(
//       int receiptId) async {
//     final db = await database;
//     return await db!.query(
//       'catch_receipt_checks',
//       where: 'receiptId = ?',
//       whereArgs: [receiptId],
//     );
//   }

//   /// ✅ Get check data for a receipt Vansale
//   Future<List<Map<String, dynamic>>> getCheckDataByReceiptIdVansale(
//       int receiptId) async {
//     final db = await database;
//     return await db!.query(
//       'catch_receipt_checks_vansale',
//       where: 'receiptId = ?',
//       whereArgs: [receiptId],
//     );
//   }

//   /// ✅ Clear all receipts after syncing
//   Future<void> clearCatchReceipts() async {
//     final db = await database;
//     await db!.delete('catch_receipt_checks');
//     await db!.delete('catch_receipts');
//   }

//   /// ✅ Clear all receipts after syncing
//   Future<void> clearCatchReceiptsVansale() async {
//     final db = await database;
//     await db!.delete('catch_receipt_checks_vansale');
//     await db!.delete('catch_receipts_vansale');
//   }

//   // Insert a new Catch Receipt when offline
//   Future<int> insertCatchReceipt(CatchModel receipt) async {
//     final db = await database;
//     return await db!.insert('catch_receipts', receipt.toJson());
//   }

//   // Insert a new Catch Receipt Vansake when offline
//   Future<int> insertCatchReceiptVansale(CatchVansaleModel receipt) async {
//     final db = await database;
//     return await db!.insert('catch_receipts_vansale', receipt.toJson());
//   }

// // Mark Catch Receipt as uploaded
//   Future<void> markCatchReceiptAsUploaded(int id) async {
//     final db = await database;
//     await db!.update('catch_receipts', {'isUploaded': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }

// // Clear all uploaded receipts from local database
//   Future<void> deleteUploadedCatchReceipts() async {
//     final db = await database;
//     await db!.delete('catch_receipts', where: 'isUploaded = 1');
//   }

//   // Method to clear the cart database
//   Future<void> clearCart() async {
//     final db = await database;
//     await db!.delete('cart'); // Delete all records from the 'cart' table
//   }

//   Future<int> insertCartItem(CartItem item) async {
//     final db = await database;
//     return await db!.insert('cart', item.toJson());
//   }

//   Future<List<CartItem>> getCartItems() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db!.query('cart');
//     return List.generate(
//       maps.length,
//       (i) => CartItem.fromJson(maps[i]),
//     );
//   }

//   Future<void> deleteCartItem(int id) async {
//     final db = await database;
//     await db!.delete('cart', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<void> updateCartItem(CartItem item) async {
//     final db = await database;
//     await db!.update(
//       'cart',
//       item.toJson(),
//       where: 'id = ?',
//       whereArgs: [item.id],
//     );
//   }

//   Future<void> updateProductVansaleItem(ProductVansale item) async {
//     final db = await database;
//     await db!.update(
//       'products_vansale',
//       item.toJson(),
//       where: 'id = ?',
//       whereArgs: [item.id],
//     );
//   }

//   Future<int> insertCategory(Category category) async {
//     final db = await database;
//     return await db!.insert('categories', category.toJson());
//   }

//   Future<List<Map<String, dynamic>>> getCategories() async {
//     final db = await database;
//     return await db!.query('categories');
//   }

//   Future<List<Map<String, dynamic>>> getProductsVansale() async {
//     final db = await database;
//     return await db!.query('products_vansale');
//   }

//   Future<List<Map<String, dynamic>>> getProductsQuds() async {
//     final db = await database;
//     return await db!.query('products_quds');
//   }

//   Future<List<Map<String, dynamic>>> getPrices() async {
//     final db = await database; 
//     return await db!.query('prices');
//   }

//   Future<List<Map<String, dynamic>>> getLastPrices() async {
//     final db = await database;
//     return await db!.query('last_prices');
//   }

//   Future<void> clearCategories() async {
//     final db = await database;
//     await db!.delete('categories');
//   }
// }
