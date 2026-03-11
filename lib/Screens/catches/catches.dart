import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/catches/catch_card/catch_card.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  // UI helpers (نفس ستايل Orders)
  final Radius _r = const Radius.circular(14);
  final EdgeInsets _pagePad = const EdgeInsets.symmetric(horizontal: 16);

  // Filters
  bool showWithdrawnReceipts = true;
  TextEditingController start_date = TextEditingController();
  TextEditingController end_date = TextEditingController();

  // Type
  String? userType;

  // Totals
  double chksTotal = 0.0;
  double cashTotal = 0.0;
  double discountTotal = 0.0;

  // Count
  int _qabdsCount = 0;

  // Future
  Future<dynamic>? _qabdsFuture;

  // iOS bluetooth scan (كما عندك)
  String platform = Platform.isIOS ? "iOS" : "Android";
  flutterBlue.FlutterBlue flutterBlueInstance = flutterBlue.FlutterBlue.instance;
  flutterBlue.BluetoothDevice? connectedIOSDevice;
  List<flutterBlue.BluetoothDevice> discoveredDevices = [];

  @override
  void initState() {
    super.initState();
    _setDefaultEndDate();
    _setIOSScan();
    _loadUserType();

    // ✅ Load once
    _qabdsFuture = getQabds();
  }

  @override
  void dispose() {
    start_date.dispose();
    end_date.dispose();
    super.dispose();
  }

  // =========================
  // Setup
  // =========================
  void _setDefaultEndDate() {
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    end_date.text = formatterDate.format(now);
  }

  void _setIOSScan() {
    if (Platform.isIOS) {
      scanIOSDevices();
    }
  }

  void _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userType = prefs.getString('type'));
  }

  Future<void> scanIOSDevices() async {
    try {
      flutterBlueInstance.startScan(timeout: const Duration(seconds: 4));
      flutterBlueInstance.scanResults.listen((results) {
        setState(() {
          discoveredDevices = results.map((r) => r.device).toList();
        });
      });
      await Future.delayed(const Duration(seconds: 5));
      flutterBlueInstance.stopScan();
    } catch (e) {
      print("Error scanning for iOS Bluetooth devices: $e");
    }
  }

  // =========================
  // Helpers: normalize response
  // =========================
  List<dynamic> _extractQabds(dynamic resp) {
    if (resp == null) return [];
    if (resp is Map) {
      final q = resp["qabds"];
      if (q is List) return q;
    }
    return [];
  }

  Map<String, dynamic> _extractTotals(dynamic resp) {
    if (resp is Map && resp["totals"] is Map) {
      return Map<String, dynamic>.from(resp["totals"]);
    }
    return {"chks": 0, "cash": 0, "discount": 0};
  }

  int _extractCount(dynamic resp, List<dynamic> fallback) {
    if (resp is Map) {
      final c = resp["qabds_count"];
      if (c is int) return c;
      if (c is String) return int.tryParse(c) ?? fallback.length;
    }
    return fallback.length;
  }

  void _applyHeaderStatsFromResp(dynamic resp, List<dynamic> qabds) {
    final totals = _extractTotals(resp);
    final count = _extractCount(resp, qabds);

    final newChks = double.tryParse(totals["chks"]?.toString() ?? "0") ?? 0.0;
    final newCash = double.tryParse(totals["cash"]?.toString() ?? "0") ?? 0.0;
    final newDisc = double.tryParse(totals["discount"]?.toString() ?? "0") ?? 0.0;

    if (_qabdsCount != count ||
        chksTotal != newChks ||
        cashTotal != newCash ||
        discountTotal != newDisc) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _qabdsCount = count;
          chksTotal = newChks;
          cashTotal = newCash;
          discountTotal = newDisc;
        });
      });
    }
  }

  void _refreshFuture() {
    setState(() {
      _qabdsFuture = start_date.text.isNotEmpty ? filterQabds() : getQabds();
    });
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: globals.Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          backgroundColor: globals.Main_Color,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: AppBarBack(title: "سندات القبض"),
          ),
          body: FutureBuilder(
            future: _qabdsFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitPulse(color: Colors.white, size: 50),
                );
              }

              final resp = snapshot.data;
              final qabds = _extractQabds(resp);
              _applyHeaderStatsFromResp(resp, qabds);

              return Column(
                children: [
                  const SizedBox(height: 10),

                  // ===== Top Card: Totals + PDF + Count + Filters =====
                  Padding(
                    padding: _pagePad,
                    child: _buildTopActionsCard(context, qabds),
                  ),

                  const SizedBox(height: 10),

                  // ===== Table Header =====
                  Padding(
                    padding: _pagePad,
                    child: _buildTableHeaderCard(),
                  ),

                  const SizedBox(height: 6),

                  // ===== List =====
                  Expanded(
                    child: (qabds.isEmpty)
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                            itemCount: qabds.length,
                            itemBuilder: (context, index) {
                              final row = qabds[index];

                              final customerId =
                                  (row["customer_id"] ?? "0").toString();

                              final customerName =
                                  (row["customer"] is Map)
                                      ? ((row["customer"]["c_name"] ?? "-")
                                          .toString())
                                      : "-";

                              return CatchCard(
                                qType: "qabd",
                                lattitude: (row['customer'] is Map &&
                                        row['customer'] != "-" &&
                                        row['customer'] != "")
                                    ? double.tryParse(
                                            row['customer']["latitude"]
                                                .toString()) ??
                                        0.0
                                    : 0.0,
                                longitude: (row['customer'] is Map &&
                                        row['customer'] != "-" &&
                                        row['customer'] != "")
                                    ? double.tryParse(
                                            row['customer']["longitude"]
                                                .toString()) ??
                                        0.0
                                    : 0.0,
                                uniqueID: row['id'],
                                id: customerId,
                                printed: row['printed'] ?? "1",
                                cash: double.tryParse(
                                        row['cash']?.toString() ?? '0') ??
                                    0.0,
                                chaks: double.tryParse(
                                        row['chks']?.toString() ?? '0') ??
                                    0.0,
                                discount: double.tryParse(
                                        row['discount']?.toString() ?? '0') ??
                                    0.0,
                                balance: (double.tryParse(
                                            row['chks']?.toString() ?? '0') ??
                                        0.0) +
                                    (double.tryParse(
                                            row['cash']?.toString() ?? '0') ??
                                        0.0) +
                                    (double.tryParse(
                                            row['discount']?.toString() ??
                                                '0') ??
                                        0.0),
                                name: customerName,
                                phone: row['q_date'] ?? "",
                                notes: row['notes'] ?? "",
                                discoveredDevices: discoveredDevices,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionsCard(BuildContext context, List<dynamic> currentQabds) {
    final bool showCheckbox = (userType == "quds");

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(_r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // Row: Title + PDF
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: globals.Main_Color),
                    const SizedBox(width: 8),
                    Text(
                      "إدارة السندات",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (currentQabds.isNotEmpty) {
                    // نفس منطقك: اطبع PDF اعتماداً على Qadbs
                    await pdfFatora8CM(currentQabds);
                    if (mounted) Navigator.pop(context); // closes dialog if any
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("لا توجد سندات لإنشاء PDF")),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  "PDF",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: globals.Main_Color,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Totals row (مثل orders)
          Row(
            children: [
              Expanded(
                child: _miniStatTile(
                  title: "مجموع الشيكات",
                  value: "${chksTotal.toStringAsFixed(2)} ₪",
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatTile(
                  title: "مجموع النقدي",
                  value: "${cashTotal.toStringAsFixed(2)} ₪",
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniStatTile(
                  title: "مجموع الخصم",
                  value: "${discountTotal.toStringAsFixed(2)} ₪",
                  icon: Icons.discount_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStatTile(
                  title: "عدد السندات",
                  value: _qabdsCount.toString(),
                  icon: Icons.format_list_numbered,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date filters
          Row(
            children: [
              Expanded(
                child: _dateField(
                  controller: start_date,
                  hint: "من تاريخ",
                  icon: Icons.calendar_month,
                  onTap: () async {
                    await setStart();
                    _refreshFuture();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(
                  controller: end_date,
                  hint: "إلى تاريخ",
                  icon: Icons.event_available,
                  onTap: () async {
                    await setEnd();
                    _refreshFuture();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Clear filter button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    start_date.clear();
                  });
                  _refreshFuture();
                },
                icon: Icon(Icons.filter_alt_off, color: Colors.grey.shade800),
                label: Text(
                  "مسح الفلتر",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Spacer(),

              // Checkbox (نفس logic)
              if (showCheckbox)
                Row(
                  children: [
                    Checkbox(
                      value: showWithdrawnReceipts,
                      activeColor: globals.Main_Color,
                      onChanged: (bool? value) {
                        setState(() {
                          showWithdrawnReceipts = value ?? true;
                        });
                        _refreshFuture();
                      },
                    ),
                    const Text(
                      "عرض الكل",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: globals.Main_Color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: globals.Main_Color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: globals.Main_Color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: controller.text.isEmpty
                      ? Colors.grey.shade600
                      : Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.all(_r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          _headerCell("#الزبون"),
          _headerCell("اسم الزبون"),
          _headerCell("الشيكات"),
          _headerCell("نقدا"),
          _headerCell("الخصم"),
          _headerCell("التاريخ"),
          _headerCell("ملاحظات"),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Text(
              "لا يوجد أي سند قبض",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Date pickers
  // =========================
  Future<void> setStart() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        start_date.text = formattedDate;
      });
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
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        end_date.text = formattedDate;
      });
    }
  }

  // =========================
  // Data (نفس منطقك، بس يرجّع Map موحد + qabds_count أوفلاين)
  // =========================

  Future<dynamic> getQabds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
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
        return jsonDecode(response.body);
      } catch (e) {
        print("Error fetching data from server: $e");
        Fluttertoast.showToast(msg: "فشل تحميل البيانات من السيرفر");
        return {"qabds": [], "qabds_count": 0, "totals": {"chks": 0, "cash": 0, "discount": 0}};
      }
    } else {
      // OFFLINE
      if (type == "quds") {
        List<CatchModel> localReceipts =
            await CartDatabaseHelper().getAllCatchReceiptsQabds();

        final list = showWithdrawnReceipts
            ? localReceipts
            : localReceipts.where((r) => r.downloaded == 0).toList();

        final mapped = list.map((receipt) {
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

        final totals = {
          "chks": list.fold(0.0, (sum, r) => sum + r.totalChecks),
          "cash": list.fold(0.0, (sum, r) => sum + r.cashAmount),
          "discount": list.fold(0.0, (sum, r) => sum + r.discount),
        };

        Fluttertoast.showToast(msg: "تم تحميل السندات من قاعدة البيانات المحلية");

        return {
          "qabds": mapped,
          "qabds_count": mapped.length,
          "totals": totals,
        };
      } else {
        List<CatchVansaleModel> localReceipts =
            await CartDatabaseHelper().getAllCatchReceiptsVansale();

        final filteredReceipts =
            localReceipts.where((r) => r.qType == "qabd").toList();

        final mapped = filteredReceipts.map((receipt) {
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

        final totals = {
          "chks": filteredReceipts.fold(0.0, (sum, r) => sum + r.totalChecks),
          "cash": filteredReceipts.fold(0.0, (sum, r) => sum + r.cashAmount),
          "discount": filteredReceipts.fold(0.0, (sum, r) => sum + r.discount),
        };

        Fluttertoast.showToast(msg: "تم تحميل السندات من قاعدة البيانات المحلية");

        return {
          "qabds": mapped,
          "qabds_count": mapped.length,
          "totals": totals,
        };
      }
    }
  }

  Future<dynamic> filterQabds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    if (globals.isOnline) {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var url = type == "quds"
          ? 'https://yaghm.com/admin/api/filter_qabds/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}'
          : '${AppLink.vansaleFilterQabds}/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}';

      // نفس منطقك: إذا عرض الكل false => أضف downloaded=1 (يعني غير محمّل)
      var finalUrl = showWithdrawnReceipts ? url : '$url&downloaded=1';

      try {
        var response = await http.get(Uri.parse(finalUrl), headers: headers);
        return jsonDecode(response.body);
      } catch (e) {
        return {"qabds": [], "qabds_count": 0, "totals": {"chks": 0, "cash": 0, "discount": 0}};
      }
    } else {
      // OFFLINE
      // نفس منطقك: جلب ضمن الفترة ثم (حسب showWithdrawnReceipts) فلترة downloaded
      List<CatchModel> filteredReceipts =
          await CartDatabaseHelper().getCatchReceiptsByDateRange(
        start_date.text.trim(),
        end_date.text.trim(),
      );

      final list = showWithdrawnReceipts
          ? filteredReceipts
          : filteredReceipts.where((r) => r.downloaded == 0).toList();

      final mapped = list.map((receipt) {
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

      final totals = {
        "chks": list.fold(0.0, (sum, r) => sum + r.totalChecks),
        "cash": list.fold(0.0, (sum, r) => sum + r.cashAmount),
        "discount": list.fold(0.0, (sum, r) => sum + r.discount),
      };

      return {
        "qabds": mapped,
        "qabds_count": mapped.length,
        "totals": totals,
      };
    }
  }

  // =========================
  // PDF (نفس فكرتك، لكن بدل ما يعتمد على Qadbs global، نمرّر القائمة الحالية)
  // =========================
  Future<void> pdfFatora8CM(List<dynamic> qabds) async {
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    String actualDate = formatterDate.format(now);

    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));

    List<pw.Widget> widgets = [];

    final title = pw.Column(
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(),
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.SizedBox(width: 5),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("التاريخ : ",
                  style: pw.TextStyle(fontSize: 20)),
            ),
          ]),
        ]),
        pw.SizedBox(height: 6),
      ],
    );
    widgets.add(title);

    final firstrow = pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        color: PdfColors.grey200,
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("ملاحظات", style: pw.TextStyle(fontSize: 14)),
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("التاريخ", style: pw.TextStyle(fontSize: 14)),
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("المبلغ", style: pw.TextStyle(fontSize: 14)),
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Center(
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("أسم الزبون", style: pw.TextStyle(fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
    widgets.add(firstrow);

    final listview = pw.ListView.builder(
      itemCount: qabds.length,
      itemBuilder: (context, index) {
        final row = qabds[index];

        final customerMap = row['customer'];
        final String cName = (customerMap is Map)
            ? (customerMap['c_name']?.toString() ?? '-')
            : '-';

        final double chks = double.tryParse(row['chks']?.toString() ?? '0') ?? 0;
        final double cash = double.tryParse(row['cash']?.toString() ?? '0') ?? 0;
        final double disc =
            double.tryParse(row['discount']?.toString() ?? '0') ?? 0;

        final double balance = chks + cash + disc;

        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Center(
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text((row["notes"] ?? "-").toString(),
                        style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Center(
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text((row["q_date"] ?? "-").toString(),
                        style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                  child: pw.Text(
                    balance.toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Center(
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(cName,
                        style: pw.TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    widgets.add(listview);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: arabicFont),
        pageFormat: PdfPageFormat.a4,
        build: (context) => widgets,
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}