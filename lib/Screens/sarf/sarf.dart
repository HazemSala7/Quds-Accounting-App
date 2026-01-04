import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/Screens/catches/catch_card/catch_card.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Server/server.dart' as globals;
import '../../Services/Drawer/drawer.dart';

class Sarf extends StatefulWidget {
  const Sarf({Key? key}) : super(key: key);

  @override
  State<Sarf> createState() => _SarfState();
}

class _SarfState extends State<Sarf> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool showWithdrawnReceipts = false;
  String? userType;
  var Qadbs;

  void getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('type');
    });
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
              title: "سندات صرف",
            ),
            preferredSize: Size.fromHeight(50)),
        body: SingleChildScrollView(
          child: Column(
            children: [
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
                            start_date.text == "" ? getSarfs() : filterSarfs();
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
                padding: const EdgeInsets.only(top: 40),
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
                              "لا يوجد أي سند صرف ",
                              style: TextStyle(fontSize: 24),
                            ),
                          ))
                      : ListView.builder(
                          itemCount: Qadbs.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return CatchCard(
                              discoveredDevices: [],
                              qType: "sarf",
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
                              cash:
                                  double.parse(Qadbs[index]['cash'].toString()),
                              chaks:
                                  double.parse(Qadbs[index]['chks'].toString()),
                              discount: double.parse(
                                  Qadbs[index]['discount'].toString()),
                              balance: double.parse(
                                      Qadbs[index]['chks'].toString()) +
                                  double.parse(
                                      Qadbs[index]['cash'].toString()) +
                                  double.parse(
                                      Qadbs[index]['discount'].toString()),
                              name: (Qadbs[index]['customer'] is Map &&
                                      Qadbs[index]['customer'] != "-" &&
                                      Qadbs[index]['customer'] != "")
                                  ? Qadbs[index]['customer']["c_name"] ?? "-"
                                  : "-",
                              phone: Qadbs[index]['q_date'] ?? "",
                              notes: Qadbs[index]['notes'] ?? "",
                            );
                          },
                        ),
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
    getSarfs();
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
        filterSarfs();
      });
    } else {
      setState(() {
        Qadbs = [];
        getSarfs();
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
        filterSarfs();
      });
    } else {
      setState(() {
        Qadbs = [];
        getSarfs();
      });
    }
  }

  bool fun = false;
  double chksTotal = 0.0;
  double cashTotal = 0.0;
  double discountTotal = 0.0;
  TextEditingController searchController = TextEditingController();

  filterSarfs() async {
    String downloadedParam = showWithdrawnReceipts ? "&downloaded=1" : "";
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

      var url = type.toString() == "quds"
          ? '${AppLink.filterCatchesReceiptSarfQuds}/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}$downloadedParam'
          : '${AppLink.vansaleFilterSarfs}/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}';

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
      if (!showWithdrawnReceipts) {
// OFFLINE MODE
        List<CatchModel> filteredReceipts =
            await CartDatabaseHelper().getCatchReceiptsSarfsByDateRange(
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
            await CartDatabaseHelper().getCatchReceiptsSarfsByDateRange(
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

  Future<void> getSarfs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
      // ✅ Online: fetch from API
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var baseUrl = type == "quds"
          ? '${AppLink.CatchesReceiptSarfQuds}/$company_id/$salesman_id'
          : '${AppLink.vansaleSarfs}/$company_id/$salesman_id';

      var url =
          showWithdrawnReceipts ? baseUrl : '$baseUrl?show_undownloaded=true';

      try {
        print("url");
        print(url);
        var response = await http.get(Uri.parse(url), headers: headers);
        var res = jsonDecode(response.body);

        setState(() {
          Qadbs = res["qabds"];
          // chksTotal = double.parse(res["totals"]["chks"].toString());
          // cashTotal = double.parse(res["totals"]["cash"].toString());
          // discountTotal = double.parse(res["totals"]["discount"].toString());
        });
      } catch (e) {
        print("Error fetching data from server: $e");
        Fluttertoast.showToast(msg: "فشل تحميل البيانات من السيرفر");
      }
    } else {
      // ✅ Offline: fetch from local database where qType == "sarf"
      if (type == "quds") {
        if (!showWithdrawnReceipts) {
          List<CatchModel> localReceipts =
              await CartDatabaseHelper().getAllCatchReceipts();
          final filteredReceipts =
              localReceipts.where((r) => r.qType == "sarf").toList();

          setState(() {
            final undownloadedReceipts =
                filteredReceipts.where((r) => r.downloaded == 0).toList();

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
              await CartDatabaseHelper().getAllCatchReceipts();

          localReceipts =
              localReceipts.where((r) => r.qType == "sarf").toList();

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

            chksTotal =
                localReceipts.fold(0.0, (sum, r) => sum + r.totalChecks);
            cashTotal = localReceipts.fold(0.0, (sum, r) => sum + r.cashAmount);
            discountTotal =
                localReceipts.fold(0.0, (sum, r) => sum + r.discount);
          });
        }
      } else {
        List<CatchVansaleModel> localReceipts =
            await CartDatabaseHelper().getAllCatchReceiptsVansale();

// ✅ Filter by qType = "qabd"
        final filteredReceipts =
            localReceipts.where((r) => r.qType == "sarf").toList();

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

      Fluttertoast.showToast(
          msg: "تم تحميل سندات الصرف من قاعدة البيانات المحلية");
    }
  }

  searchCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };

    var url =
        'http://yaghm.com/admin/api/customers/search?id=${searchController.text}';
    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);
    // print("res");
    // print(res);
    return res;
  }
}
