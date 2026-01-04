import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:quds_yaghmour/LocalDB/Models/rest-products-model.dart';
import 'package:quds_yaghmour/Screens/rest_products/rest_card/rest_card.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Server/server.dart' as globals;
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';

class RestProducts extends StatefulWidget {
  const RestProducts({Key? key}) : super(key: key);

  @override
  State<RestProducts> createState() => _RestProductsState();
}

class _RestProductsState extends State<RestProducts> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  List<RestProductItem> restProductItems = [];
  bool isProcessing = false;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<void> _printInvoice({
    required String macAddress,
    required String date,
    required String time,
    required List<RestProductItem> items,
    required String salesManNumber,
  }) async {
    await _printInvoiceAndroid(
      macAddress: macAddress,
      items: items,
      date: date,
      time: time,
      salesManNumber: salesManNumber,
    );
  }

  Future<void> _printInvoiceAndroid({
    required String macAddress,
    required String date,
    required String time,
    required List<RestProductItem> items,
    required String salesManNumber,
  }) async {
    await _connectToAndroidDevice(macAddress);

    final invoiceZPL = generateInvoiceZPL(
        items: items,
        date: date,
        time: time,
        salesManNumber: salesManNumber,
        macAddress: macAddress);

    try {
      bluetooth.write(invoiceZPL); // Pass the string directly
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Invoice printed successfully!")),
      // );
      await _disconnectFromAndroidDevice();
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error printing invoice: $e")),
      // );
      await _disconnectFromAndroidDevice();
    }
  }

  Future<void> _connectToAndroidDevice(String macAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? macAddressPrinter = prefs.getString('mac_address_printer');

    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      isProcessing = true;
    });

    try {
      // If permissions are granted, proceed to get the bonded devices
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      // Look for the device with the matching MAC address
      BluetoothDevice? targetDevice = devices.firstWhere(
        (d) => d.address == macAddress,
        orElse: () => BluetoothDevice("hazem", macAddressPrinter),
      );

      if (targetDevice != null) {
        await bluetooth.connect(targetDevice);
        if (!mounted) return; // Ensure the widget is still in the tree
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Connected to ${targetDevice.name}")),
        // );
      } else {
        if (!mounted) return; // Ensure the widget is still in the tree
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("No device with MAC address $macAddress")),
        // );
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Error connecting to device: $e")),
        // );
      }
    } finally {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _disconnectFromAndroidDevice() async {
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      isProcessing = true;
    });

    try {
      bool? isConnected = await bluetooth.isConnected;

      if (isConnected == true) {
        await bluetooth.disconnect();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device disconnected successfully")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device is not connected.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Error disconnecting from device: ${e.toString()}")),
        );
      }
    } finally {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isProcessing = false;
      });
    }
  }

  List<String> _chunkZPL(String zpl, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < zpl.length; i += chunkSize) {
      chunks.add(zpl.substring(
          i, i + chunkSize > zpl.length ? zpl.length : i + chunkSize));
    }
    return chunks;
  }

  String generateInvoiceZPL({
    required String macAddress,
    required String date,
    required String time,
    required List<RestProductItem> items,
    required String salesManNumber,
  }) {
    final int baseHeight = 510;
    final int rowHeight = 30;
    final int footerHeight = 160;
    int punusCount = 0;
    final int itemSectionHeight = (items.length + punusCount) * rowHeight;
    final int paperHeight = baseHeight + itemSectionHeight + footerHeight;

    final StringBuffer zpl = StringBuffer();

    zpl.write("""
^XA
^CI28
^CW1,E:TT0003M_.FNT
^LL${paperHeight}
^PA0,1,1,1

^FO1,200^GB569,0,8^FS

^FO160,30^A1N,40,40^FDالبضاعة المتبقية^FS

^FO20,100^A1N,30,30^FDالتاريخ: $date^FS
^FO20,140^A1N,30,30^FDالوقت: $time^FS
^FO20,180^A1N,30,30^FDرقم المندوب: $salesManNumber^FS
""");

    // Table Header
    zpl.write("""
^FO5,230^GB550,3,3^FS
^FO20,235^A1N,28,28^FDالموجود^FS
^FO110,235^A1N,28,28^FDالمباع^FS
^FO210,235^A1N,28,28^FDاسم الصنف^FS
^FO470,235^A1N,28,28^FDرقم^FS
^FO5,265^GB550,3,3^FS
""");

    // Vertical Lines
    int tableStartY = 270;
    zpl.write("""
^FO90,${tableStartY}^GB3,${itemSectionHeight},3^FS
^FO190,${tableStartY}^GB3,${itemSectionHeight},3^FS
^FO460,${tableStartY}^GB3,${itemSectionHeight},3^FS
""");

    // Items Rows
    int yPosition = tableStartY;
    for (var item in items) {
      String trimmedName = item.productName!.length > 25
          ? item.productName!.substring(0, 25)
          : item.productName!;

      zpl.write("""
^FO470,$yPosition^A1N,26,26^FD${item.productID}^FS
^FO200,$yPosition^A1N,26,26^FD$trimmedName^FS
^FO110,$yPosition^A1N,26,26^FD${item.soldQTY}^FS
^FO10,$yPosition^A1N,26,26^FD${item.restQTY}^FS
""");
      yPosition += rowHeight;
    }

    // Footer Line
    zpl.write("""
^FO20,$yPosition^GB550,3,3^FS
^XZ
""");

    return zpl.toString();
  }

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
          child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Scaffold(
            key: _scaffoldState,
            drawer: DrawerMain(),
            appBar: PreferredSize(
                child: AppBarBack(
                  title: "البضاعة المتبقية",
                ),
                preferredSize: Size.fromHeight(50)),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                            onTap: () async {
                              var arabicFont = pw.Font.ttf(await rootBundle
                                  .load("assets/fonts/Hacen_Tunisia.ttf"));
                              List<pw.Widget> widgets = [];
                              final title = pw.Column(
                                children: [
                                  pw.Center(
                                    child: pw.Directionality(
                                      textDirection: pw.TextDirection.rtl,
                                      child: pw.Text(
                                        "البضاعه المتبقيه",
                                        style: pw.TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  pw.SizedBox(
                                    height: 20,
                                  ),
                                ],
                              );
                              widgets.add(title);
                              final firstrow = pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                      flex: 3,
                                      child: pw.Center(
                                        child: pw.Text(
                                          "الكمية المتبقيه",
                                          style: pw.TextStyle(fontSize: 14),
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
                                          "الكمية المباعه",
                                          style: pw.TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  pw.Directionality(
                                    textDirection: pw.TextDirection.rtl,
                                    child: pw.Expanded(
                                      child: pw.Center(
                                        child: pw.Text(
                                          "أسم الصنف",
                                          style: pw.TextStyle(fontSize: 14),
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
                                          "#الصنف",
                                          style: pw.TextStyle(fontSize: 14),
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
                                itemCount: RestProductArray.length,
                                itemBuilder: (context, index) {
                                  return pw.Padding(
                                    padding: const pw.EdgeInsets.only(
                                        right: 15, left: 15, top: 15),
                                    child: pw.Container(
                                      child: pw.Column(
                                        children: [
                                          pw.Row(
                                            mainAxisAlignment: pw
                                                .MainAxisAlignment.spaceAround,
                                            children: [
                                              pw.Directionality(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                child: pw.Expanded(
                                                  flex: 3,
                                                  child: pw.Center(
                                                    child: pw.Text(
                                                      "${RestProductArray[index]['sold_quantity'] ?? ""}",
                                                      style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight.bold,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              pw.Directionality(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                child: pw.Expanded(
                                                  flex: 3,
                                                  child: pw.Center(
                                                    child: pw.Text(
                                                      "${RestProductArray[index]['rest_quantity'] ?? 0}",
                                                      style: pw.TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              pw.Directionality(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                child: pw.Expanded(
                                                  child: pw.Container(
                                                    width: 100,
                                                    child: pw.Text(
                                                      "${RestProductArray[index]['p_name'] ?? ""}",
                                                      style: pw.TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              pw.Directionality(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                child: pw.Expanded(
                                                  flex: 1,
                                                  child: pw.Center(
                                                    child: pw.Text(
                                                      "${RestProductArray[index]['id'] ?? 1}",
                                                      style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight.bold,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                top: 10),
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
                                  build: (context) =>
                                      widgets, //here goes the widgets list
                                ),
                              );
                              Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async =>
                                    pdf.save(),
                              );
                            },
                            child: Container(
                                height: 40,
                                width: 70,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Main_Color),
                                child: Center(
                                    child: Text(
                                  "PDF",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )))),
                        Visibility(
                          visible: Platform.isIOS ? false : true,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: ButtonWidget(
                                name: "طباعة zebra",
                                height: 40,
                                width: 120,
                                BorderColor: Main_Color,
                                FontSize: 16,
                                OnClickFunction: () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  String? macAddressPrinter =
                                      prefs.getString('mac_address_printer');
                                  String? invoiceHeader =
                                      prefs.getString('invoice_header');
                                  String? shopNo = prefs.getString('shop_no');
                                  String? type = prefs.getString('type');
                                  int? salesman_id =
                                      prefs.getInt('salesman_id');
                                  var now = DateTime.now();
                                  var formatterDate = DateFormat('yy-MM-dd');
                                  var formatterTime = DateFormat('kk:mm:ss');
                                  String actualDate = formatterDate.format(now);
                                  String actualTime = formatterTime.format(now);

                                  _printInvoice(
                                    macAddress: macAddressPrinter.toString(),
                                    items: restProductItems,
                                    date: actualDate.toString(),
                                    time: actualTime.toString(),
                                    salesManNumber: salesman_id.toString(),
                                  );
                                },
                                BorderRaduis: 10,
                                ButtonColor: Main_Color,
                                NameColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Main_Color,
                                    border: Border.all(color: Colors.white)),
                                child: Center(
                                  child: Text(
                                    "#الصنف",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Main_Color,
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "أسم الصنف",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Main_Color,
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "الكمية المتبقيه",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Main_Color,
                                    border: Border.all(color: Colors.white)),
                                child: Center(
                                  child: Text(
                                    "الكمية المباعه",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  loading
                      ? Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height,
                          child: Center(
                            child: SpinKitPulse(
                              color: Main_Color,
                              size: 60,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: ListView.builder(
                            itemCount: RestProductArray.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return RestCard(
                                id: RestProductArray[index]['id'] ?? 1,
                                name: RestProductArray[index]['p_name'] ?? "",
                                rest_qty: RestProductArray[index]
                                        ['rest_quantity'] ??
                                    0,
                                sold_qty: RestProductArray[index]
                                        ['sold_quantity'] ??
                                    "",
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Material(
                    child: Text(
                      "مجموع الكميات المتبقيه : ${sumRestQuantity.toString()}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
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
    setRestProducts();
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
        start_date.text = formattedDate; //set output date to TextField value.
      });
    } else {
      // print("Date is not selected");
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
      // print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      // print(
      //     formattedDate); //formatted date output using intl package =>  2021-03-16
      //you can implement different kind of Date Format here according to your requirement

      setState(() {
        end_date.text = formattedDate; //set output date to TextField value.
      });
    } else {
      // print("Date is not selected");
    }
  }

  bool fun = false;
  TextEditingController searchController = TextEditingController();

  List RestProductArray = [];
  bool loading = true;
  int sumRestQuantity = 0;
  setRestProducts() async {
    RestProductArray.clear();
    sumRestQuantity = 0;

    if (globals.isOnline) {
      // ✅ Online: Get data from API
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');

      var headers = {
        'Authorization': 'Bearer $token',
        'ContentType': 'application/json'
      };
      var url =
          'http://yaghm.com/admin/api/rest_products/${company_id.toString()}/${salesman_id.toString()}';
      var response = await http.get(Uri.parse(url), headers: headers);
      var res = jsonDecode(response.body)["products"];

      for (int i = 0; i < res.length; i++) {
        if (res[i]["rest_quantity"] != 0) {
          RestProductArray.add(res[i]);
          sumRestQuantity +=
              double.parse(res[i]['rest_quantity'].toString()).toInt();
          restProductItems.add(
            RestProductItem(
              productID: res[i]['id'].toString(),
              productName: res[i]['p_name'],
              restQTY: res[i]['rest_quantity'].toString(),
              soldQTY: res[i]['sold_quantity'].toString(),
            ),
          );
        }
      }
    } else {
      // ✅ Offline: Get data from local DB
      final dbHelper = CartDatabaseHelper();
      List<Map<String, dynamic>> localProducts =
          await dbHelper.getProductsVansale();

      for (var product in localProducts) {
        double qty = double.tryParse(product['quantity'].toString()) ?? 0;
        double paidQty =
            double.tryParse(product['productPaidQty'].toString()) ?? 0;

        if (qty > 0) {
          RestProductArray.add({
            'id': product['id'],
            'p_name': product['p_name'],
            'rest_quantity': qty.toStringAsFixed(2),
            'sold_quantity': paidQty.toStringAsFixed(2),
          });
          sumRestQuantity += qty.toInt();
          restProductItems.add(
            RestProductItem(
                productID: product['id'].toString(),
                productName: product['p_name'],
                restQTY: qty.toStringAsFixed(2).toString(),
                soldQTY: paidQty.toStringAsFixed(2)),
          );
        }
      }
    }

    loading = false;
    setState(() {});
  }
}
