// import 'package:date_format/date_format.dart';
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/history-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/check-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../LocalDB/Models/invoice-model.dart';
import '../../Server/domains/domains.dart';
import '../../Server/server.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../Services/Drawer/drawer.dart';

class CatchReceipt extends StatefulWidget {
  final id, name, balance;
  const CatchReceipt({Key? key, this.id, required this.balance, this.name})
      : super(key: key);

  @override
  State<CatchReceipt> createState() => _CatchReceiptState();
}

class _CatchReceiptState extends State<CatchReceipt> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool isProcessing = false;
  String platform = Platform.isIOS ? "iOS" : "Android";
  List<flutterBlue.BluetoothDevice> discoveredDevices = [];

  // iOS Variables
  flutterBlue.FlutterBlue flutterBlueInstance =
      flutterBlue.FlutterBlue.instance;
  flutterBlue.BluetoothDevice? connectedIOSDevice;

  // Android Variables
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  TextEditingController macController = TextEditingController();
  String vansaleCanPrint = "";
  initval() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _vansaleCanPrint = prefs.getString('vansale_can_print') ?? "true";
    if (Platform.isIOS) {
      scanIOSDevices(); // 👈 only scan on iOS
    }
    setState(() {
      nameController.text = widget.name.toString();
      vansaleCanPrint = _vansaleCanPrint.toString();
      balanceController.text = widget.balance.toString();
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

  // requestPermission() async {
  //   PermissionStatus status = await Permission.bluetooth.request();
  //   if (!status.isGranted) {
  //     // Handle permission denied case
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Bluetooth permission not granted")),
  //     );
  //     return;
  //   }
  //   PermissionStatus locationStatus = await Permission.location.request();
  //   if (!locationStatus.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Location permission not granted")),
  //     );
  //     return;
  //   }
  // }

  @override
  void initState() {
    // requestPermission();
    super.initState();
    initval();
  }

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldState,
          drawer: DrawerMain(),
          appBar: PreferredSize(
              child: AppBarBack(
                title: "اضافة سند قبض",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 15, left: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "أسم الزبون",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 15, left: 15, top: 5),
                              child: Container(
                                height: 50,
                                width: double.infinity,
                                child: TextField(
                                  controller: nameController,
                                  obscureText: false,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color(0xff34568B), width: 2.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 2.0, color: Color(0xffD6D3D3)),
                                    ),
                                    hintText: "أسم الزبون",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 15, left: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "رصيد الزبون",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 15, left: 15, top: 5),
                              child: Container(
                                height: 50,
                                width: double.infinity,
                                child: TextField(
                                  controller: balanceController,
                                  obscureText: false,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color(0xff34568B), width: 2.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 2.0, color: Color(0xffD6D3D3)),
                                    ),
                                    hintText: "رصيد الزبون",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "المجموع النقدي",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        controller: CashController,
                        obscureText: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (hazem) {
                          setState(() {
                            var init_value = double.parse(
                                    DiscountController.text == ""
                                        ? "0"
                                        : DiscountController.text) +
                                double.parse(CashController.text == ""
                                    ? "0"
                                    : CashController.text) +
                                double.parse(
                                    TOTAL.text == "" ? "0" : TOTAL.text);

                            MAINTOTAL.text = init_value.toString();
                          });
                        },
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "المجموع النقدي",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "الخصم",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        controller: DiscountController,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (hazem) {
                          setState(() {
                            var init_value = double.parse(
                                    DiscountController.text == ""
                                        ? "0"
                                        : DiscountController.text) +
                                double.parse(CashController.text == ""
                                    ? "0"
                                    : CashController.text) +
                                double.parse(
                                    TOTAL.text == "" ? "0" : TOTAL.text);

                            MAINTOTAL.text = init_value.toString();
                          });
                        },
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "الخصم",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "مجموع الشيكات",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 50,
                            child: TextField(
                              controller: TOTAL,
                              readOnly: true,
                              onChanged: (hazem) {
                                setState(() {
                                  var init_value = double.parse(
                                          DiscountController.text == ""
                                              ? "0"
                                              : DiscountController.text) +
                                      double.parse(CashController.text == ""
                                          ? "0"
                                          : CashController.text) +
                                      double.parse(
                                          TOTAL.text == "" ? "0" : TOTAL.text);

                                  MAINTOTAL.text = init_value.toString();
                                });
                              },
                              obscureText: false,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xff34568B), width: 2.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      width: 2.0, color: Color(0xffD6D3D3)),
                                ),
                                hintText: "مجموع الشيكات",
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return SingleChildScrollView(
                                      child: AlertDialog(
                                        actions: <Widget>[
                                          Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 50,
                                                            right: 15,
                                                            left: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "قيمه الشيك",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5,
                                                            left: 5,
                                                            top: 5),
                                                    child: Container(
                                                      height: 50,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        keyboardType: TextInputType
                                                            .numberWithOptions(
                                                                signed: true,
                                                                decimal: true),
                                                        controller:
                                                            valueController,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff34568B),
                                                                width: 2.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                width: 2.0,
                                                                color: Color(
                                                                    0xffD6D3D3)),
                                                          ),
                                                          hintText:
                                                              "قيمه الشيك",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10,
                                                            right: 15,
                                                            left: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "تاريخ الاستحقاق",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5,
                                                            left: 5,
                                                            top: 5),
                                                    child: Container(
                                                      height: 50,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        onTap: _pickDate,
                                                        controller:
                                                            datechekController,
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff34568B),
                                                                width: 2.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                width: 2.0,
                                                                color: Color(
                                                                    0xffD6D3D3)),
                                                          ),
                                                          hintText:
                                                              "تاريخ الاستحقاق",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10,
                                                            right: 15,
                                                            left: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "رقم الشك",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5,
                                                            left: 5,
                                                            top: 5),
                                                    child: Container(
                                                      height: 50,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        controller:
                                                            cheknumController,
                                                        obscureText: false,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly, // Allows only digits
                                                          LengthLimitingTextInputFormatter(
                                                              8), // Limits to 8 digits
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff34568B),
                                                                width: 2.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                width: 2.0,
                                                                color: Color(
                                                                    0xffD6D3D3)),
                                                          ),
                                                          hintText: "رقم الشك",
                                                        ),
                                                      ),
                                                    ),
                                                  ),

// Bank Number (Max 2 digits)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10,
                                                            right: 15,
                                                            left: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "رقم البنك",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5,
                                                            left: 5,
                                                            top: 5),
                                                    child: Container(
                                                      height: 50,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        controller:
                                                            bank_numController,
                                                        obscureText: false,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly, // Allows only digits
                                                          LengthLimitingTextInputFormatter(
                                                              2), // Limits to 2 digits
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff34568B),
                                                                width: 2.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                width: 2.0,
                                                                color: Color(
                                                                    0xffD6D3D3)),
                                                          ),
                                                          hintText: "رقم البنك",
                                                        ),
                                                      ),
                                                    ),
                                                  ),

// Account Number (Max 10 digits)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10,
                                                            right: 15,
                                                            left: 15),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "رقم الحساب",
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5,
                                                            left: 5,
                                                            top: 5),
                                                    child: Container(
                                                      height: 50,
                                                      width: double.infinity,
                                                      child: TextField(
                                                        controller:
                                                            accountnumController,
                                                        obscureText: false,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly, // Allows only digits
                                                          LengthLimitingTextInputFormatter(
                                                              10), // Limits to 10 digits
                                                        ],
                                                        decoration:
                                                            InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff34568B),
                                                                width: 2.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                width: 2.0,
                                                                color: Color(
                                                                    0xffD6D3D3)),
                                                          ),
                                                          hintText:
                                                              "رقم الحساب",
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 25,
                                                            left: 25,
                                                            top: 25),
                                                    child: MaterialButton(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          10))),
                                                      height: 50,
                                                      minWidth: double.infinity,
                                                      color: Color(0xff34568B),
                                                      textColor: Colors.white,
                                                      child: Text(
                                                        "اضافة شيك",
                                                        style: TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      onPressed: () {
                                                        if (valueController
                                                                    .text ==
                                                                "" ||
                                                            datechekController
                                                                    .text ==
                                                                "") {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                content: Text(
                                                                    'الرجاء تعبئه جميع الفراغات'),
                                                                actions: <Widget>[
                                                                  InkWell(
                                                                    onTap: () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: Text(
                                                                      'حسنا',
                                                                      style: TextStyle(
                                                                          color:
                                                                              Color(0xff34568B)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        } else {
                                                          cheks_array.add(
                                                              valueController
                                                                  .text);
                                                          setState(() {
                                                            chk_no_array.add(
                                                                cheknumController
                                                                    .text);
                                                            value_array.add(
                                                                valueController
                                                                    .text);
                                                            date_array.add(
                                                                datechekController
                                                                    .text);
                                                            account_num_array.add(
                                                                accountnumController
                                                                    .text);
                                                            bank_num_array.add(
                                                                bank_numController
                                                                    .text);

                                                            check_total +=
                                                                double.parse(
                                                                    valueController
                                                                        .text);
                                                            TOTAL.text =
                                                                check_total
                                                                    .toString();

                                                            var init_value = double.parse(
                                                                    DiscountController.text ==
                                                                            ""
                                                                        ? "0"
                                                                        : DiscountController
                                                                            .text) +
                                                                double.parse(CashController
                                                                            .text ==
                                                                        ""
                                                                    ? "0"
                                                                    : CashController
                                                                        .text) +
                                                                double.parse(
                                                                    TOTAL.text ==
                                                                            ""
                                                                        ? "0"
                                                                        : TOTAL
                                                                            .text);

                                                            MAINTOTAL.text =
                                                                init_value
                                                                    .toString();
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                          setState(() {
                                                            cheknumController
                                                                .text = "";
                                                            valueController
                                                                .text = "";
                                                            datechekController
                                                                .text = "";
                                                            accountnumController
                                                                .text = "";
                                                            bank_numController
                                                                .text = "";
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  icon: Icon(
                                                    Icons.arrow_back_sharp,
                                                    size: 30,
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: Main_Color),
                                height: 50,
                                width: 50,
                                child: Center(
                                    child: Image.asset("assets/plus.jpeg")),
                              ),
                            ))
                      ],
                    ),
                  ),
                  Visibility(
                    visible: cheks_array.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: SizedBox(
                        height: 80,
                        width: double.infinity,
                        child: ListView.builder(
                          itemCount: cheks_array.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, int index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 15, left: 15),
                              child: Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  Container(
                                    height: 60,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Main_Color,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${cheks_array[index]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.all(2),
                                    onPressed: () {
                                      // ✅ 1) قيمة الشيك (من value_array الأفضل لأنه هو الذي يُرسل للسيرفر)
                                      final double v = double.tryParse(
                                              value_array[index].toString()) ??
                                          double.tryParse(
                                              cheks_array[index].toString()) ??
                                          0.0;

                                      setState(() {
                                        // ✅ 2) تعديل مجموع الشيكات
                                        check_total -= v;
                                        if (check_total < 0) check_total = 0;

                                        TOTAL.text = check_total.toString();

                                        // ✅ 3) حذف نفس العنصر من جميع القوائم (مهم جدًا)
                                        cheks_array.removeAt(index);

                                        if (index < chk_no_array.length)
                                          chk_no_array.removeAt(index);
                                        if (index < value_array.length)
                                          value_array.removeAt(index);
                                        if (index < date_array.length)
                                          date_array.removeAt(index);
                                        if (index < account_num_array.length)
                                          account_num_array.removeAt(index);
                                        if (index < bank_num_array.length)
                                          bank_num_array.removeAt(index);

                                        // ✅ 4) إعادة حساب المجموع النهائي
                                        final discount = double.tryParse(
                                                DiscountController.text.isEmpty
                                                    ? "0"
                                                    : DiscountController
                                                        .text) ??
                                            0.0;
                                        final cash = double.tryParse(
                                                CashController.text.isEmpty
                                                    ? "0"
                                                    : CashController.text) ??
                                            0.0;
                                        final checks = double.tryParse(
                                                TOTAL.text.isEmpty
                                                    ? "0"
                                                    : TOTAL.text) ??
                                            0.0;

                                        MAINTOTAL.text =
                                            (discount + cash + checks)
                                                .toString();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "المجموع الكلي",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      child: TextField(
                        readOnly: true,
                        controller: MAINTOTAL,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "المجموع الكلي",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "ملاحظات",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      child: TextField(
                        controller: NotesController,
                        obscureText: false,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xff34568B), width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 2.0, color: Color(0xffD6D3D3)),
                          ),
                          hintText: "ملاحظات",
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 25, left: 25, top: 35, bottom: 20),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      height: 50,
                      minWidth: double.infinity,
                      color: Color(0xff34568B),
                      textColor: Colors.white,
                      child: Text(
                        "اضافة سند قبض",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              actions: <Widget>[
                                Visibility(
                                  visible: vansaleCanPrint.toString() == "true",
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 5.0),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
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
                                            send("8cm");
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: Main_Color,
                                            ),
                                            width: double.infinity,
                                            child: Center(
                                              child: Text(
                                                "طباعة 8سم",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 5.0),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);

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
                                            send("A4");
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: Main_Color,
                                            ),
                                            width: double.infinity,
                                            child: Center(
                                              child: Text(
                                                "طباعة A4",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 5.0),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
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
                                            send("nothing");
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: Main_Color,
                                            ),
                                            width: double.infinity,
                                            child: Center(
                                              child: Text(
                                                "طباعة مباشرة",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                            content: SizedBox(
                                                height: 100,
                                                width: 100,
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator())),
                                          );
                                        },
                                      );
                                      send(nothing());
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  nothing() {}

  var check_total = 0.0;

  List cheks_array = [];

  List chk_no_array = [];
  List value_array = [];
  List date_array = [];
  List account_num_array = [];
  List bank_num_array = [];

  TextEditingController dateinput = TextEditingController();
  _pickDate() async {
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
        datechekController.text =
            formattedDate; //set output date to TextField value.
      });
    } else {
      // print("Date is not selected");
    }
  }

  TextEditingController MAINTOTAL = TextEditingController();
  TextEditingController cheknumController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  TextEditingController datechekController = TextEditingController();
  TextEditingController accountnumController = TextEditingController();
  TextEditingController bank_numController = TextEditingController();

  TextEditingController TOTAL = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController balanceController = TextEditingController();
  TextEditingController CashController = TextEditingController();
  TextEditingController DiscountController = TextEditingController();
  TextEditingController ChksController = TextEditingController();
  TextEditingController NotesController = TextEditingController();
  send(pdf) async {
    // print("cheks_array");
    // print(cheks_array);
    // print(cheks_array.length);
    // print(chk_no_array);
    // print(chk_no_array.length);
    // return;

    if (MAINTOTAL.text == '') {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('الرجاء اضافة المجموع النقدي او شيك'),
            actions: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'حسنا',
                  style: TextStyle(color: Color(0xff34568B)),
                ),
              ),
            ],
          );
        },
      );
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var now = DateTime.now();
      var formatterDate = DateFormat('yy-MM-dd');
      var formatterTime = DateFormat('kk:mm:ss');
      String? senderName = prefs.getString('sender_name');
      String? customerPhone = prefs.getString('phone');
      String actualDate = formatterDate.format(now);
      String actualTime = formatterTime.format(now);
      int? company_id = prefs.getInt('company_id');
      String? macAddressPrinter = prefs.getString('mac_address_printer');
      String? invoiceHeader = prefs.getString('invoice_header');
      String? shopNo = prefs.getString('shop_no');
      int? salesman_id = prefs.getInt('salesman_id');
      String? store_id_order = prefs.getString('store_id') ?? "0";
      String? type = prefs.getString('type');
      if (isOnline) {
        var url = type.toString() == "quds"
            ? AppLink.addCatchReceiptQuds
            : AppLink.vansaleAddCatchReceipt;
        var request = new http.MultipartRequest("POST", Uri.parse(url));
        request.fields['downloaded'] = "0";
        request.fields['store_id'] = store_id_order.toString();
        request.fields['customer_id'] = widget.id.toString();
        request.fields['company_id'] = company_id.toString();
        request.fields['salesman_id'] = salesman_id.toString();
        request.fields['q_type'] = "qabd";
        request.fields['cash'] =
            CashController.text == "" ? "0" : CashController.text;
        request.fields['discount'] =
            DiscountController.text == "" ? "0" : DiscountController.text;
        request.fields['notes'] =
            NotesController.text == "" ? "-" : NotesController.text;
        request.fields['q_date'] = actualDate.toString();
        request.fields['q_time'] = actualTime.toString();
        if (chk_no_array.isNotEmpty) {
          request.fields['chks'] = chk_no_array.length.toString();
          for (int i = 0; i < chk_no_array.length; i++) {
            request.fields['chk_no[$i]'] = chk_no_array[i].toString();
            request.fields['chk_value[$i]'] = value_array[i].toString();
            request.fields['chk_date[$i]'] = date_array[i].toString();
            request.fields['bank_no[$i]'] = bank_num_array[i].toString();
            request.fields['bank_branch[$i]'] = bank_num_array[i].toString();
            request.fields['account_no[$i]'] = account_num_array[i].toString();
          }
        }

        var response = await request.send();
        response.stream.transform(utf8.decoder).listen((value) async {
          Map valueMap = json.decode(value);
          if (valueMap['message'].toString() ==
              'Catch Receipt created successfully') {
            if (senderName.toString() != "" || senderName!.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Text('هل تريد ارسال رسالة SMS ?'),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              Fluttertoast.showToast(
                                msg: "تم اضافة سند القبض بنجاح",
                              );

                              pdf;
                              Navigator.pop(context);
                              sendSMS(
                                  message:
                                      "شكرا لتسديدك مبلغ   ${MAINTOTAL.text}",
                                  phoneNumber: customerPhone.toString(),
                                  senderName: senderName.toString());
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Main_Color,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "نعم",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Main_Color,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "لا",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
              if (pdf.toString() == "nothing") {
                print("1");
                var totalValue = parseValue(DiscountController.text) +
                    parseValue(TOTAL.text) +
                    parseValue(CashController.text);
                if (Platform.isIOS) {
                  _showDeviceSelectionPopup(
                      printed: "0",
                      macAddress: macAddressPrinter.toString(),
                      invoiceHeader: invoiceHeader.toString(),
                      cashTotal:
                          CashController.text == "" ? "0" : CashController.text,
                      customerName: widget.name.toString(),
                      date: actualDate.toString(),
                      time: actualTime.toString(),
                      discount: DiscountController.text == ""
                          ? "0"
                          : DiscountController.text,
                      finalTotal: totalValue.toString(),
                      invoiceNumber: type.toString() == "quds"
                          ? valueMap["catch_reciept"]["id"].toString()
                          : valueMap["catch_reciept"]["qabd_id"].toString(),
                      salesManNumber: salesman_id.toString(),
                      shaksTotal: TOTAL.text,
                      licensedOperator: shopNo.toString());
                } else {
                  _printInvoice(
                      printed: "0",
                      macAddress: macAddressPrinter.toString(),
                      invoiceHeader: invoiceHeader.toString(),
                      cashTotal:
                          CashController.text == "" ? "0" : CashController.text,
                      customerName: widget.name.toString(),
                      date: actualDate.toString(),
                      time: actualTime.toString(),
                      discount: DiscountController.text == ""
                          ? "0"
                          : DiscountController.text,
                      finalTotal: totalValue.toString(),
                      invoiceNumber: type.toString() == "quds"
                          ? valueMap["catch_reciept"]["id"].toString()
                          : valueMap["catch_reciept"]["qabd_id"].toString(),
                      salesManNumber: salesman_id.toString(),
                      shaksTotal: TOTAL.text,
                      licensedOperator: shopNo.toString());
                }

                if (type != "quds") {
                  updateCatchReceiptPrintedValue(
                      valueMap["catch_reciept"]["qabd_id"].toString(), "1");
                }
                Navigator.pop(context);
              }
            } else {
              Navigator.of(context, rootNavigator: true).pop();
              Fluttertoast.showToast(
                msg: "تم اضافة سند القبض بنجاح",
              );
              if (pdf.toString() == "nothing") {
                print("2");
                var totalValue = parseValue(DiscountController.text) +
                    parseValue(TOTAL.text) +
                    parseValue(CashController.text);
                print("2.1");
                if (Platform.isIOS) {
                  Navigator.of(context, rootNavigator: true).pop();
                  _showDeviceSelectionPopup(
                      printed: "0",
                      macAddress: macAddressPrinter.toString(),
                      invoiceHeader: invoiceHeader.toString(),
                      cashTotal:
                          CashController.text == "" ? "0" : CashController.text,
                      customerName: widget.name.toString(),
                      date: actualDate.toString(),
                      time: actualTime.toString(),
                      discount: DiscountController.text == ""
                          ? "0"
                          : DiscountController.text,
                      finalTotal: totalValue.toString(),
                      invoiceNumber: type.toString() == "quds"
                          ? valueMap["catch_reciept"]["id"].toString()
                          : valueMap["catch_reciept"]["qabd_id"].toString(),
                      salesManNumber: salesman_id.toString(),
                      shaksTotal: TOTAL.text,
                      licensedOperator: shopNo.toString());
                  return;
                } else {
                  _printInvoice(
                      macAddress: macAddressPrinter.toString(),
                      invoiceHeader: invoiceHeader.toString(),
                      time: actualTime.toString(),
                      printed: "0",
                      cashTotal:
                          CashController.text == "" ? "0" : CashController.text,
                      customerName: widget.name.toString(),
                      date: actualDate.toString(),
                      discount: DiscountController.text == ""
                          ? "0"
                          : DiscountController.text,
                      finalTotal: totalValue.toString(),
                      invoiceNumber: type.toString() == "quds"
                          ? valueMap["catch_reciept"]["id"].toString()
                          : valueMap["catch_reciept"]["qabd_id"].toString(),
                      salesManNumber: salesman_id.toString(),
                      shaksTotal: TOTAL.text,
                      licensedOperator: shopNo.toString());
                }

                if (type != "quds") {
                  updateCatchReceiptPrintedValue(
                      valueMap["catch_reciept"]["id"].toString(), "1");
                }
              }

              if (pdf == "A4") {
                Navigator.of(context, rootNavigator: true).pop();
                await pdfFatoraA4(type.toString() == "quds"
                    ? valueMap["catch_reciept"]["id"].toString()
                    : valueMap["catch_reciept"]["qabd_id"].toString());
                return;
              } else if (pdf == "8cm") {
                Navigator.of(context, rootNavigator: true).pop();
                await pdfFatora8cm(type.toString() == "quds"
                    ? valueMap["catch_reciept"]["id"].toString()
                    : valueMap["catch_reciept"]["qabd_id"].toString());
                return;
              } else {
                pdf;
              }
              Navigator.pop(context);
            }
            addHistory(widget.id, "2");
          } else {
            Navigator.of(context, rootNavigator: true).pop();
            print('failed');
          }
        });
      } else {
        if (type.toString() == "quds") {
          CatchModel newReceipt = CatchModel(
            customerName: widget.name,
            customerID: widget.id,
            qType: "qabd",
            isUploaded: 0,
            cashAmount: double.tryParse(CashController.text) ?? 0.0,
            discount: double.tryParse(DiscountController.text) ?? 0.0,
            totalChecks: double.tryParse(TOTAL.text) ?? 0.0,
            finalTotal: double.tryParse(MAINTOTAL.text) ?? 0.0,
            notes: NotesController.text,
            downloaded: 0,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            time: DateFormat('kk:mm:ss').format(DateTime.now()),
          );

          int receiptId =
              await CartDatabaseHelper().insertCatchReceipt(newReceipt);

          // Save checks
          if (chk_no_array.isNotEmpty) {
            for (int i = 0; i < chk_no_array.length; i++) {
              CheckModel check = CheckModel(
                receiptId: receiptId,
                checkNumber: chk_no_array[i].toString(),
                checkValue: double.tryParse(value_array[i].toString()) ?? 0.0,
                checkDate: date_array[i].toString(),
                bankNumber: bank_num_array[i].toString(),
                accountNumber: account_num_array[i].toString(),
              );

              await CartDatabaseHelper().insertCheck(check);
            }
          }
        } else {
          CatchVansaleModel newReceipt = CatchVansaleModel(
            customerName: widget.name,
            customerID: widget.id,
            qType: "qabd",
            isUploaded: 0,
            cashAmount: double.tryParse(CashController.text) ?? 0.0,
            discount: double.tryParse(DiscountController.text) ?? 0.0,
            totalChecks: double.tryParse(TOTAL.text) ?? 0.0,
            finalTotal: double.tryParse(MAINTOTAL.text) ?? 0.0,
            notes: NotesController.text,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            time: DateFormat('kk:mm:ss').format(DateTime.now()),
          );

          int receiptId =
              await CartDatabaseHelper().insertCatchReceiptVansale(newReceipt);

          // Save checks
          if (chk_no_array.isNotEmpty) {
            for (int i = 0; i < chk_no_array.length; i++) {
              CheckVansaleModel check = CheckVansaleModel(
                receiptId: receiptId,
                checkNumber: chk_no_array[i].toString(),
                checkValue: double.tryParse(value_array[i].toString()) ?? 0.0,
                checkDate: date_array[i].toString(),
                bankNumber: bank_num_array[i].toString(),
                accountNumber: account_num_array[i].toString(),
              );

              await CartDatabaseHelper().insertCheckVansale(check);
            }
          }
        }
        final now = DateTime.now();
        final formatter = DateFormat('dd-MM-yyyy hh:mm a', 'en');
        HistoryModel newhistoryRecord = HistoryModel(
          created_at: formatter.format(now),
          customer_id: widget.id,
          h_code: "2",
          lattitude: "",
          longitude: "",
        );

        await CartDatabaseHelper().insertHistory(newhistoryRecord);
        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "تم حفظ سند القبض محلياً وسيتم رفعه عند توفر الإنترنت");
        Navigator.pop(context);
      }
    }
  }

  void _showDeviceSelectionPopup({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) {
    if (connectedIOSDevice != null && connectedIOSDevice!.id.id == macAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Already connected to ${connectedIOSDevice!.name}")),
      );

      _printInvoice(
          printed: "0",
          macAddress: connectedIOSDevice!.id.id,
          invoiceHeader: invoiceHeader.toString(),
          cashTotal: CashController.text == "" ? "0" : CashController.text,
          customerName: widget.name.toString(),
          date: date.toString(),
          time: time.toString(),
          discount:
              DiscountController.text == "" ? "0" : DiscountController.text,
          finalTotal: finalTotal.toString(),
          invoiceNumber: invoiceNumber.toString(),
          salesManNumber: salesManNumber.toString(),
          shaksTotal: TOTAL.text,
          licensedOperator: licensedOperator.toString());

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

                      _connectToIOSDevice(
                          printed: "0",
                          macAddress: device.id.id,
                          invoiceHeader: invoiceHeader.toString(),
                          cashTotal: CashController.text == ""
                              ? "0"
                              : CashController.text,
                          customerName: widget.name.toString(),
                          date: date.toString(),
                          time: time.toString(),
                          discount: DiscountController.text == ""
                              ? "0"
                              : DiscountController.text,
                          finalTotal: finalTotal.toString(),
                          invoiceNumber: invoiceNumber.toString(),
                          salesManNumber: salesManNumber.toString(),
                          shaksTotal: TOTAL.text,
                          licensedOperator: licensedOperator.toString());
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

  double parseValue(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 0.0; // Default to 0.0 if value is null or empty
    }
    try {
      return double.parse(value.toString());
    } catch (e) {
      print('Error parsing value: $value');
      return 0.0; // Default to 0.0 on parse failure
    }
  }

  Future<void> _printInvoice({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    if (Platform.isIOS) {
      print("1.11");
      if (connectedIOSDevice == null) {
        print("1.12");
        await _connectToIOSDevice(
            macAddress: macAddress,
            cashTotal: cashTotal,
            printed: printed,
            customerName: customerName,
            date: date,
            time: time,
            invoiceHeader: invoiceHeader,
            discount: discount,
            finalTotal: finalTotal,
            invoiceNumber: invoiceNumber,
            salesManNumber: salesManNumber,
            shaksTotal: shaksTotal,
            licensedOperator: licensedOperator);
      }
      print("1.13");

      final invoiceZPL = generateInvoiceZPL(
          cashTotal: cashTotal,
          printed: printed,
          customerName: customerName,
          date: date,
          time: time,
          invoiceHeader: invoiceHeader,
          discount: discount,
          finalTotal: finalTotal,
          invoiceNumber: invoiceNumber,
          salesManNumber: salesManNumber,
          shaksTotal: shaksTotal,
          licensedOperator: licensedOperator);

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
                  await Future.delayed(Duration(milliseconds: 200));
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invoice printed successfully!")),
                  );
                }

                // ✅ Disconnect only after successful printing
                try {
                  await connectedIOSDevice!.disconnect();
                  connectedIOSDevice = null;
                  print("🔌 iOS printer disconnected.");
                } catch (e) {
                  print("❗ Failed to disconnect iOS printer: $e");
                }

                return;
              }
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No writable characteristic found")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No connected iOS printer found")),
            );
          }
        }
      } catch (e) {
        print("e");
        print(e);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error printing invoice: $e")),
          );
        }
      }
    } else {
      await _printInvoiceAndroid(
          macAddress: macAddress,
          cashTotal: cashTotal,
          printed: printed,
          customerName: customerName,
          date: date,
          time: time,
          invoiceHeader: invoiceHeader,
          discount: discount,
          finalTotal: finalTotal,
          invoiceNumber: invoiceNumber,
          salesManNumber: salesManNumber,
          shaksTotal: shaksTotal,
          licensedOperator: licensedOperator);
    }
  }

  // Fetch iOS Devices and Connect
  Future<void> _connectToIOSDevice({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String invoiceHeader,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    if (mounted) {
      setState(() {
        isProcessing = true;
      });
    }

    try {
      // Find the device
      final deviceToConnect = discoveredDevices.firstWhere(
        (device) => device.id.id == macAddress,
        // orElse: () => null, // Prevents exception if device is not found
      );

      if (deviceToConnect == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device not found")),
        );
        return;
      }

      // If the device is already connected, disconnect it first
      if (connectedIOSDevice?.id.id == deviceToConnect.id.id) {
        await connectedIOSDevice?.disconnect();
        connectedIOSDevice = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device disconnected.")),
        );
        return;
      }

      await deviceToConnect.connect();

      connectedIOSDevice = deviceToConnect;

      // Print invoice after successful connection
      _printInvoice(
          printed: "0",
          macAddress: macAddress.toString(),
          invoiceHeader: invoiceHeader.toString(),
          cashTotal: CashController.text == "" ? "0" : CashController.text,
          customerName: widget.name.toString(),
          date: date.toString(),
          time: time.toString(),
          discount:
              DiscountController.text == "" ? "0" : DiscountController.text,
          finalTotal: finalTotal.toString(),
          invoiceNumber: invoiceNumber.toString(),
          salesManNumber: salesManNumber.toString(),
          shaksTotal: TOTAL.text,
          licensedOperator: licensedOperator.toString());
    } catch (e) {
      print("error");
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to device: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
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
        print("1");
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
      // Explicitly check if the device is connected
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected!) {
        await bluetooth.disconnect();
        if (!mounted) return; // Ensure the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device disconnected successfully")),
        );
      } else {
        if (!mounted) return; // Ensure the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No device is currently connected")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error disconnecting from device: $e")),
        );
      }
    } finally {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _printInvoiceAndroid({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String invoiceHeader,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    await _connectToAndroidDevice(macAddress);

    final invoiceZPL = generateInvoiceZPL(
      invoiceNumber: invoiceNumber,
      printed: printed,
      licensedOperator: licensedOperator,
      invoiceHeader: invoiceHeader,
      date: date,
      time: time,
      customerName: customerName,
      cashTotal: cashTotal,
      salesManNumber: salesManNumber,
      shaksTotal: shaksTotal,
      discount: discount,
      finalTotal: finalTotal,
    );

    try {
      bluetooth.write(invoiceZPL); // Pass the string directly
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Invoice printed successfully!")),
      // );
      await _disconnectFromAndroidDevice();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error printing invoice: $e")),
      );
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

  pdfFatoraA4(String invoiceNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var now = DateTime.now();
    var formatterDate = DateFormat('yy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    int? salesman_id = prefs.getInt('salesman_id');

    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"),
    );

    final imagelogo = pw.MemoryImage(
      (await rootBundle.load('assets/quds_logo.jpeg')).buffer.asUint8List(),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 10),

              // Title
              pw.Center(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text("سند قبض", style: pw.TextStyle(fontSize: 26)),
                ),
              ),

              pw.SizedBox(height: 20),

              // Row: رقم السند + نسخة + مرخص
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  buildMiniBlock("رقم السند", invoiceNumber),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Row: التاريخ + الوقت
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  buildMiniBlock("التاريخ", actualDate),
                  buildMiniBlock("الوقت", actualTime),
                ],
              ),

              pw.SizedBox(height: 10),
              buildStyledRow("اسم الزبون", widget.name),

              pw.Divider(),

              // Totals Section (two-column block)
              pw.SizedBox(height: 10),
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  children: [
                    buildTotalsRow("مجموع النقدي", CashController.text),
                    buildTotalsRow("مجموع الشيكات", TOTAL.text),
                    buildTotalsRow("الخصم", DiscountController.text),
                    buildTotalsRow("المجموع النهائي", MAINTOTAL.text),
                  ],
                ),
              ),

              if (salesman_id.toString() != "999")
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    buildStyledRow("رقم المندوب", salesman_id.toString()),
                  ],
                ),

              pw.SizedBox(height: 10),
              if (NotesController.text.trim().isNotEmpty)
                buildStyledRow("الملاحظات", NotesController.text,
                    isNotes: true),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget buildStyledRow(String label, String value, {bool isNotes = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: isNotes ? 250 : 100,
          height: isNotes ? 40 : 30,
          padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: pw.BorderRadius.circular(5),
            color: PdfColors.grey100,
          ),
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(value, style: pw.TextStyle(fontSize: 14)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text("$label :", style: pw.TextStyle(fontSize: 18)),
        ),
        pw.SizedBox(width: 40),
      ],
    );
  }

  pw.Widget buildTotalsRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 16)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  pw.Widget buildMiniBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 14)),
        ),
        pw.Container(
          padding: pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5),
          ),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  pdfFatora8cm(String invoiceNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var now = DateTime.now();
    var formatterDate = DateFormat('yy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    int? salesman_id = prefs.getInt('salesman_id');

    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(226.8, double.infinity),
        build: (context) => pw.Padding(
          padding: pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 10),

              // Title
              pw.Center(
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text("سند قبض",
                      style: pw.TextStyle(fontSize: 18, font: arabicFont)),
                ),
              ),

              pw.SizedBox(height: 10),

              miniBlock("رقم السند", invoiceNumber, arabicFont),
              miniBlock("التاريخ", actualDate, arabicFont),
              miniBlock("الوقت", actualTime, arabicFont),
              miniBlock("اسم الزبون", widget.name, arabicFont),

              pw.Container(
                padding: pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  color: PdfColors.grey200,
                ),
                child: pw.Column(
                  children: [
                    totalRow("مجموع النقدي", CashController.text, arabicFont),
                    totalRow("مجموع الشيكات", TOTAL.text, arabicFont),
                    totalRow("الخصم", DiscountController.text, arabicFont),
                    totalRow("المجموع النهائي", MAINTOTAL.text, arabicFont),
                  ],
                ),
              ),

              if (salesman_id.toString() != "999")
                miniBlock("رقم المندوب", salesman_id.toString(), arabicFont),

              if (NotesController.text.trim().isNotEmpty)
                miniBlock("الملاحظات", NotesController.text, arabicFont),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget miniBlock(String label, String value, pw.Font arabicFont) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text(label,
                  style: pw.TextStyle(font: arabicFont, fontSize: 14)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                padding: pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(value,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: arabicFont, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget totalRow(String label, String value, pw.Font arabicFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 14, font: arabicFont),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, font: arabicFont),
          ),
        ],
      ),
    );
  }
}

String generateInvoiceZPL({
  required String invoiceNumber,
  required String invoiceHeader,
  required String printed,
  required String licensedOperator,
  required String date,
  required String time,
  required String customerName,
  required String salesManNumber,
  required String discount,
  required String shaksTotal,
  required String cashTotal,
  required String finalTotal,
}) {
  // final int baseHeight = 380; // Starting height of the items
  // final int rowHeight = 30; // Height for each row
  // final int footerHeight = 160; // Space for footer
  // final int paperHeight = baseHeight +footerHeight;

  final StringBuffer zpl = StringBuffer();

  // Header with Company Name, Invoice Details, and Shop Name
  zpl.write("""
  ^XA
  ^CI28
  ^CW1,E:TT0003M_.FNT
  ^LL700
  ^PA0,1,1,1
  $invoiceHeader
^FO1,218^GB569,0,8^FS



  // Invoice Details

  ^FO20,330^A1N,30,30^FDالتاريخ: $date^FS
  ^FO20,370^A1N,30,30^FDالوقت: $time^FS

  ^FO20,400^A1N,30,30^FD${customerName.toString()}^FS
  """);

  if (licensedOperator.toString() == "999999999" ||
      licensedOperator.toString() == "0" ||
      licensedOperator == "null" ||
      licensedOperator.toString() == "") {
    zpl.write("""
 ^FO100,240^A1N,30,30^FD رقم: $invoiceNumber^FS
  """);
  } else if (printed.toString() == "1") {
    zpl.write("""

  ^FO100,240^A1N,30,30^FDسند قبض رقم: $invoiceNumber^FS
  ^FO20,290^A1N,30,30^FDCopy^FS
  ^FO360,290^A1N,30,30^FDمشتغل مرخص^FS
  ^FO360,330^A1N,30,30^FD$licensedOperator^FS
  """);
  } else {
    zpl.write("""

  ^FO100,240^A1N,30,30^FDسند قبض رقم: $invoiceNumber^FS
  ^FO20,290^A1N,30,30^FDOriginal^FS
  ^FO360,290^A1N,30,30^FDمشتغل مرخص^FS
  ^FO360,330^A1N,30,30^FD$licensedOperator^FS
  """);
  }

  // Footer with Totals
  zpl.write("""
  ^FO360,450^A1N,30,30^FDمجموع النقدي^FS
  ^FO200,450^A1N,30,30^FD${cashTotal.toString()}^FS
  ^FO360,480^A1N,30,30^FDمجموع الشيكات^FS
  ^FO200,480^A1N,30,30^FD${shaksTotal.toString()}^FS
  ^FO360,520^A1N,30,30^FDخصم^FS
  ^FO200,520^A1N,30,30^FD${discount}^FS
  ^FO360,560^A1N,30,30^FDالمجموع النهائي^FS
  ^FO200,560^A1N,30,30^FD${finalTotal}^FS

  // Representative Number
  ^FO20,590^A1N,30,30^FDرقم المندوب^FS
  ^FO20,630^A1N,30,30^FD${salesManNumber.toString()}^FS
  ^XZ
  """);

  return zpl.toString();
}
