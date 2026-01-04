import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../LocalDB/Models/CartModel.dart';
import '../../LocalDB/Provider/CartProvider.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import 'package:provider/provider.dart';

class AddProduct extends StatefulWidget {
  final id,
      name,
      qty,
      customer_id,
      desc,
      productBarcode,
      image,
      qtyExist,
      productUnit;
  var price, packingNumber, packingPrice, productColors;
  bool checkProductBarcode, checkProductBarcode20or13, isOnline;
  AddProduct({
    Key? key,
    this.id,
    this.qtyExist,
    this.name,
    this.productUnit,
    required this.isOnline,
    required this.productBarcode,
    required this.image,
    required this.checkProductBarcode,
    required this.checkProductBarcode20or13,
    this.desc,
    this.customer_id,
    this.qty,
    required this.productColors,
    required this.packingNumber,
    required this.packingPrice,
    required this.price,
  }) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  TextEditingController nameController = TextEditingController();
  TextEditingController invoiceID = TextEditingController();
  TextEditingController qty = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController bonus1Controller = TextEditingController();
  TextEditingController bonus2Controller = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController discountContrller = TextEditingController();
  TextEditingController totalController = TextEditingController();
  String selectedColor = '';
  List<String> _Names = [];
  String type = "";
  String vansaleCanChangePassword = "";
  var STORE;

  setContrllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_id_order = prefs.getString('store_id');
    String? _vansaleCanChangePassword =
        prefs.getString('vansale_can_change_password');
    String? _type = prefs.getString('type');
    STORE = store_id_order ?? "";
    nameController.text = widget.name;
    descController.text = widget.desc;
    priceController.text = widget.price.toString();
    unitController.text = widget.productUnit.toString();
    qtyController.text = widget.isOnline
        ? _type.toString() == "vansale"
            ? widget.qtyExist.toString()
            : widget.checkProductBarcode20or13
                ? widget.qtyExist.toString()
                : widget.qty.toString() == "null"
                    ? "0"
                    : widget.qty.toString()
        : widget.qtyExist.toString();
    discountContrller.text = "0";
    qty.text = _type.toString() == "quds"
        ? ""
        : widget.checkProductBarcode20or13
            ? widget.qty.toString()
            : "1";
    var init_total = double.parse(qty.text == "" ? "0" : qty.text) *
        double.parse(priceController.text) *
        (1 - (double.parse(discountContrller.text) / 100));
    totalController.text = init_total.toStringAsFixed(2);
    type = _type.toString();
    vansaleCanChangePassword = _vansaleCanChangePassword.toString();
    setState(() {});
  }

  CartProvider? cartProvider;

  @override
  void initState() {
    super.initState();
    cartProvider = Provider.of<CartProvider>(context, listen: false);
    setContrllers();
    setPrice();
  }

  var basic_price;
  var price4;
  var price3;
  var price20;

  setPrice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? price_code = prefs.getString('price_code');

    var url =
        'http://app.qasrawi.ps:8800/quds_qasrawi/api/get_price_by_product_id/$price_code/${widget.id}';

    var response = await http.get(Uri.parse(url));
    var res = jsonDecode(response.body);
    setState(() {
      basic_price = res["basic_price"];
      price4 = res["price4"];
      price3 = res["price3"];
      price20 = res["price20"];
    });
  }

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
              child: AppBarBack(
                title: "اضافة صنف",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.only(top: 20, right: 15, left: 15),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         "رقم الفاتورة",
                  //         style: TextStyle(
                  //             fontSize: 16, fontWeight: FontWeight.bold),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                  //   child: Container(
                  //     height: 50,
                  //     width: double.infinity,
                  //     child: TextField(
                  //       controller: invoiceID,
                  //       obscureText: false,
                  //       decoration: InputDecoration(
                  //         focusedBorder: OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               color: Color(0xff34568B), width: 2.0),
                  //         ),
                  //         enabledBorder: OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               width: 2.0, color: Color(0xffD6D3D3)),
                  //         ),
                  //         hintText: "رقم الفاتورة",
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "أسم المنتج",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        readOnly: true,
                        controller: nameController,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "أسم الصنف",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "الكمية",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            "الكمية الموجودة",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            child: TextField(
                              keyboardType: TextInputType.numberWithOptions(
                                  signed: true, decimal: true),
                              controller: qty,
                              onChanged: (hazem) {
                                setState(() {
                                  var init_total = double.parse(qty.text) *
                                      double.parse(priceController.text) *
                                      (1 -
                                          (double.parse(
                                                  discountContrller.text) /
                                              100));
                                  totalController.text =
                                      init_total.toStringAsFixed(2);
                                });
                              },
                              obscureText: false,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xff34568B), width: 2.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 2.0, color: Color(0xffD6D3D3)),
                                ),
                                hintText: "الكمية",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              readOnly: true,
                              controller: qtyController,
                              obscureText: false,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xff34568B), width: 2.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 2.0, color: Color(0xffD6D3D3)),
                                ),
                                hintText: "الكمية الموجوده",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: ponus1 == false && ponus2 == false ? false : true,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 20, right: 15, left: 15),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Visibility(
                            visible: ponus1,
                            child: Expanded(
                              flex: 1,
                              child: Text(
                                "بونص 1",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Visibility(
                            visible: ponus2,
                            child: Expanded(
                              flex: 1,
                              child: Text(
                                "بونص 2",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Row(
                      children: [
                        Visibility(
                          visible: ponus1,
                          child: Expanded(
                            flex: 1,
                            child: Container(
                              height: 50,
                              width: double.infinity,
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: bonus1Controller,
                                obscureText: false,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xff34568B), width: 2.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2.0, color: Color(0xffD6D3D3)),
                                  ),
                                  hintText: "بونص 1",
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: ponus2,
                          child: SizedBox(
                            width: 15,
                          ),
                        ),
                        Visibility(
                          visible: ponus2,
                          child: Expanded(
                            flex: 1,
                            child: Container(
                              height: 50,
                              width: double.infinity,
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: bonus2Controller,
                                obscureText: false,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xff34568B), width: 2.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2.0, color: Color(0xffD6D3D3)),
                                  ),
                                  hintText: "بونص 2",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "وصف المنتج",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        controller: descController,
                        readOnly: true,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "وصف المنتج",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "الوحدة",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        controller: unitController,
                        readOnly: true,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "الوحدة",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "سعر المنتج",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        readOnly: type.toString() == "quds"
                            ? false
                            : vansaleCanChangePassword.toString() == "true"
                                ? false
                                : true,
                        onChanged: (_) async {
                          // if (STORE.toString() == "30" ||
                          //     STORE.toString() == "31" ||
                          //     STORE.toString() == "33" ||
                          //     STORE.toString() == "79" ||
                          //     STORE.toString() == "83" ||
                          //     STORE.toString() == "88") {
                          //   if (double.parse(priceController.text) <
                          //       double.parse(price20.toString())) {
                          //     priceController.text = price20.toString();
                          //   } else if (double.parse(priceController.text) >
                          //       double.parse(price3.toString())) {
                          //     priceController.text = price3.toString();
                          //   }
                          // } else {
                          //   if (double.parse(priceController.text) <
                          //       double.parse(price4.toString())) {
                          //     priceController.text = price4.toString();
                          //   }
                          // }

                          // setState(() {});
                          setState(() {
                            var init_total = double.parse(qty.text) *
                                double.parse(priceController.text) *
                                (1 -
                                    (double.parse(discountContrller.text) /
                                        100));
                            totalController.text =
                                init_total.toStringAsFixed(2);
                          });
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        controller: priceController,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "السعر",
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: discountSetting,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 20, right: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "الخصم",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: discountSetting,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 15, left: 15, top: 5),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        child: TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          onChanged: (hazem) {
                            setState(() {
                              var init_total = double.parse(qty.text) *
                                  double.parse(priceController.text) *
                                  (1 -
                                      (double.parse(discountContrller.text) /
                                          100));
                              totalController.text =
                                  init_total.toStringAsFixed(2);
                            });
                          },
                          controller: discountContrller,
                          obscureText: false,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xff34568B), width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                            hintText: "الخصم",
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "المجموع",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        readOnly: true,
                        controller: totalController,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "المجموع",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: widget.productColors == null ||
                            widget.productColors.isEmpty
                        ? Container()
                        : ListView.builder(
                            itemCount: widget.productColors.length,
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final colorData = widget.productColors[index];
                              String colorCode = colorData['color'];
                              bool isSelected = selectedColor == colorCode;

                              int quantity = colorData['quantity'] ?? 0;
                              TextEditingController _countController =
                                  TextEditingController();
                              _countController.text = quantity.toString();

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        decoration: BoxDecoration(
                                          color: Color(
                                              int.parse('0xFF$colorCode')),
                                          border: Border.all(
                                            color: Colors.transparent,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Color: $colorCode',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed: () {
                                            setState(() {
                                              if (quantity > 0) {
                                                quantity--;
                                                colorData['quantity'] =
                                                    quantity;
                                                int newQuantity = int.tryParse(
                                                        quantity.toString()) ??
                                                    0;
                                                updateProductColorQuantity(
                                                    index, newQuantity);
                                              }
                                            });
                                          },
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: TextField(
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            controller: _countController,
                                            onChanged: (_) {
                                              colorData['quantity'] =
                                                  int.parse(_.toString());
                                              quantity =
                                                  int.parse(_.toString());
                                              int newQuantity = int.tryParse(
                                                      quantity.toString()) ??
                                                  0;
                                              updateProductColorQuantity(
                                                  index, newQuantity);
                                              setState(() {});
                                            },
                                            onSubmitted: (_) {
                                              colorData['quantity'] =
                                                  int.parse(_.toString());
                                              quantity =
                                                  int.parse(_.toString());
                                              int newQuantity = int.tryParse(
                                                      quantity.toString()) ??
                                                  0;
                                              updateProductColorQuantity(
                                                  index, newQuantity);
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              quantity++;
                                              colorData['quantity'] = quantity;
                                              int newQuantity = int.tryParse(
                                                      quantity.toString()) ??
                                                  0;
                                              updateProductColorQuantity(
                                                  index, newQuantity);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  Visibility(
                    visible: notes,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 20, right: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "ملاحظات",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: notes,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(right: 15, left: 15, top: 5),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        child: TextField(
                          controller: notesController,
                          obscureText: false,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xff34568B), width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                            hintText: "ملاحظات",
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 25, left: 25, top: 35, bottom: 30),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      height: 50,
                      minWidth: double.infinity,
                      color: Color(0xff34568B),
                      textColor: Colors.white,
                      child: Text(
                        "اضافة صنف",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: isButtonDisabled
                          ? null
                          : () {
                              if (qty.text == "") {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                        'الرجاء ادخال الكمية',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      actions: <Widget>[
                                        InkWell(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Container(
                                            width: 100,
                                            height: 40,
                                            decoration: BoxDecoration(
                                                color: Main_Color,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Center(
                                              child: Text(
                                                "حسنا",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                if (widget.productColors == null ||
                                    widget.productColors.isEmpty ||
                                    widget.productColors.length == 0) {
                                  if (double.parse(qty.text) >
                                      double.parse(qtyController.text == "null"
                                          ? "0"
                                          : qtyController.text)) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          content: Text(
                                              'الكمية المطلوبه اكبر من الكمية الموجوده , هل تريد الاستمرار ؟ '),
                                          actions: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    send();
                                                  },
                                                  child: Container(
                                                    width: 100,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                        color: Main_Color,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: Center(
                                                      child: Text(
                                                        "نعم",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Container(
                                                    width: 100,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                        color: Main_Color,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: Center(
                                                      child: Text(
                                                        "لا",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    send();
                                  }
                                  setState(() {
                                    isButtonDisabled = true;
                                  });
                                  _disableButtonForDuration(
                                      Duration(seconds: 3));
                                } else {
                                  for (int i = 0;
                                      i < widget.productColors.length;
                                      i++) {
                                    _Names.add(widget.productColors[i]["color"]
                                        .toString());
                                  }
                                  for (int i = 0;
                                      i < widget.productColors.length;
                                      i++) {
                                    if (int.parse(widget.productColors[i]
                                                    ['quantity'] ==
                                                null
                                            ? "0"
                                            : widget.productColors[i]
                                                    ['quantity']
                                                .toString()) >=
                                        1) {
                                      final newItem = CartItem(
                                        productBarcode: widget
                                                .checkProductBarcode
                                            ? widget.productBarcode.toString()
                                            : "",
                                        quantityexists:
                                            double.parse(widget.qty.toString()),
                                        colorsNames: _Names.map(
                                            (size) => size.toString()).toList(),
                                        notes: notesController.text == ""
                                            ? "-"
                                            : notesController.text,
                                        color: widget.productColors[i]["color"]
                                            .toString(),
                                        productId: widget.id.toString(),
                                        name: widget.name,
                                        image: widget.image,
                                        price:
                                            double.parse(priceController.text),
                                        discount: double.parse(
                                            discountContrller.text),
                                        quantity: double.parse(widget
                                            .productColors[i]['quantity']
                                            .toString()),
                                        ponus1: bonus1Controller.text == ""
                                            ? "0"
                                            : bonus1Controller.text,
                                        ponus2: bonus2Controller.text == ""
                                            ? "0"
                                            : bonus2Controller.text,
                                      );
                                      cartProvider!.addToCart(newItem);
                                      Fluttertoast.showToast(
                                          msg:
                                              "تم اضافة هذا المنتج الى الفاتورة بنجاح");
                                      Navigator.pop(context,
                                          true); // Instead of just Navigator.pop(context)
                                    }
                                  }
                                }
                              }
                            },
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

  void _disableButtonForDuration(Duration duration) {
    setState(() {
      isButtonDisabled = true;
    });

    Future.delayed(duration, () {
      setState(() {
        isButtonDisabled = false;
      });
    });
  }

  bool isButtonDisabled = false;

  send() async {
    if (double.parse(qtyController.text == "null" ? "0" : qtyController.text) >
            0 &&
        double.parse(priceController.text.toString()) == 0.0) {
      // Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(
              'الكمية أكبر من 1 و السعر يساوي صفر , لا يمكن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Main_Color,
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      "حسنا",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (nameController.text == '' || qtyController.text == '') {
      // Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('الرجاء تعبئه جميع الفراغات'),
            actions: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'حسنا',
                  style: TextStyle(color: Color(0xff34568B)),
                ),
              ),
            ],
          );
        },
      );
    } else {
      final newItem = CartItem(
        productBarcode:
            widget.checkProductBarcode ? widget.productBarcode.toString() : "",
        color: "",
        colorsNames: [],
        discount: double.parse(discountContrller.text),
        image: "",
        notes: notesController.text,
        ponus2: bonus2Controller.text == "" ? "0" : bonus2Controller.text,
        productId: widget.id.toString(),
        quantityexists: double.parse(
            widget.qty.toString() == "null" ? "0" : widget.qty.toString()),
        name: widget.name,
        price: double.parse(priceController.text),
        quantity: double.parse(qty.text),
        ponus1: bonus1Controller.text == "" ? "0" : bonus1Controller.text,
      );
      cartProvider!.addToCart(newItem);
      Fluttertoast.showToast(msg: "تم اضافة هذا المنتج الى الفاتورة بنجاح");
      Navigator.pop(context, true); // Instead of just Navigator.pop(context)
    }
  }

  double calculateTotal() {
    double totalPrice = 0.0;
    for (var colorData in widget.productColors) {
      int quantity = colorData['quantity'] ?? 0;
      double colorPrice = quantity * double.parse(priceController.text);
      totalPrice += colorPrice;
    }
    return totalPrice;
  }

  void updateProductColorQuantity(int index, int newQuantity) {
    setState(() {
      widget.productColors[index]['quantity'] = newQuantity;
      totalController.text = calculateTotal().toStringAsFixed(2);
    });
  }
}
