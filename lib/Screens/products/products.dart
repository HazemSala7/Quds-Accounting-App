import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/CartModel.dart';
import 'package:quds_yaghmour/LocalDB/Provider/CartProvider.dart';
import 'package:quds_yaghmour/Screens/add_product/add_product.dart';
import 'package:quds_yaghmour/Screens/show_order/show_order.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/components/product-widget-quds/product-widget-quds.dart';
import 'package:quds_yaghmour/components/product-widget-vansale/product-widget-vansale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';
import '../../Services/Drawer/drawer.dart';

class Products extends StatefulWidget {
  final id, name, category_id, type;
  Products({Key? key, this.id, this.name, this.category_id, required this.type})
      : super(key: key);

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  List<TextEditingController> priceControllers = [];
  List<TextEditingController> qtyControllers = [];
  List<TextEditingController> bonusControllers = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _showMicOverlay = false;

// For scrolling to found product
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _itemKeys = {};

  var categories;
  int selectedCategoryIndex = 0;
  int selectedCategoryId = 0;
  bool search = false;
  bool _hasMoreOfflineData = true;
  bool _isLoadingMoreOffline = false;
  bool isOnline = false;
  int _page = 1;
  String type = "";
  final int _limit = 20;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = false;
  bool _isLoadMoreRunning = false;
  List _posts = [];
  var PRODUCTS = [];
  List prices = [];
  TextEditingController idController = TextEditingController();
  var final_product = [];
  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
          child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Scaffold(
            key: _scaffoldState,
            drawer: DrawerMain(),
            appBar: PreferredSize(
                child: AppBarBack(
                  title: "المنتجات",
                ),
                preferredSize: Size.fromHeight(50)),
            body: _isFirstLoadRunning
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        topMethod(),
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: SpinKitPulse(
                            color: Main_Color,
                            size: 60,
                          ),
                        ),
                      ],
                    ),
                  )
                : isOnline
                    ? Column(
                        children: [
                          topMethod(),
                          categoriesMethod(),
                          SizedBox(
                            height: 10,
                          ),
                          productStyleTwo
                              ? Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 150),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Table(
                                          border: TableBorder.all(
                                              color: Colors.grey.shade400,
                                              width: 1),
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          columnWidths: const {
                                            0: FixedColumnWidth(180),
                                            1: FixedColumnWidth(90),
                                            2: FixedColumnWidth(90),
                                            3: FixedColumnWidth(90),
                                            4: FixedColumnWidth(100),
                                            5: FixedColumnWidth(100),
                                          },
                                          children: [
                                            // Header Row
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade300),
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("الاسم",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("المتوفر",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("الكمية",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("السعر",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("بونص",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("المجموع",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                              ],
                                            ),
                                            ...List.generate(
                                              (_posts.length ==
                                                          priceControllers
                                                              .length &&
                                                      _posts.length ==
                                                          qtyControllers
                                                              .length &&
                                                      _posts.length ==
                                                          bonusControllers
                                                              .length)
                                                  ? _posts.length
                                                  : 0,
                                              (index) => _buildStyledRow(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    child: GridView.builder(
                                        cacheExtent: 150,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisSpacing: 5,
                                          childAspectRatio:
                                              productImage ? 0.7 : 1.6,
                                          mainAxisSpacing: 0,
                                          crossAxisCount: 2,
                                        ),
                                        controller: _controller,
                                        // ignore: unnecessary_null_comparison
                                        itemCount:
                                            _posts != null ? _posts.length : 0,
                                        itemBuilder: (_, int index) {
                                          return widget.type == "quds"
                                              ? ProductCardQuds(
                                                  packingNumber: _posts[index]
                                                          ['Package_num'] ??
                                                      "",
                                                  packingPrice: _posts[index]
                                                          ['Package_price'] ??
                                                      "",
                                                  product_colors: _posts[index]
                                                          ['product_colors'] ??
                                                      [],
                                                  customer_id:
                                                      widget.id.toString(),
                                                  price: _posts[index]
                                                          ['price'] ??
                                                      "-",
                                                  productUnit: _posts[index]
                                                          ['unit'] ??
                                                      "-",
                                                  name: _posts[index]
                                                          ['p_name'] ??
                                                      "-",
                                                  desc: _posts[index]
                                                          ['description'] ??
                                                      "-",
                                                  id: _posts[index]['id'],
                                                  qty: _posts[index]
                                                          ['quantity'] ??
                                                      "0",
                                                  image: _posts[index]
                                                          ['images'] ??
                                                      "-",
                                                )
                                              : ProductCardVansale(
                                                  customer_id:
                                                      widget.id.toString(),
                                                  price: _posts[index]
                                                          ['price'] ??
                                                      "-",
                                                  productUnit: _posts[index]
                                                          ['unit'] ??
                                                      "-",
                                                  name: _posts[index]
                                                          ['p_name'] ??
                                                      "-",
                                                  desc: _posts[index]
                                                          ['description'] ??
                                                      "-",
                                                  id: _posts[index]
                                                      ['product_id'],
                                                  qty: _posts[index]
                                                          ['quantity'] ??
                                                      "0",
                                                  image: _posts[index]
                                                          ['images'] ??
                                                      "-",
                                                );
                                        }),
                                  ),
                                ),
                          if (_isLoadMoreRunning == true)
                            const Padding(
                              padding: EdgeInsets.only(top: 10, bottom: 100),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          topMethod(),
                          categoriesMethod(),
                          SizedBox(
                            height: 10,
                          ),
                          productStyleTwo
                              ? Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Table(
                                          border: TableBorder.all(
                                              color: Colors.grey.shade400,
                                              width: 1),
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          columnWidths: const {
                                            0: FixedColumnWidth(180),
                                            1: FixedColumnWidth(90),
                                            2: FixedColumnWidth(90),
                                            3: FixedColumnWidth(90),
                                            4: FixedColumnWidth(100),
                                            5: FixedColumnWidth(100),
                                          },
                                          children: [
                                            // Header Row
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade300),
                                              children: const [
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("الاسم",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("المتوفر",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("الكمية",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("السعر",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("بونص",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text("المجموع",
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                              ],
                                            ),
                                            ...List.generate(
                                              (_posts.length ==
                                                          priceControllers
                                                              .length &&
                                                      _posts.length ==
                                                          qtyControllers
                                                              .length &&
                                                      _posts.length ==
                                                          bonusControllers
                                                              .length)
                                                  ? _posts.length
                                                  : 0,
                                              (index) => _buildStyledRow(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 120),
                                    child: GridView.builder(
                                        cacheExtent: 500,
                                        controller: _controller,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisSpacing: 5,
                                          childAspectRatio:
                                              productImage ? 0.7 : 1.4,
                                          mainAxisSpacing: 0,
                                          crossAxisCount: 2,
                                        ),
                                        itemCount:
                                            _posts != null ? _posts.length : 0,
                                        itemBuilder: (_, int index) {
                                          return widget.type == "quds"
                                              ? ProductCardQuds(
                                                  productUnit: _posts[index]
                                                          ['productUnit'] ??
                                                      "-",
                                                  packingNumber: _posts[index]
                                                          ['Package_num'] ??
                                                      "",
                                                  packingPrice: _posts[index]
                                                          ['Package_price'] ??
                                                      "",
                                                  product_colors: _posts[index]
                                                          ['product_colors'] ??
                                                      [],
                                                  customer_id:
                                                      widget.id.toString(),
                                                  price: _posts[index]
                                                          ['price'] ??
                                                      "-",
                                                  name: _posts[index]
                                                          ['p_name'] ??
                                                      "-",
                                                  desc: _posts[index]
                                                          ['description'] ??
                                                      "-",
                                                  id: _posts[index]['id'],
                                                  qty: _posts[index]
                                                          ['quantity'] ??
                                                      "0",
                                                  image: _posts[index]
                                                          ['images'] ??
                                                      "-",
                                                )
                                              : ProductCardVansale(
                                                  productUnit: _posts[index]
                                                          ['productUnit'] ??
                                                      "-",
                                                  customer_id:
                                                      widget.id.toString(),
                                                  price: _posts[index]
                                                          ['price'] ??
                                                      "-",
                                                  name: _posts[index]
                                                          ['p_name'] ??
                                                      "-",
                                                  desc: _posts[index]
                                                          ['description'] ??
                                                      "-",
                                                  id: _posts[index]['id'],
                                                  qty: _posts[index]
                                                          ['quantity'] ??
                                                      "0",
                                                  image: _posts[index]
                                                          ['images'] ??
                                                      "-",
                                                );
                                        }),
                                  ),
                                ),
                          if (_isLoadMoreRunning == true ||
                              _isLoadingMoreOffline)
                            const Padding(
                              padding: EdgeInsets.only(top: 10, bottom: 100),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
          ),
          _showOrderWidget(),
          if (_showMicOverlay)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.redAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "جاري الاستماع... قل: افتح [اسم المنتج]",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }

  double _calculateTotal() {
    double total = 0.0;
    for (int i = 0; i < _posts.length; i++) {
      final price = double.tryParse(priceControllers[i].text) ?? 0.0;
      final qty = double.tryParse(qtyControllers[i].text) ?? 0.0;
      final bonus = int.tryParse(bonusControllers[i].text) ?? 0;
      total += (price * qty) + bonus;
    }
    return total;
  }

  DataRow _buildDataRow(int index) {
    var product = _posts[index];

    TextEditingController priceController =
        TextEditingController(text: product['price'].toString());
    TextEditingController qtyController = TextEditingController(text: "0");
    TextEditingController bonusController =
        TextEditingController(text: (product['bonus'] ?? '0').toString());

    double getTotal() {
      double price = double.tryParse(priceController.text) ?? 0;
      int qty = int.tryParse(qtyController.text) ?? 0;
      int bonus = int.tryParse(bonusController.text) ?? 0;
      return price * qty + bonus;
    }

    return DataRow(cells: [
      DataCell(Text(
        product['p_name'].toString().length > 20
            ? product['p_name'].toString().substring(0, 20) + '...'
            : product['p_name'].toString(),
      )),
      DataCell(
        SizedBox(
          width: 60,
          child: TextField(
            controller: priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {}); // to update total
            },
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 60,
          child: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() {}); // to update total
            },
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 60,
          child: TextField(
            controller: bonusController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() {}); // to update total
            },
          ),
        ),
      ),
      DataCell(Text(getTotal().toStringAsFixed(1))),
    ]);
  }

  TableRow _buildStyledRow(int index) {
    var product = _posts[index];
    final priceController = priceControllers[index];
    final qtyController = qtyControllers[index];
    final bonusController = bonusControllers[index];
    double getTotal() {
      double price = double.tryParse(priceController.text) ?? 0;
      int qty = int.tryParse(qtyController.text) ?? 0; // ✅ safer
      int bonus = int.tryParse(bonusController.text) ?? 0;
      return price * qty + bonus;
    }

    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Tooltip(
          message: product['p_name'].toString(),
          child: Text(
            product['p_name'].toString().length > 20
                ? product['p_name'].toString().substring(0, 20) + '...'
                : product['p_name'].toString(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          product['quantity']?.toString() ?? '-', // or product['qty_exist']
          textAlign: TextAlign.center,
        ),
      ),
      _styledCell(qtyController),
      _styledCell(priceController),
      _styledCell(bonusController),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(getTotal().toStringAsFixed(1), textAlign: TextAlign.center),
      ),
    ]);
  }

  Widget _styledCell(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Editable field background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.shade300, // Highlight editable
            width: 1.2,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            isDense: true,
            hintText: 'قابل للتعديل',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  double calculateTotal(List<CartItem> cartItems) {
    double total = 0;
    for (CartItem item in cartItems) {
      double subTotal = 0.0;
      if (item.discount == 0.0) {
        subTotal = item.price * item.quantity;
      } else {
        subTotal = double.parse(item.quantity.toString()) *
            double.parse(item.price.toString()) *
            (1 - (double.parse(item.discount.toString()) / 100));
      }
      total += subTotal;
    }
    return total;
  }

  Widget _showOrderWidget() {
    // If you prefer not to watch the whole provider, you can wrap only the total row with Consumer.
    final cartProvider = Provider.of<CartProvider>(context, listen: true);
    final double cartTotal = calculateTotal(cartProvider.cartItems);

    return Material(
      child: Container(
        width: double.infinity,
        height:
            productStyleTwo ? 150 : 140, // a bit taller to fit the total row
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 199, 199, 199)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer name
              Row(
                children: [
                  const Text(
                    "أسم الزبون : ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      widget.name.length > 25
                          ? '${widget.name.substring(0, 25)}...'
                          : widget.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Main_Color,
                      ),
                    ),
                  ),
                ],
              ),

              // Cart total (from CartProvider) — show it for both styles if you want.
              Visibility(
                visible: !productStyleTwo,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      const Text(
                        "مجموع الفاتورة:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "₪${cartTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Main_Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action button (kept the same logic you had)
              productStyleTwo
                  ? Consumer<CartProvider>(
                      builder: (context, cartProvider, _) => InkWell(
                        onTap: () {
                          // Keep your "save order" behavior that adds current screen inputs to the cart:
                          for (int i = 0; i < _posts.length; i++) {
                            final qty =
                                int.tryParse(qtyControllers[i].text) ?? 0;
                            if (qty > 0) {
                              final item = CartItem(
                                productBarcode: "",
                                quantityexists: double.tryParse(
                                      _posts[i]['quantityexists'].toString(),
                                    ) ??
                                    0,
                                productId: _posts[i]['id'].toString(),
                                color: "",
                                colorsNames: const [],
                                name: _posts[i]['p_name'].toString(),
                                image: _posts[i]['images'].toString(),
                                notes: "-",
                                price:
                                    double.tryParse(priceControllers[i].text) ??
                                        0.0,
                                discount: 0.0,
                                quantity:
                                    double.tryParse(qty.toString()) ?? 0.0,
                                ponus1: bonusControllers[i].text ?? "0",
                                ponus2: "0",
                              );
                              cartProvider.addToCart(item);
                            }
                          }

                          Fluttertoast.showToast(
                            msg: "تم حفظ الطلبية بنجاح",
                            backgroundColor: Colors.green,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowOrder(
                                id: widget.id,
                                name: widget.name,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(83, 89, 219, 1),
                                Color.fromRGBO(32, 39, 160, 0.6),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "حفظ الطلبية",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowOrder(
                                id: widget.id,
                                name: widget.name,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(83, 89, 219, 1),
                                Color.fromRGBO(32, 39, 160, 0.6),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type.toString() == "quds"
                                  ? "عرض الطلبية"
                                  : "عرض الفاتورة",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoriesMethod() {
    return Visibility(
      visible: type.toString() == "quds" &&
          categories != null &&
          categories.length != 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, right: 10),
        child: Container(
          height: 35,
          width: double.infinity,
          child: ListView.builder(
            itemCount: categories?.length ?? 0,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(right: 5, left: 5),
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      selectedCategoryId = categories[index]['id'];
                      selectedCategoryIndex = index;
                      _hasNextPage = true;
                    });

                    if (isOnline) {
                      if (index == 0) {
                        setState(() {
                          _posts = [];
                          _page = 1;
                          selectedCategoryIndex = 0;
                          selectedCategoryId = 0;
                        });
                        _firstLoad();
                      } else {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        int? company_id = prefs.getInt('company_id');
                        int? salesman_id = prefs.getInt('salesman_id');
                        String? code_price = prefs.getString('price_code');

                        setState(() {
                          _posts = [];
                          _page = 1;
                        });

                        var url =
                            "${AppLink.productsByCategoryID}/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}/${selectedCategoryId}?page=$_page";

                        final res = await http.get(Uri.parse(url));
                        setState(() {
                          _posts = json.decode(res.body)["products"]["data"];
                        });
                      }
                    } else {
                      if (index == 0) {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        int? company_id = prefs.getInt('company_id');
                        setState(() {
                          _posts = [];
                        });
                        // Fetch products from local database
                        CartDatabaseHelper _dbHelper = CartDatabaseHelper();
                        List<Map<String, dynamic>> localProducts =
                            await _dbHelper.getProductsQuds();

                        List<Map<String, dynamic>> localPrices =
                            await _dbHelper.getPrices();
                        List<Map<String, dynamic>> localLastPrices =
                            await _dbHelper.getLastPrices();

                        int totalProducts = localProducts.length;
                        _page = 1; // Reset pagination

                        if (totalProducts > 50) {
                          // If more than 50 products, load the first batch
                          List<Map<String, dynamic>> initialProducts =
                              _processProducts(
                                  localProducts.sublist(0, _limit),
                                  localPrices,
                                  localLastPrices,
                                  company_id!,
                                  prefs);

                          setState(() {
                            _posts = initialProducts;
                            _hasMoreOfflineData = true; // Enable pagination
                          });
                        } else {
                          // If 50 or fewer products, load all at once
                          List<Map<String, dynamic>> allProducts =
                              _processProducts(localProducts, localPrices,
                                  localLastPrices, company_id!, prefs);

                          setState(() {
                            _posts = allProducts;
                            _hasMoreOfflineData = false; // No pagination needed
                          });
                        }
                        syncControllersWithPosts();
                      } else {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        int? company_id = prefs.getInt('company_id');
                        setState(() {
                          _posts = [];
                          _page = 1;
                        });
                        // Fetch products from local database
                        CartDatabaseHelper _dbHelper = CartDatabaseHelper();
                        List<Map<String, dynamic>> localProducts =
                            await _dbHelper.getProductsQuds();

                        // Filter only products of selected category when type is 'quds'
                        List<Map<String, dynamic>> filteredProducts =
                            localProducts.where((product) {
                          return product['category_id'] == selectedCategoryId;
                        }).toList();

                        List<Map<String, dynamic>> localPrices =
                            await _dbHelper.getPrices();
                        List<Map<String, dynamic>> localLastPrices =
                            await _dbHelper.getLastPrices();

                        int totalProducts = filteredProducts.length;

                        _page = 1; // Reset pagination

                        // If more than 50 products, load the first batch
                        List<Map<String, dynamic>> initialProducts =
                            _processProducts(
                                filteredProducts.sublist(0, totalProducts),
                                localPrices,
                                localLastPrices,
                                company_id!,
                                prefs);

                        setState(() {
                          _posts = initialProducts;
                          _hasMoreOfflineData = true; // Enable pagination
                        });

                        syncControllersWithPosts();
                      }
                    }
                  },
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 2,
                        color: selectedCategoryIndex == index
                            ? Colors.red
                            : Colors.black,
                      ),
                      color: Colors.black,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          categories[index]["name"].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget topMethod() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, top: 15),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Row(
              children: [
                // ===== Search field =====
                Expanded(
                  child: TextField(
                    controller: idController,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.start,
                    onSubmitted: (_) async {
                      if (isOnline) {
                        if (idController.text != "") {
                          searchProducts();
                        } else {
                          _firstLoad();
                        }
                      } else {
                        // OFFLINE SEARCH (same logic you already have)
                        if (_.toString().isEmpty) {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          int? company_id = prefs.getInt('company_id');
                          CartDatabaseHelper _dbHelper = CartDatabaseHelper();

                          List<Map<String, dynamic>> localProducts =
                              type.toString() == "quds"
                                  ? await _dbHelper.getProductsQuds()
                                  : await _dbHelper.getProductsVansale();

                          List<Map<String, dynamic>> localPrices =
                              await _dbHelper.getPrices();
                          List<Map<String, dynamic>> localLastPrices =
                              await _dbHelper.getLastPrices();

                          List<Map<String, dynamic>> updatedProducts = [];

                          for (final product in localProducts) {
                            Map<String, dynamic> mutableProduct =
                                Map.from(product);

                            String product_id = mutableProduct['id'].toString();
                            int customer_id = int.parse(widget.id.toString());
                            String price_code =
                                prefs.getString('price_code') ?? '';

                            // prices for this product/company
                            List<Map<String, dynamic>> prices =
                                localPrices.where((price) {
                              return price['product_id'].toString() ==
                                      product_id.toString() &&
                                  price['company_id'].toString() ==
                                      company_id.toString();
                            }).toList();

                            // last price for this product/company/customer
                            List<Map<String, dynamic>> lastPriceCheck =
                                localLastPrices.where((lastPrice) {
                              return lastPrice['product_id'].toString() ==
                                      product_id.toString() &&
                                  lastPrice['company_id'].toString() ==
                                      company_id.toString() &&
                                  lastPrice['customer_id'].toString() ==
                                      customer_id.toString();
                            }).toList();

                            if (lastPriceCheck.isEmpty) {
                              if (prices.isEmpty) {
                                mutableProduct['price'] = '0';
                              } else if (prices.length == 1) {
                                mutableProduct['price'] =
                                    prices[0]['price'].toString();
                              } else {
                                var selectedPrice = prices.firstWhere(
                                  (price) => price['price_code'] == price_code,
                                  orElse: () => {'price': '0'},
                                );
                                mutableProduct['price'] =
                                    selectedPrice['price'].toString();
                              }
                            } else {
                              mutableProduct['price'] =
                                  lastPriceCheck[0]['price'].toString();
                            }

                            mutableProduct['price'] = (double.tryParse(
                                        mutableProduct['price'].toString()) ??
                                    0.0)
                                .toStringAsFixed(1);

                            // images fix
                            if (mutableProduct['images'] != null &&
                                mutableProduct['images'].toString().length >
                                    7) {
                              mutableProduct['images'] =
                                  "https:/${mutableProduct['images'].toString().substring(7)}";
                            }

                            // category filter
                            if (selectedCategoryId == 0 ||
                                mutableProduct['category_id'] ==
                                    selectedCategoryId) {
                              updatedProducts.add(mutableProduct);
                            }
                          }

                          setState(() {
                            _posts = updatedProducts;
                          });

                          // IMPORTANT: when you change _posts, resync controllers
                          syncControllersWithPosts();
                        } else {
                          // OFFLINE SEARCH WITH TEXT FILTER
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          int? company_id = prefs.getInt('company_id');
                          CartDatabaseHelper _dbHelper = CartDatabaseHelper();

                          List<Map<String, dynamic>> localProducts =
                              type.toString() == "quds"
                                  ? await _dbHelper.getProductsQuds()
                                  : await _dbHelper.getProductsVansale();

                          List<Map<String, dynamic>> localPrices =
                              await _dbHelper.getPrices();
                          List<Map<String, dynamic>> localLastPrices =
                              await _dbHelper.getLastPrices();

                          List<Map<String, dynamic>> updatedProducts = [];

                          for (final product in localProducts) {
                            Map<String, dynamic> mutableProduct =
                                Map.from(product);

                            String product_id = mutableProduct['id'].toString();
                            int customer_id = int.parse(widget.id.toString());
                            String price_code =
                                prefs.getString('price_code') ?? '';

                            List<Map<String, dynamic>> prices =
                                localPrices.where((price) {
                              return price['product_id'].toString() ==
                                      product_id.toString() &&
                                  price['company_id'].toString() ==
                                      company_id.toString();
                            }).toList();

                            List<Map<String, dynamic>> lastPriceCheck =
                                localLastPrices.where((lastPrice) {
                              return lastPrice['product_id'].toString() ==
                                      product_id.toString() &&
                                  lastPrice['company_id'].toString() ==
                                      company_id.toString() &&
                                  lastPrice['customer_id'].toString() ==
                                      customer_id.toString();
                            }).toList();

                            if (lastPriceCheck.isEmpty) {
                              if (prices.isEmpty) {
                                mutableProduct['price'] = '0';
                              } else if (prices.length == 1) {
                                mutableProduct['price'] =
                                    prices[0]['price'].toString();
                              } else {
                                var selectedPrice = prices.firstWhere(
                                  (price) => price['price_code'] == price_code,
                                  orElse: () => {'price': '0'},
                                );
                                mutableProduct['price'] =
                                    selectedPrice['price'].toString();
                              }
                            } else {
                              mutableProduct['price'] =
                                  lastPriceCheck[0]['price'].toString();
                            }

                            mutableProduct['price'] = (double.tryParse(
                                        mutableProduct['price'].toString()) ??
                                    0.0)
                                .toStringAsFixed(1);

                            if (mutableProduct['images'] != null &&
                                mutableProduct['images'].toString().length >
                                    7) {
                              mutableProduct['images'] =
                                  "https:/${mutableProduct['images'].toString().substring(7)}";
                            }

                            if (selectedCategoryId == 0 ||
                                mutableProduct['category_id'] ==
                                    selectedCategoryId) {
                              updatedProducts.add(mutableProduct);
                            }
                          }

                          setState(() {
                            _posts = updatedProducts.where((p) {
                              final n = (p['p_name'] ?? '').toString();
                              return n
                                      .toLowerCase()
                                      .contains(_.toLowerCase()) ||
                                  n.contains(_);
                            }).toList();
                          });

                          syncControllersWithPosts();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'بحث عن أسم الصنف',
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Main_Color, width: 2.0),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(width: 2.0, color: Color(0xffD6D3D3)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ===== Mic button =====
                GestureDetector(
                  onTap: _startListeningProduct, // <-- your speech function
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(83, 89, 219, 1),
                          Color.fromRGBO(32, 39, 160, 0.6),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  searchProducts() async {
    _posts.clear();
    setState(() {
      _isFirstLoadRunning = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    try {
      var url = type.toString() == "quds"
          ? 'https://yaghm.com/admin/api/search_products/${idController.text}/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}'
          : 'https://yaghm.com/admin/api/search_products_vansale_new/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}/${idController.text}';

      var response = await http.get(Uri.parse(url));
      var res = jsonDecode(response.body)["products"];
      setState(() {
        _posts = res;
      });
      setState(() {
        _isFirstLoadRunning = false;
      });
    } catch (err) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    }
  }

  void syncControllersWithPosts() {
    priceControllers = List.generate(
      _posts.length,
      (i) => TextEditingController(text: _posts[i]['price'].toString()),
    );
    qtyControllers = List.generate(
      _posts.length,
      (i) => TextEditingController(text: "0"),
    );
    bonusControllers = List.generate(
      _posts.length,
      (i) =>
          TextEditingController(text: (_posts[i]['bonus'] ?? '0').toString()),
    );
  }

  void _firstLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    String? type = prefs.getString('type');
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      var url = type == "quds"
          ? "${AppLink.allProductsProducts}/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}?page=$_page${hideProductLessThan0 ? "&hide=hide" : ""}"
          : "https://yaghm.com/admin/api/products_vansale/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}?page=$_page";
      final res = await http.get(Uri.parse(url));
      setState(() {
        _posts = type.toString() == "quds"
            ? json.decode(res.body)["products"]["data"]
            : json.decode(res.body)["products"];
      });
      syncControllersWithPosts();
    } catch (err) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  void _loadMore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    String? userID = prefs.getString('user_id');
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller!.position.extentAfter < 100) {
      setState(() {
        _isLoadMoreRunning = true;
      });
      _page += 1;
      try {
        var url = selectedCategoryIndex == 0
            ? type.toString() == "quds"
                ? "${AppLink.allProductsProducts}/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}?page=$_page${hideProductLessThan0 ? "&hide=hide" : ""}"
                : "https://yaghm.com/admin/api/products_vansale/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}?page=$_page"
            : "${AppLink.productsByCategoryID}/${company_id.toString()}/${salesman_id.toString()}/${widget.id.toString()}/${code_price}/${selectedCategoryId}?page=$_page";
        final res = await http.get(Uri.parse(url));
        final List fetchedPosts = json.decode(res.body)["products"]["data"];
        if (fetchedPosts.isNotEmpty) {
          setState(() {
            _posts.addAll(fetchedPosts);
          });
        } else {
          setState(() {
            _hasNextPage = false;
          });
          Fluttertoast.showToast(
              msg: "جميع المنتجات تم تحميلها",
              backgroundColor: Colors.green,
              fontSize: 17);
        }
      } catch (err) {
        if (kDebugMode) {
          print('Something went wrong!');
        }
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  ScrollController? _controller;

  @override
  void dispose() {
    if (isOnline) {
      _controller
          ?.removeListener(_loadMore); // Remove online pagination listener
    } else {
      _controller?.removeListener(
          _loadMoreOffline); // Remove offline pagination listener
    }
    _controller?.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> getCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? companyId = prefs.getInt('company_id');
    bool isOnline = prefs.getBool('isOnline') ?? true;
    if (isOnline) {
      var url =
          'https://yaghm.com/admin/api/categories/${companyId.toString()}';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        setState(() {
          categories = [
            {"id": 0, "name": "جميع الأصناف"},
            ...res["categories"]
          ];
          selectedCategoryIndex = 0;
          selectedCategoryId = 0;
        });
      } else {
        throw Exception('Failed to load categories from API');
      }
    } else {
      CartDatabaseHelper _dbHelper = CartDatabaseHelper();
      List<Map<String, dynamic>> localCategories =
          await _dbHelper.getCategories();

      setState(() {
        categories = [
          {"id": 0, "name": "جميع الأصناف"},
          ...localCategories
        ];
        selectedCategoryIndex = 0;
        selectedCategoryId = 0;
      });
    }
  }

  void _loadMoreOffline() async {
    if (idController.text == "") {
      if (_hasMoreOfflineData &&
          !_isLoadingMoreOffline &&
          _controller!.position.extentAfter < 100) {
        setState(() {
          _isLoadingMoreOffline = true;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? company_id = prefs.getInt('company_id');
        CartDatabaseHelper _dbHelper = CartDatabaseHelper();
        List<Map<String, dynamic>> localProducts = type == "quds"
            ? await _dbHelper.getProductsQuds()
            : await _dbHelper.getProductsVansale();

        List<Map<String, dynamic>> localPrices = await _dbHelper.getPrices();
        List<Map<String, dynamic>> localLastPrices =
            await _dbHelper.getLastPrices();

        int startIndex = _page * _limit;
        int endIndex = startIndex + _limit;

        if (startIndex < localProducts.length) {
          List<Map<String, dynamic>> paginatedProducts = _processProducts(
              localProducts.sublist(
                  startIndex, endIndex.clamp(0, localProducts.length)),
              localPrices,
              localLastPrices,
              company_id!,
              prefs);

          setState(() {
            _posts.addAll(paginatedProducts);
            _page++;
            if (endIndex >= localProducts.length) {
              _hasMoreOfflineData = false;
            }
          });
        } else {
          setState(() {
            _hasMoreOfflineData = false;
          });
        }

        setState(() {
          _isLoadingMoreOffline = false;
        });
      }
    }
  }

  void setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    String? _type = prefs.getString('type') ?? "";
    bool _isOnline = prefs.getBool('isOnline') ?? true;

    setState(() {
      type = _type;
      isOnline = _isOnline;
    });

    if (isOnline) {
      _firstLoad();
    } else {
      // Load products from local database
      CartDatabaseHelper _dbHelper = CartDatabaseHelper();
      List<Map<String, dynamic>> localProducts = type == "quds"
          ? await _dbHelper.getProductsQuds()
          : await _dbHelper.getProductsVansale();

      List<Map<String, dynamic>> localPrices = await _dbHelper.getPrices();
      List<Map<String, dynamic>> localLastPrices =
          await _dbHelper.getLastPrices();

      int totalProducts = localProducts.length;
      _page = 1; // Reset pagination

      if (totalProducts > 50) {
        // If more than 50 products, load the first batch
        List<Map<String, dynamic>> initialProducts = _processProducts(
            localProducts.sublist(0, _limit),
            localPrices,
            localLastPrices,
            company_id!,
            prefs);

        setState(() {
          _posts = initialProducts;
          _hasMoreOfflineData = true; // Enable pagination
        });
      } else {
        // If 50 or fewer products, load all at once
        List<Map<String, dynamic>> allProducts = _processProducts(
            localProducts, localPrices, localLastPrices, company_id!, prefs);

        setState(() {
          _posts = allProducts;
          _hasMoreOfflineData = false; // No pagination needed
        });
      }
      syncControllersWithPosts();
    }
  }

  List<Map<String, dynamic>> _processProducts(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> localPrices,
    List<Map<String, dynamic>> localLastPrices,
    int company_id,
    SharedPreferences prefs,
  ) {
    final List<Map<String, dynamic>> processedProducts = [];

    final String customer_id = widget.id.toString();
    final String price_codePref = (prefs.getString('price_code') ?? '').trim();
    final String lastPriceSetting =
        (prefs.getString('last_price') ?? 'true').trim();
    final bool useLastPrice = lastPriceSetting.toLowerCase() != 'false';
    final bool hideProductLessThan0 =
        prefs.getBool('hideProductLessThan0') ?? false;

    // --- Helpers ---
    bool _eq(dynamic a, dynamic b) => a?.toString() == b?.toString();

    double _toDouble(dynamic v, {double orElse = 0.0}) {
      if (v == null) return orElse;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return orElse;
      return double.tryParse(s) ?? orElse;
    }

    // Index local prices by product for faster lookups
    final Map<String, List<Map<String, dynamic>>> pricesByProduct = {};
    for (final p in localPrices) {
      final pid = p['product_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      (pricesByProduct[pid] ??= []).add(p);
    }

    // Index last prices by product (latest first if you store many)
    final Map<String, List<Map<String, dynamic>>> lastByProduct = {};
    for (final lp in localLastPrices) {
      // mirror backend filters
      if (!_eq(lp['company_id'], company_id)) continue;
      if (!_eq(lp['customer_id'], customer_id)) continue;
      final pid = lp['product_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      (lastByProduct[pid] ??= []).add(lp);
    }

    for (final product in products) {
      final Map<String, dynamic> mutableProduct = Map.from(product);
      final String pid = mutableProduct['id']?.toString() ?? '0';

      // 🛑 Optional stock filter
      if (hideProductLessThan0) {
        final qty = _toDouble(mutableProduct['quantity']);
        if (qty <= 0) continue;
      }

      // 1) Try last price (if enabled)
      double? chosen = null;
      if (useLastPrice) {
        final lpList = lastByProduct[pid];
        if (lpList != null && lpList.isNotEmpty) {
          // Take the *latest*. If you don’t store created_at locally, at least take the first.
          // Optionally sort by created_at desc if available.
          final price = _toDouble(lpList.first['price'], orElse: 0.0);
          if (price > 0) chosen = price;
        }
      }

      // 2) If not found, try price by code
      if (chosen == null) {
        final allPrices = pricesByProduct[pid] ?? const [];
        if (allPrices.isEmpty) {
          chosen = 0.0;
        } else if (allPrices.length == 1) {
          // Mirror backend "single price" behavior
          chosen = _toDouble(allPrices.first['price'], orElse: 0.0);
        } else {
          // Multiple prices → match price_code
          final effectiveCode = price_codePref; // may be ''
          Map<String, dynamic>? selected = allPrices.firstWhere(
            (p) =>
                _eq(p['company_id'], company_id) &&
                _eq(p['product_id'], pid) &&
                _eq(p['price_code'], effectiveCode),
            orElse: () => <String, dynamic>{},
          );

          if (selected.isNotEmpty) {
            chosen = _toDouble(selected['price'], orElse: 0.0);
          } else {
            // Fallback: if no match by code, pick *any* price for this product/company
            final anyForCompany = allPrices.firstWhere(
              (p) =>
                  _eq(p['company_id'], company_id) && _eq(p['product_id'], pid),
              orElse: () => <String, dynamic>{},
            );
            chosen = _toDouble(anyForCompany['price'], orElse: 0.0);

            // Helpful debug to find mismatched price_code types/values
            // (Remove these prints in production)
            // ignore: avoid_print
            print('[PRICE FALLBACK] pid=$pid price_code="$effectiveCode" '
                'no match in localPrices; using any price=${chosen?.toStringAsFixed(1)}');
          }
        }
      }

      // Defensive: never let it be null
      final priceDouble = (chosen ?? 0.0);
      mutableProduct['price'] = priceDouble.toStringAsFixed(1);

      // Optional category filter (unchanged)
      if (selectedCategoryId == 0 ||
          _eq(mutableProduct['category_id'], selectedCategoryId)) {
        processedProducts.add(mutableProduct);
      }
    }

    return processedProducts;
  }

  Future<void> _startListeningProduct() async {
    final available = await _speech.initialize(
      onError: (_) {
        Fluttertoast.showToast(msg: "خطأ في الميكروفون");
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _showMicOverlay = false;
        });
      },
    );

    if (!available) {
      Fluttertoast.showToast(msg: "الميكروفون غير متاح");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isListening = true;
      _showMicOverlay = true;
    });

    _speech.listen(
      localeId: 'ar',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      onResult: (result) async {
        if (!result.finalResult) return;

        final spoken = result.recognizedWords.trim();

        await _speech.stop();
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _showMicOverlay = false;
        });

        await _searchFromBackendAndOpenAddProduct(spoken);
      },
    );
  }

  String _normalizeArabic(String s) {
    var x = s.trim();
    x = x.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    x = x.replaceAll('ة', 'ه');
    x = x.replaceAll(RegExp(r'\s+'), ' ');
    return x;
  }

  Future<void> _searchFromBackendAndOpenAddProduct(String command) async {
    final c = _normalizeArabic(command);

    String? name;
    if (c.contains('افتح منتج')) {
      name = c.split('افتح منتج').last.trim();
    } else if (c.startsWith('افتح')) {
      name = c.replaceFirst('افتح', '').trim();
    } else if (c.startsWith('ضيف')) {
      name = c.replaceFirst('ضيف', '').trim();
    } else if (c.startsWith('اضف')) {
      name = c.replaceFirst('اضف', '').trim();
    } else {
      name = c.trim();
    }

    if (name == null || name.isEmpty) {
      Fluttertoast.showToast(msg: "قل: افتح [اسم المنتج]");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? companyId = prefs.getInt('company_id');
    final int? salesmanId = prefs.getInt('salesman_id');
    final String? codePrice = prefs.getString('price_code');
    final String? t = prefs.getString('type');
    final bool online = prefs.getBool('isOnline') ?? true;

    if (companyId == null || salesmanId == null) {
      Fluttertoast.showToast(msg: "بيانات الحساب غير مكتملة");
      return;
    }

    final String query = Uri.encodeComponent(name);

    final String url = (t.toString() == "quds")
        ? "https://yaghm.com/admin/api/search_products/$query/${companyId.toString()}/${salesmanId.toString()}/${widget.id.toString()}/$codePrice"
        : "https://yaghm.com/admin/api/search_products_vansale_new/${companyId.toString()}/${salesmanId.toString()}/${widget.id.toString()}/$codePrice/$query";
    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        Fluttertoast.showToast(msg: "فشل البحث من السيرفر");
        return;
      }

      final decoded = jsonDecode(res.body);

      final List products = (t.toString() == "quds")
          ? (decoded["products"] is Map
              ? (decoded["products"]["data"] ?? [])
              : (decoded["products"] ?? []))
          : (decoded["products"] ?? []);

      if (products.isEmpty) {
        Fluttertoast.showToast(msg: "لم يتم العثور على المنتج: $name");
        return;
      }

      final Map first = Map<String, dynamic>.from(products.first);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddProduct(
            isOnline: online,
            checkProductBarcode20or13: false,
            checkProductBarcode: true,
            productBarcode:
                (first["product_barcode"] ?? first["barcode"] ?? "").toString(),
            packingNumber:
                (first["Package_num"] ?? first["packingNumber"] ?? "")
                    .toString(),
            packingPrice:
                (first["Package_price"] ?? first["packingPrice"] ?? "")
                    .toString(),
            id: (first["id"] ?? first["product_id"]).toString(),
            name: (first["p_name"] ?? first["name"] ?? "-").toString(),
            productUnit:
                (first["unit"] ?? first["productUnit"] ?? "-").toString(),
            productColors: (first["product_colors"] ?? []),
            image: (first["images"] ?? first["img_path"] ?? "").toString(),
            customer_id: widget.id.toString(),
            price: (first["price"] ?? "0").toString(),
            qty: (first["quantity"] ?? "0").toString(),
            qtyExist: (first["quantity"] ?? "0").toString(),
            desc: (first["description"] ?? first["desc"] ?? "-").toString(),
          ),
        ),
      );
    } catch (_) {
      Fluttertoast.showToast(msg: "حدث خطأ أثناء البحث");
    }
  }

  @override
  void initState() {
    super.initState();
    setControllers();
    getCategories();
    _controller = ScrollController();
    _controller!.addListener(_scrollListener);
    _speech = stt.SpeechToText();
  }

  void _scrollListener() {
    if (isOnline) {
      _loadMore();
    } else {
      _loadMoreOffline();
    }
  }
}
