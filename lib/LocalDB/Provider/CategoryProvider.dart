// import 'package:flutter/material.dart';
// import 'package:quds_yaghmour/LocalDB/Models/category-model.dart';
// import '../DataBase/DataBase.dart';

// class CategoryProvider extends ChangeNotifier {
//   List<Category> _categories = [];
//   CartDatabaseHelper _dbHelper = CartDatabaseHelper();

//   List<Category> get categories => _categories;

//   CategoryProvider() {
//     _init();
//   }

//   Future<void> _init() async {
//     _categories = await _dbHelper.getCategories();
//     notifyListeners();
//   }

//   Future<void> addCategory(Category category) async {
//     await _dbHelper.insertCategory(category);
//     _categories = await _dbHelper.getCategories(); // Refresh categories
//     notifyListeners();
//   }

//   Future<void> clearCategories() async {
//     await _dbHelper.clearCategories();
//     _categories.clear();
//     notifyListeners();
//   }
// }
