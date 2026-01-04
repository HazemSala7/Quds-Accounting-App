import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Screens/add_product/add_product.dart';
import 'package:quds_yaghmour/Screens/edit_product_data/edit_product_data.dart';
import 'package:quds_yaghmour/Screens/products/product_view/product_view.dart';
import 'package:quds_yaghmour/components/product-widget-quds/product-widget-quds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../LocalDB/DataBase/DataBase.dart';
import '../../../LocalDB/Models/CartModel.dart';
import '../../../LocalDB/Provider/CartProvider.dart';
import '../../../Server/server.dart';
import 'package:provider/provider.dart';

class ProductCardVansale extends StatefulWidget {
  final image, name, desc, price_code, id;
  var qty,
      price,
      customer_id,
      packingNumber,
      product_colors,
      packingPrice,
      productUnit;

  ProductCardVansale(
      {Key? key,
      this.image,
      required this.id,
      required this.productUnit,
      required this.customer_id,
      required this.qty,
      this.price_code,
      required this.price,
      required this.desc,
      this.name})
      : super(key: key);

  @override
  State<ProductCardVansale> createState() => _ProductCardVansaleState();
}

class _ProductCardVansaleState extends State<ProductCardVansale> {
  @override
  String? localImagePath;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final db = await CartDatabaseHelper().database;
    final List<Map<String, dynamic>> result = await db!.query(
      'products_images',
      where: 'id = ?',
      whereArgs: [widget.id.toString()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      setState(() {
        localImagePath = result.first['productImage'];
      });
    }
  }

  Widget _buildImage(String? imagePath) {
    return ProductCardQuds.buildImage(imagePath);
  }

  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddProduct(
                      isOnline: isOnline,
                      image: widget.image,
                      packingNumber: widget.packingNumber,
                      packingPrice: widget.packingPrice,
                      productColors: widget.product_colors,
                      checkProductBarcode20or13: false,
                      checkProductBarcode: false,
                      productUnit: widget.productUnit.toString(),
                      productBarcode: "",
                      id: widget.id,
                      name: widget.name,
                      customer_id: widget.customer_id.toString(),
                      price: widget.price,
                      qty: widget.qty,
                      qtyExist: widget.qty,
                      desc: widget.desc,
                    )));
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10),
          child: Container(
            child: Wrap(
              children: [
                Visibility(
                  visible: productImage,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 7,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        height: 140,
                        width: double.infinity,
                        child: Center(
                          child: SizedBox(
                            height: 200,
                            width: 250,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              child: _buildImage(localImagePath),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EditProductData(
                                              id: widget.id,
                                              product_id: widget.id.toString(),
                                              name: widget.name,
                                              price: widget.price,
                                              qty: widget.qty,
                                            )));
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 30,
                              )),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProductView(
                                              image: localImagePath.toString(),
                                            )));
                              },
                              icon: Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 30,
                              )),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 7,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  // height: 30,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              widget.name.length > 40
                                  ? widget.name.substring(0, 40) + '...'
                                  : widget.name,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Text(
                                  "الموجود : ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  '${widget.qty}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Main_Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              '${double.parse(widget.price.toString()).toStringAsFixed(1).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")}₪',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Main_Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (double.parse(widget.qty.toString()) < 1.0) {
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
                                      final newItem = CartItem(
                                        productBarcode: "",
                                        color: "",
                                        colorsNames: [],
                                        discount: 0.0,
                                        image: "",
                                        notes: "",
                                        ponus2: "0",
                                        productId: widget.id,
                                        quantityexists:
                                            double.parse(widget.qty.toString()),
                                        name: widget.name,
                                        price: double.parse(
                                            widget.price.toString()),
                                        quantity: 1,
                                        ponus1: "0",
                                      );
                                      cartProvider.addToCart(newItem);
                                      Navigator.pop(context);
                                      Fluttertoast.showToast(
                                        msg:
                                            "تم اضافة هذا المنتج الى الفاتورة بنجاح",
                                      );

                                      Timer(Duration(milliseconds: 300), () {
                                        Fluttertoast
                                            .cancel(); // Dismiss the toast after the specified duration
                                      });
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
                                          "نعم",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
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
                                              BorderRadius.circular(10)),
                                      child: Center(
                                        child: Text(
                                          "لا",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
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
                    } else if (double.parse(widget.price.toString()) == 0.0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text(
                              'لا يمكن أن يكون السعر يساوي صفر , الرجاء اضافة سعر لهذا المنتج',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
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
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      final newItem = CartItem(
                        color: "",
                        productBarcode: "",
                        colorsNames: [],
                        discount: 0.0,
                        image: "",
                        notes: "",
                        ponus2: "0",
                        quantityexists: double.parse(widget.qty.toString()),
                        productId: widget.id.toString(),
                        name: widget.name,
                        price: double.parse(widget.price.toString()),
                        quantity: 1.0,
                        ponus1: "0",
                      );
                      cartProvider.addToCart(newItem);
                      Fluttertoast.showToast(
                        msg: "تم اضافة هذا المنتج الى الفاتورة بنجاح",
                      );
                      Timer(Duration(milliseconds: 300), () {
                        Fluttertoast
                            .cancel(); // Dismiss the toast after the specified duration
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color.fromRGBO(83, 89, 219, 1),
                          Color.fromRGBO(32, 39, 160, 0.6),
                        ]),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10))),
                    height: 35,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        "اضافة الى الفاتورة",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
