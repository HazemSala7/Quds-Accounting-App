import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/Screens/catches/catch_card/catch_card.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Server/server.dart' as globals;
import '../../Services/Drawer/drawer.dart';

class Sarf extends StatefulWidget {
  const Sarf({Key? key}) : super(key: key);

  @override
  State<Sarf> createState() => _SarfState();
}

class _SarfState extends State<Sarf> {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  bool showWithdrawnReceipts = false; // نفس منطقك
  String? userType;
  var Qadbs;

  // ✅ totals + count (NEW)
  double chksTotal = 0.0;
  double cashTotal = 0.0;
  double discountTotal = 0.0;
  int qabdsCount = 0;

  // controllers
  final TextEditingController start_date = TextEditingController();
  final TextEditingController end_date = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  void getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userType = prefs.getString('type'));
  }

  @override
  void initState() {
    super.initState();
    _setControllers();
    getSarfs();
    getUserType();
  }

  void _setControllers() {
    final now = DateTime.now();
    final formatterDate = DateFormat('yyyy-MM-dd');
    final actualDate = formatterDate.format(now);
    setState(() => end_date.text = actualDate);
  }

  // =========================
  // ✅ UI helpers (NEW DESIGN)
  // =========================
  Widget _totalsHeader() {
    final totalAll = (chksTotal + cashTotal + discountTotal);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "سندات صرف",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: globals.Main_Color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: globals.Main_Color.withOpacity(0.2)),
                ),
                child: Text(
                  "العدد: $qabdsCount",
                  style: TextStyle(
                    color: globals.Main_Color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _totalChip(
                  title: "نقداً",
                  value: cashTotal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _totalChip(
                  title: "شيكات",
                  value: chksTotal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _totalChip(
                  title: "خصم",
                  value: discountTotal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.summarize_outlined, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "الإجمالي",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  "${totalAll.toStringAsFixed(2)}₪",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalChip({required String title, required double value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${value.toStringAsFixed(2)}₪",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dateField("من تاريخ", start_date, setStart)),
              const SizedBox(width: 12),
              Expanded(child: _dateField("الى تاريخ", end_date, setEnd)),
            ],
          ),
          const SizedBox(height: 8),
          if (userType == "quds")
            Row(
              children: [
                Checkbox(
                  value: showWithdrawnReceipts,
                  onChanged: (bool? value) {
                    setState(() {
                      showWithdrawnReceipts = value ?? false;
                      Qadbs = [];
                      // نفس منطقك
                      start_date.text == "" ? getSarfs() : filterSarfs();
                    });
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  "عرض الكل",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      start_date.clear();
                      // end_date نخليها زي ما هي
                      Qadbs = [];
                    });
                    getSarfs();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEFEFEF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "تحديث",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }

  Widget _dateField(String hint, TextEditingController controller, Function onTap) {
    return SizedBox(
      height: 46,
      child: TextField(
        onTap: () => onTap(),
        controller: controller,
        readOnly: true,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: globals.Main_Color, width: 1.8),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 1.2, color: Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // =========================
  // ✅ UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: globals.Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBarBack(title: "سندات صرف"),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ✅ totals + count card
                _totalsHeader(),

                // ✅ filters card (better design)
                _filtersCard(),

                // ✅ list
                if (Qadbs == null)
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: SpinKitPulse(color: globals.Main_Color, size: 60),
                  )
                else if (Qadbs.length == 0)
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: const Center(
                      child: Text(
                        "لا يوجد أي سند صرف",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    itemCount: Qadbs.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                    itemBuilder: (context, index) {
                      return CatchCard(
                        discoveredDevices: const [],
                        qType: "sarf",
                        lattitude: (Qadbs[index]['customer'] is Map &&
                                Qadbs[index]['customer'] != "-" &&
                                Qadbs[index]['customer'] != "")
                            ? double.tryParse(
                                    Qadbs[index]['customer']["latitude"].toString()) ??
                                0.0
                            : 0.0,
                        longitude: (Qadbs[index]['customer'] is Map &&
                                Qadbs[index]['customer'] != "-" &&
                                Qadbs[index]['customer'] != "")
                            ? double.tryParse(
                                    Qadbs[index]['customer']["longitude"].toString()) ??
                                0.0
                            : 0.0,
                        uniqueID: Qadbs[index]['id'],
                        id: Qadbs[index]['customer_id'] ?? "0",
                        printed: Qadbs[index]['printed'] ?? "1",
                        cash: double.tryParse(Qadbs[index]['cash']?.toString() ?? '0') ?? 0.0,
                        chaks: double.tryParse(Qadbs[index]['chks']?.toString() ?? '0') ?? 0.0,
                        discount: double.tryParse(Qadbs[index]['discount']?.toString() ?? '0') ?? 0.0,
                        balance: (double.tryParse(Qadbs[index]['chks']?.toString() ?? '0') ?? 0.0) +
                            (double.tryParse(Qadbs[index]['cash']?.toString() ?? '0') ?? 0.0) +
                            (double.tryParse(Qadbs[index]['discount']?.toString() ?? '0') ?? 0.0),
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
        ),
      ),
    );
  }

  // =========================
  // ✅ Date pickers
  // =========================
  Future<void> setStart() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        Qadbs = [];
        start_date.text = formattedDate;
      });
      filterSarfs();
    } else {
      setState(() {
        Qadbs = [];
      });
      getSarfs();
    }
  }

  Future<void> setEnd() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        Qadbs = [];
        end_date.text = formattedDate;
      });
      filterSarfs();
    } else {
      setState(() {
        Qadbs = [];
      });
      getSarfs();
    }
  }

  // =========================
  // ✅ API / Local logic (UNCHANGED) + totals/count wiring
  // =========================
  Future<void> filterSarfs() async {
    String downloadedParam = showWithdrawnReceipts ? "&downloaded=1" : "";
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
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
        chksTotal = double.tryParse(res["totals"]["chks"].toString()) ?? 0.0;
        cashTotal = double.tryParse(res["totals"]["cash"].toString()) ?? 0.0;
        discountTotal =
            double.tryParse(res["totals"]["discount"].toString()) ?? 0.0;
        qabdsCount = int.tryParse(res["qabds_count"]?.toString() ?? "") ??
            (Qadbs?.length ?? 0);
      });
    } else {
      if (!showWithdrawnReceipts) {
        List<CatchModel> filteredReceipts =
            await CartDatabaseHelper().getCatchReceiptsSarfsByDateRange(
          start_date.text.trim(),
          end_date.text.trim(),
        );

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
              "customer": {"c_name": receipt.customerName},
            };
          }).toList();

          chksTotal = localChk;
          cashTotal = localCash;
          discountTotal = localDiscount;
          qabdsCount = Qadbs.length;
        });
      } else {
        List<CatchModel> filteredReceipts =
            await CartDatabaseHelper().getCatchReceiptsSarfsByDateRange(
          start_date.text.trim(),
          end_date.text.trim(),
        );

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
              "customer": {"c_name": receipt.customerName},
            };
          }).toList();

          chksTotal = localChk;
          cashTotal = localCash;
          discountTotal = localDiscount;
          qabdsCount = Qadbs.length;
        });
      }
    }
  }

  Future<void> getSarfs() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
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
        var response = await http.get(Uri.parse(url), headers: headers);
        var res = jsonDecode(response.body);

        setState(() {
          Qadbs = res["qabds"];

          // ✅ totals + count (NEW)
          chksTotal = double.tryParse(res["totals"]?["chks"]?.toString() ?? "0") ?? 0.0;
          cashTotal = double.tryParse(res["totals"]?["cash"]?.toString() ?? "0") ?? 0.0;
          discountTotal =
              double.tryParse(res["totals"]?["discount"]?.toString() ?? "0") ?? 0.0;

          qabdsCount =
              int.tryParse(res["qabds_count"]?.toString() ?? "") ?? (Qadbs?.length ?? 0);
        });
      } catch (e) {
        Fluttertoast.showToast(msg: "فشل تحميل البيانات من السيرفر");
      }
    } else {
      if (type == "quds") {
        if (!showWithdrawnReceipts) {
          List<CatchModel> localReceipts =
              await CartDatabaseHelper().getAllCatchReceipts();
          final filteredReceipts =
              localReceipts.where((r) => r.qType == "sarf").toList();

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
                "customer": {"c_name": receipt.customerName},
              };
            }).toList();

            chksTotal = undownloadedReceipts.fold(0.0, (sum, r) => sum + r.totalChecks);
            cashTotal = undownloadedReceipts.fold(0.0, (sum, r) => sum + r.cashAmount);
            discountTotal = undownloadedReceipts.fold(0.0, (sum, r) => sum + r.discount);
            qabdsCount = Qadbs.length;
          });
        } else {
          List<CatchModel> localReceipts =
              await CartDatabaseHelper().getAllCatchReceipts();

          localReceipts = localReceipts.where((r) => r.qType == "sarf").toList();

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

            chksTotal = localReceipts.fold(0.0, (sum, r) => sum + r.totalChecks);
            cashTotal = localReceipts.fold(0.0, (sum, r) => sum + r.cashAmount);
            discountTotal = localReceipts.fold(0.0, (sum, r) => sum + r.discount);
            qabdsCount = Qadbs.length;
          });
        }
      } else {
        List<CatchVansaleModel> localReceipts =
            await CartDatabaseHelper().getAllCatchReceiptsVansale();

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

          chksTotal = filteredReceipts.fold(0.0, (sum, r) => sum + r.totalChecks);
          cashTotal = filteredReceipts.fold(0.0, (sum, r) => sum + r.cashAmount);
          discountTotal = filteredReceipts.fold(0.0, (sum, r) => sum + r.discount);
          qabdsCount = Qadbs.length;
        });
      }

      Fluttertoast.showToast(msg: "تم تحميل سندات الصرف من قاعدة البيانات المحلية");
    }
  }

  Future<dynamic> searchCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };

    var url =
        'http://yaghm.com/admin/api/customers/search?id=${searchController.text}';
    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);
    return res;
  }
}