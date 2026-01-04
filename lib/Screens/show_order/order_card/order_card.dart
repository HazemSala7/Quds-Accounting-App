import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quds_yaghmour/components/product-widget-quds/product-widget-quds.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import '../../edit_product/edit_product.dart';

class OrderCard extends StatefulWidget {
  final image, name, total, notes, product_id, color;
  Function removeProduct;
  Function editProduct;
  int id;
  var qty, discount, ponus_one, ponus_two, price, invoice_id;
  var ItemCart;
  OrderCard(
      {Key? key,
      this.image,
      required this.qty,
      required this.product_id,
      required this.color,
      required this.notes,
      required this.id,
      required this.invoice_id,
      this.price,
      this.name,
      required this.ponus_one,
      required this.removeProduct,
      required this.editProduct,
      required this.ponus_two,
      required this.discount,
      required this.ItemCart,
      this.total})
      : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  @override
  void _handleMenuSelection(int value) {
    // Handle the selected option
    switch (value) {
      case 1:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("هل تريد بالتأكيد حذف هذا المنتج من الطلبية؟"),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        widget.removeProduct();
                        Fluttertoast.showToast(msg: "تم حذف المنتج بنجاح");
                      },
                      child: Container(
                        height: 50,
                        width: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Main_Color),
                        child: Center(
                          child: Text(
                            "نعم",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Main_Color),
                      child: Center(
                        child: Text(
                          "لا",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );

        break;
      case 2:
        widget.editProduct();
        break;
      case 3:
        // Handle option 3
        break;
      default:
        break;
    }
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, right: 15, left: 15),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 7,
                  blurRadius: 5,
                ),
              ],
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4)),
                          child: ProductCardQuds.buildImage(widget.image),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Text(
                                "الاسم :",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  widget.name.length > 50
                                      ? widget.name.substring(0, 50) + '...'
                                      : widget.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "السعر :",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                "₪${widget.price}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "الكمية :",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                '${widget.qty}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Visibility(
                            visible: widget.color == null ||
                                    widget.color.toString() == ""
                                ? false
                                : true,
                            child: Row(
                              children: [
                                Text(
                                  "اللون :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width: 50,
                                  height: 20,
                                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                        '0xFF${widget.color}')), // Convert color code to Color object
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 2.0,
                                    ),

                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ponus1,
                            child: Row(
                              children: [
                                Text(
                                  "بونص 1 :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "${widget.ponus_one}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: ponus2,
                            child: Row(
                              children: [
                                Text(
                                  "بونص 2 :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "${widget.ponus_two}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: discountSetting,
                            child: Row(
                              children: [
                                Text(
                                  "الخصم :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "${widget.discount}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "المجموع :",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                widget.total.toString().length < 5
                                    ? "₪${widget.total}"
                                    : "₪${widget.total.toString().substring(0, 4)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Visibility(
                            visible: notes,
                            child: Row(
                              children: [
                                Text(
                                  "الملاحظات :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  widget.notes,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 30,
              width: 30,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
              child: Center(
                child: PopupMenuButton<int>(
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    PopupMenuItem<int>(
                      value: 1,
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Main_Color,
                        ),
                        title: Text(
                          'حذف',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 2,
                      child: ListTile(
                        leading: Icon(
                          Icons.edit,
                          color: Main_Color,
                        ),
                        title: Text(
                          'تعديل',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ),
                  ],
                  onSelected: (int value) {
                    _handleMenuSelection(value);
                  },
                  child: FaIcon(
                    FontAwesomeIcons.listUl,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
