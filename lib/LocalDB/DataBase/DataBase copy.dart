// // CartDatabaseHelper (lossless migrations)
// // - Safe, transactional schema upgrades
// // - No data loss (no drops). Adds missing tables/columns. Optional indexes.
// // - Foreign keys enforced. Safe DEFAULTS for NOT NULL adds.

// import 'dart:async';
// import 'dart:io';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';

// // Your models
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
// import '../Models/CartModel.dart';

// class CartDatabaseHelper {
//   static final CartDatabaseHelper _instance = CartDatabaseHelper._internal();
//   factory CartDatabaseHelper() => _instance;
//   CartDatabaseHelper._internal();

//   static const int dbVersion = 37;
//   static Database? _database;

//   Future<Database?> get database async {
//     if (_database != null) return _database;
//     _database = await _initDatabase();
//     return _database;
//   }

//   Future<Database> _initDatabase() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, 'quds.db');

//     return await openDatabase(
//       path,
//       version: dbVersion,
//       onCreate: _createDb,
//       onUpgrade: _onUpgrade,
//     );
//   }

//   // ---------------------- MIGRATION CORE ---------------------- //

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     await db.transaction((txn) async {
//       await _ensureTablesAndColumns(txn, expectedSchemas);

//       // —— versioned, idempotent extras —— //
//       if (oldVersion < 35) {
//         await _createIndexes(txn);
//         // Optional: normalize boolean/text inconsistencies here.
//       }
//     });
//   }

//   /// Ensures each table exists with at least the expected columns.
//   /// If a table is missing -> CREATE TABLE. If a column is missing -> ALTER ADD COLUMN with a safe DEFAULT when NOT NULL.
//   Future<void> _ensureTablesAndColumns(
//     DatabaseExecutor db,
//     Map<String, Map<String, String>> schemas,
//   ) async {
//     for (final table in schemas.entries) {
//       final tableName = table.key;
//       final expectedColumns = table.value;

//       final exists = await _tableExists(db, tableName);
//       if (!exists) {
//         final createSql = _buildCreateTableSQL(tableName, expectedColumns);
//         await db.execute(createSql);
//         // ignore: avoid_print
//         print('🆕 Created table `$tableName`');
//         continue;
//       }

//       // Table exists → add any missing columns safely
//       final existingCols = await _getExistingColumns(db, tableName);
//       for (final col in expectedColumns.entries) {
//         final colName = col.key;
//         final rawSpec = col.value.trim();
//         if (!existingCols.contains(colName)) {
//           final safeSpec = _withSafeDefault(rawSpec);
//           await db
//               .execute('ALTER TABLE $tableName ADD COLUMN $colName $safeSpec');
//           // ignore: avoid_print
//           print(
//               '✅ Added column `$colName` to `$tableName` with spec: $safeSpec');
//         }
//       }
//     }
//   }

//   Future<bool> _tableExists(DatabaseExecutor db, String table) async {
//     final res = await db.rawQuery(
//       "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
//       [table],
//     );
//     return res.isNotEmpty;
//   }

//   Future<Set<String>> _getExistingColumns(
//       DatabaseExecutor db, String table) async {
//     final info = await db.rawQuery('PRAGMA table_info($table)');
//     return info.map((row) => (row['name'] as String)).toSet();
//   }

//   String _buildCreateTableSQL(String table, Map<String, String> columns) {
//     final defs = columns.entries
//         .map((e) => '${e.key} ${_withSafeDefault(e.value)}')
//         .join(', ');
//     return 'CREATE TABLE $table ($defs)';
//   }

//   /// Appends a DEFAULT literal when spec has NOT NULL but no DEFAULT, so ALTER ADD COLUMN succeeds on non-empty tables.
//   String _withSafeDefault(String spec) {
//     final s = spec.trim();
//     final hasDefault = RegExp(r'\bDEFAULT\b', caseSensitive: false).hasMatch(s);
//     final isNotNull =
//         RegExp(r'\bNOT\s+NULL\b', caseSensitive: false).hasMatch(s);
//     if (!isNotNull || hasDefault) return s;

//     final upper = s.toUpperCase();
//     String defaultLit;
//     if (upper.contains('TEXT')) {
//       defaultLit = "DEFAULT ''";
//     } else if (upper.contains('REAL') || upper.contains('DOUBLE')) {
//       defaultLit = 'DEFAULT 0.0';
//     } else if (upper.contains('INTEGER')) {
//       defaultLit = 'DEFAULT 0';
//     } else {
//       defaultLit = "DEFAULT ''";
//     }
//     return '$s $defaultLit';
//   }

//   /// For breaking changes (remove/rename columns, change PK), use: rename → recreate → copy → drop old.
//   Future<void> _recreateTableKeepingData(
//     DatabaseExecutor db, {
//     required String table,
//     required Map<String, String> newSchema,
//     required List<String> copyColumns,
//   }) async {
//     final temp = '${table}_old';
//     await db.execute('ALTER TABLE $table RENAME TO $temp');
//     await db.execute(_buildCreateTableSQL(table, newSchema));
//     final colsList = copyColumns.map((c) => '"$c"').join(', ');
//     await db
//         .execute('INSERT INTO $table ($colsList) SELECT $colsList FROM $temp');
//     await db.execute('DROP TABLE $temp');
//   }

//   Future<void> _createIndexes(DatabaseExecutor db) async {
//     // Hot paths
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)');
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_order_items_vansale_order_id ON order_items_vansale(order_id)');
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_catch_checks_receiptId ON catch_receipt_checks(receiptId)');
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_catch_checks_vansale_receiptId ON catch_receipt_checks_vansale(receiptId)');
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_products_vansale_barcode ON products_vansale(product_barcode)');
//     await db.execute(
//         'CREATE INDEX IF NOT EXISTS idx_products_quds_barcode ON products_quds(product_barcode)');

//     // Guard against dup IDs since those tables use TEXT ids without PKs
//     await db.execute(
//         'CREATE UNIQUE INDEX IF NOT EXISTS idx_products_vansale_id ON products_vansale(id)');
//     await db.execute(
//         'CREATE UNIQUE INDEX IF NOT EXISTS idx_products_quds_id ON products_quds(id)');
//     await db.execute(
//         'CREATE UNIQUE INDEX IF NOT EXISTS idx_products_images_id ON products_images(id)');
//   }

//   // ---------------------- EXPECTED SCHEMAS ---------------------- //

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
//       'quantityexists': 'REAL NOT NULL', // use REAL consistently
//       'price': 'REAL NOT NULL',
//       'quantity': 'REAL NOT NULL',
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
//       'isUploaded':
//           'TEXT', // keep as TEXT for now (backfill later if you standardize)
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
//       'productUnit': 'TEXT DEFAULT ""',
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
//       'productUnit': 'TEXT DEFAULT ""',
//     },
//     'products_images': {
//       'id': 'TEXT NOT NULL',
//       'productImage': 'TEXT NOT NULL',
//       'company_id': 'INTEGER NOT NULL', // ⬅️ keep INTEGER (was mismatched)
//     },
//     // ---- Added missing tables so upgrades from old versions don't skip them ----
//     'orders_archive': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'customer_id': 'TEXT',
//       'user_id': 'TEXT',
//       'store_id': 'TEXT',
//       'total_amount': 'REAL',
//       'discount': 'REAL',
//       'cash_paid': 'REAL',
//       'order_date': 'TEXT',
//       'order_time': 'TEXT',
//       'deliveryDate': 'TEXT',
//       'status': "TEXT DEFAULT 'pending'",
//     },
//     'order_items_archive': {
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
//     },
//     'orders_vansale_archive': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'fatora_number': 'TEXT',
//       'customer_id': 'TEXT',
//       'user_id': 'TEXT',
//       'store_id': 'TEXT',
//       'latitude': 'TEXT',
//       'longitude': 'TEXT',
//       'total_amount': 'REAL',
//       'discount': 'REAL',
//       'cash_paid': 'REAL',
//       'order_date': 'TEXT',
//       'cash': 'TEXT',
//       'deliveryDate': 'TEXT',
//       'order_time': 'TEXT',
//       'status': "TEXT DEFAULT 'pending'",
//     },
//     'order_items_vansale_archive': {
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
//     },
//     'prices': {
//       'id': 'INTEGER NOT NULL',
//       'product_id': 'TEXT NOT NULL',
//       'price_code': 'TEXT NOT NULL',
//       'price': 'TEXT NOT NULL', // keep TEXT as per your create
//       'company_id': 'INTEGER NOT NULL',
//     },
//     'categories': {
//       'id': 'INTEGER NOT NULL',
//       'name': 'TEXT NOT NULL',
//       'company_id': 'INTEGER NOT NULL',
//       'salesman_id': 'INTEGER NOT NULL',
//     },
//     'last_prices': {
//       'id': 'INTEGER PRIMARY KEY',
//       'company_id': 'TEXT NOT NULL',
//       'product_id': 'TEXT NOT NULL',
//       'customer_id': 'TEXT NOT NULL',
//       'price': 'REAL',
//     },
//     'catch_receipts': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'customerID': 'TEXT NOT NULL',
//       'customerName': 'TEXT NOT NULL',
//       'cashAmount': 'REAL NOT NULL',
//       'discount': 'REAL NOT NULL',
//       'totalChecks': 'REAL NOT NULL',
//       'finalTotal': 'REAL NOT NULL',
//       'notes': 'TEXT NOT NULL',
//       'qType': 'TEXT NOT NULL',
//       'date': 'TEXT NOT NULL',
//       'time': 'TEXT NOT NULL',
//       'downloaded': 'INTEGER NOT NULL',
//       'isUploaded': 'INTEGER NOT NULL DEFAULT 0',
//     },
//     'catch_receipt_checks': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'receiptId': 'INTEGER NOT NULL',
//       'checkNumber': 'TEXT NOT NULL',
//       'checkValue': 'REAL NOT NULL',
//       'checkDate': 'TEXT NOT NULL',
//       'bankNumber': 'TEXT NOT NULL',
//       'accountNumber': 'TEXT NOT NULL',
//     },
//     'catch_receipts_vansale': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'customerID': 'TEXT NOT NULL',
//       'customerName': 'TEXT NOT NULL',
//       'cashAmount': 'REAL NOT NULL',
//       'discount': 'REAL NOT NULL',
//       'totalChecks': 'REAL NOT NULL',
//       'finalTotal': 'REAL NOT NULL',
//       'notes': 'TEXT NOT NULL',
//       'qType': 'TEXT NOT NULL',
//       'date': 'TEXT NOT NULL',
//       'time': 'TEXT NOT NULL',
//       'isUploaded': 'INTEGER NOT NULL DEFAULT 0',
//     },
//     'catch_receipt_checks_vansale': {
//       'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
//       'receiptId': 'INTEGER NOT NULL',
//       'checkNumber': 'TEXT NOT NULL',
//       'checkValue': 'REAL NOT NULL',
//       'checkDate': 'TEXT NOT NULL',
//       'bankNumber': 'TEXT NOT NULL',
//       'accountNumber': 'TEXT NOT NULL',
//     },
//   };

//   // ---------------------- onCreate ---------------------- //

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
//         quantityexists REAL NOT NULL,
//         price REAL NOT NULL,
//         quantity REAL NOT NULL,
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
//       CREATE TABLE IF NOT EXISTS catch_receipts (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         customerID TEXT NOT NULL,
//         customerName TEXT NOT NULL,
//         cashAmount REAL NOT NULL,
//         discount REAL NOT NULL,
//         totalChecks REAL NOT NULL,
//         finalTotal REAL NOT NULL,
//         notes TEXT NOT NULL,
//         qType TEXT NOT NULL,
//         date TEXT NOT NULL,
//         time TEXT NOT NULL,
//         downloaded INTEGER NOT NULL,
//         isUploaded INTEGER NOT NULL DEFAULT 0
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS catch_receipt_checks (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         receiptId INTEGER NOT NULL,
//         checkNumber TEXT NOT NULL,
//         checkValue REAL NOT NULL,
//         checkDate TEXT NOT NULL,
//         bankNumber TEXT NOT NULL,
//         accountNumber TEXT NOT NULL,
//         FOREIGN KEY (receiptId) REFERENCES catch_receipts(id) ON DELETE CASCADE
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS catch_receipts_vansale (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         customerID TEXT NOT NULL,
//         customerName TEXT NOT NULL,
//         cashAmount REAL NOT NULL,
//         discount REAL NOT NULL,
//         totalChecks REAL NOT NULL,
//         finalTotal REAL NOT NULL,
//         notes TEXT NOT NULL,
//         qType TEXT NOT NULL,
//         date TEXT NOT NULL,
//         time TEXT NOT NULL,
//         isUploaded INTEGER NOT NULL DEFAULT 0
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS catch_receipt_checks_vansale (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         receiptId INTEGER NOT NULL,
//         checkNumber TEXT NOT NULL,
//         checkValue REAL NOT NULL,
//         checkDate TEXT NOT NULL,
//         bankNumber TEXT NOT NULL,
//         accountNumber TEXT NOT NULL,
//         FOREIGN KEY (receiptId) REFERENCES catch_receipts(id) ON DELETE CASCADE
//       )
//     ''');

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
//         productUnit TEXT DEFAULT ''
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE products_images (
//         id TEXT NOT NULL,
//         productImage TEXT NOT NULL,
//         company_id INTEGER NOT NULL
//       )
//     ''');

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
//         productUnit TEXT DEFAULT ''
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE prices (
//         id INTEGER NOT NULL,
//         product_id TEXT NOT NULL,
//         price_code TEXT NOT NULL,
//         price TEXT NOT NULL,
//         company_id INTEGER NOT NULL
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE categories (
//         id INTEGER NOT NULL,
//         name TEXT NOT NULL,
//         company_id INTEGER NOT NULL,
//         salesman_id INTEGER NOT NULL
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS last_prices (
//         id INTEGER PRIMARY KEY,
//         company_id TEXT NOT NULL,
//         product_id TEXT NOT NULL,
//         customer_id TEXT NOT NULL,
//         price REAL
//       );
//     ''');

//     // Indexes
//     await _createIndexes(db);
//   }

//   // ---------------------- CRUD & HELPERS ---------------------- //

//   Future<void> updatePrintedStatusForOrderVansale(
//       int orderId, String printedStatus) async {
//     final db = await database;
//     await db!.update('orders_vansale', {'printed': printedStatus},
//         where: 'id = ?', whereArgs: [orderId]);
//   }

//   Future<String?> getMaxFatoraNumber() async {
//     final db = await database;
//     final result = await db!.query('maxFatoraNumber', limit: 1);
//     if (result.isNotEmpty) return result.first['maxFatoraNumber']?.toString();
//     return null;
//   }

//   Future<void> updateMaxFatoraNumber(String newNumber) async {
//     final db = await database;
//     await db!.delete('maxFatoraNumber');
//     await db.insert('maxFatoraNumber', {'maxFatoraNumber': newNumber});
//   }

//   // Accept int or String productId safely
//   Future<double> getProductStock(dynamic productId) async {
//     final db = await database;
//     final id = productId.toString();
//     final result = await db!
//         .query('products_vansale', where: 'id = ?', whereArgs: [id], limit: 1);
//     if (result.isNotEmpty) {
//       final raw = result.first['quantity'];
//       if (raw is num) return raw.toDouble();
//       if (raw is String) return double.tryParse(raw) ?? 0.0;
//     }
//     return 0.0;
//   }

//   Future<void> updateProductStock(dynamic productId, double newQuantity) async {
//     final db = await database;
//     final id = productId.toString();
//     await db!.update('products_vansale', {'quantity': newQuantity},
//         where: 'id = ?', whereArgs: [id]);
//   }

//   Future<int> insertOrder(OrderModel order) async {
//     final db = await database;
//     return await db!.insert('orders', order.toJson());
//   }

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

//   Future<int> deleteOrder(int orderId) async {
//     final db = await database;
//     return await db!.delete('orders', where: 'id = ?', whereArgs: [orderId]);
//   }

//   Future<void> clearOrders() async {
//     final db = await database;
//     await db!.delete('order_items');
//     await db.delete('orders');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
//     final db = await database;
//     return await db!
//         .query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItems() async {
//     final db = await database;
//     return await db!.query('order_items');
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsVansale() async {
//     final db = await database;
//     return await db!.query('order_items_vansale');
//   }

//   Future<int> insertOrderArchive(OrderArchiveModel order) async {
//     final db = await database;
//     return await db!.insert('orders_archive', order.toJson());
//   }

//   Future<void> insertOrderItemsArchive(
//       int orderId, List<OrderItemArchiveModel> items) async {
//     final db = await database;
//     for (var item in items) {
//       item.orderId = orderId;
//       await db!.insert('order_items_archive', item.toJson());
//     }
//   }

//   Future<List<Map<String, dynamic>>> getUnUploadedOrders() async {
//     final db = await database;
//     return await db!.query('orders', where: 'isUploaded = ?', whereArgs: [0]);
//   }

//   Future<int> deleteOrderArchive(int orderId) async {
//     final db = await database;
//     return await db!
//         .delete('orders_archive', where: 'id = ?', whereArgs: [orderId]);
//   }

//   Future<void> clearOrdersArchive() async {
//     final db = await database;
//     await db!.delete('order_items_archive');
//     await db.delete('orders_archive');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsArchive(int orderId) async {
//     final db = await database;
//     return await db!.query('order_items_archive',
//         where: 'order_id = ?', whereArgs: [orderId]);
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsArchive() async {
//     final db = await database;
//     return await db!.query('order_items_archive');
//   }

//   Future<List<Map<String, dynamic>>> getAllOrderItemsVansaleArchive() async {
//     final db = await database;
//     return await db!.query('order_items_vansale_archive');
//   }

//   Future<int> insertOrderVansale(OrderVansaleModel order) async {
//     final db = await database;
//     return await db!.insert('orders_vansale', order.toJson());
//   }

//   Future<int> insertOrderVansaleArchive(OrderVansaleArchiveModel order) async {
//     final db = await database;
//     return await db!.insert('orders_vansale_archive', order.toJson());
//   }

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

//   Future<List<Map<String, dynamic>>> getPendingOrdersVansale() async {
//     final db = await database;
//     return await db!.query('orders_vansale');
//   }

//   Future<int> deleteOrderVansale(int orderId) async {
//     final db = await database;
//     return await db!
//         .delete('orders_vansale', where: 'id = ?', whereArgs: [orderId]);
//   }

//   Future<void> clearOrdersVansale() async {
//     final db = await database;
//     await db!.delete('order_items_vansale');
//     await db.delete('orders_vansale');
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsVansale(int orderId) async {
//     final db = await database;
//     return await db!.query('order_items_vansale',
//         where: 'order_id = ?', whereArgs: [orderId]);
//   }

//   Future<List<Map<String, dynamic>>> getOrderItemsQuds(int orderId) async {
//     final db = await database;
//     return await db!
//         .query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
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
//     final maps = await db!.query('catch_receipt_checks',
//         where: 'receiptId = ?', whereArgs: [receiptId]);
//     return List.generate(maps.length, (i) => CheckModel.fromJson(maps[i]));
//   }

//   Future<List<CatchModel>> getUnuploadedCatchReceipts() async {
//     final db = await database;
//     final maps = await db!
//         .query('catch_receipts', where: 'isUploaded = ?', whereArgs: [0]);
//     return List.generate(
//         maps.length, (i) => CatchModel.fromDatabaseJson(maps[i]));
//   }

//   Future<List<CatchVansaleModel>> getUnuploadedCatchReceiptsVansale() async {
//     final db = await database;
//     final maps = await db!.query('catch_receipts_vansale');
//     return List.generate(
//         maps.length, (i) => CatchVansaleModel.fromDatabaseJson(maps[i]));
//   }

//   Future<List<CatchModel>> getAllCatchReceipts() async {
//     final db = await database;
//     final maps = await db!.query('catch_receipts');
//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'] as int?,
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
//         isUploaded: (maps[i]['isUploaded'] ?? 0) as int,
//         downloaded: (maps[i]['downloaded'] ?? 0) as int,
//       );
//     });
//   }

//   Future<List<CatchModel>> getCatchReceiptsByDateRange(
//       String startDate, String endDate) async {
//     final db = await database;
//     final maps = await db!.query('catch_receipts',
//         where: 'date BETWEEN ? AND ?', whereArgs: [startDate, endDate]);
//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'] as int?,
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount'] ?? '0.0'),
//         totalChecks: _convertToDouble(maps[i]['totalChecks'] ?? '0.0'),
//         discount: _convertToDouble(maps[i]['discount'] ?? '0.0'),
//         finalTotal: _convertToDouble(maps[i]['cashAmount'] ?? '0.0') +
//             _convertToDouble(maps[i]['totalChecks'] ?? '0.0') -
//             _convertToDouble(maps[i]['discount'] ?? '0.0'),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: (maps[i]['isUploaded'] ?? 0) as int,
//         downloaded: (maps[i]['downloaded'] ?? 0) as int,
//       );
//     });
//   }

//   Future<List<CatchModel>> getCatchReceiptsSarfsByDateRange(
//       String startDate, String endDate) async {
//     final db = await database;
//     final maps = await db!.query(
//       'catch_receipts',
//       where: 'date BETWEEN ? AND ? AND qType = ?',
//       whereArgs: [startDate, endDate, 'sarf'],
//     );
//     return List.generate(maps.length, (i) {
//       return CatchModel(
//         id: maps[i]['id'] as int?,
//         customerID: maps[i]['customerID']?.toString() ?? '',
//         customerName: maps[i]['customerName']?.toString() ?? '-',
//         cashAmount: _convertToDouble(maps[i]['cashAmount'] ?? '0.0'),
//         totalChecks: _convertToDouble(maps[i]['totalChecks'] ?? '0.0'),
//         discount: _convertToDouble(maps[i]['discount'] ?? '0.0'),
//         finalTotal: _convertToDouble(maps[i]['cashAmount'] ?? '0.0') +
//             _convertToDouble(maps[i]['totalChecks'] ?? '0.0') -
//             _convertToDouble(maps[i]['discount'] ?? '0.0'),
//         notes: maps[i]['notes']?.toString() ?? '',
//         qType: maps[i]['qType']?.toString() ?? '',
//         date: maps[i]['date']?.toString() ?? '',
//         time: maps[i]['time']?.toString() ?? '',
//         isUploaded: (maps[i]['isUploaded'] ?? 0) as int,
//         downloaded: (maps[i]['downloaded'] ?? 0) as int,
//       );
//     });
//   }

//   Future<List<CatchVansaleModel>> getAllCatchReceiptsVansale() async {
//     final db = await database;
//     final maps = await db!.query('catch_receipts_vansale');
//     return List.generate(maps.length, (i) {
//       return CatchVansaleModel(
//         id: maps[i]['id'] as int?,
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
//         isUploaded: (maps[i]['isUploaded'] ?? 0) as int,
//       );
//     });
//   }

//   static double _convertToDouble(dynamic value) {
//     if (value == null) return 0.0;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }

//   Future<List<CatchModel>> getCatchReceipts() async {
//     final db = await database;
//     final maps = await db!
//         .query('catch_receipts', where: 'qType = ?', whereArgs: ['qabd']);
//     return List.generate(maps.length, (i) => CatchModel.fromJson(maps[i]));
//   }

//   Future<List<CatchVansaleModel>> getCatchReceiptsVansale() async {
//     final db = await database;
//     final maps = await db!.query('catch_receipts_vansale',
//         where: 'qType = ?', whereArgs: ['qabd']);
//     return List.generate(
//         maps.length, (i) => CatchVansaleModel.fromDatabaseJson(maps[i]));
//   }

//   Future<List<Map<String, dynamic>>> getCheckDataByReceiptId(
//       int receiptId) async {
//     final db = await database;
//     return await db!.query('catch_receipt_checks',
//         where: 'receiptId = ?', whereArgs: [receiptId]);
//   }

//   Future<List<Map<String, dynamic>>> getCheckDataByReceiptIdVansale(
//       int receiptId) async {
//     final db = await database;
//     return await db!.query('catch_receipt_checks_vansale',
//         where: 'receiptId = ?', whereArgs: [receiptId]);
//   }

//   Future<void> clearCatchReceipts() async {
//     final db = await database;
//     await db!.delete('catch_receipt_checks');
//     await db!.delete('catch_receipts');
//   }

//   Future<void> clearCatchReceiptsVansale() async {
//     final db = await database;
//     await db!.delete('catch_receipt_checks_vansale');
//     await db!.delete('catch_receipts_vansale');
//   }

//   Future<int> insertCatchReceipt(CatchModel receipt) async {
//     final db = await database;
//     return await db!.insert('catch_receipts', receipt.toJson());
//   }

//   Future<int> insertCatchReceiptVansale(CatchVansaleModel receipt) async {
//     final db = await database;
//     return await db!.insert('catch_receipts_vansale', receipt.toJson());
//   }

//   Future<void> markCatchReceiptAsUploaded(int id) async {
//     final db = await database;
//     await db!.update('catch_receipts', {'isUploaded': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }

//   Future<void> deleteUploadedCatchReceipts() async {
//     final db = await database;
//     await db!.delete('catch_receipts', where: 'isUploaded = 1');
//   }

//   Future<void> clearCart() async {
//     final db = await database;
//     await db!.delete('cart');
//   }

//   Future<int> insertCartItem(CartItem item) async {
//     final db = await database;
//     return await db!.insert('cart', item.toJson());
//   }

//   Future<List<CartItem>> getCartItems() async {
//     final db = await database;
//     final maps = await db!.query('cart');
//     return List.generate(maps.length, (i) => CartItem.fromJson(maps[i]));
//   }

//   Future<void> deleteCartItem(int id) async {
//     final db = await database;
//     await db!.delete('cart', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<void> updateCartItem(CartItem item) async {
//     final db = await database;
//     await db!
//         .update('cart', item.toJson(), where: 'id = ?', whereArgs: [item.id]);
//   }

//   Future<void> updateProductVansaleItem(ProductVansale item) async {
//     final db = await database;
//     await db!.update('products_vansale', item.toJson(),
//         where: 'id = ?', whereArgs: [item.id]);
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

// // ---------------------- OPTIONAL: Move migrator to a mixin ---------------------- //
// // If you want to reuse the migration helpers in other DB helpers, you can
// // move _ensureTablesAndColumns / _withSafeDefault / _buildCreateTableSQL /
// // _tableExists / _getExistingColumns / _recreateTableKeepingData / _createIndexes
// // into a separate file (e.g., lib/LocalDB/db_migration_utils.dart) as a mixin:
// /*
// // lib/LocalDB/db_migration_utils.dart
// mixin DbMigrationUtils {
//   Future<void> ensureTablesAndColumns(DatabaseExecutor db, Map<String, Map<String, String>> schemas) async { /* ... */ }
//   String withSafeDefault(String spec) { /* ... */ }
//   String buildCreateTableSQL(String table, Map<String, String> columns) { /* ... */ }
//   Future<bool> tableExists(DatabaseExecutor db, String table) async { /* ... */ }
//   Future<Set<String>> getExistingColumns(DatabaseExecutor db, String table) async { /* ... */ }
//   Future<void> recreateTableKeepingData(DatabaseExecutor db, { required String table, required Map<String, String> newSchema, required List<String> copyColumns, }) async { /* ... */ }
//   Future<void> createIndexes(DatabaseExecutor db) async { /* ... */ }
// }

// // Then in your helper: class CartDatabaseHelper with DbMigrationUtils { ... }
// */
