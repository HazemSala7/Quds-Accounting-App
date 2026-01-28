import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/orders_details/orders_details.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Optional widths config passed from the parent header so columns align perfectly.
class KashfLayout {
  final double balance, mnh, lah, bayan, date, actionId, notes;
  final String customerName, customerID;
  const KashfLayout({
    required this.balance,
    required this.customerID,
    required this.customerName,
    required this.mnh,
    required this.lah,
    required this.bayan,
    required this.date,
    required this.actionId,
    required this.notes,
  });

  double get total => balance + mnh + lah + bayan + date + actionId + notes;
}

class KashfCard extends StatefulWidget {
  final dynamic mnh, lah, balance, bayan, date, action_id, notes;
  final dynamic actions, shekat;
  final String customerName, customerID;

  /// NEW: optional layout widths to match the header row
  final KashfLayout? layoutWidths;

  const KashfCard({
    Key? key,
    required this.action_id,
    required this.customerID,
    required this.customerName,
    this.mnh,
    this.lah,
    required this.date,
    required this.shekat,
    required this.notes,
    required this.bayan,
    required this.balance,
    required this.actions,
    this.layoutWidths,
  }) : super(key: key);

  @override
  State<KashfCard> createState() => _KashfCardState();
}

class _KashfCardState extends State<KashfCard> {
  // Default widths used when layoutWidths is not provided.
  static const double _wBalance = 70;
  static const double _wMnh = 50;
  static const double _wLah = 50;
  static const double _wBayan = 100;
  static const double _wDate = 100;
  static const double _wAction = 50;
  static const double _wNotes = 100;

  KashfLayout get _w =>
      widget.layoutWidths ??
      const KashfLayout(
        balance: _wBalance,
        mnh: _wMnh,
        customerID: "0",
        customerName: "",
        lah: _wLah,
        bayan: _wBayan,
        date: _wDate,
        actionId: _wAction,
        notes: _wNotes,
      );

  bool get _parentControlsHorizontal =>
      widget.layoutWidths !=
      null; // if parent passed widths, it likely scrolls.

  @override
  Widget build(BuildContext context) {
    final notesText = (widget.notes ?? '-').toString();

    final topRow = SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: SizedBox(
          width: _w.total,
          child: Row(
            children: [
              _cell(
                width: _w.balance,
                bg: const Color(0xffDFDFDF),
                text: widget.balance.toString().length > 15
                    ? '${widget.balance.toString().substring(0, 15)}...'
                    : widget.balance.toString(),
                bold: true,
              ),
              _cell(
                width: _w.mnh,
                bg: Colors.white,
                text: '${widget.mnh}',
                bold: true,
              ),
              _cell(
                width: _w.lah,
                bg: const Color(0xffDFDFDF),
                text: '${widget.lah}',
                bold: true,
              ),
              // البيان (clickable when "مبيعات")
              InkWell(
                onTap: () {
                  if (widget.bayan == "مبيعات" ||
                      widget.bayan == "مشتريات" ||
                      widget.bayan == "مردرد مشتريات" ||
                      widget.bayan == "مردرد مبيعات") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersDetails(
                          printed: "0",
                          customer_id: widget.customerID,
                          orderDiscount: "0",
                          fatoraID: "1",
                          fatoraNumber: widget.action_id.toString(),
                          orderNotes: "",
                          deliveryDate: "",
                          customer_name: widget.customerName,
                          order_total: double.parse(widget.mnh.toString()),
                          f_code: "2",
                          id: widget.action_id,
                        ),
                      ),
                    );
                  }
                },
                child: _cell(
                  width: _w.bayan,
                  bg: Colors.white,
                  text: '${widget.bayan}',
                  bold: true,
                ),
              ),
              _cell(
                width: _w.date,
                bg: const Color(0xffDFDFDF),
                text: '${widget.date}',
                bold: true,
              ),
              _cell(
                width: _w.actionId,
                bg: Colors.white,
                text: '${widget.action_id}',
                bold: true,
              ),
              // NEW: الملاحظات
              _cell(
                width: _w.notes,
                bg: const Color(0xffF8F8F8),
                text: notesText.isEmpty ? '-' : notesText,
                bold: true,
                textColor: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        // If parent controls horizontal scroll, just paint fixed width row.
        // Otherwise wrap our own horizontal scroll so it never overflows.
        if (_parentControlsHorizontal)
          topRow
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: topRow,
          ),

        // ====== PRODUCTS SUBTABLE (if "مبيعات") ======
        Visibility(
          visible: widget.bayan == "مبيعات" ||
              widget.bayan == "مشتريات" ||
              widget.bayan == "مردرد مشتريات" ||
              widget.bayan == "مردرد مبيعات",
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "رقم الصنف",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8F8F8),
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "أسم الصنف",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "الكمية",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8F8F8),
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "بونص",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8F8F8),
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "الخصم",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8F8F8),
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "السعر",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffD6D3D3)),
                        ),
                        child: Center(
                          child: Text(
                            "المجموع الكلي",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Main_Color,
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
        ),
        Visibility(
          visible: widget.bayan == "مبيعات" ||
              widget.bayan == "مشتريات" ||
              widget.bayan == "مردرد مشتريات" ||
              widget.bayan == "مردرد مبيعات",
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              itemCount: (widget.actions as List).length,
              itemBuilder: (BuildContext context, int index) {
                final a = widget.actions[index] ?? {};
                return order_card(
                  product_name: (a['product_name'] ?? "-").toString(),
                  product_id: (a['product_id'] ?? "-").toString(),
                  discount: (a['discount'] ?? "-").toString(),
                  ponus1ini: (a['bonus1'] ?? "").toString(),
                  qty: (a['p_quantity'] ?? "-").toString(),
                  price: (a['p_price'] ?? "-").toString(),
                  total: (a['total'] ?? "-").toString(),
                );
              },
            ),
          ),
        ),

        // ====== CHECKS SUBTABLE ======
        Visibility(
          visible: widget.bayan == "قبض شيكات" ||
              widget.bayan == "صرف شيكات" ||
              widget.bayan == "شيكات مرتجعة",
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffF8F8F8),
                              border:
                                  Border.all(color: const Color(0xffD6D3D3)),
                            ),
                            child: Center(
                              child: Text(
                                "قيمة الشك",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Main_Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xffD6D3D3)),
                            ),
                            child: Center(
                              child: Text(
                                "رقم الشك ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Main_Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xffD6D3D3)),
                            ),
                            child: Center(
                              child: Text(
                                "تاريخ الاستحقاق",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Main_Color,
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
                padding: const EdgeInsets.only(bottom: 15),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: (widget.shekat as List).length,
                  itemBuilder: (BuildContext context, int index) {
                    final s = widget.shekat[index] ?? {};
                    return shakCard(
                      chakNumber: (s['chk_no'] ?? "-").toString(),
                      chakValue: (s['chk_value'] ?? 0) is num
                          ? (s['chk_value'] as num).toInt()
                          : int.tryParse((s['chk_value'] ?? '0').toString()) ??
                              0,
                      chakDate: (s['chk_date'] ?? "").toString(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ====== helpers ======
  Widget _cell({
    required double width,
    required String text,
    Color bg = Colors.white,
    bool bold = false,
    Color textColor = Colors.black,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: const Color(0xffD6D3D3)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }

  Widget order_card({
    String product_id = "",
    String product_name = "",
    String name = "",
    String ponus1ini = "",
    String discount = "",
    String qty = "",
    String price = "",
    String total = "",
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    product_id.isEmpty ? "-" : product_id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8F8),
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    product_name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    qty,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8F8),
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    ponus1ini,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8F8),
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    discount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8F8),
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    "₪$price",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    "₪$total",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget shakCard({
    String chakNumber = "",
    int chakValue = 0,
    String chakDate = "",
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F8F8),
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    chakValue.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    chakNumber.isEmpty ? "-" : chakNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffD6D3D3)),
                ),
                child: Center(
                  child: Text(
                    chakDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Main_Color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
