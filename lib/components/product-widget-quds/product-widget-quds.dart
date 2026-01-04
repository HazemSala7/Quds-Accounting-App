import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Screens/add_product/add_product.dart';
import 'package:quds_yaghmour/Screens/edit_product_data/edit_product_data.dart';
import 'package:quds_yaghmour/Screens/products/product_view/product_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../LocalDB/Models/CartModel.dart';
import '../../../LocalDB/Provider/CartProvider.dart';
import '../../../Server/server.dart';

class ProductCardQuds extends StatefulWidget {
  final image, name, desc, price_code, id;
  var qty,
      price,
      customer_id,
      product_colors,
      packingPrice,
      packingNumber,
      productUnit;

  ProductCardQuds(
      {Key? key,
      this.image,
      required this.id,
      required this.product_colors,
      required this.productUnit,
      required this.packingPrice,
      required this.packingNumber,
      required this.customer_id,
      required this.qty,
      this.price_code,
      required this.price,
      required this.desc,
      this.name})
      : super(key: key);

  @override
  State<ProductCardQuds> createState() => _ProductCardQudsState();

  /// 🔁 Reusable method to build image from network or file
  static Widget buildImage(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return Image.asset("assets/quds_logo.jpeg", fit: BoxFit.fill);
    }

    final cleanedPath = imagePath.trim();

    // ✅ Network image
    if (cleanedPath.startsWith("http://") ||
        cleanedPath.startsWith("https://")) {
      return Image.network(
        cleanedPath,
        fit: BoxFit.fill,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            Image.asset("assets/quds_logo.jpeg", fit: BoxFit.cover),
      );
    }

    // ✅ Local file
    if (File(cleanedPath).existsSync()) {
      return Image.file(
        File(cleanedPath),
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) =>
            Image.asset("assets/quds_logo.jpeg", fit: BoxFit.fill),
      );
    }

    // ✅ Fallback
    return Image.asset("assets/quds_logo.jpeg", fit: BoxFit.fill);
  }
}

class _ProductCardQudsState extends State<ProductCardQuds> {
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

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddProduct(
                      isOnline: isOnline,
                      checkProductBarcode20or13: false,
                      checkProductBarcode: true,
                      productBarcode: "",
                      packingNumber: widget.packingNumber,
                      packingPrice: widget.packingPrice,
                      id: widget.id,
                      name: widget.name,
                      productUnit: widget.productUnit.toString(),
                      productColors: widget.product_colors,
                      image: localImagePath,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              child: isOnline
                                  ? Image.network(
                                      widget.image,
                                      fit: BoxFit.fill,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            backgroundColor: Main_Color,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Image.asset("assets/quds_logo.jpeg",
                                              fit: BoxFit.cover),
                                    )
                                  : _buildImage(localImagePath),
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
                                              image: isOnline
                                                  ? widget.image.toString()
                                                  : localImagePath.toString(),
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
                  height: 70,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          '${widget.price} ₪',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Main_Color),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (widget.product_colors.length == 0) {
                      final newItem = CartItem(
                        productBarcode: "",
                        quantityexists: 0,
                        productId: widget.id.toString(),
                        color: "",
                        colorsNames: [],
                        name: widget.name,
                        image: localImagePath.toString(),
                        notes: "-",
                        price: double.parse(widget.price.toString()),
                        discount: 0.0,
                        quantity: 1,
                        ponus1: "0",
                        ponus2: "0",
                      );
                      cartProvider.addToCart(newItem);
                      Fluttertoast.showToast(
                        msg: "تم اضافة هذا المنتج الى الطلبية بنجاح",
                      );
                      Timer(Duration(milliseconds: 300), () {
                        Fluttertoast.cancel();
                      });
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddProduct(
                                    isOnline: isOnline,
                                    checkProductBarcode20or13: false,
                                    checkProductBarcode: true,
                                    productBarcode: "",
                                    packingNumber: widget.packingNumber,
                                    packingPrice: widget.packingPrice,
                                    id: widget.id,
                                    name: widget.name,
                                    productColors: widget.product_colors,
                                    image: localImagePath,
                                    customer_id: widget.customer_id.toString(),
                                    price: widget.price,
                                    qty: widget.qty,
                                    desc: widget.desc,
                                  )));
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
                        "اضافة الى الطلبية",
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
