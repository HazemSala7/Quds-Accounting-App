import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/kashf_card/kashf_card.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/progress_dialog/progress_dialog.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class KashfHesab extends StatefulWidget {
  final customer_id, name, balance;
  const KashfHesab(
      {Key? key, this.customer_id, this.name, required this.balance})
      : super(key: key);

  @override
  State<KashfHesab> createState() => _KashfHesabState();
}

class _KashfHesabState extends State<KashfHesab> {
  @override
  static const double _tableWidth = 520;
  final ScrollController _hHeaderCtrl = ScrollController();
  final ScrollController _hBodyCtrl = ScrollController();
  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
          child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerMain(),
        appBar: PreferredSize(
            child: AppBarBack(
              title: "كشف حساب",
            ),
            preferredSize: Size.fromHeight(50)),
        body: _isFirstLoadRunning
            ? Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: SpinKitPulse(
                  color: Main_Color,
                  size: 60,
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Text(
                                "${widget.name.length > 14 ? widget.name.substring(0, 14) + '...' : widget.name} : ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                "₪${widget.balance}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return ProgressDialog();
                                },
                              );
                              await Future.delayed(Duration(seconds: 5));
                              getAllStatments(false);
                            } catch (e) {
                              Fluttertoast.showToast(
                                  msg: "حدث خطأ ما , الرجاء المحاوله فيما بعد");
                            }
                          },
                          child: Container(
                            height: 40,
                            width: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Main_Color,
                            ),
                            child: Center(
                              child: Text(
                                "طباعة",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 25, left: 10, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            child: TextField(
                              onTap: setStart,
                              controller: start_date,
                              readOnly: true,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'من تاريخ',
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
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            child: TextField(
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              onTap: setEnd,
                              controller: end_date,
                              readOnly: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'الى تاريخ',
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
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          // HEADER (horizontal scroll)
                          SizedBox(
                            height: 40,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _hHeaderCtrl,
                              child: Container(
                                width: _tableWidth,
                                child: Row(
                                  children: const [
                                    _HeaderCell(label: "الرصيد", width: 70),
                                    _HeaderCell(label: "منه", width: 50),
                                    _HeaderCell(label: "له", width: 50),
                                    _HeaderCell(label: "البيان", width: 100),
                                    _HeaderCell(label: "التاريخ", width: 100),
                                    _HeaderCell(label: "رقم السند", width: 50),
                                    _HeaderCell(label: "الملاحظات", width: 100),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // BODY fills the remaining height
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _hBodyCtrl,
                              child: SizedBox(
                                width: _tableWidth,
                                child: ListView.builder(
                                  controller: _controller,
                                  itemCount: listPDF.length,
                                  itemBuilder: (context, index) {
                                    customersBalances.clear();
                                    for (var customer in listPDF) {
                                      customersBalances.add(
                                          customer['money_amount'].toString());
                                    }

                                    final notes = (listPDF[index]['notes'] ??
                                            listPDF[index]['note'] ??
                                            listPDF[index]['remark'] ??
                                            listPDF[index]['comments'] ??
                                            "-")
                                        .toString();

                                    return KashfCard(
                                      customerID: widget.customer_id.toString(),
                                      customerName: widget.name.toString(),
                                      actions: listPDF[index]['action'] ?? [],
                                      shekat: listPDF[index]['shekat'] ?? [],
                                      action_id:
                                          listPDF[index]['action_id'] ?? "-",
                                      balance:
                                          listPDF[index]['balance'].toString(),
                                      bayan:
                                          listPDF[index]['action_type'] ?? "",
                                      mnh: double.parse(listPDF[index]
                                                      ['money_amount']
                                                  .toString()) >
                                              0
                                          ? listPDF[index]['money_amount']
                                              .toString()
                                          : "0",
                                      lah: double.parse(listPDF[index]
                                                      ['money_amount']
                                                  .toString()) <
                                              0
                                          ? (double.parse(listPDF[index]
                                                          ['money_amount']
                                                      .toString()) *
                                                  -1)
                                              .toString()
                                          : "0",
                                      date: listPDF[index]['action_date'] ?? "",
                                      notes: notes,
                                      layoutWidths: KashfLayout(
                                        customerID:
                                            widget.customer_id.toString(),
                                        customerName: widget.name.toString(),
                                        balance: 70,
                                        mnh: 50,
                                        lah: 50,
                                        bayan: 100,
                                        date: 100,
                                        actionId: 50,
                                        notes: 100,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Optional: a tiny space for the bottom loader so it doesn't fight layout
                          if (_isLoadMoreRunning)
                            const Padding(
                              padding: EdgeInsets.only(top: 10, bottom: 8),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      )),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  final customersBalances = [];

  getCustomerBalance(int index) {
    double sum = 0.0;
    for (var i = 0; i < index + 1; i++) {
      sum += double.parse(customersBalances[i]);
    }
    return sum;
  }

  pdfPrinter8CM(bool withproduct) async {
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    List<pw.Widget> widgets = [];
    final title = pw.Column(
      children: [
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              "كشف حساب",
              style: pw.TextStyle(fontSize: 15),
            ),
          ),
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(widget.name.toString(),
                    style: pw.TextStyle(fontSize: 8))),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("السيد : ")),
          ],
        ),
        pw.SizedBox(
          height: 20,
        ),
      ],
    );
    widgets.add(title);
    final firstrow = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 1,
            child: pw.Center(
              child: pw.Text(
                "رقم السند",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 2,
            child: pw.Center(
              child: pw.Text(
                "التاريخ",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 3,
            child: pw.Center(
              child: pw.Text(
                "البيان",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 1,
            child: pw.Center(
              child: pw.Text(
                "له",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 1,
            child: pw.Center(
              child: pw.Text(
                "منه",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Expanded(
            flex: 1,
            child: pw.Center(
              child: pw.Text(
                "الرصيد",
                style: pw.TextStyle(fontSize: 5),
              ),
            ),
          ),
        ),
      ],
    );
    widgets.add(firstrow);
    final firstpadding = pw.Padding(
      padding: pw.EdgeInsets.only(top: 10),
      child: pw.Container(
        width: double.infinity,
        height: 2,
        color: PdfColors.grey,
      ),
    );
    widgets.add(firstpadding);
    final listview = pw.ListView.builder(
      itemCount: listPDFAll.length,
      itemBuilder: (context, index) {
        customersBalances.clear();
        for (var customer in listPDFAll) {
          customersBalances.add(customer['money_amount'].toString());
        }
        return listPDFAll[index]["action_type"] != "مبيعات"
            ? firstrowPDF(index, false)
            : pw.Column(children: [
                firstrowPDF(index, false),
                withproduct
                    ? pw.Column(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 15),
                            child: pw.Container(
                              height: 40,
                              width: double.infinity,
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("المجموع الكلي",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("السعر",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("بونص",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("الكمية",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 3,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("أسم الصنف",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                        flex: 1,
                                        child: pw.Container(
                                          child: pw.Center(
                                              child: pw.Text("رقم الصنف",
                                                  style: pw.TextStyle(
                                                      fontSize: 4))),
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          listPDFAll[index]["action"].length == 0
                              ? pw.Text(
                                  "لا يوجد منتجات",
                                )
                              : pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 15),
                                  child: pw.ListView.builder(
                                    itemCount:
                                        listPDFAll[index]["action"].length > 15
                                            ? 15
                                            : listPDFAll[index]["action"]
                                                .length,
                                    itemBuilder: (context, i) {
                                      return order_card(
                                        fat8cm: true,
                                        product_name: listPDFAll[index]
                                                ["action"][i]['product_name'] ??
                                            "-",
                                        product_id: listPDFAll[index]["action"]
                                                [i]['product_id'] ??
                                            "-",
                                        qty: listPDFAll[index]["action"][i]
                                                ['p_quantity'] ??
                                            "-",
                                        ponus: listPDFAll[index]["action"][i]
                                                ['bonus1'] ??
                                            "-",
                                        price: listPDFAll[index]["action"][i]
                                                ['p_price'] ??
                                            "-",
                                        total: listPDFAll[index]["action"][i]
                                                ['total'] ??
                                            "-",
                                      );
                                    },
                                  ),
                                )
                        ],
                      )
                    : pw.Container()
              ]);
      },
    );
    widgets.add(listview);
    final totals = pw.Column(
      children: [
        pw.SizedBox(
          height: 20,
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(total_mnh.toString(),
                    style: pw.TextStyle(fontSize: 12))),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("الرصيد المدين : ",
                    style: pw.TextStyle(fontSize: 12))),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(total_lah.toString(),
                    style: pw.TextStyle(fontSize: 12))),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("الرصيد الدائن : ",
                    style: pw.TextStyle(fontSize: 12))),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("${LastBalanceValue}",
                    style: pw.TextStyle(fontSize: 12))),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("المجموع النهائي : ",
                    style: pw.TextStyle(fontSize: 12))),
          ],
        ),
      ],
    );
    widgets.add(totals);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        maxPages: 20,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        pageFormat: PdfPageFormat(
          4 * PdfPageFormat.cm,
          20 * PdfPageFormat.cm,
        ),
        build: (context) => widgets, //here goes the widgets list
      ),
    );

    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> pdfPrinterA4(bool withProduct, bool withShekat) async {
    print("1.0");
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    final pdf = pw.Document();
    const chunkSize = 50;

    for (var i = 0; i < listPDFAll.length; i += chunkSize) {
      final chunk = listPDFAll.sublist(
        i,
        (i + chunkSize > listPDFAll.length) ? listPDFAll.length : i + chunkSize,
      );

      List<pw.Widget> widgets = [];

      // Only show title on the first page
      if (i == 0) {
        widgets.add(
          pw.Column(children: [
            pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("كشف حساب", style: pw.TextStyle(fontSize: 20)),
              ),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(widget.name.toString(),
                        style: pw.TextStyle(fontSize: 15))),
                pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text("السيد : ")),
              ],
            ),
            pw.SizedBox(height: 20),
          ]),
        );
      }

      // Add your original list rendering code but use chunk instead of listPDFAll
      for (int j = 0; j < chunk.length; j++) {
        int originalIndex =
            i + j; // required to use correct index in firstrowPDF

        widgets.add(
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: chunk[j]["action_type"] == "مبيعات" ||
                    chunk[j]["action_type"] == "مشتريات" ||
                    chunk[j]["action_type"] == "مردرد مشتريات" ||
                    chunk[j]["action_type"] == "مردرد مبيعات"
                ? pw.Column(children: [
                    firstrowPDF(originalIndex, true),
                    if (withProduct) ...[
                      // Header
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          border: pw.Border.all(color: PdfColors.black),
                        ),
                        child: pw.Row(
                          children: [
                            "المبلغ",
                            "السعر",
                            "الخصم",
                            "بونص",
                            "الكمية",
                            "اسم الصنف",
                            "رقم الصنف"
                          ]
                              .map((e) => pw.Expanded(
                                    child: pw.Center(
                                      child: pw.Directionality(
                                          textDirection: pw.TextDirection.rtl,
                                          child: pw.Text(e)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // Products
                      if (chunk[j]["action"].isEmpty)
                        pw.Text("لا يوجد منتجات")
                      else
                        ...List.generate(chunk[j]["action"].length, (k) {
                          return pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.black),
                            ),
                            child: pw.Row(
                              children: [
                                'total',
                                'p_price',
                                'discount',
                                'bonus1',
                                'p_quantity',
                                'product_name',
                                'product_id'
                              ]
                                  .map((key) => pw.Expanded(
                                        child: pw.Center(
                                          child: pw.Directionality(
                                            textDirection: pw.TextDirection.rtl,
                                            child: pw.Text(chunk[j]["action"][k]
                                                        [key]
                                                    ?.toString() ??
                                                "-"),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          );
                        }),
                    ]
                  ])
                : (["قبض شيكات", "صرف شيكات", "شيكات مرتجعة"]
                        .contains(chunk[j]["action_type"]))
                    ? pw.Column(children: [
                        firstrowPDF(originalIndex, true),
                        // Header
                        if (withShekat) ...[
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              border: pw.Border.all(color: PdfColors.black),
                            ),
                            child: pw.Row(
                              children:
                                  ["قيمة الشك", "رقم الشك", "تاريخ الاستحقاق"]
                                      .map((e) => pw.Expanded(
                                            child: pw.Center(
                                              child: pw.Directionality(
                                                  textDirection:
                                                      pw.TextDirection.rtl,
                                                  child: pw.Text(e)),
                                            ),
                                          ))
                                      .toList(),
                            ),
                          ),
                          // Shekat
                          if (chunk[j]["shekat"].isEmpty)
                            pw.Text("لا يوجد شيكات")
                          else
                            ...List.generate(chunk[j]["shekat"].length, (k) {
                              return pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black),
                                ),
                                child: pw.Row(
                                  children: ['chk_value', 'chk_no', 'chk_date']
                                      .map((key) => pw.Expanded(
                                            child: pw.Center(
                                              child: pw.Directionality(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                child: pw.Text(chunk[j]
                                                            ["shekat"][k][key]
                                                        ?.toString() ??
                                                    "-"),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            }),
                        ]
                      ])
                    : firstrowPDF(originalIndex, true),
          ),
        );
      }

      // Show totals only once, on last page
      if (i + chunkSize >= listPDFAll.length) {
        widgets.add(
          pw.Column(
            children: [
              pw.SizedBox(height: 20),
              ...[
                {"label": "الرصيد المدين : ", "value": total_mnh},
                {"label": "الرصيد الدائن : ", "value": total_lah},
                {"label": "المجموع النهائي : ", "value": LastBalanceValue}
              ].map((item) => pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(item["value"].toString()),
                        ),
                        pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(item["label"],
                              style: pw.TextStyle(fontSize: 18)),
                        )
                      ],
                    ),
                  )),
            ],
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont),
          margin: pw.EdgeInsets.all(20),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: pw.TextStyle(color: PdfColors.black, fontSize: 14),
              ),
            ),
          ),
          build: (context) => widgets,
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  TextEditingController start_date = TextEditingController();
  TextEditingController end_date = TextEditingController();
  setControllers() {
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    String actualDate = formatterDate.format(now);
    setState(() {
      end_date.text = actualDate;
    });
  }

  setStart() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        start_date.text = formattedDate;
      });
      if (start_date.text != "") {
        _pageFilter = 1;
        filterStatmentsFirstCall();
      } else {
        _page = 1;
        _firstLoad();
      }
    } else {
      // print("Date is not selected");
    }
  }

  setEnd() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        end_date.text = formattedDate;
      });
      if (end_date.text != "") {
        filterStatmentsFirstCall();
      } else {
        _firstLoad();
      }
    } else {
      // print("Date is not selected");
    }
  }

  pw.Padding firstrowPDF(int index, bool A4) {
    return pw.Padding(
      padding: A4
          ? pw.EdgeInsets.only(right: 15, left: 15, top: 5)
          : pw.EdgeInsets.only(top: 5),
      child: pw.Container(
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Center(
                      child: pw.Text(
                        "${listPDFAll[index]['action_id'] ?? "-"}",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: A4 ? 14 : 5),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 2,
                    child: pw.Center(
                      child: pw.Text(
                        "${listPDFAll[index]['action_date'] ?? ""}",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: A4 ? 14 : 5),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 3,
                    child: pw.Center(
                      child: pw.Text(
                        "${listPDFAll[index]['action_type'] ?? ""}",
                        style: pw.TextStyle(fontSize: A4 ? 14 : 5),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Center(
                      child: pw.Text(
                        "${double.parse(listPDFAll[index]['money_amount'].toString()) < 0 ? double.parse(listPDFAll[index]['money_amount'].toString()) * -1 : "0"}",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: A4 ? 14 : 5),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Center(
                      child: pw.Text(
                        "${double.parse(listPDFAll[index]['money_amount'].toString()) > 0 ? listPDFAll[index]['money_amount'].toString() : "0"}",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: A4 ? 14 : 5),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Center(
                      child: pw.Text(
                        "${double.parse(listPDFAll[index]['balance'].toString()).toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: A4 ? 14 : 5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Container(
                width: double.infinity,
                height: 2,
                color: PdfColors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }

  var listPDFAll = [];
  var listPDF = [];
  List array_mnh = [];
  List action_type = [];
  double total_mnh = 0.0;

  List array_lah = [];
  double total_lah = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setControllers();
    _firstLoad();
    _controller = ScrollController()..addListener(_loadMore);
    // sync horizontal scrolling between header and body
    _hBodyCtrl.addListener(() {
      if (_hHeaderCtrl.hasClients && _hHeaderCtrl.offset != _hBodyCtrl.offset) {
        _hHeaderCtrl.jumpTo(_hBodyCtrl.offset);
      }
    });
    _hHeaderCtrl.addListener(() {
      if (_hBodyCtrl.hasClients && _hBodyCtrl.offset != _hHeaderCtrl.offset) {
        _hBodyCtrl.jumpTo(_hHeaderCtrl.offset);
      }
    });
  }

  // At the beginning, we fetch the first 20 posts
  int _page = 1;
  int _pageFilter = 1;
  // you can change this value to fetch more or less posts per page (10, 15, 5, etc)
  final int _limit = 20;

  // There is next page or not
  bool _hasNextPage = true;

  // Used to display loading indicators when _firstLoad function is running
  bool _isFirstLoadRunning = false;

  // Used to display loading indicators when _loadMore function is running
  bool _isLoadMoreRunning = false;

  filterStatmentsFirstCall() async {
    setState(() {
      _isFirstLoadRunning = true;
      listPDF = [];
      listPDFAll = [];
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        'https://yaghm.com/admin/api/filter_statments/$company_id/$salesman_id/${widget.customer_id.toString()}/${start_date.text}/${end_date.text}/${order_kashf_from_new_to_old ? "desc" : "asc"}?page=$_pageFilter';

    var response = await http.get(Uri.parse(url), headers: headers);
    try {
      setState(() {
        listPDF = json.decode(response.body)["statments"]["data"];
        listPDFAll = json.decode(response.body)["statments"]["data"];
        _isFirstLoadRunning = false;
      });
    } catch (e) {
      setState(() {
        var responseData = json.decode(response.body);
        if (responseData.containsKey("statments")) {
          listPDF = responseData["statments"]["data"];
          listPDFAll = responseData["statments"]["data"];
        } else if (responseData.containsKey("statement")) {
          listPDF = [responseData["statement"]];
          listPDFAll = [responseData["statement"]];
        }
        _isFirstLoadRunning = false;
      });
    }
  }

  filterStatmentsSecondCall() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller!.position.extentAfter < 300) {
      print("10");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');
      var headers = {
        'Authorization': 'Bearer $token',
        'ContentType': 'application/json'
      };
      setState(() {
        _isLoadMoreRunning = true;
      });
      _pageFilter += 1;
      var url =
          'https://yaghm.com/admin/api/filter_statments/$company_id/$salesman_id/${widget.customer_id.toString()}/${start_date.text}/${end_date.text}/${order_kashf_from_new_to_old ? "desc" : "asc"}?page=$_pageFilter';
      var response = await http.get(Uri.parse(url), headers: headers);
      final List fetchedPosts = json.decode(response.body)["statments"]["data"];
      if (fetchedPosts.isNotEmpty) {
        // Filter out duplicates based on unique identifiers
        final uniqueFetchedPosts = fetchedPosts
            .where((newPost) => !listPDF
                .any((existingPost) => newPost['id'] == existingPost['id']))
            .toList();

        setState(() {
          listPDF.addAll(uniqueFetchedPosts);
        });
      } else {
        Fluttertoast.showToast(msg: "نهاية الكشف");
        Timer(Duration(milliseconds: 300), () {
          Fluttertoast.cancel();
        });
      }
      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  var LastBalanceValue;

  // This function will be called when the app launches (see the initState function)
  void _firstLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      var url =
          "https://yaghm.com/admin/api/statments/${company_id.toString()}/${widget.customer_id.toString()}/${order_kashf_from_new_to_old ? "desc" : "asc"}?page=$_page";
      final res = await http.get(Uri.parse(url));
      setState(() {
        listPDF = json.decode(res.body)["statments"]["data"];
      });
    } catch (err) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  bool withProduct = false;
  bool withShekat = false;
  getAllStatments(bool? withPro) async {
    setState(() {
      total_lah = 0.0;
      total_mnh = 0.0;
      listPDFAll.clear();
      array_mnh.clear();
      array_lah.clear();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    try {
      if (start_date.text == "" || end_date.text == "") {
        var url =
            "https://yaghm.com/admin/api/all_statments/${company_id.toString()}/${widget.customer_id.toString()}/${order_kashf_from_new_to_old ? "desc" : "asc"}?page=$_page";
        print("url");
        print(url);
        final res = await http.get(Uri.parse(url));
        setState(() {
          listPDFAll = json.decode(res.body)["statments"];
          for (int i = 0; i < listPDFAll.length; i++) {
            if (double.parse(listPDFAll[i]['money_amount'].toString()) > 0) {
              var money = listPDFAll[i]['money_amount'].toString();

              array_mnh.add(money);
            } else {
              var money =
                  double.parse(listPDFAll[i]['money_amount'].toString()) * -1;

              array_lah.add(money);
            }
          }
          for (int i = 0; i < array_mnh.length; i++) {
            total_mnh = total_mnh + double.parse(array_mnh[i].toString());
          }
          for (int i = 0; i < array_lah.length; i++) {
            total_lah = total_lah + double.parse(array_lah[i].toString());
          }
          var lastBalanceASC =
              listPDFAll.isNotEmpty ? listPDFAll.last['balance'] : null;
          var lastBalanceDESC =
              listPDFAll.isNotEmpty ? listPDFAll.first['balance'] : null;

          LastBalanceValue =
              order_kashf_from_new_to_old ? lastBalanceDESC : lastBalanceASC;
        });
      } else {
        print("2");
        var url =
            "https://yaghm.com/admin/api/get_all_filter_statments/$company_id/$salesman_id/${widget.customer_id.toString()}/${start_date.text}/${end_date.text}/${order_kashf_from_new_to_old ? "desc" : "asc"}";
        final res = await http.get(Uri.parse(url));
        setState(() {
          listPDFAll = json.decode(res.body)["statments"];
          for (int i = 0; i < listPDFAll.length; i++) {
            if (double.parse(listPDFAll[i]['money_amount'].toString()) > 0) {
              var money = listPDFAll[i]['money_amount'].toString();

              array_mnh.add(money);
            } else {
              var money =
                  double.parse(listPDFAll[i]['money_amount'].toString()) * -1;

              array_lah.add(money);
            }
          }
          for (int i = 0; i < array_mnh.length; i++) {
            total_mnh = total_mnh + double.parse(array_mnh[i].toString());
          }
          for (int i = 0; i < array_lah.length; i++) {
            total_lah = total_lah + double.parse(array_lah[i].toString());
          }
          var lastBalanceASC =
              listPDFAll.isNotEmpty ? listPDFAll.last['balance'] : null;
          var lastBalanceDESC =
              listPDFAll.isNotEmpty ? listPDFAll.first['balance'] : null;

          LastBalanceValue =
              order_kashf_from_new_to_old ? lastBalanceDESC : lastBalanceASC;
        });
      }

      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                actions: <Widget>[
                  CheckboxListTile(
                    title: Text('طباعة مع منتجات'),
                    value: withProduct,
                    onChanged: (bool? value) {
                      setState(() {
                        withProduct = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('طباعة مع شكات'),
                    value: withShekat,
                    onChanged: (bool? value) {
                      setState(() {
                        withShekat = value!;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              actions: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
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
                                      pdfPrinter8CM(withPro!);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "طباعة 8سم",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
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

                                      pdfPrinterA4(withProduct, withShekat);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "طباعة A4",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Main_Color,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          "لا أريد",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Main_Color,
                        ),
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            "طباعة",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (err) {
      if (kDebugMode) {
        Navigator.of(context, rootNavigator: true).pop();
        print('Something went wrong , $err');
      }
    }
  }

  void showPrintOptionsDialog(BuildContext context, bool? withPro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              actions: <Widget>[
                CheckboxListTile(
                  title: Text('طباعة مع منتجات'),
                  value: withProduct,
                  onChanged: (bool? value) {
                    setState(() {
                      withProduct = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('طباعة مع شكات'),
                  value: withShekat,
                  onChanged: (bool? value) {
                    setState(() {
                      withShekat = value!;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            actions: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: InkWell(
                                  onTap: () {
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
                                    pdfPrinter8CM(withPro!);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Main_Color,
                                    ),
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        "طباعة 8سم",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: InkWell(
                                  onTap: () {
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

                                    pdfPrinterA4(withProduct, withShekat);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Main_Color,
                                    ),
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        "طباعة A4",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Main_Color,
                                    ),
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        "لا أريد",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Main_Color,
                      ),
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          "طباعة",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // This function will be triggered whenver the user scroll
  // to near the bottom of the list view
  void _loadMore() async {
    if (start_date.text != "") {
      filterStatmentsSecondCall();
    } else {
      print("1");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');
      String? code_price = prefs.getString('price_code');
      if (_hasNextPage == true &&
          _isFirstLoadRunning == false &&
          _isLoadMoreRunning == false &&
          _controller!.position.extentAfter < 300) {
        setState(() {
          _isLoadMoreRunning =
              true; // Display a progress indicator at the bottom
        });
        _page += 1; // Increase _page by 1

        try {
          var url =
              "https://yaghm.com/admin/api/statments/${company_id.toString()}/${widget.customer_id.toString()}/${order_kashf_from_new_to_old ? "desc" : "asc"}?page=$_page";

          final res = await http.get(Uri.parse(url));

          final List fetchedPosts = json.decode(res.body)["statments"]["data"];
          if (fetchedPosts.isNotEmpty) {
            // Filter out duplicates based on unique identifiers
            final uniqueFetchedPosts = fetchedPosts
                .where((newPost) => !listPDF
                    .any((existingPost) => newPost['id'] == existingPost['id']))
                .toList();

            setState(() {
              listPDF.addAll(uniqueFetchedPosts);
            });
          } else {
            Fluttertoast.showToast(msg: "نهاية الكشف");
            Timer(Duration(milliseconds: 300), () {
              Fluttertoast.cancel();
            });
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
  }

  ScrollController? _controller;
  // ScrollController? _controllerFilterStatments;

  @override
  void dispose() {
    _controller?.removeListener(_loadMore);
    _hHeaderCtrl.dispose();
    _hBodyCtrl.dispose();
    super.dispose();
  }

  pw.Container order_card(
      {String product_id = "",
      String product_name = "",
      bool fat8cm = false,
      String name = "",
      String qty = "",
      String ponus = "",
      String price = "",
      String total = ""}) {
    return pw.Container(
      width: double.infinity,
      height: 15,
      child: pw.Padding(
        padding:
            pw.EdgeInsets.only(left: fat8cm ? 0 : 10, right: fat8cm ? 0 : 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            // Expanded(flex: 1, child: Center(child: Text(product_id))),

            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text("$total",
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text("$price",
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text(ponus,
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text(qty,
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text(
                            product_name.length > 20
                                ? product_name.substring(0, 20) + '...'
                                : product_name,
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text(product_id == "" ? "-" : product_id,
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 8))),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  pw.Container shakCard(
      {String shakValue = "",
      String shakNumber = "",
      String shakDate = "",
      bool fat8cm = false}) {
    return pw.Container(
      width: double.infinity,
      height: 15,
      child: pw.Padding(
        padding:
            pw.EdgeInsets.only(left: fat8cm ? 0 : 10, right: fat8cm ? 0 : 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text("$shakValue",
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 12))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text("$shakNumber",
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 12))),
                  )),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    child: pw.Center(
                        child: pw.Text(shakDate.toString(),
                            style: pw.TextStyle(fontSize: fat8cm ? 4 : 12))),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  const _HeaderCell({Key? key, required this.label, required this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Color.fromRGBO(83, 89, 219, 1),
            Color.fromRGBO(32, 39, 160, 0.6),
          ]),
          border: Border.all(color: Colors.white)),
      width: width,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
