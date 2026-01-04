import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Screens/add_sarf/add_sarf.dart';
import 'package:quds_yaghmour/Screens/catch_receipt/catch_receipt.dart';
import 'package:quds_yaghmour/Screens/categories/categories.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/kashf_hesab.dart';
import 'package:quds_yaghmour/Screens/sarf/sarf.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/qr_code_scanner/qr_code_scanner.dart';
import 'package:quds_yaghmour/main.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Services/Drawer/drawer.dart';
import '../add_product/add_product.dart';
import '../customers/customers.dart';
import '../products/products.dart';
import 'customer_details_card/customer_details_card.dart';

class CustomerDetails extends StatefulWidget {
  final id, name, balance, lattitude, longitude;
  bool edit;
  CustomerDetails(
      {Key? key,
      this.id,
      required this.edit,
      required this.balance,
      this.name,
      required this.lattitude,
      required this.longitude})
      : super(key: key);

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  @override
  String scanBarcode = '';
  bool isOnline = false;
  final FocusNode _barcodeFocusNode = FocusNode();
  String type = "";
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  TextEditingController idController = TextEditingController();
  TextEditingController badrcodeController = TextEditingController();
  var Price_Code;
  var roleID;
  initiatePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? code_price = prefs.getString('price_code');
    String? _type = prefs.getString('type') ?? "quds";
    String? _roleID = prefs.getString('role_id');
    bool _isOnline = prefs.getBool('isOnline') ?? true;

    setState(() {
      Price_Code = code_price;
      roleID = _roleID.toString();
      isOnline = _isOnline;
      type = _type;
    });
  }

  Timer? _timer;
  bool dontgo = false;

  editName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var url = AppLink.editCustomerName;
    final response = await http.post(
      Uri.parse(url),
      body: {
        'customer_id': widget.id.toString(),
        'company_id': company_id.toString(),
        'salesman_id': salesman_id.toString(),
        'c_name': nameController.text,
        'phone1': phoneNumberController.text,
      },
    );
    var data = jsonDecode(response.body);
    print("data");
    print({
      'customer_id': widget.id.toString(),
      'company_id': company_id.toString(),
      'salesman_id': salesman_id.toString(),
      'c_name': nameController.text,
      'phone1': phoneNumberController.text,
    });
    print(data);
    if (data['status'] == 'true') {
      Navigator.of(context, rootNavigator: true).pop();
      Fluttertoast.showToast(msg: "تم تعديل أسم الزبون بنجاح");
      Navigator.pop(context, true);
      var headers = {'ContentType': 'application/json'};
      var url = '${AppLink.customers}/$company_id/$salesman_id';
      var response = await http.get(Uri.parse(url), headers: headers);
      var res = jsonDecode(response.body)['customers'];

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => Customers(
            CustomersArray: res,
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context, rootNavigator: true).pop();
      // print('fsdsdfs');
    }
  }

  _AnimatedFlutterLogoState() {
    _timer = new Timer(const Duration(milliseconds: 400), () {
      setState(() {});
    });
  }

  bool qr_barcode = false;
  barcodeScan() async {
    final scannedBarcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(),
      ),
    );

    if (scannedBarcode != null) {
      return scannedBarcode;
    }
  }

  // qrScan() async {
  //   String barcodeScanRes = "";

  //   try {
  //     barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
  //         '#ff6666', 'Cancel', true, ScanMode.QR);
  //   } on PlatformException {
  //     barcodeScanRes = '';
  //   }

  //   return barcodeScanRes;
  // }

  var pr;

  setPrice(pro_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var url =
        'http://yaghm.com/admin/api/check_invoiceproducts/${company_id.toString()}/${salesman_id.toString()}/${widget.id}/$pro_id';
    var response = await http.get(Uri.parse(url));
    var res = jsonDecode(response.body);
    if (res["invoiceproducts"].length == 0) {
      return "0";
    } else {
      return res["invoiceproducts"][0]["p_price"];
    }
  }

  setPriceBarcode(pro_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var url =
        'http://yaghm.com/admin/api/get_price_barcode/${company_id.toString()}/${salesman_id.toString()}/${widget.id}/$pro_id';
    var response = await http.get(Uri.parse(url));
    var res = jsonDecode(response.body);
    if (res["invoiceproducts"].length == 0) {
      return "0";
    } else {
      return res["invoiceproducts"][0]["p_price"];
    }
  }

  searchProducts() async {
    if (isOnline) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');
      String? type = prefs.getString('type');
      String? code_price = prefs.getString('price_code');
      var url = type == "quds"
          ? 'http://yaghm.com/admin/api/get_specefic_product_quds/${idController.text}/${company_id.toString()}/${salesman_id.toString()}/${widget.id}/${code_price}'
          : 'http://yaghm.com/admin/api/get_specefic_product_vansale/${idController.text}/${company_id.toString()}/${salesman_id.toString()}/${widget.id}/${code_price}';
      var response = await http.get(Uri.parse(url));
      try {
        var res = jsonDecode(response.body)["products"][0];
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          idController.text = "";
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddProduct(
                      isOnline: isOnline,
                      image: "",
                      packingNumber: "",
                      packingPrice: "",
                      productColors: "",
                      checkProductBarcode20or13: false,
                      id: res["id"],
                      productUnit: res["unit"] ?? "",
                      desc: res["description"] ?? "",
                      name: res["p_name"],
                      checkProductBarcode: false,
                      productBarcode: "",
                      customer_id: widget.name.toString(),
                      price: res["price"],
                      qty: res["quantity"] ?? "0",
                      qtyExist: res["quantity"] ?? "0",
                    )));
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(msg: "المنتج غير متوفر!");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? company_id = prefs.getInt('company_id')?.toString();
      final dbHelper = CartDatabaseHelper();
      String productId = idController.text.trim();

// Fetch data from DB
      List<Map<String, dynamic>> products = type.toString() == "quds"
          ? await dbHelper.getProductsQuds()
          : await dbHelper.getProductsVansale();

      List<Map<String, dynamic>> localPrices = await dbHelper.getPrices();
      List<Map<String, dynamic>> localLastPrices =
          await dbHelper.getLastPrices();

// 🔍 Find the product you want directly
      Map<String, dynamic>? matchedProduct = products.firstWhere(
        (p) => p['id'].toString() == productId,
        orElse: () => {},
      );

// ❌ If product not found
      if (matchedProduct == null || matchedProduct.isEmpty) {
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(msg: "المنتج غير متوفر!");
        return;
      }

// ✅ Now process only this product
      Map<String, dynamic> mutableProduct = Map.from(matchedProduct);
      String product_id = mutableProduct['id'].toString();
      String customer_id = widget.id.toString();
      String price_code = prefs.getString('price_code') ?? '';

// Filter prices
      List<Map<String, dynamic>> prices = localPrices.where((price) {
        return price['product_id'].toString() == product_id &&
            price['company_id'].toString() == company_id;
      }).toList();

// Filter last prices
      List<Map<String, dynamic>> lastPriceCheck =
          localLastPrices.where((lastPrice) {
        return lastPrice['product_id'].toString() == product_id &&
            lastPrice['company_id'].toString() == company_id &&
            lastPrice['customer_id'].toString() == customer_id;
      }).toList();

// Determine final price
      if (lastPriceCheck.isEmpty) {
        if (prices.isEmpty) {
          mutableProduct['price'] = '0';
        } else if (prices.length == 1) {
          mutableProduct['price'] = prices[0]['price'].toString();
        } else {
          var selectedPrice = prices.firstWhere(
              (price) => price['price_code'] == price_code,
              orElse: () => {'price': '0'});
          mutableProduct['price'] = selectedPrice['price'].toString();
        }
      } else {
        mutableProduct['price'] = lastPriceCheck[0]['price'].toString();
      }

// Format price
      mutableProduct['price'] =
          double.parse(mutableProduct['price']).toString();

// Fix image path
      if (mutableProduct['images'] != null &&
          mutableProduct['images'].length > 7) {
        mutableProduct['images'] =
            "https://aliexpress.ps/quds_laravel/public/storage/${mutableProduct['images'].substring(7)}";
      }

// ✅ Navigate to product page
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        idController.text = "";
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProduct(
            isOnline: isOnline,
            image: mutableProduct['images'],
            packingNumber: "",
            packingPrice: "",
            productColors: "",
            productUnit: mutableProduct['productUnit'] ?? "-",
            checkProductBarcode20or13: false,
            id: mutableProduct['id'],
            desc: mutableProduct['description'] ?? "",
            name: mutableProduct['p_name'],
            checkProductBarcode: false,
            productBarcode: mutableProduct['product_barcode'],
            customer_id: widget.name.toString(),
            price: mutableProduct["price"].toString(),
            qty: mutableProduct['quantity'] ?? "0",
            qtyExist: mutableProduct['quantity'] ?? "0",
          ),
        ),
      );
    }
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  search_bar() async {
    if (isOnline) {
      // ONLINE - Perform API search
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? company_id = prefs.getInt('company_id');
        int? salesman_id = prefs.getInt('salesman_id');
        String? type = prefs.getString('type');
        // API URL for barcode search
        var url = type.toString() == "quds"
            ? 'https://yaghm.com/admin/api/search_products_barcode/${company_id.toString()}/${salesman_id.toString()}/${scanBarcode.toString()}'
            : 'https://yaghm.com/admin/api/search_products_barcode_vansale/${company_id.toString()}/${salesman_id.toString()}/${scanBarcode.toString()}';
        var response = await http.get(Uri.parse(url));
        var res = jsonDecode(response.body)["products"][0];
        var price = "0";
        var prices = res["prices"];

        // Same pricing logic as before
        if (type == "quds") {
          pr = await setPriceBarcode(scanBarcode.toString());
          if (pr.toString() == "0") {
            if (prices.isEmpty) {
              price = "0";
            } else if (prices.length == 1) {
              price = prices[0]["price"];
            } else {
              var _price = prices.firstWhere(
                  (e) => e["price_code"] == Price_Code,
                  orElse: () => {"price": "0"});
              price = _price["price"];
            }
          } else {
            price = pr;
          }
        } else {
          if (prices.isEmpty) {
            price = "0";
          } else if (prices.length == 1) {
            price = prices[0]["price"];
          } else {
            var _price = prices.firstWhere((e) => e["price_code"] == Price_Code,
                orElse: () => {"price": "0"});
            price = _price["price"];
          }
        }

        // Navigate to AddProduct screen
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          badrcodeController.text = "";
        });
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProduct(
              isOnline: isOnline,
              image: res["image"] ?? "",
              packingNumber: res["packingNumber"] ?? "",
              packingPrice: res["packingPrice"] ?? "",
              productColors: res["productColors"] ?? "",
              productUnit: res["unit"] ?? "",
              checkProductBarcode20or13: scanBarcode.toString().length == 20 ||
                  scanBarcode.toString().length == 13,
              id: res["id"].toString(),
              desc: res["description"] ?? "",
              checkProductBarcode: true,
              productBarcode: scanBarcode.toString(),
              name: res["p_name"] ?? "Unknown Product",
              customer_id: widget.name.toString(),
              price: price,
              qty: res["quantity"].toString(),
              qtyExist: type.toString() == "quds"
                  ? res["quantity"].toString()
                  : res["qty"].toString(),
            ),
          ),
        );

        // 🔁 If AddProduct returns true, request focus
        if (result == true) {
          FocusScope.of(context).requestFocus(_barcodeFocusNode);
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "المنتج غير متوفر , الرجاء المحاولة فيما بعد");
      }
    } else {
      // OFFLINE - Perform local search
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? company_id = prefs.getInt('company_id')?.toString();
        final dbHelper = CartDatabaseHelper();

        List<Map<String, dynamic>> products = type.toString() == "quds"
            ? await dbHelper.getProductsQuds()
            : await dbHelper.getProductsVansale();

        List<Map<String, dynamic>> localPrices = await dbHelper.getPrices();
        List<Map<String, dynamic>> localLastPrices =
            await dbHelper.getLastPrices();

        // First: Try to find by barcode
        Map<String, dynamic> matchedProduct = products.firstWhere(
          (product) =>
              product['product_barcode'].toString() == scanBarcode.toString(),
          orElse: () => {},
        );

        // If not found by barcode and barcode has 20 or 13 digits, try to extract ID
        if (matchedProduct.isEmpty &&
            (scanBarcode.length == 20 || scanBarcode.length == 13)) {
          String productId = scanBarcode.length == 20
              ? scanBarcode.substring(3, 7)
              : scanBarcode.substring(3, 7);

          matchedProduct = products.firstWhere(
            (p) => p['id'].toString() == productId,
            orElse: () => {},
          );
        }

        if (matchedProduct.isNotEmpty) {
          Map<String, dynamic> mutableProduct = Map.from(matchedProduct);
          String product_id = mutableProduct['id'].toString();
          String customer_id = widget.id.toString();
          String price_code = prefs.getString('price_code') ?? '';

          List<Map<String, dynamic>> prices = localPrices.where((price) {
            return price['product_id'].toString() == product_id &&
                price['company_id'].toString() == company_id;
          }).toList();

          List<Map<String, dynamic>> lastPriceCheck =
              localLastPrices.where((lastPrice) {
            return lastPrice['product_id'].toString() == product_id &&
                lastPrice['company_id'].toString() == company_id &&
                lastPrice['customer_id'].toString() == customer_id;
          }).toList();

          if (lastPriceCheck.isEmpty) {
            if (prices.isEmpty) {
              mutableProduct['price'] = '0';
            } else if (prices.length == 1) {
              mutableProduct['price'] = prices[0]['price'].toString();
            } else {
              var selectedPrice = prices.firstWhere(
                  (price) => price['price_code'] == price_code,
                  orElse: () => {'price': '0'});
              mutableProduct['price'] = selectedPrice['price'].toString();
            }
          } else {
            mutableProduct['price'] = lastPriceCheck[0]['price'].toString();
          }

          mutableProduct['price'] =
              double.parse(mutableProduct['price']).toStringAsFixed(1);

          if (mutableProduct['images'] != null &&
              mutableProduct['images'].length > 7) {
            mutableProduct['images'] =
                "https://aliexpress.ps/quds_laravel/public/storage/${mutableProduct['images'].substring(7)}";
          }

          double qty = 0.0;
          int barcodeLength = scanBarcode.toString().length;
          if (barcodeLength == 20) {
            qty = int.parse(scanBarcode.substring(7, 13)) / 100;
          } else if (barcodeLength == 13) {
            qty = int.parse(scanBarcode.substring(7, 12)) / 1000;
          } else {
            qty = double.tryParse(mutableProduct["quantity"].toString()) ?? 0.0;
          }

          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            badrcodeController.text = "";
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProduct(
                isOnline: isOnline,
                image: mutableProduct["images"] ?? "",
                productUnit: mutableProduct["productUnit"] ?? "-",
                packingNumber: mutableProduct["packingNumber"] ?? "",
                packingPrice: mutableProduct["packingPrice"] ?? "",
                productColors: mutableProduct["productColors"] ?? "",
                checkProductBarcode20or13:
                    barcodeLength == 20 || barcodeLength == 13,
                id: mutableProduct["id"].toString(),
                desc: mutableProduct["description"] ?? "",
                checkProductBarcode: true,
                productBarcode: scanBarcode.toString(),
                name: mutableProduct["p_name"] ?? "Unknown Product",
                customer_id: widget.name.toString(),
                price: mutableProduct["price"].toString(),
                qty: qty.toString(),
                qtyExist: mutableProduct["quantity"].toString(),
              ),
            ),
          );
          FocusScope.of(context).requestFocus(_barcodeFocusNode);
        } else {
          Navigator.of(context, rootNavigator: true).pop();
          Fluttertoast.showToast(
              msg: "المنتج غير متوفر , الرجاء المحاولة فيما بعد");
        }
      } catch (e) {
        print("121212eee");
        print(e);
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "المنتج غير متوفر , الرجاء المحاولة فيما بعد");
      }
    }
  }

  dont() {
    Navigator.of(context, rootNavigator: true).pop();
    Fluttertoast.showToast(msg: "لديك خطأ ما");
  }

  searchBarcode() async {
    var barcode = await barcodeScan();
    setState(() {
      scanBarcode = barcode.toString();
    });
    scanBarcode.toString() == "" && dontgo == false ? dont() : search_bar();
  }

  lastStep() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
              height: 100,
              width: 100,
              child: Center(child: CircularProgressIndicator())),
        );
      },
    );
    searchBarcode();
  }

  Future<void> updateCustomerLocation() async {
    showLoadingDialog();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');
      Position position = await _getCurrentLocation();
      double latitude = position.latitude;
      double longitude = position.longitude;

      // API endpoint
      final String url =
          'https://yaghm.com/admin/api/customers/${widget.id.toString()}/location?_method=PUT';

      final Map<String, dynamic> data = {
        "company_id": company_id.toString(),
        "salesman_id": salesman_id.toString(),
        "latitude": latitude.toString(),
        "longitude": longitude.toString()
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        showSnackBar("تم تحديث موقع الزبون بنجاح");
      } else {
        showSnackBar("Failed to update location");
        print('Error: ${response.body}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      showSnackBar("Error: ${e.toString()}");
      print('Exception: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("يتم الأن تحديث الموقع .... الرجاء الانتظار"),
            ],
          ),
        );
      },
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  FocusNode n = new FocusNode();
  var focusNode = FocusNode();

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
              child: AppBarBack(
                title: type.toString() == "quds"
                    ? "القدس موبايل"
                    : "القدس موبايل Vansale",
              ),
              preferredSize: Size.fromHeight(50)),
          body: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 25, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "أسم الزبون : ${widget.name}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          ],
                        ),
                        Visibility(
                          visible: widget.edit,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('تعديل بيانات الزبون'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                              labelText: 'أسم الزبون'),
                                        ),
                                        TextField(
                                          controller: phoneNumberController,
                                          decoration: InputDecoration(
                                              labelText: 'رقم هاتف الزبون'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('خروج'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // print("priceController.text");
                                          // print(priceController.text);
                                          if (nameController.text == "" ||
                                              phoneNumberController.text ==
                                                  "") {
                                            // Navigator.of(context, rootNavigator: true).pop();
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: Text(
                                                    'الرجاء تعبئة جميع البيانات',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  actions: <Widget>[
                                                    InkWell(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Container(
                                                        width: 100,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                            color: Main_Color,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                        child: Center(
                                                          child: Text(
                                                            "حسنا",
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: SizedBox(
                                                      height: 100,
                                                      width: 100,
                                                      child: Center(
                                                          child:
                                                              CircularProgressIndicator())),
                                                );
                                              },
                                            );
                                            editName();
                                          }
                                        },
                                        child: Text('حفظ البيانات'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "تعديل الاسم",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                              decoration: BoxDecoration(
                                  color: Main_Color,
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: roleID.toString() == "3" ? false : true,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 20, left: 20, top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            height: 50,
                            width: 200,
                            child: TextField(
                              controller: idController,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'بحث عن رقم الصنف',
                                hintStyle: TextStyle(
                                    fontWeight: FontWeight.w400, fontSize: 14),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Main_Color, width: 2.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 2.0, color: Color(0xffD6D3D3)),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              searchProducts();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: Center(
                                            child:
                                                CircularProgressIndicator())),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text("بحث",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    )),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: roleID.toString() == "3" ? false : true,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 20, left: 20, top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            height: 50,
                            width: 200,
                            child: RawKeyboardListener(
                              focusNode: focusNode,
                              onKey: (event) async {
                                if (event
                                    .isKeyPressed(LogicalKeyboardKey.enter)) {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  setState(() {
                                    scanBarcode = badrcodeController.text;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator())),
                                      );
                                    },
                                  );
                                  setState(() {});
                                }
                              },
                              child: TextField(
                                controller: badrcodeController,
                                textInputAction: TextInputAction.done,
                                focusNode: _barcodeFocusNode,
                                textAlign: TextAlign.center,
                                obscureText: false,
                                onSubmitted: (value) async {
                                  setState(() {
                                    scanBarcode = badrcodeController.text;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: SizedBox(
                                            height: 100,
                                            width: 100,
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator())),
                                      );
                                    },
                                  );
                                  search_bar();
                                },
                                decoration: InputDecoration(
                                  hintText: 'بحث عن باركود الصنف',
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Main_Color, width: 2.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2.0, color: Color(0xffD6D3D3)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                scanBarcode = badrcodeController.text;
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: Center(
                                            child:
                                                CircularProgressIndicator())),
                                  );
                                },
                              );
                              search_bar();
                            },
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text("بحث",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    )),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: roleID.toString() == "3" ? false : true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, left: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Visibility(
                                visible: JUST,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      qr_barcode = true;
                                    });
                                    dontgo
                                        ? Navigator.of(context,
                                                rootNavigator: true)
                                            .pop()
                                        : lastStep();
                                  },
                                  child: Container(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        "بحث عن طريق الباركود",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.white),
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(colors: [
                                        Color.fromRGBO(83, 89, 219, 1),
                                        Color.fromRGBO(32, 39, 160, 0.6),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 20, left: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Visibility(
                            visible: JUST || type == "vansale",
                            child: InkWell(
                              onTap: updateCustomerLocation,
                              child: Container(
                                height: 50,
                                child: Center(
                                  child: Text(
                                    "تحديث موقع الزبون",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          flex: 1,
                          child: Visibility(
                            visible: JUST || type == "vansale",
                            child: InkWell(
                              onTap: () async {
                                final _url = Uri.parse(
                                    "https://www.google.com/maps?q=${widget.lattitude.toString()},${widget.longitude.toString()}");
                                if (!await launchUrl(_url,
                                    mode: LaunchMode.externalApplication)) {
                                  Fluttertoast.showToast(
                                      msg:
                                          "لم يتم التمكن من الدخول الرابط , الرجاء المحاولة فيما بعد");
                                }
                              },
                              child: Container(
                                height: 50,
                                child: Center(
                                  child: Text(
                                    "رؤية موقع الزبون",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(83, 89, 219, 1),
                                    Color.fromRGBO(32, 39, 160, 0.6),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                      height: 300,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Visibility(
                                visible:
                                    roleID.toString() == "3" ? false : true,
                                child: CustomerDetailsCard(
                                  name: type.toString() == "quds"
                                      ? "طلبية مبيعات"
                                      : "فاتورة مبيعات",
                                  my_icon: Icons.request_page,
                                  navi: () async {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    String? type = prefs.getString('type');
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Products(
                                                  type: type,
                                                  id: widget.id,
                                                  name: widget.name,
                                                )));
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) => Categories(
                                    //               id: widget.id,
                                    //               name: widget.name,
                                    //             )));
                                  },
                                ),
                              ),
                              Visibility(
                                visible: roleID.toString() == "3" ||
                                        roleID.toString() == "4"
                                    ? false
                                    : true,
                                child: CustomerDetailsCard(
                                  name: "سند قبض",
                                  my_icon: Icons.money,
                                  navi: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => CatchReceipt(
                                                  balance: widget.balance,
                                                  name: widget.name.toString(),
                                                  id: widget.id,
                                                )));
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Visibility(
                                visible: roleID.toString() == "3" ||
                                        roleID.toString() == "4"
                                    ? false
                                    : true,
                                child: CustomerDetailsCard(
                                  name: "سند صرف",
                                  my_icon: Icons.money,
                                  navi: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => AddSarf(
                                                  name: widget.name.toString(),
                                                  id: widget.id,
                                                )));
                                  },
                                ),
                              ),
                              Visibility(
                                visible:
                                    roleID.toString() == "4" ? false : true,
                                child: CustomerDetailsCard(
                                  name: "كشف حساب",
                                  my_icon: Icons.account_balance,
                                  navi: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => KashfHesab(
                                                balance:
                                                    widget.balance.toString(),
                                                name: widget.name.toString(),
                                                customer_id:
                                                    widget.id.toString())));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initiatePrefs();
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    super.dispose();
  }
}
