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
      padding: const EdgeInsets.only(top: 15, right: 15, left: 15, bottom: 10),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Product Image
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 180,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12)),
                          child: ProductCardQuds.buildImage(widget.image),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Row(
                              children: [
                                Icon(Icons.inventory_2, 
                                  size: 18, 
                                  color: Color(0xff34568B).withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.name.length > 40
                                        ? widget.name.substring(0, 40) + '...'
                                        : widget.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: Color(0xff2c3e50)),
                                  ),
                                ),
                              ],
                            ),
                            // Price
                            Row(
                              children: [
                                Icon(Icons.attach_money, 
                                  size: 18, 
                                  color: Color(0xff34568B).withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  "السعر : ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "₪${widget.price}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 13,
                                      color: Color(0xff34568B)),
                                ),
                              ],
                            ),
                            // Quantity
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, 
                                  size: 18, 
                                  color: Color(0xff34568B).withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  "الكمية : ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.qty}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 13,
                                      color: Color(0xff34568B)),
                                ),
                              ],
                            ),
                            // Color
                            Visibility(
                              visible: widget.color == null ||
                                      widget.color.toString() == ""
                                  ? false
                                  : true,
                              child: Row(
                                children: [
                                  Icon(Icons.palette, 
                                    size: 18, 
                                    color: Color(0xff34568B).withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "اللون : ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 30,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(
                                          int.parse('0xFF${widget.color}')),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bonus 1
                            Visibility(
                              visible: ponus1,
                              child: Row(
                                children: [
                                  Icon(Icons.card_giftcard, 
                                    size: 18, 
                                    color: Color(0xff34568B).withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "بونص 1 : ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.ponus_one}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: Color(0xff34568B)),
                                  ),
                                ],
                              ),
                            ),
                            // Bonus 2
                            Visibility(
                              visible: ponus2,
                              child: Row(
                                children: [
                                  Icon(Icons.card_giftcard, 
                                    size: 18, 
                                    color: Color(0xff34568B).withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "بونص 2 : ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.ponus_two}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: Color(0xff34568B)),
                                  ),
                                ],
                              ),
                            ),
                            // Discount
                            Visibility(
                              visible: discountSetting,
                              child: Row(
                                children: [
                                  Icon(Icons.local_offer, 
                                    size: 18, 
                                    color: Color(0xff34568B).withOpacity(0.7)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "الخصم : ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600, 
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${widget.discount}%",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                            // Total
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xff34568B).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xff34568B).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calculate, 
                                        size: 16, 
                                        color: Color(0xff34568B).withOpacity(0.7)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "المجموع :",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.total.toString().length < 5
                                        ? "₪${widget.total}"
                                        : "₪${widget.total.toString().substring(0, 4)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13,
                                        color: Color(0xff34568B)),
                                  ),
                                ],
                              ),
                            ),
                            // Notes (if visible)
                            Visibility(
                              visible: notes,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.note, 
                                      size: 14, 
                                      color: Colors.amber.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.notes,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          color: Colors.amber.shade900),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          // Action Menu Button
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff34568B),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff34568B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: PopupMenuButton<int>(
                itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'حذف',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Color(0xff34568B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'تعديل',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (int value) {
                  _handleMenuSelection(value);
                },
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
