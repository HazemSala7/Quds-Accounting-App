import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/Screens/orders_details/orders_details.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Services/AppBar/appbar_back.dart';
import '../../Services/Drawer/drawer.dart';

class Orders extends StatefulWidget {
  const Orders({Key? key}) : super(key: key);

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  final TextEditingController start_date = TextEditingController();
  final TextEditingController end_date = TextEditingController();

  bool search = false; // left as-is
  String type = "";
  bool showWithdrawnReceipts = true;
  String? userType;

  // UI helpers
  final Radius _r = const Radius.circular(14);
  final EdgeInsets _pagePad = const EdgeInsets.symmetric(horizontal: 16);

  // ✅ Infinite scroll
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _orders = [];

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _page = 1;
  final int _perPage = 30;
  int _lastPage = 1;

  // ✅ totals:
  // 1) sum of LOADED orders only (اجمالي المعروض)
  double _loadedTotalSum = 0.0;
  // 2) sum of ALL filtered orders from API if provided (المجموع)
  double _allTotalSum = 0.0;

  @override
  void initState() {
    super.initState();
    setControllers();
    getUserType();

    _scrollController.addListener(_onScroll);

    // ✅ start load
    _reloadAll();
  }

  @override
  void dispose() {
    start_date.dispose();
    end_date.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => userType = prefs.getString('type'));
  }

  Future<void> setControllers() async {
    final prefs = await SharedPreferences.getInstance();
    type = prefs.getString('type') ?? "quds";

    final now = DateTime.now();
    final formatterDate = DateFormat('yyyy-MM-dd');
    final actualDate = formatterDate.format(now);

    if (!mounted) return;
    setState(() => end_date.text = actualDate);
  }

  // =========================
  // Infinite scroll triggers
  // =========================
  void _onScroll() {
    if (!isOnline) return;
    if (_initialLoading || _loadingMore || !_hasMore) return;

    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
      _loadMore();
    }
  }

  Future<void> _reloadAll() async {
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _hasMore = true;
      _page = 1;
      _lastPage = 1;
      _orders.clear();
      _loadedTotalSum = 0.0;
      _allTotalSum = 0.0;
    });

    try {
      final resp = await _fetchOrdersPage(page: 1);

      final data = _extractOrders(resp);
      final lp = _extractLastPage(resp);
      final allSum = _extractAllTotalSum(resp);

      _orders.addAll(data);
      _lastPage = lp;
      _hasMore = isOnline ? (_page < _lastPage) : false;

      _recalcLoadedSum();

      // ✅ set total of ALL results (if backend provides it)
      if (allSum > 0) _allTotalSum = allSum;

      if (!mounted) return;
      setState(() => _initialLoading = false);

      if (isOnline && _hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _initialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تحميل البيانات: $e")),
      );
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _initialLoading) return;

    setState(() => _loadingMore = true);

    try {
      final next = _page + 1;
      final resp = await _fetchOrdersPage(page: next);

      final data = _extractOrders(resp);
      final lp = _extractLastPage(resp);
      final allSum = _extractAllTotalSum(resp);

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        _page = next;
        _lastPage = lp;
        _orders.addAll(data);
        _hasMore = _page < _lastPage;
      }

      _recalcLoadedSum();

      // ✅ update total ALL if returned later
      if (allSum > 0) _allTotalSum = allSum;

      if (!mounted) return;
      setState(() => _loadingMore = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تحميل المزيد: $e")),
      );
    }
  }

  void _recalcLoadedSum() {
    double s = 0.0;
    for (final o in _orders) {
      final raw = (o is Map)
          ? (o["f_value"] ??
              o["total_final"] ??
              o["total"] ??
              o["amount"] ??
              "0")
          : "0";
      s += double.tryParse(raw.toString()) ?? 0.0;
    }
    _loadedTotalSum = s;
  }

  // =========================
  // Networking / Data fetch
  // =========================
  Future<dynamic> _fetchOrdersPage({required int page}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? t = prefs.getString('type');

    // ---------- OFFLINE ----------
    if (!isOnline) {
      final dbHelper = CartDatabaseHelper();

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        t.toString() == "quds"
            ? await dbHelper.getPendingOrders()
            : await dbHelper.getPendingOrdersVansale(),
      );

      final List<Map<String, dynamic>> items = t.toString() == "quds"
          ? await dbHelper.getAllOrderItems()
          : await dbHelper.getAllOrderItemsVansale();

      final Map<int, List<Map<String, dynamic>>> groupedItems = {};
      for (final item in items) {
        final int orderId = item['order_id'];
        groupedItems.putIfAbsent(orderId, () => []).add(item);
      }

      DateTime? startDate =
          start_date.text.isEmpty ? null : DateTime.tryParse(start_date.text);
      DateTime? endDate =
          end_date.text.isEmpty ? null : DateTime.tryParse(end_date.text);

      List<Map<String, dynamic>> filtered = orders;
      if (startDate != null && endDate != null) {
        filtered = orders.where((order) {
          final orderDate =
              DateTime.tryParse((order["order_date"] ?? "").toString());
          if (orderDate == null) return false;
          return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              orderDate.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      }

      try {
        filtered.sort((a, b) {
          final dtA = '${a["order_date"]} ${a["order_time"] ?? "00:00:00"}';
          final dtB = '${b["order_date"]} ${b["order_time"] ?? "00:00:00"}';
          return (DateTime.tryParse(dtB) ?? DateTime(2000))
              .compareTo(DateTime.tryParse(dtA) ?? DateTime(2000));
        });
      } catch (_) {}

      final mappedOrders = filtered.map((order) {
        final total = double.tryParse(order["total_amount"].toString()) ?? 0.0;
        return {
          ...order,
          "customer": [
            {"c_name": order["customerName"] ?? order["customer_name"] ?? "-"}
          ],
          "fatora_no": order["fatora_number"],
          "f_value": total.toStringAsFixed(2),
          "f_date": order["order_date"],
          "delivery_date": order["deliveryDate"],
          "f_discount": (order["discount"] ?? "0").toString(),
          "items": groupedItems[order["id"]] ?? [],
        };
      }).toList();

      final sumAll = mappedOrders.fold<double>(
        0.0,
        (p, e) => p + (double.tryParse(e["f_value"].toString()) ?? 0.0),
      );

      // ✅ offline has both totals = same (because all are loaded)
      return {
        "orders": mappedOrders,
        "all_total_sum": sumAll,
      };
    }

    // ---------- ONLINE ----------
    final token = prefs.getString('access_token');
    final companyId = prefs.getInt('company_id');
    final salesmanId = prefs.getInt('salesman_id');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final baseUrl = (t == "quds")
        ? '${AppLink.orders}/$companyId/$salesmanId'
        : '${AppLink.ordersVansale}/$companyId/$salesmanId';

    final query = <String, String>{
      "paginate": "true",
      "page": page.toString(),
      "per_page": _perPage.toString(),

      // ✅ request totals from backend (if supported)
      "include_stats": "true",
      "sum_field": "f_value",
      "date_field": "created_at",
    };

    if (!showWithdrawnReceipts) {
      query["show_undownloaded"] = "true";
    }

    if (start_date.text.isNotEmpty) query["date_from"] = start_date.text;
    if (end_date.text.isNotEmpty) query["date_to"] = end_date.text;

    final uri = Uri.parse(baseUrl).replace(queryParameters: query);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // =========================
  // Response helpers
  // =========================
  List<dynamic> _extractOrders(dynamic resp) {
    if (resp == null) return [];
    if (resp is Map) {
      final o = resp["orders"];
      if (o is List) return o;

      if (o is Map) {
        final data = o["data"];
        if (data is List) return data;
      }

      final d = resp["data"];
      if (d is List) return d;
    }
    return [];
  }

  int _extractLastPage(dynamic resp) {
    if (resp is Map) {
      final p = resp["pagination"];
      if (p is Map) {
        final lp = p["last_page"];
        if (lp is int) return lp;
        if (lp is String) return int.tryParse(lp) ?? 1;
      }
      final o = resp["orders"];
      if (o is Map) {
        final lp = o["last_page"];
        if (lp is int) return lp;
        if (lp is String) return int.tryParse(lp) ?? 1;
      }
    }
    return 1;
  }

  /// ✅ backend may return total in:
  /// - resp["all_total_sum"]
  /// - resp["filtered_orders_total_sum"]
  /// - resp["stats"]["sum"]
  double _extractAllTotalSum(dynamic resp) {
    if (resp is Map) {
      // direct fields
      final v1 = resp["all_total_sum"];
      if (v1 is num) return v1.toDouble();
      if (v1 is String) return double.tryParse(v1) ?? 0.0;

      final v2 = resp["filtered_orders_total_sum"];
      if (v2 is num) return v2.toDouble();
      if (v2 is String) return double.tryParse(v2) ?? 0.0;

      // nested stats
      final stats = resp["stats"];
      if (stats is Map) {
        final vs = stats["sum"] ?? stats["total_sum"];
        if (vs is num) return vs.toDouble();
        if (vs is String) return double.tryParse(vs) ?? 0.0;
      }
    }
    return 0.0;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final bool isQuds = (type == "quds");
    final String title = isQuds ? "الطلبيات" : "الفواتير";

    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          backgroundColor: Main_Color,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBarBack(title: title),
          ),
          body: _initialLoading
              ? const Center(child: SpinKitPulse(color: Colors.white, size: 50))
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: _pagePad,
                      child: _buildTopActionsCard(context),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: _pagePad,
                      child: _buildTableHeaderCard(),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: (_orders.isEmpty)
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _reloadAll,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 10, 16, 16),
                                itemCount: _orders.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _orders.length) {
                                    if (!isOnline) return const SizedBox(height: 24);
                                    if (_loadingMore) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18),
                                        child: Center(
                                          child: SpinKitThreeBounce(
                                              color: Colors.white, size: 20),
                                        ),
                                      );
                                    }
                                    return const SizedBox(height: 24);
                                  }

                                  final order = _orders[index] as Map;

                                  final customerId =
                                      (order["customer_id"] ?? "").toString();

                                  final customerName =
                                      (order["customer_name"] ?? "")
                                              .toString()
                                              .isNotEmpty
                                          ? (order["customer_name"] ?? "-")
                                              .toString()
                                          : (order["customer"] != null &&
                                                  order["customer"] is List &&
                                                  (order["customer"] as List)
                                                      .isNotEmpty)
                                              ? (order["customer"][0]["c_name"] ??
                                                      "-")
                                                  .toString()
                                              : "-";

                                  final value = (order["f_value"] ??
                                          order["total_final"] ??
                                          order["total"] ??
                                          "0")
                                      .toString();

                                  final fatoraNo =
                                      (order["fatora_no"] ?? order["id"] ?? "")
                                          .toString();

                                  final id = (order["id"] ?? "").toString();
                                  final date =
                                      (order["f_date"] ?? order["created_at"] ?? "")
                                          .toString();
                                  final notes = (order["notes"] ?? "").toString();
                                  final deliveryDate =
                                      (order["delivery_date"] ?? "").toString();
                                  final discount =
                                      (order["f_discount"] ?? "0").toString();

                                  return _orderCardPro(
                                    context: context,
                                    customer: customerId,
                                    customerName: customerName,
                                    value: value,
                                    fatoraNo: fatoraNo,
                                    id: id,
                                    date: date,
                                    orderNotes: notes,
                                    deliveryDate: deliveryDate,
                                    orderDiscount: discount,
                                    index: index,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTopActionsCard(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Main_Color),
                    const SizedBox(width: 8),
                    Text(
                      "إدارة القائمة",
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
                  if (_orders.isNotEmpty) {
                    await pdfOrders(_orders);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("لا توجد طلبات لإنشاء ملف PDF")),
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
                  backgroundColor: Main_Color,
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

          // ✅ two totals (no count)
          Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.view_list,
                        size: 18, color: Colors.grey.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "عدد الطلبيات المعروضة: ${_orders.length}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Main_Color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Main_Color.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.summarize,
                        size: 18, color: Colors.grey.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "المجموع: ₪${(_allTotalSum > 0 ? _allTotalSum : _loadedTotalSum).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _dateField(
                  controller: start_date,
                  hint: "من تاريخ",
                  icon: Icons.calendar_month,
                  onTap: () async {
                    await setStart();
                    await _reloadAll();
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
                    await _reloadAll();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  setState(() => start_date.clear());
                  await _reloadAll();
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
              if (showCheckbox)
                Row(
                  children: [
                    Checkbox(
                      value: showWithdrawnReceipts,
                      activeColor: Main_Color,
                      onChanged: (bool? value) async {
                        setState(() => showWithdrawnReceipts = value ?? true);
                        await _reloadAll();
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
            Icon(icon, color: Main_Color),
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
          _headerCell("رقم الزبون"),
          _headerCell("اسم الزبون"),
          _headerCell("القيمة"),
          _headerCell("التاريخ"),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
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
              "لا توجد بيانات لعرضها",
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

  Widget _orderCardPro({
    required BuildContext context,
    required String date,
    required String value,
    required String orderNotes,
    required String fatoraNo,
    required String id,
    required String customer,
    required String customerName,
    required String deliveryDate,
    required String orderDiscount,
    required int index,
  }) {
    final Color bg = index.isEven ? Colors.white : Colors.grey.shade50;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersDetails(
                printed: "1",
                orderDiscount: orderDiscount,
                orderNotes: orderNotes,
                customer_id: customer,
                deliveryDate: deliveryDate.toString(),
                customer_name: customerName,
                order_total: double.tryParse(value.toString()) ?? 0.0,
                f_code: "1",
                id: id,
                fatoraNumber: fatoraNo,
                fatoraID: fatoraNo,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Main_Color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    fatoraNo.isEmpty ? "-" : fatoraNo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Main_Color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          customer.isEmpty ? "-" : customer,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.event,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            date.isEmpty ? "-" : date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₪${value.isEmpty ? "0.00" : value}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey.shade600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // PDF
  // =========================
  Future<void> pdfOrders(List<dynamic> orders) async {
    final arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    final pdf = pw.Document();
    const bool showDeliveryDateColumn = true;

    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Column(
        children: [
          pw.Text("قائمة الطلبات",
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 5),
            pw.Text("التاريخ: ",
                textDirection: pw.TextDirection.rtl,
                style: const pw.TextStyle(fontSize: 14)),
          ]),
          pw.SizedBox(height: 10),
        ],
      ),
    );

    widgets.add(
      pw.Container(
        height: 40,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
                child: pw.Center(
                    child: pw.Text("التاريخ",
                        textDirection: pw.TextDirection.rtl,
                        style: const pw.TextStyle(fontSize: 14)))),
            if (showDeliveryDateColumn)
              pw.Expanded(
                  child: pw.Center(
                      child: pw.Text("تاريخ الاستلام",
                          textDirection: pw.TextDirection.rtl,
                          style: const pw.TextStyle(fontSize: 14)))),
            pw.Expanded(
                child: pw.Center(
                    child: pw.Text("القيمة",
                        textDirection: pw.TextDirection.rtl,
                        style: const pw.TextStyle(fontSize: 14)))),
            pw.Expanded(
                child: pw.Center(
                    child: pw.Text("اسم الزبون",
                        textDirection: pw.TextDirection.rtl,
                        style: const pw.TextStyle(fontSize: 14)))),
            pw.Expanded(
                child: pw.Center(
                    child: pw.Text("رقم الزبون",
                        textDirection: pw.TextDirection.rtl,
                        style: const pw.TextStyle(fontSize: 14)))),
          ],
        ),
      ),
    );

    for (final order in orders) {
      final customerName =
          (order["customer_name"] ?? "").toString().isNotEmpty
              ? (order["customer_name"] ?? " - ").toString()
              : (order["customer"] != null &&
                      order["customer"] is List &&
                      (order["customer"] as List).isNotEmpty)
                  ? (order["customer"][0]["c_name"] ?? " - ").toString()
                  : " - ";

      final rowValue =
          (order["f_value"] ?? order["total_final"] ?? order["total"] ?? "0")
              .toString();

      widgets.add(
        pw.Container(
          height: 40,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Center(
                      child: pw.Text(
                          (order["f_date"] ?? order["created_at"] ?? "")
                              .toString(),
                          textDirection: pw.TextDirection.rtl,
                          style: const pw.TextStyle(fontSize: 12)))),
              if (showDeliveryDateColumn)
                pw.Expanded(
                    child: pw.Center(
                        child: pw.Text(
                            (order["delivery_date"] ?? "").toString(),
                            textDirection: pw.TextDirection.rtl,
                            style: const pw.TextStyle(fontSize: 12)))),
              pw.Expanded(
                  child: pw.Center(
                      child: pw.Text(rowValue,
                          textDirection: pw.TextDirection.rtl,
                          style: const pw.TextStyle(fontSize: 12)))),
              pw.Expanded(
                  child: pw.Center(
                      child: pw.Text(customerName,
                          textDirection: pw.TextDirection.rtl,
                          style: const pw.TextStyle(fontSize: 12)))),
              pw.Expanded(
                  child: pw.Center(
                      child: pw.Text((order["customer_id"] ?? "").toString(),
                          textDirection: pw.TextDirection.rtl,
                          style: const pw.TextStyle(fontSize: 12)))),
            ],
          ),
        ),
      );
    }

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

  // =========================
  // Date pickers
  // =========================
  Future<void> setStart() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      if (!mounted) return;
      setState(() => start_date.text = formattedDate);
    }
  }

  Future<void> setEnd() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      if (!mounted) return;
      setState(() => end_date.text = formattedDate);
    }
  }
}