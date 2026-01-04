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
  TextEditingController start_date = TextEditingController();
  TextEditingController end_date = TextEditingController();
  bool search = false;
  String type = "";
  bool showWithdrawnReceipts = true;
  String? userType;

  void getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('type');
    });
  }

  @override
  void initState() {
    super.initState();
    setControllers();
    getUserType();
  }

  setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _type = prefs.getString('type') ?? "quds";
    type = _type;
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    String actualDate = formatterDate.format(now);
    setState(() {
      end_date.text = actualDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBarBack(
              title: type == "quds" ? "الطلبيات" : "الفواتير",
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        var orders = start_date.text.isNotEmpty
                            ? await filterOrders()
                            : await getOrders();
                        if (orders != null && orders["orders"] != null) {
                          await pdfOrders(orders["orders"]);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("لا توجد طلبات لإنشاء ملف PDF")),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: Text(
                        "إنشاء ملف PDF",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Main_Color,
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onTap: setStart,
                        controller: start_date,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'من تاريخ',
                          hintStyle: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xffD6D3D3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Main_Color, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        onTap: setEnd,
                        controller: end_date,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'الى تاريخ',
                          hintStyle: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xffD6D3D3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Main_Color, width: 1.5),
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
                            getOrders();
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell("رقم الزبون"),
                      _buildHeaderCell("أسم الزبون"),
                      _buildHeaderCell("القيمة"),
                      _buildHeaderCell("التاريخ"),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FutureBuilder(
                        future: start_date.text.isNotEmpty
                            ? filterOrders()
                            : getOrders(),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              alignment: Alignment.center,
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: SpinKitPulse(
                                color: Main_Color,
                                size: 50,
                              ),
                            );
                          } else if (snapshot.hasData &&
                              snapshot.data != null) {
                            var orders = snapshot.data["orders"];
                            print("orders");
                            print(orders);
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                var order = orders[index];
                                return orderCard(
                                  customer: order["customer_id"] ?? "",
                                  customer_name: order["customer"].length != 0
                                      ? order["customer"][0]["c_name"]
                                      : "-",
                                  value: order["f_value"] ?? "",
                                  fatora_id: order["fatora_no"].toString(),
                                  id: order["id"].toString(),
                                  date: order["f_date"] ?? "",
                                  orderNotes: order["notes"] ?? "",
                                  fatoraNumber: order["fatora_no"].toString(),
                                  deliveryDate: order["delivery_date"] ?? "",
                                  orderDiscount: order["f_discount"].toString(),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Text(
                                "لا توجد بيانات لعرضها",
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 16),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ),
    );
  }

  Widget orderCard({
    String date = "",
    String value = "",
    String orderNotes = "",
    String fatoraNumber = "",
    String id = "0",
    String fatora_id = "0",
    String customer = "",
    String customer_name = "",
    String deliveryDate = "",
    String orderDiscount = "",
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
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
                customer_name: customer_name,
                order_total: double.parse(value),
                f_code: "1",
                id: id,
                fatoraNumber: fatoraNumber,
                fatoraID: fatora_id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              _buildOrderCell(customer),
              _buildOrderCell(customer_name, isBold: true),
              _buildOrderCell("₪$value"),
              _buildOrderCell(date),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCell(String text, {bool isBold = false}) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> pdfOrders(List<dynamic> orders) async {
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    final pdf = pw.Document();

    List<pw.Widget> widgets = [];

    // Add title and header details
    final title = pw.Column(
      children: [
        pw.Text(
          "قائمة الطلبات",
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(fontSize: 20),
        ),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text(
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            "التاريخ: ",
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(fontSize: 14),
          ),
        ]),
        pw.SizedBox(height: 10),
      ],
    );
    widgets.add(title);

    // Add table header
    final headerRow = pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                "التاريخ",
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ),
          if (deliveryDate)
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  "تاريخ الاستلام",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                "القيمة",
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                "اسم الزبون",
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                "رقم الزبون",
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
    widgets.add(headerRow);

    // Add order rows
    for (var order in orders) {
      final orderRow = pw.Container(
        height: 40,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  order["f_date"] ?? "",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (deliveryDate)
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    order["delivery_date"] ?? "",
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ),
              ),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  "${order["f_value"]?.toString() ?? ""}",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  order["customer"][0]["c_name"] ?? " - ",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  order["customer_id"]?.toString() ?? "",
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
      widgets.add(orderRow);
    }

    final pdfPage = pw.MultiPage(
      theme: pw.ThemeData.withFont(base: arabicFont),
      pageFormat: PdfPageFormat.a4,
      build: (context) => widgets,
    );

    pdf.addPage(pdfPage);

    // Display the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<dynamic> getOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? type = prefs.getString('type');
    if (!isOnline) {
      final dbHelper = CartDatabaseHelper();

      // ✅ Clone the orders list to make it mutable
      List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        type.toString() == "quds"
            ? await dbHelper.getPendingOrders()
            : await dbHelper.getPendingOrdersVansale(),
      );

      List<Map<String, dynamic>> items = type.toString() == "quds"
          ? await dbHelper.getAllOrderItems()
          : await dbHelper.getAllOrderItemsVansale();

      // Group items by order_id
      Map<int, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in items) {
        int orderId = item['order_id'];
        groupedItems.putIfAbsent(orderId, () => []).add(item);
      }

      try {
        orders.sort((a, b) {
          String dateTimeA =
              '${a["order_date"]} ${a["order_time"] ?? "00:00:00"}';
          String dateTimeB =
              '${b["order_date"]} ${b["order_time"] ?? "00:00:00"}';
          DateTime dtA = DateTime.tryParse(dateTimeA) ?? DateTime(2000);
          DateTime dtB = DateTime.tryParse(dateTimeB) ?? DateTime(2000);
          return dtB.compareTo(dtA); // Newest first
        });
      } catch (e, stack) {
        print("❌ Error during sorting:");
        print(e);
      }

      return {
        "orders": orders.map((order) {
          return {
            ...order,
            "customer": [
              type.toString() == "quds"
                  ? {"c_name": order["customerName"] ?? "-"}
                  : {"c_name": order["customerName"] ?? "-"}
            ],
            "fatora_no": order["fatora_number"],
            "f_value": double.tryParse(order["total_amount"].toString())
                    ?.toStringAsFixed(2) ??
                "0.00",
            "f_date": order["order_date"],
            "delivery_date": order["deliveryDate"],
            "f_discount": order["discount"] ?? "0",
            "items": groupedItems[order["id"]] ?? [],
          };
        }).toList()
      };
    }

    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var baseUrl = type == "quds"
        ? '${AppLink.orders}/$company_id/$salesman_id'
        : '${AppLink.ordersVansale}/$company_id/$salesman_id';

    var url =
        showWithdrawnReceipts ? baseUrl : '$baseUrl?show_undownloaded=true';

    var response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> filterOrders() async {
    if (!isOnline) {
      final dbHelper = CartDatabaseHelper();
      List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        await dbHelper.getPendingOrdersVansale(),
      );
      List<Map<String, dynamic>> items =
          await dbHelper.getAllOrderItemsVansale();

      // Group items by order_id
      Map<int, List<Map<String, dynamic>>> groupedItems = {};
      for (var item in items) {
        int orderId = item['order_id'];
        groupedItems.putIfAbsent(orderId, () => []).add(item);
      }

      // Parse input dates
      DateTime? startDate = DateTime.tryParse(start_date.text);
      DateTime? endDate = DateTime.tryParse(end_date.text);

      if (startDate == null || endDate == null) {
        return {"orders": []}; // or throw error
      }

      // Filter by date
      orders = orders.where((order) {
        DateTime? orderDate = DateTime.tryParse(order["order_date"] ?? "");
        return orderDate != null &&
            orderDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(Duration(days: 1)));
      }).toList();

      // Sort by datetime descending
      orders.sort((a, b) {
        String dtA = '${a["order_date"]} ${a["order_time"] ?? "00:00:00"}';
        String dtB = '${b["order_date"]} ${b["order_time"] ?? "00:00:00"}';
        return (DateTime.tryParse(dtB) ?? DateTime(2000))
            .compareTo(DateTime.tryParse(dtA) ?? DateTime(2000));
      });

      return {
        "orders": orders.map((order) {
          return {
            ...order,
            "customer": [
              {"c_name": order["customer_name"] ?? "-"}
            ],
            "fatora_no": order["fatora_number"],
            "f_value": double.tryParse(order["total_amount"].toString())
                    ?.toStringAsFixed(2) ??
                "0.00",
            "f_date": order["order_date"],
            "delivery_date": order["deliveryDate"],
            "f_discount": order["discount"] ?? "0",
            "items": groupedItems[order["id"]] ?? [],
          };
        }).toList()
      };
    }

    // ✅ Online case (unchanged)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? type = prefs.getString('type');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json',
    };
    var url = type == "quds"
        ? 'https://yaghm.com/admin/api/filter_orders/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}'
        : '${AppLink.ordersFilterVansale}/$company_id/$salesman_id?start_date=${start_date.text}&end_date=${end_date.text}';
    var response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  setStart() async {
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

  setEnd() async {
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
}
