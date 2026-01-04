import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/catches/catch_card/catch_card.dart';
import 'package:quds_yaghmour/Screens/total_receivables/total_card/total_card.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Server/server.dart' as globals;
import '../../Services/Drawer/drawer.dart';

class Catches extends StatefulWidget {
  const Catches({Key? key}) : super(key: key);

  @override
  State<Catches> createState() => _CatchesState();
}

class _CatchesState extends State<Catches> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool showWithdrawnReceipts = true;
  String platform = Platform.isIOS ? "iOS" : "Android";
  String? userType;
  // iOS Variables
  flutterBlue.FlutterBlue flutterBlueInstance =
      flutterBlue.FlutterBlue.instance;
  flutterBlue.BluetoothDevice? connectedIOSDevice;
  List<flutterBlue.BluetoothDevice> discoveredDevices = [];

  void getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('type');
    });
  }

  Future<void> scanIOSDevices() async {
    try {
      // Start scanning
      flutterBlueInstance.startScan(timeout: Duration(seconds: 4));

      // Listen to scan results
      flutterBlueInstance.scanResults.listen((results) {
        setState(() {
          discoveredDevices = results.map((r) => r.device).toList();
        });
      });

      // Stop scanning after 5 seconds just in case
      await Future.delayed(Duration(seconds: 5));
      flutterBlueInstance.stopScan();
    } catch (e) {
      print("Error scanning for iOS Bluetooth devices: $e");
    }
  }

  setCont() {
    if (Platform.isIOS) {
      scanIOSDevices(); // 👈 only scan on iOS
    }
    setState(() {});
  }

  Widget build(BuildContext context) {
    return Container(
      color: globals.Main_Color,
      child: SafeArea(
          child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerMain(),
        appBar: PreferredSize(
            child: AppBarBack(
              title: "سندات القبض",
            ),
            preferredSize: Size.fromHeight(50)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "مجموع الشيكات : ${chksTotal}₪",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "مجموع النقدي : ${cashTotal}₪",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "مجموع الخصم : ${discountTotal}₪",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Center(
                                          child: CircularProgressIndicator())),
                                );
                              },
                            );
                            pdfFatora8CM();
                          },
                          child: Container(
                              height: 40,
                              width: 130,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: globals.Main_Color),
                              child: Center(
                                  child: Text(
                                "طباعة PDF",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )))),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 25, left: 25, top: 25),
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
                              borderSide: BorderSide(
                                  color: globals.Main_Color, width: 2.0),
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
                              borderSide: BorderSide(
                                  color: globals.Main_Color, width: 2.0),
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
              Visibility(
                visible: userType == "quds",
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, left: 25),
                  child: Row(
                    children: [
                      Checkbox(
                        value: showWithdrawnReceipts,
                        onChanged: (bool? value) {
                          setState(() {
                            showWithdrawnReceipts = value!;
                            Qadbs = [];
                            start_date.text == "" ? getQabds() : filterQabds();
                          });
                        },
                      ),
                      Text(
                        "عرض الكل ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Colors.white)),
                          child: Center(
                            child: Text(
                              "#الزبون",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Color(0xffD6D3D3))),
                          child: Center(
                            child: Text(
                              "أسم الزبون",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Color(0xffD6D3D3))),
                          child: Center(
                            child: Text(
                              "الشيكات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Color(0xffD6D3D3))),
                          child: Center(
                            child: Text(
                              "نقدا",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Color(0xffD6D3D3))),
                          child: Center(
                            child: Text(
                              "الخصم",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Colors.white)),
                          child: Center(
                            child: Text(
                              "التاريخ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                              color: globals.Main_Color,
                              border: Border.all(color: Colors.white)),
                          child: Center(
                            child: Text(
                              "ملاحظات",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Qadbs == null
                  ? Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SpinKitPulse(
                        color: globals.Main_Color,
                        size: 60,
                      ),
                    )
                  : Qadbs.length == 0
                      ? Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(
                              "لا يوجد أي سند قبض ",
                              style: TextStyle(fontSize: 24),
                            ),
                          ))
                      : ListView.builder(
                          itemCount: Qadbs.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return CatchCard(
                              qType: "qabd",
                              lattitude: (Qadbs[index]['customer'] is Map &&
                                      Qadbs[index]['customer'] != "-" &&
                                      Qadbs[index]['customer'] != "")
                                  ? double.tryParse(Qadbs[index]['customer']
                                              ["latitude"]
                                          .toString()) ??
                                      0.0
                                  : 0.0,
                              longitude: (Qadbs[index]['customer'] is Map &&
                                      Qadbs[index]['customer'] != "-" &&
                                      Qadbs[index]['customer'] != "")
                                  ? double.tryParse(Qadbs[index]['customer']
                                              ["longitude"]
                                          .toString()) ??
                                      0.0
                                  : 0.0,
                              uniqueID: Qadbs[index]['id'],
                              id: Qadbs[index]['customer_id'] ?? "0",
                              printed: Qadbs[index]['printed'] ?? "1",
                              cash: double.tryParse(
                                      Qadbs[index]['cash']?.toString() ??
                                          '0') ??
                                  0.0,
                              chaks: double.tryParse(
                                      Qadbs[index]['chks']?.toString() ??
                                          '0') ??
                                  0.0,
                              discount: double.tryParse(
                                      Qadbs[index]['discount']?.toString() ??
                                          '0') ??
                                  0.0,
                              balance: (double.tryParse(
                                          Qadbs[index]['chks']?.toString() ??
                                              '0') ??
                                      0.0) +
                                  (double.tryParse(
                                          Qadbs[index]['cash']?.toString() ??
                                              '0') ??
                                      0.0) +
                                  (double.tryParse(Qadbs[index]['discount']
                                              ?.toString() ??
                                          '0') ??
                                      0.0),
                              name: (Qadbs[index]['customer'] is Map &&
                                      Qadbs[index]['customer'] != "-" &&
                                      Qadbs[index]['customer'] != "")
                                  ? Qadbs[index]['customer']["c_name"] ?? "-"
                                  : "-",
                              phone: Qadbs[index]['q_date'] ?? "",
                              notes: Qadbs[index]['notes'] ?? "",
                              discoveredDevices: discoveredDevices,
                            );
                          },
                        ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      )),
    );
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

  @override
  void initState() {
    super.initState();
    setControllers();
    setCont();
    getQabds();
    getUserType();
  }

  setStart() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(
            2000), //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      // print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      // print(
      //     formattedDate); //formatted date output using intl package =>  2021-03-16
      //you can implement different kind of Date Format here according to your requirement

      setState(() {
        Qadbs = [];
        start_date.text = formattedDate;
        filterQabds();
      });
    } else {
      setState(() {
        Qadbs = [];
        getQabds();
      });
    }
  }

  setEnd() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(
            2000), //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        Qadbs = [];
        end_date.text = formattedDate;
        filterQabds();
      });
    } else {
      setState(() {
        Qadbs = [];
        getQabds();
      });
    }
  }

  bool fun = false;
  TextEditingController searchController = TextEditingController();
  filterQabds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    // Check if app is online
    if (globals.isOnline) {
      // ONLINE MODE - use API
      var headers = {
        'Authorization': 'Bearer $token',
        'ContentType': 'application/json'
      };

      var url = type == "quds"
          ? 'https://yaghm.com/admin/api/filter_qabds/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}'
          : '${AppLink.vansaleFilterQabds}/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}';

      var finalUrl = showWithdrawnReceipts ? url : '$url&downloaded=1';

      var response = await http.get(Uri.parse(finalUrl), headers: headers);
      var res = jsonDecode(response.body);

      setState(() {
        Qadbs = res["qabds"];
        chksTotal = double.parse(res["totals"]["chks"].toString());
        cashTotal = double.parse(res["totals"]["cash"].toString());
        discountTotal = double.parse(res["totals"]["discount"].toString());
      });
    } else {
      if (!!showWithdrawnReceipts) {
        // OFFLINE MODE
        List<CatchModel> filteredReceipts =
            await CartDatabaseHelper().getCatchReceiptsByDateRange(
          start_date.text.trim(),
          end_date.text.trim(),
        );

// Calculate totals
        double localChk = 0.0;
        double localCash = 0.0;
        double localDiscount = 0.0;

        for (var item in filteredReceipts) {
          localChk += item.totalChecks;
          localCash += item.cashAmount;
          localDiscount += item.discount;
        }

        setState(() {
          Qadbs = filteredReceipts.map((receipt) {
            return {
              "id": receipt.id,
              "customer_id": receipt.customerID,
              "cash": receipt.cashAmount,
              "chks": receipt.totalChecks,
              "finalTotal": receipt.finalTotal,
              "discount": receipt.discount,
              "notes": receipt.notes,
              "q_date": receipt.date,
              "q_type": receipt.qType,
              "customer": {
                "c_name": receipt.customerName,
              },
            };
          }).toList();

          chksTotal = localChk;
          cashTotal = localCash;
          discountTotal = localDiscount;
        });
      } else {
        // OFFLINE MODE
        List<CatchModel> filteredReceipts =
            await CartDatabaseHelper().getCatchReceiptsByDateRange(
          start_date.text.trim(),
          end_date.text.trim(),
        );

// Calculate totals
        double localChk = 0.0;
        double localCash = 0.0;
        double localDiscount = 0.0;

        for (var item in filteredReceipts) {
          localChk += item.totalChecks;
          localCash += item.cashAmount;
          localDiscount += item.discount;
        }
        final undownloadedReceipts =
            filteredReceipts.where((r) => r.downloaded == 0).toList();
        setState(() {
          Qadbs = undownloadedReceipts.map((receipt) {
            return {
              "id": receipt.id,
              "customer_id": receipt.customerID,
              "cash": receipt.cashAmount,
              "chks": receipt.totalChecks,
              "finalTotal": receipt.finalTotal,
              "discount": receipt.discount,
              "notes": receipt.notes,
              "q_date": receipt.date,
              "q_type": receipt.qType,
              "customer": {
                "c_name": receipt.customerName,
              },
            };
          }).toList();

          chksTotal = localChk;
          cashTotal = localCash;
          discountTotal = localDiscount;
        });
      }
    }
  }

  var Qadbs;
  double chksTotal = 0.0;
  double cashTotal = 0.0;
  double discountTotal = 0.0;
  Future<void> getQabds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
      // ✅ Online: Fetch from API
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var baseUrl = type == "quds"
          ? '${AppLink.CatchesReceiptQabdQuds}/$company_id/$salesman_id'
          : '${AppLink.vansaleQabds}/$company_id/$salesman_id';

      var url =
          showWithdrawnReceipts ? baseUrl : '$baseUrl?show_undownloaded=true';

      try {
        var response = await http.get(Uri.parse(url), headers: headers);
        var res = jsonDecode(response.body);

        setState(() {
          Qadbs = res["qabds"];
          chksTotal = double.parse(res["totals"]["chks"].toString());
          cashTotal = double.parse(res["totals"]["cash"].toString());
          discountTotal = double.parse(res["totals"]["discount"].toString());
        });
      } catch (e) {
        print("Error fetching data from server: $e");
        Fluttertoast.showToast(msg: "فشل تحميل البيانات من السيرفر");
      }
    } else {
      // ✅ Offline: Fetch from local SQLite database

      if (type == "quds") {
        if (!showWithdrawnReceipts) {
          List<CatchModel> localReceipts =
              await CartDatabaseHelper().getAllCatchReceiptsQabds();

          setState(() {
            final undownloadedReceipts =
                localReceipts.where((r) => r.downloaded == 0).toList();

            Qadbs = undownloadedReceipts.map((receipt) {
              return {
                "id": receipt.id,
                "customer_id": receipt.customerID,
                "cash": receipt.cashAmount,
                "chks": receipt.totalChecks,
                "finalTotal": receipt.finalTotal,
                "discount": receipt.discount,
                "notes": receipt.notes,
                "q_date": receipt.date,
                "q_type": receipt.qType,
                "customer": {"c_name": receipt.customerName},
              };
            }).toList();

            chksTotal =
                undownloadedReceipts.fold(0, (sum, r) => sum + r.totalChecks);
            cashTotal =
                undownloadedReceipts.fold(0, (sum, r) => sum + r.cashAmount);
            discountTotal =
                undownloadedReceipts.fold(0, (sum, r) => sum + r.discount);
          });
        } else {
          List<CatchModel> localReceipts =
              await CartDatabaseHelper().getAllCatchReceiptsQabds();

          setState(() {
            Qadbs = localReceipts.map((receipt) {
              return {
                "id": receipt.id,
                "customer_id": receipt.customerID,
                "cash": receipt.cashAmount,
                "chks": receipt.totalChecks,
                "finalTotal": receipt.finalTotal,
                "discount": receipt.discount,
                "notes": receipt.notes,
                "q_date": receipt.date,
                "q_type": receipt.qType,
                "customer": {"c_name": receipt.customerName},
              };
            }).toList();

            chksTotal = localReceipts.fold(0, (sum, r) => sum + r.totalChecks);
            cashTotal = localReceipts.fold(0, (sum, r) => sum + r.cashAmount);
            discountTotal = localReceipts.fold(0, (sum, r) => sum + r.discount);
          });
        }
      } else {
        List<CatchVansaleModel> localReceipts =
            await CartDatabaseHelper().getAllCatchReceiptsVansale();

        // ✅ Filter by qType = "qabd"
        final filteredReceipts =
            localReceipts.where((r) => r.qType == "qabd").toList();

        setState(() {
          Qadbs = filteredReceipts.map((receipt) {
            return {
              "id": receipt.id,
              "customer_id": receipt.customerID,
              "cash": receipt.cashAmount,
              "chks": receipt.totalChecks,
              "finalTotal": receipt.finalTotal,
              "discount": receipt.discount,
              "notes": receipt.notes,
              "q_date": receipt.date,
              "q_type": receipt.qType,
              "customer": {"c_name": receipt.customerName},
            };
          }).toList();

          chksTotal = filteredReceipts.fold(0, (sum, r) => sum + r.totalChecks);
          cashTotal = filteredReceipts.fold(0, (sum, r) => sum + r.cashAmount);
          discountTotal =
              filteredReceipts.fold(0, (sum, r) => sum + r.discount);
        });
      }

      Fluttertoast.showToast(msg: "تم تحميل السندات من قاعدة البيانات المحلية");
    }
  }

  pdfFatora8CM() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? shop_no = prefs.getString('shop_no');
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    List<pw.Widget> widgets = [];
    final title = pw.Column(
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(),
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.SizedBox(width: 5),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child:
                    pw.Text("التاريخ : ", style: pw.TextStyle(fontSize: 20))),
          ]),
        ]),
        pw.SizedBox(height: 2),
      ],
    );
    widgets.add(title);
    final firstrow = pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Expanded(
              flex: 1,
              child: pw.Container(
                child: pw.Center(
                  child: pw.Text(
                    "ملاحظات",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Expanded(
              flex: 2,
              child: pw.Container(
                child: pw.Center(
                  child: pw.Text(
                    "التاريخ",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Expanded(
              flex: 1,
              child: pw.Container(
                child: pw.Center(
                  child: pw.Text(
                    "المبلغ",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Expanded(
              flex: 6,
              child: pw.Container(
                child: pw.Center(
                  child: pw.Text(
                    "أسم الزبون",
                    style: pw.TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    widgets.add(firstrow);

    final listview = pw.ListView.builder(
      itemCount: Qadbs.length,
      itemBuilder: (context, index) {
        // Safely extract the customer name
        final customerMap = Qadbs[index]['customer'] ?? {};
        final String cName = customerMap.toString() == "-"
            ? "-"
            : customerMap['c_name']?.toString() ?? '';

        // Truncate if longer than 15 characters
        final String displayName =
            cName.length > 15 ? '${cName.substring(0, 15)}...' : cName;
        var BALANCE = double.parse(Qadbs[index]['chks'].toString()) +
            double.parse(Qadbs[index]['cash'].toString()) +
            double.parse(Qadbs[index]['discount'].toString());
        return pw.Container(
          height: 15,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(right: 5, left: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          "${Qadbs[index]["notes"] ?? "-"}",
                          style: pw.TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          "${Qadbs[index]["q_date"] ?? "-"}",
                          style: pw.TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          "${BALANCE}",
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Expanded(
                    flex: 6,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          displayName,
                          style: pw.TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    widgets.add(listview);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        pageFormat: PdfPageFormat.a4,

        build: (context) => widgets, //here goes the widgets list
      ),
    );
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
