import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/invoice-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../Services/AppBar/appbar_back.dart';
import '../../Services/Drawer/drawer.dart';

class OrdersDetails extends StatefulWidget {
  final id, f_code, fatoraNumber;
  final String customer_id,
      orderNotes,
      fatoraID,
      customer_name,
      printed,
      deliveryDate,
      orderDiscount;
  final double order_total;

  OrdersDetails({
    Key? key,
    this.id,
    required this.deliveryDate,
    required this.fatoraID,
    required this.orderNotes,
    required this.orderDiscount,
    required this.printed,
    required this.f_code,
    required this.fatoraNumber,
    required this.customer_id,
    required this.customer_name,
    required this.order_total,
  }) : super(key: key);

  @override
  State<OrdersDetails> createState() => _OrdersDetailsState();
}

class _OrdersDetailsState extends State<OrdersDetails> {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  String type = "";
  List<flutterBlue.BluetoothDevice> discoveredDevices = [];
  String vansaleCanPrint = "";
  List<InvoiceItem> fatoraItems = [];

  double totalQty = 0.0;
  double totalBonus = 0.0;

  // FIX: keep one future so FutureBuilder doesn't restart on every setState
  late Future<dynamic> _detailsFuture;

  // Common Variables
  bool isProcessing = false;
  String platform = Platform.isIOS ? "iOS" : "Android";

  // iOS Variables
  flutterBlue.FlutterBlue flutterBlueInstance =
      flutterBlue.FlutterBlue.instance;
  flutterBlue.BluetoothDevice? connectedIOSDevice;

  // Android Variables
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  TextEditingController macController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Create the future ONCE
    _detailsFuture = widget.f_code == "1" ? getOrders() : getKashf();
    // Other setup (safe to call setState inside without recreating the future)
    setControllers();
  }

  void _recomputeTotals() {
    double q = 0.0;
    double b = 0.0;
    for (final it in fatoraItems) {
      q += (it.quantity);
      final bb = double.tryParse(it.bonus.toString()) ?? 0.0;
      b += bb;
    }
    setState(() {
      totalQty = q;
      totalBonus = b;
    });
  }

  setControllers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _type = prefs.getString('type') ?? "quds";
    String? _vansaleCanPrint = prefs.getString('vansale_can_print') ?? "true";
    type = _type;
    vansaleCanPrint = _vansaleCanPrint;
    if (Platform.isIOS) {
      scanIOSDevices(); // 👈 only scan on iOS
    }
    setState(() {});
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
              title: type.toString() == "quds"
                  ? "تفاصيل الطلبية"
                  : "تفاصيل الفاتورة",
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Visibility(
                  visible: vansaleCanPrint.toString() == "true",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: ButtonWidget(
                          name: "طباعة zebra",
                          height: 40,
                          width: 100,
                          BorderColor: Main_Color,
                          FontSize: 16,
                          OnClickFunction: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final String? macAddressPrinter =
                                prefs.getString('mac_address_printer');
                            final String? invoiceHeader =
                                prefs.getString('invoice_header');
                            final String? shopNo = prefs.getString('shop_no');
                            final String? userTypePref = prefs.getString(
                                'type'); // renamed to avoid shadowing
                            final int? salesman_id =
                                prefs.getInt('salesman_id');

                            var now = DateTime.now();
                            var formatterDate = DateFormat('yy-MM-dd');
                            var formatterTime = DateFormat('kk:mm:ss');
                            String actualDate = formatterDate.format(now);
                            String actualTime = formatterTime.format(now);

                            if (Platform.isIOS) {
                              _showDeviceSelectionPopup(
                                userType: userTypePref.toString(),
                                macAddress: macAddressPrinter.toString(),
                                items: fatoraItems,
                                customerName: widget.customer_name.toString(),
                                date: actualDate.toString(),
                                time: actualTime.toString(),
                                invoiceHeader: invoiceHeader.toString(),
                                discount: widget.orderDiscount.toString(),
                                finalTotal: widget.order_total.toString(),
                                invoiceNumber: widget.fatoraNumber.toString(),
                                salesManNumber: salesman_id.toString(),
                                licensedOperator: shopNo.toString(),
                              );
                            } else {
                              _printInvoice(
                                userType: userTypePref.toString(),
                                macAddress: macAddressPrinter.toString(),
                                items: fatoraItems,
                                customerName: widget.customer_name.toString(),
                                date: actualDate.toString(),
                                time: actualTime.toString(),
                                invoiceHeader: invoiceHeader.toString(),
                                discount: widget.orderDiscount.toString(),
                                finalTotal: widget.order_total.toString(),
                                invoiceNumber: widget.fatoraNumber.toString(),
                                salesManNumber: salesman_id.toString(),
                                licensedOperator: shopNo.toString(),
                              );
                            }

                            if (userTypePref != "quds") {
                              updatePrintedValue(widget.id.toString(), "1");
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                          BorderRaduis: 10,
                          ButtonColor: Main_Color,
                          NameColor: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: ButtonWidget(
                          name: "طباعة PDF",
                          height: 40,
                          width: 100,
                          BorderColor: Main_Color,
                          FontSize: 16,
                          OnClickFunction: () async {
                            pdfFatoraA4(fatoraItems);
                          },
                          BorderRaduis: 10,
                          ButtonColor: Main_Color,
                          NameColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 10.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 7,
                            blurRadius: 5),
                      ],
                    ),
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الزبون :  ${widget.customer_id}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('أسم الزبون : ${widget.customer_name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('الخصم : ${widget.orderDiscount}₪',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(
                            'مجموع الفاتورة :  ${widget.order_total.toStringAsFixed(2)}₪',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('مجموع الكميات :  ${totalQty.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('مجموع البونص :  ${totalBonus.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 7,
                            blurRadius: 5),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("رقم الصنف",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("أسم الصنف",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("لون الصنف",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("الكمية",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("السعر",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("بونص",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                        Expanded(
                            flex: 1,
                            child: Center(
                                child: Text("المجموع الكلي",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                ),

                // === Fixed FutureBuilder ===
                FutureBuilder(
                  future: _detailsFuture,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: SpinKitPulse(color: Main_Color, size: 60),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()));
                    }

                    final orderDetails = snapshot.data["orders_details"] ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemCount: orderDetails.length,
                      itemBuilder: (BuildContext context, int index) {
                        // Detect proper quantity/price fields
                        var qtyRaw = orderDetails[index]['p_quantity'] ??
                            orderDetails[index]['quantity'];
                        var priceRaw = orderDetails[index]['p_price'] ??
                            orderDetails[index]['price'];
                        var ponusRaw = orderDetails[index]['bonus1'] ??
                            orderDetails[index]['bonus1'];

                        String cleanPrice(dynamic raw) {
                          if (raw == null) return "0";
                          return raw
                              .toString()
                              .replaceAll(RegExp(r'[^\d.]'), '');
                        }

                        var qty =
                            double.tryParse(qtyRaw?.toString() ?? '0') ?? 0;
                        var price = double.tryParse(cleanPrice(priceRaw)) ?? 0;

                        var discount = double.tryParse(
                                orderDetails[index]['discount']?.toString() ??
                                    '0') ??
                            0;

                        var init_total = qty * price * (1 - (discount / 100));

                        return order_card(
                          product_name: orderDetails[index]['product'] != null
                              ? (orderDetails[index]['product']["p_name"] ??
                                  "-")
                              : (orderDetails[index]['product_name'] ?? "-"),
                          product_id:
                              orderDetails[index]['product_id']?.toString() ??
                                  "-",
                          qty: qtyRaw.toString(),
                          price: priceRaw.toString(),
                          ponus: ponusRaw.toString(),
                          color_name:
                              orderDetails[index]['color_name']?.toString() ??
                                  "-",
                          total: init_total.toStringAsFixed(2),
                        );
                      },
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

  void _showDeviceSelectionPopup({
    required String macAddress,
    required String invoiceHeader,
    required String invoiceNumber,
    required String licensedOperator,
    required String date,
    required String time,
    required String userType,
    required List<InvoiceItem> items,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String finalTotal,
  }) {
    if (connectedIOSDevice != null && connectedIOSDevice!.id.id == macAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Already connected to ${connectedIOSDevice!.name}")),
      );

      _printInvoice(
        macAddress: connectedIOSDevice!.id.id,
        userType: userType,
        items: items,
        customerName: customerName,
        invoiceHeader: invoiceHeader,
        date: date,
        time: time,
        discount: discount,
        finalTotal: finalTotal,
        invoiceNumber: invoiceNumber,
        salesManNumber: salesManNumber,
        licensedOperator: licensedOperator,
      );
      return;
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Select a Device"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = discoveredDevices[index];
                  return ListTile(
                    title: Text(
                        device.name.isEmpty ? "Unnamed Device" : device.name),
                    subtitle: Text(device.id.id),
                    onTap: () {
                      Navigator.of(context).pop();
                      _connectToDevice(
                        macAddress: device.id.id,
                        userType: userType,
                        items: items,
                        customerName: customerName,
                        invoiceHeader: invoiceHeader,
                        date: date,
                        time: time,
                        discount: discount,
                        finalTotal: finalTotal,
                        invoiceNumber: invoiceNumber,
                        salesManNumber: salesManNumber,
                        licensedOperator: licensedOperator,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _connectToDevice({
    required String macAddress,
    required String invoiceNumber,
    required String userType,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required List<InvoiceItem> items,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String finalTotal,
  }) async {
    if (platform == "iOS") {
      await _connectToIOSDevice(
        macAddress: macAddress,
        userType: userType,
        items: items,
        customerName: customerName,
        invoiceHeader: invoiceHeader,
        date: date,
        time: time,
        discount: discount,
        finalTotal: finalTotal,
        invoiceNumber: invoiceNumber,
        salesManNumber: salesManNumber,
        licensedOperator: licensedOperator,
      );
    } else {
      await _connectToAndroidDevice(macAddress);
    }
  }

  Future<void> _disconnectFromAndroidDevice() async {
    if (!mounted) return;
    setState(() => isProcessing = true);

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Device disconnected successfully")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No device is currently connected")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error disconnecting from device: $e")));
      }
    } finally {
      if (!mounted) return;
      setState(() => isProcessing = false);
    }
  }

  Future<void> _connectToAndroidDevice(String macAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? macAddressPrinter = prefs.getString('mac_address_printer');

    if (!mounted) return;
    setState(() => isProcessing = true);

    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      BluetoothDevice? targetDevice = devices.firstWhere(
        (d) => d.address == macAddress,
        orElse: () => BluetoothDevice("hazem", macAddressPrinter),
      );

      if (targetDevice != null) {
        await bluetooth.connect(targetDevice);
      }
    } catch (_) {
      // swallow and continue
    } finally {
      if (!mounted) return;
      setState(() => isProcessing = false);
    }
  }

  Future<void> _connectToIOSDevice({
    required String macAddress,
    required String invoiceNumber,
    required String userType,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required List<InvoiceItem> items,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String finalTotal,
  }) async {
    if (mounted) setState(() => isProcessing = true);

    try {
      final deviceToConnect =
          discoveredDevices.firstWhere((device) => device.id.id == macAddress);
      if (connectedIOSDevice?.id.id == deviceToConnect.id.id) {
        await connectedIOSDevice?.disconnect();
        connectedIOSDevice = null;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Device disconnected.")));
        return;
      }

      await deviceToConnect.connect();
      connectedIOSDevice = deviceToConnect;

      _printInvoice(
        macAddress: macAddress,
        userType: userType,
        items: items,
        customerName: customerName,
        invoiceHeader: invoiceHeader,
        date: date,
        time: time,
        discount: discount,
        finalTotal: finalTotal,
        invoiceNumber: invoiceNumber,
        salesManNumber: salesManNumber,
        licensedOperator: licensedOperator,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error connecting to device: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _printInvoice({
    required String macAddress,
    required String invoiceNumber,
    required String userType,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required List<InvoiceItem> items,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String finalTotal,
  }) async {
    if (Platform.isIOS) {
      if (connectedIOSDevice == null) {
        await _connectToIOSDevice(
          macAddress: macAddress,
          userType: userType,
          items: items,
          customerName: customerName,
          invoiceHeader: invoiceHeader,
          date: date,
          time: time,
          discount: discount,
          finalTotal: finalTotal,
          invoiceNumber: invoiceNumber,
          salesManNumber: salesManNumber,
          licensedOperator: licensedOperator,
        );
      }

      final invoiceZPL = generateInvoiceZPL(
        invoiceHeader: invoiceHeader,
        userType: userType,
        items: items,
        customerName: customerName,
        date: date,
        time: time,
        discount: discount,
        finalTotal: finalTotal,
        invoiceNumber: invoiceNumber,
        salesManNumber: salesManNumber,
        licensedOperator: licensedOperator,
      );

      try {
        if (connectedIOSDevice != null) {
          List<flutterBlue.BluetoothService> services =
              await connectedIOSDevice!.discoverServices();
          for (var service in services) {
            for (var characteristic in service.characteristics) {
              if (characteristic.properties.write) {
                for (String chunk in _chunkZPL(invoiceZPL, 200)) {
                  await characteristic
                      .write(Uint8List.fromList(utf8.encode(chunk)));
                  await Future.delayed(const Duration(milliseconds: 200));
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Invoice printed successfully!")));
                }
                try {
                  await connectedIOSDevice!.disconnect();
                  connectedIOSDevice = null;
                } catch (_) {}
                return;
              }
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("No writable characteristic found")));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("No connected iOS printer found")));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error printing invoice: $e")));
        }
      }
    } else {
      await _printInvoiceAndroid(
        macAddress: macAddress,
        invoiceHeader: invoiceHeader,
        userType: userType,
        items: items,
        customerName: customerName,
        date: date,
        time: time,
        discount: discount,
        finalTotal: finalTotal,
        invoiceNumber: invoiceNumber,
        salesManNumber: salesManNumber,
        licensedOperator: licensedOperator,
      );
    }
  }

  Future<void> _printInvoiceAndroid({
    required String macAddress,
    required String invoiceNumber,
    required String invoiceHeader,
    required String licensedOperator,
    required String userType,
    required String date,
    required String time,
    required List<InvoiceItem> items,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String finalTotal,
  }) async {
    await _connectToAndroidDevice(macAddress);

    final invoiceZPL = generateInvoiceZPL(
      invoiceHeader: invoiceHeader,
      userType: userType,
      items: items,
      invoiceNumber: invoiceNumber,
      licensedOperator: licensedOperator,
      date: date,
      time: time,
      customerName: customerName,
      salesManNumber: salesManNumber,
      discount: discount,
      finalTotal: finalTotal,
    );

    try {
      bluetooth.write(invoiceZPL);
      await _disconnectFromAndroidDevice();
    } catch (e) {
      await _disconnectFromAndroidDevice();
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
    required String invoiceNumber,
    required String invoiceHeader,
    required String licensedOperator,
    required String userType,
    required String date,
    required String time,
    required String customerName,
    required String salesManNumber,
    required List<InvoiceItem> items,
    required String discount,
    required String finalTotal,
  }) {
    final int baseHeight = 510;
    final int rowHeight = 30;
    final int footerHeight = 160;
    int punusCount = 0;
    for (int i = 0; i < items.length; i++) {
      if (int.parse(items[i].bonus.toString()) != 0) {
        punusCount++;
      }
    }
    final int itemSectionHeight = (items.length + punusCount) * rowHeight;
    final int paperHeight = baseHeight + itemSectionHeight + footerHeight;

    final StringBuffer zpl = StringBuffer();

    zpl.write("""
^XA
^CI28
^CW1,E:TT0003M_.FNT
^LL${paperHeight}
^PA0,1,1,1
$invoiceHeader
^FO1,218^GB569,0,8^FS

^FO20,310^A1N,30,30^FDالتاريخ: $date^FS
^FO20,350^A1N,30,30^FDالوقت: $time^FS
^FO160,390^A1N,30,30^FD${customerName.toString()}^FS
""");

    if (userType == "quds" ||
        licensedOperator == "999999999" ||
        licensedOperator.isEmpty) {
      zpl.write("""
^FO160,230^A1N,30,30^FD رقم: ${widget.id.toString()}^FS
""");
    } else {
      zpl.write("""
^FO160,230^A1N,30,30^FDفاتورة ضريبية رقم: $invoiceNumber^FS
^FO20,270^A1N,30,30^FD${widget.printed.toString() == "1" ? "Copy" : "Original"}^FS
^FO360,270^A1N,30,30^FDمشغل مرخص^FS
^FO360,310^A1N,30,30^FD$licensedOperator^FS
""");
    }

    zpl.write("""
^FO5,445^GB500,3,3^FS
^FO5,445^A1N,27,27^FDالاسم               الكمية       السعر   المجموع^FS
^FO5,475^GB500,3,3^FS
""");

    int tableStartY = 480;
    zpl.write("""
^FO200,${tableStartY}^GB3,${itemSectionHeight},3^FS
^FO100,${tableStartY}^GB3,${itemSectionHeight},3^FS
^FO310,${tableStartY}^GB3,${itemSectionHeight},3^FS
""");

    int yPosition = tableStartY;
    for (var item in items) {
      String name = item.name.length > 30
          ? item.name.substring(0, 30)
          : item.name.padLeft(20);
      String quantity = item.quantity.toStringAsFixed(1).padLeft(6);
      String price = item.price.toStringAsFixed(1).padLeft(6);
      String total = item.total.toStringAsFixed(1).padLeft(6);

      zpl.write("""
^FO330,$yPosition^A1N,21,21^FD$name^FS
^FO210,$yPosition^A1N,28,28^FD$quantity^FS
^FO110,$yPosition^A1N,28,28^FD$price^FS
^FO10,$yPosition^A1N,28,28^FD$total^FS
""");
      yPosition += rowHeight;

      if (int.parse(item.bonus.toString()) != 0 &&
          item.bonus.toString() != "null") {
        zpl.write("""
^FO330,$yPosition^A1N,21,21^FD$name^FS
^FO210,$yPosition^A1N,28,28^FD${item.bonus.toString()}^FS
^FO110,$yPosition^A1N,28,28^FD0^FS
^FO10,$yPosition^A1N,28,28^FD0^FS
""");
        yPosition += rowHeight;
      }
    }

    final double computedTotal =
        items.fold<double>(0, (sum, item) => sum + item.total);

    zpl.write("""
^FO20,$yPosition^GB550,3,3^FS
^FO20,${yPosition + 20}^A1N,30,30^FDالمجموع:        ${computedTotal.toStringAsFixed(1)}^FS
^FO330,${yPosition + 20}^A1N,30,30^FDرقم المندوب^FS
^FO20,${yPosition + 60}^A1N,30,30^FDالخصم:          ${discount}^FS
^FO330,${yPosition + 60}^A1N,30,30^FD${salesManNumber.toString()}^FS
^FO20,${yPosition + 100}^GB550,3,3^FS
^FO20,${yPosition + 130}^A1N,30,30^FDالمجموع النهائي:       ${finalTotal}^FS
^XZ
""");

    return zpl.toString();
  }

  getOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? type = prefs.getString('type');
    var isOffline = !isOnline;

    if (isOffline) {
      final dbHelper = CartDatabaseHelper();
      List<Map<String, dynamic>> items = [];
      if (type == "quds") {
        items = await dbHelper.getOrderItemsQuds(int.parse(widget.fatoraID));
      } else {
        items = await dbHelper.getOrderItemsVansale(int.parse(widget.fatoraID));
      }

      fatoraItems.clear();
      for (var item in items) {
        var discountValue =
            double.tryParse(item['discount']?.toString() ?? '0') ?? 0;
        var q = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
        var p = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        var total = q * p * (1 - (discountValue / 100));

        fatoraItems.add(
          InvoiceItem(
            name: item["product_name"] ?? "-",
            quantity: q,
            price: p,
            bonus: item["bonus1"]?.toString() ?? "0",
            discount: discountValue,
            total: total,
          ),
        );
      }
      _recomputeTotals();
      return {"orders_details": items};
    }

    var url = type == "quds"
        ? "${AppLink.ordersDetails}/${widget.id}/$company_id/$salesman_id"
        : 'https://yaghm.com/admin/api/orders_details_vansale/${widget.fatoraNumber}/$company_id/$salesman_id';

    var response = await http.get(Uri.parse(url));
    var res = jsonDecode(response.body);

    fatoraItems.clear();
    for (var item in res["orders_details"]) {
      var discountValue =
          double.tryParse(item["discount"]?.toString() ?? '0') ?? 0;
      var q = double.tryParse(item["p_quantity"]?.toString() ??
              item["quantity"]?.toString() ??
              '0') ??
          0;
      var p = double.tryParse(item["p_price"]?.toString() ??
              item["price"]?.toString() ??
              '0') ??
          0;
      var total = q * p * (1 - (discountValue / 100));

      fatoraItems.add(
        InvoiceItem(
          name: item['product']?["p_name"] ?? item['product_name'] ?? "-",
          quantity: q,
          price: p,
          bonus: (item["bonus1"] ?? "0").toString(),
          discount: discountValue,
          total: total,
        ),
      );
    }
    _recomputeTotals();
    return res;
  }

  getKashf() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        'https://yaghm.com/admin/api/getkashfs/${widget.fatoraNumber.toString()}/$company_id/$salesman_id/2';
    var response = await http.get(Uri.parse(url), headers: headers);

    var res = jsonDecode(response.body);

    // Optional: populate fatoraItems here as well if needed for totals on Kashf flow:
    fatoraItems.clear();
    final list = (res["orders_details"] as List?) ?? [];
    for (var item in list) {
      final q = double.tryParse(
              (item["p_quantity"] ?? item["quantity"])?.toString() ?? '0') ??
          0;
      final p = double.tryParse(
              (item["p_price"] ?? item["price"])?.toString() ?? '0') ??
          0;
      final discountValue =
          double.tryParse(item["discount"]?.toString() ?? '0') ?? 0;
      final total = q * p * (1 - (discountValue / 100));
      fatoraItems.add(
        InvoiceItem(
          name: item['product']?["p_name"] ?? item['product_name'] ?? "-",
          quantity: q,
          price: p,
          bonus: (item["bonus1"] ?? "0").toString(),
          discount: discountValue,
          total: total,
        ),
      );
    }
    _recomputeTotals();

    return res;
  }

  Widget order_card({
    String product_id = "",
    String product_name = "",
    String color_name = "",
    String name = "",
    String qty = "",
    String price = "",
    String ponus = "",
    String total = "",
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 10),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 7,
                blurRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Expanded(flex: 1, child: Center(child: Text(product_id))),
            Expanded(flex: 1, child: Center(child: Text(product_name))),
            Expanded(
              flex: 1,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: _parseHexColor(color_name),
                  border: Border.all(color: Colors.transparent, width: 2.0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Expanded(flex: 1, child: Center(child: Text(qty))),
            Expanded(flex: 1, child: Center(child: Text("₪$price"))),
            Expanded(flex: 1, child: Center(child: Text("$ponus"))),
            Expanded(flex: 1, child: Center(child: Text("₪$total"))),
          ],
        ),
      ),
    );
  }

  Color _parseHexColor(String colorName) {
    try {
      if (colorName.isNotEmpty &&
          RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(colorName)) {
        return Color(int.parse('0xFF$colorName'));
      } else {
        return Colors.transparent;
      }
    } catch (e) {
      return Colors.transparent;
    }
  }

  pdfFatoraA4(var cartItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? shop_no = prefs.getString('shop_no');
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    final double computedTotal =
        fatoraItems.fold<double>(0, (sum, item) => sum + item.total);
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));

    List<pw.Widget> widgets = [];

    final title = pw.Column(
      children: [
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("تسعيرة", style: const pw.TextStyle(fontSize: 20)),
          ),
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(),
                style: const pw.TextStyle(fontSize: 17)),
            pw.SizedBox(width: 5),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("التاريخ : ",
                    style: const pw.TextStyle(fontSize: 17))),
          ]),
        ]),
        pw.SizedBox(height: 5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(widget.customer_name.toString(),
                  style: const pw.TextStyle(fontSize: 17))),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("اسم الزبون : ",
                  style: const pw.TextStyle(fontSize: 17))),
        ]),
        // If you intend deliveryDate as boolean, adjust; currently widget.deliveryDate is String in your ctor
        // Example guard:
        // if (widget.deliveryDate.isNotEmpty) ...
      ],
    );
    widgets.add(title);

    final firstrow = pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
          color: PdfColors.grey300,
          border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                  border:
                      pw.Border(left: pw.BorderSide(color: PdfColors.grey400))),
              child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                      child: pw.Text("المبلغ",
                          style: const pw.TextStyle(fontSize: 17)))),
            ),
          ),
          if (discountSetting)
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.grey400))),
                child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Center(
                        child: pw.Text("الخصم",
                            style: const pw.TextStyle(fontSize: 17)))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                  border:
                      pw.Border(left: pw.BorderSide(color: PdfColors.grey400))),
              child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                      child: pw.Text("السعر",
                          style: const pw.TextStyle(fontSize: 17)))),
            ),
          ),
          if (ponus1)
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.grey400))),
                child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Center(
                        child: pw.Text("بونص",
                            style: const pw.TextStyle(fontSize: 17)))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                  border:
                      pw.Border(left: pw.BorderSide(color: PdfColors.grey400))),
              child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                      child: pw.Text("الكمية",
                          style: const pw.TextStyle(fontSize: 17)))),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                  border:
                      pw.Border(left: pw.BorderSide(color: PdfColors.grey400))),
              child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                      child: pw.Text("الصنف",
                          style: const pw.TextStyle(fontSize: 17)))),
            ),
          ),
        ],
      ),
    );
    widgets.add(firstrow);

    final listview = pw.ListView.builder(
      itemCount: fatoraItems.length,
      itemBuilder: (context, index) {
        var item = fatoraItems[index];

        List<String> nameLines = [];
        String remainingName = item.name;
        int maxCharsPerLine = 15;
        List<String> words = remainingName.split(' ');
        String currentLine = "";
        for (var word in words) {
          if ((currentLine.length + word.length) <= maxCharsPerLine) {
            currentLine += (currentLine.isEmpty ? "" : " ") + word;
          } else {
            nameLines.add(currentLine);
            currentLine = word;
          }
        }
        if (currentLine.isNotEmpty) nameLines.add(currentLine);

        double rowHeight = 25.0 + (nameLines.length * 25.0);

        return pw.Container(
          height: rowHeight,
          decoration:
              pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.grey400))),
                  child: pw.Center(
                      child: pw.Text(item.total.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 17))),
                ),
              ),
              if (discountSetting)
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(
                            left: pw.BorderSide(color: PdfColors.grey400))),
                    child: pw.Center(
                        child: pw.Text("0.00",
                            style: const pw.TextStyle(fontSize: 17))),
                  ),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.grey400))),
                  child: pw.Center(
                      child: pw.Text(item.price.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 17))),
                ),
              ),
              if (ponus1)
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                        border: pw.Border(
                            left: pw.BorderSide(color: PdfColors.grey400))),
                    child: pw.Center(
                        child: pw.Text(
                            double.parse(item.bonus).toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 17))),
                  ),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.grey400))),
                  child: pw.Center(
                      child: pw.Text(item.quantity.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 17))),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          left: pw.BorderSide(color: PdfColors.grey400))),
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: nameLines
                            .map((line) => pw.Text(line,
                                style: const pw.TextStyle(fontSize: 14)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    widgets.add(listview);

    final total = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        if (widget.orderNotes.toString() != "")
          pw.Column(
            children: [
              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(widget.orderNotes.toString(),
                        style: const pw.TextStyle(fontSize: 17))),
                pw.SizedBox(width: 5),
                pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text("الملاحظات : ",
                        style: const pw.TextStyle(fontSize: 17))),
              ]),
            ],
          ),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text(computedTotal.toString(),
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("المجموع قبل الخصم : ",
                  style: const pw.TextStyle(fontSize: 17))),
        ]),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text(widget.orderDiscount.toString(),
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(" الخصم : ",
                  style: const pw.TextStyle(fontSize: 17))),
        ]),
        pw.SizedBox(height: 10),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text(widget.order_total.toString(),
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("المجموع النهائي : ",
                  style: const pw.TextStyle(fontSize: 17))),
        ]),
      ],
    );
    widgets.add(total);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: arabicFont),
        pageFormat: PdfPageFormat.a4,
        build: (context) => widgets,
      ),
    );
    Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
