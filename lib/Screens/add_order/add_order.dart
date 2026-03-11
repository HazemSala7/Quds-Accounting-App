import 'dart:async';
import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:date_format/date_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/city-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/history-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/invoice-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-archive-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-item-archive-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-item-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-item-vansale-archive-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-item-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-vansale-archive-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/order-vansale-model.dart';
import 'package:quds_yaghmour/Screens/settings/settings.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:location/location.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:quds_yaghmour/Services/data_downloader/data_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../LocalDB/Models/CartModel.dart';
import '../../LocalDB/Provider/CartProvider.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import '../products/products.dart';
import 'package:pdf/widgets.dart' as pw;

class AddOrder extends StatefulWidget {
  final id, total, fatora_id, customer_name;
  const AddOrder(
      {Key? key, this.id, this.total, this.fatora_id, this.customer_name})
      : super(key: key);

  @override
  State<AddOrder> createState() => _AddOrderState();
}

class _AddOrderState extends State<AddOrder> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  String price_code = "";
  String CASH = "";
  String vansaleCanPrint = "";
  String type = "";
  List<flutterBlue.BluetoothDevice> discoveredDevices = [];
  BluetoothDevice? connectedDevice;
  bool isButtonDisabled = false;
  setContrllers() async {
    valueController.text = widget.total.toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _price = prefs.getString('price_code');
    String? _vansaleCanPrint = prefs.getString('vansale_can_print');
    String? _type = prefs.getString('type') ?? "quds";
    String? cash = prefs.getString('cash');
    price_code = _price!;
    CASH = cash!;
    if (CASH == "yes") {
      orders = true;
    } else {
      // orders = false;
    }
    type = _type;
    vansaleCanPrint = _vansaleCanPrint.toString();
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

  bool orders = true;
  bool isZemSelected = false;

  @override
  void initState() {
    super.initState();
    setContrllers();
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
                title:
                    type.toString() == "quds" ? "اضافة طلبية" : "اضافة فاتورة",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 15, bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xff34568B).withOpacity(0.08),
                              Color(0xff34568B).withOpacity(0.03),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff34568B).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.toString() == "quds" ? "قيمة الطلبية" : "قيمه الفاتورة",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "₪",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff34568B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: valueController,
                                    obscureText: false,
                                    readOnly: true,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xff34568B),
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: type.toString() == "quds"
                                          ? "قيمة الطلبية"
                                          : "قيمه الفاتورة",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 8, bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff34568B).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الخصم",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.local_offer,
                                    color: Color(0xff34568B), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    keyboardType: TextInputType.numberWithOptions(
                                        decimal: true),
                                    controller: DiscountController,
                                    obscureText: false,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    onChanged: (_) {
                                      if (DiscountController.text == "") {
                                        setState(() {
                                          discountPercentageController.text = "0";
                                          valueafterController.text =
                                              valueController.text;
                                        });
                                      } else {
                                        setState(() {
                                          var discountAmount = double.parse(
                                              DiscountController.text);
                                          var total =
                                              double.parse(valueController.text);
                                          var discountPercent =
                                              (discountAmount / total) * 100;
                                          discountPercentageController.text =
                                              discountPercent
                                                  .toStringAsFixed(2);
                                          var totalAfterDiscount =
                                              total - discountAmount;
                                          valueafterController.text =
                                              totalAfterDiscount.toString();
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "الخصم",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 8, bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff34568B).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "نسبة الخصم",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.percent,
                                    color: Color(0xff34568B), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    keyboardType: TextInputType.numberWithOptions(
                                        decimal: true),
                                    controller: discountPercentageController,
                                    obscureText: false,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    onChanged: (_) {
                                      if (discountPercentageController.text ==
                                          "") {
                                        setState(() {
                                          DiscountController.text = "0";
                                          valueafterController.text =
                                              valueController.text;
                                        });
                                      } else {
                                        setState(() {
                                          var discountPercent = double.parse(
                                              discountPercentageController
                                                  .text);
                                          var total = double.parse(
                                              valueController.text);
                                          var discountAmount =
                                              (discountPercent / 100) * total;
                                          DiscountController.text =
                                              discountAmount.toString();
                                          var totalAfterDiscount =
                                              total - discountAmount;
                                          valueafterController.text =
                                              totalAfterDiscount.toString();
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "نسبة الخصم",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 8, bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xff34568B).withOpacity(0.08),
                              Color(0xff34568B).withOpacity(0.03),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff34568B).withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "المجموع بعد الخصم",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calculate,
                                    color: Color(0xff34568B), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: valueafterController,
                                    obscureText: false,
                                    readOnly: true,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xff34568B),
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "المجموع بعد الخصم",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: deliveryDate,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15, top: 8, bottom: 8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xff34568B).withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "تاريخ التسليم",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Color(0xff34568B), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: deliveryDateController,
                                      readOnly: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "تاريخ التسليم",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      onTap: () async {
                                        DateTime? selectedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                          locale: Locale('ar', ''),
                                        );
                                        if (selectedDate != null) {
                                          deliveryDateController.text =
                                              "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15, left: 15, top: 8, bottom: 8),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff34568B).withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الملاحظات",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes,
                                    color: Color(0xff34568B), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: NotesController,
                                    obscureText: false,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "ملاحظات",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: type.toString() == "vansale",
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 15, left: 15, bottom: 8),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xff34568B).withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.attach_money,
                                            color: Color(0xff34568B), size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          "نقدا",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    FlutterSwitch(
                                      activeColor: Colors.green,
                                      width: 60.0,
                                      height: 30.0,
                                      valueFontSize: 25.0,
                                      toggleSize: 27.0,
                                      value: orders,
                                      borderRadius: 30.0,
                                      padding: 3.0,
                                      onToggle: (val) {
                                        if (CASH == "no") {
                                          setState(() {
                                            orders = true;
                                            isZemSelected = false;
                                          });
                                        } else {
                                          setState(() {
                                            orders = true;
                                            isZemSelected = false;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.card_giftcard,
                                            color: Color(0xff34568B), size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          "ذمم",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    FlutterSwitch(
                                      activeColor: Colors.green,
                                      width: 60.0,
                                      height: 30.0,
                                      valueFontSize: 25.0,
                                      toggleSize: 27.0,
                                      value: isZemSelected,
                                      borderRadius: 30.0,
                                      padding: 3.0,
                                      onToggle: (val) {
                                        if (CASH == "no") {
                                          setState(() {
                                            orders = false;
                                            isZemSelected = true;
                                          });
                                        } else {
                                          setState(() {
                                            orders = false;
                                            isZemSelected = true;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 15, left: 15, top: 20, bottom: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff34568B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        elevation: 4,
                        shadowColor: Color(0xff34568B).withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.toString() == "quds"
                                ? "حفظ الطلبية"
                                : "حفظ الفاتورة",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      onPressed: isSaveButtonDisabled
                          ? () {
                              showToastMessage();
                            }
                          : () {
                              setState(() {
                                isSaveButtonDisabled = true;
                              });
                              enableButton();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    actions: <Widget>[
                                      Visibility(
                                        visible: vansaleCanPrint.toString() ==
                                            "true",
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () async {
                                                  setState(() =>
                                                      _openWaybillAfterSave =
                                                          true);

                                                  // Close the options dialog
                                                  Navigator.pop(context);

                                                  // Show a small loader while we save
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        const AlertDialog(
                                                      content: SizedBox(
                                                        height: 100,
                                                        width: 100,
                                                        child: Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                      ),
                                                    ),
                                                  );

                                                  // Trigger your existing save path WITHOUT printing
                                                  // (your `send` already receives a value; passing `nothing()` keeps it in the "save only" path)
                                                  send(nothing());
                                                },
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: Main_Color,
                                                  ),
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: Text(
                                                      "انشاء بوليصة لشركة التوصيل",
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
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () {
                                                  final cartProvider =
                                                      Provider.of<CartProvider>(
                                                          context,
                                                          listen: false);
                                                  List<CartItem> cartItems =
                                                      cartProvider.cartItems;
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
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
                                                  send(pdfFatora5CM(cartItems));
                                                },
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: Main_Color,
                                                  ),
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: Text(
                                                      "طباعة 5سم",
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
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () {
                                                  final cartProvider =
                                                      Provider.of<CartProvider>(
                                                          context,
                                                          listen: false);
                                                  List<CartItem> cartItems =
                                                      cartProvider.cartItems;
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
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
                                                  send(pdfFatora8CM(cartItems));
                                                },
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () {
                                                  final cartProvider =
                                                      Provider.of<CartProvider>(
                                                          context,
                                                          listen: false);
                                                  List<CartItem> cartItems =
                                                      cartProvider.cartItems;
                                                  Navigator.pop(context);

                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
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
                                                  send(pdfFatoraA4(cartItems));
                                                },
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () {
                                                  final cartProvider =
                                                      Provider.of<CartProvider>(
                                                          context,
                                                          listen: false);
                                                  List<CartItem> cartItems =
                                                      cartProvider.cartItems;
                                                  Navigator.pop(context);

                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
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
                                                  send(pdfFatoraA4WithImage(
                                                      cartItems));
                                                },
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: Main_Color,
                                                  ),
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: Text(
                                                      "طباعة A4 مع صور المنتجات",
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
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
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
                                                        BorderRadius.circular(
                                                            4),
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
                                            send(nothing());
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
                                                vansaleCanPrint.toString() ==
                                                        "true"
                                                    ? "لا أريد الطباعة"
                                                    : "حفظ الفاتورة",
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

  // holds the number of the just-created order (online: fatora->id, offline: maxFatora)
  String? lastCreatedOrderNumber;

// when true, we will open the delivery form right after a successful save
  bool _openWaybillAfterSave = false;

  Future<void> _maybeOpenWaybillAfterSave(String orderNumber) async {
    if (!_openWaybillAfterSave) return;
    if (orderNumber.isEmpty) return;

    // reset flag
    _openWaybillAfterSave = false;

    // close the small loader if still visible
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final prefs = await SharedPreferences.getInstance();

    await onCreateWaybillPressed(
      orderNumber: orderNumber,
      defaultCustomerName: widget.customer_name?.toString(),
      defaultPhone: prefs.getString('phone') ?? '',
      defaultAddress: prefs.getString('customer_address') ?? '',
    );
  }

  Future<void> onCreateWaybillPressed({
    required String orderNumber,
    String? defaultCustomerName,
    String? defaultPhone,
    String? defaultAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final allowed = prefs.getBool('delivery_api_allowed') ?? false;
    print("allowed");
    print(allowed);

    if (!allowed) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('غير مسموح'),
          content:
              Text('لا تملك صلاحية استخدام خدمة التوصيل.\nفضلًا تواصل معنا.'),
        ),
      );
      return;
    }

    final result = await showDeliveryFormDialog(
      initialOrderNumber: orderNumber,
      initialCustomerName:
          defaultCustomerName ?? widget.customer_name?.toString() ?? '',
      initialPhone: defaultPhone ?? (prefs.getString('phone') ?? ''),
      password: defaultPhone ?? (prefs.getString('passwordAPI') ?? ''),
      email: defaultPhone ?? (prefs.getString('emailAPI') ?? ''),
      initialAddress:
          defaultAddress ?? (prefs.getString('customer_address') ?? ''),
    );

    if (result == null) return;

    await sendShipmentDynamic(
      email: result.email,
      password: result.password,
      orderNumber: result.orderNumber,
      receiverName: result.customerName,
      receiverPhone: result.phone,
      receiverPhone2: (result.phone2?.isEmpty ?? true) ? null : result.phone2,
      addressLine1: result.address,
      description: result.description,
      cityId: result.cityId,
      qty: result.qty,
      notes: result.notes ?? 'NTE Delivery',
      cod: result.cod ?? 0,
      weight: result.weight ?? 1.0,
    );
  }

  Future<DeliveryFormResult?> showDeliveryFormDialog({
    required String email,
    required String password,
    required String initialOrderNumber,
    required String initialCustomerName,
    required String initialPhone,
    required String initialAddress,
  }) {
    final formKey = GlobalKey<FormState>();

    // === Build default description from cart items ===
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    List<String> _namesFromArray() {
      try {
        final arr = cartProvider.getProductsArray();
        if (arr is List && arr.isNotEmpty) {
          return arr
              .map((p) => (p["name"] ?? '').toString().trim())
              .where((n) => n.isNotEmpty && n != 'اجرة توصيل')
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }

    List<String> _namesFromCartItems() {
      try {
        final items = cartProvider.cartItems; // if exposed by your provider
        if (items is List && items.isNotEmpty) {
          return items
              .map((ci) => (ci.name ?? '').toString().trim())
              .where((n) => n.isNotEmpty && n != 'اجرة توصيل')
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }

    final productNames = (() {
      final a = _namesFromArray();
      if (a.isNotEmpty) return a;
      return _namesFromCartItems();
    })();

    final defaultDescription = productNames.join(' / ');
    // === End default description ===

    // Controllers (descriptionCtrl uses defaultDescription)
    final orderCtrl = TextEditingController(text: initialOrderNumber);
    final nameCtrl = TextEditingController(text: initialCustomerName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final phone2Ctrl = TextEditingController();
    final descriptionCtrl = TextEditingController(text: defaultDescription);
    final addressCtrl = TextEditingController(text: initialAddress);
    final notesCtrl = TextEditingController();
    final codCtrl = TextEditingController(text: widget.total.toString());
    final weightCtrl = TextEditingController(text: '1.0');
    final qtyCtrl = TextEditingController(text: '1');

    final TextEditingController _cityController = TextEditingController();
    City? _selectedCity;
    int? _selectedCityId;

    // Default fallback city id if user doesn't pick
    int cityId = 8;

    return showDialog<DeliveryFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('بيانات الشحنة'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(labelText: 'رقم الطلب'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المستلم'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'هاتف المستلم'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: phone2Ctrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'هاتف إضافي (اختياري)'),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await _openCityPicker(context);
                    if (picked != null) {
                      setState(() {
                        _selectedCity = picked;
                        _selectedCityId = picked.id;
                        _cityController.text = picked.displayName();
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        hintText: 'اختر المدينة',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (_) =>
                          (_selectedCityId == null) ? 'اختر مدينة' : null,
                    ),
                  ),
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
                TextFormField(
                  controller: codCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'قيمة الفاتورة شاملة التوصيل',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'عدد الطرود'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(labelText: 'الوزن (كجم)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(
                  context,
                  DeliveryFormResult(
                    email: email,
                    password: password,
                    orderNumber: orderCtrl.text.trim(),
                    customerName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    phone2: phone2Ctrl.text.trim().isEmpty
                        ? null
                        : phone2Ctrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    cityId: _selectedCityId ?? cityId,
                    description:
                        descriptionCtrl.text, // prefilled list (editable)
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                    qty: int.parse(qtyCtrl.text),
                    cod: double.tryParse(codCtrl.text.trim()) ?? 0,
                    weight: double.tryParse(weightCtrl.text.trim()) ?? 1.0,
                  ),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  Future<City?> _openCityPicker(BuildContext context) async {
    final debouncer = _Debouncer(ms: 350);
    final searchCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    List<City> items = [];
    int current = 1;
    int last = 1;
    bool loading = false;
    String currentQuery = '';
    bool disposed = false;

    Future<void> load({bool reset = false}) async {
      if (loading) return;
      if (!reset && current > last) return;

      loading = true;
      try {
        if (reset) {
          current = 1;
          last = 1;
          items.clear();
        }
        final page = await _fetchCities(page: current, query: currentQuery);
        items.addAll(page.data);
        last = page.lastPage;
        current++;
      } finally {
        loading = false;
      }
    }

    return showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool didInit = false;

        scrollCtrl.addListener(() async {
          if (scrollCtrl.position.pixels >=
              scrollCtrl.position.maxScrollExtent - 120) {
            final stf = ctx as Element; // for setState access inside builder
            await load();
            if (!disposed) stf.markNeedsBuild();
          }
        });

        return StatefulBuilder(
          builder: (ctx, setBS) {
            // kick off initial load once, then rebuild
            if (!didInit) {
              didInit = true;
              () async {
                await load(reset: true);
                if (!disposed) setBS(() {});
              }();
            }

            Future<void> onSearch(String val) async {
              debouncer.run(() async {
                currentQuery = val;
                await load(reset: true);
                if (!disposed) setBS(() {});
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 12,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.75,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      decoration: const InputDecoration(
                        labelText: 'ابحث عن المدينة',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: (items.isEmpty && loading)
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              controller: scrollCtrl,
                              itemCount:
                                  items.length + ((current <= last) ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                if (i >= items.length) {
                                  // pagination spinner row
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final c = items[i];
                                return ListTile(
                                  title: Text(c.displayName()),
                                  subtitle: (c.regionId != null)
                                      ? Text('Region: ${c.regionId}')
                                      : null,
                                  onTap: () => Navigator.pop(ctx, c),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      disposed = true;
    });
  }

  // cache for the one-shot response
  List<City> _allCitiesCache = [];
  bool _allCitiesLoaded = false;

  Future<CitiesPage> _fetchCities({
    required int page,
    String? query,
    int perPage = 20,
  }) async {
    // Load once from the new "all cities" endpoint, then serve from memory
    if (!_allCitiesLoaded) {
      final uri = Uri.parse('https://yaghm.com/admin/api/logestechs/cities-all')
          .replace(queryParameters: {
        'only_active': '1',
        'fields':
            'id,name,arabic_name,english_name,region_id,is_selected,is_active',
      });

      final r = await http.get(uri, headers: {'Accept': 'application/json'});
      if (r.statusCode != 200) {
        throw Exception('Cities-all failed: ${r.statusCode} -> ${r.body}');
      }

      final map = json.decode(r.body) as Map<String, dynamic>;
      final List list = (map['data'] ?? []) as List;

      _allCitiesCache = list
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.displayName().compareTo(b.displayName()));

      _allCitiesLoaded = true;
    }

    // Client-side search
    final t = (query ?? '').trim().toLowerCase();
    final filtered = (t.isEmpty)
        ? _allCitiesCache
        : _allCitiesCache.where((c) {
            final s =
                '${c.displayName()} ${c.englishName ?? ''} ${c.name ?? ''}'
                    .toLowerCase();
            return s.contains(t);
          }).toList();

    // Keep your existing paging interface (served from memory)
    final total = filtered.length;
    final lastPage = total == 0 ? 1 : ((total + perPage - 1) / perPage).floor();
    final start = (page - 1) * perPage;
    final end = (start + perPage) > total ? total : (start + perPage);
    final slice =
        (start >= 0 && start < total) ? filtered.sublist(start, end) : <City>[];

    return CitiesPage(
      data: slice,
      currentPage: page,
      lastPage: lastPage,
    );
  }

  TimeOfDay selectedTime = TimeOfDay(hour: 00, minute: 00);
  String setTimet = '';
  bool isScanning = false;
  TextEditingController Controller = TextEditingController();

  String _hour = '', _minute = '', _time = '';

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

  final String invoiceNumber = 'INV123456';
  final String licensedOperator = '123456789';
  final String date = '2024-12-04';
  final String shopName = 'My Shop';
  final double discount = 10.0;
  final double finalTotal = 75.0;

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
          licensedOperator: licensedOperator);
    } else {
      await _connectToAndroidDevice(macAddress);
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
          licensedOperator: licensedOperator);
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

  bool isSaveButtonDisabled = false;

  void enableButton() {
    Future.delayed(Duration(minutes: 1), () {
      setState(() {
        isSaveButtonDisabled = false;
      });
    });
  }

  void showToastMessage() {
    Fluttertoast.showToast(
      msg: "يرجى الانتظار لمدة دقيقة قبل المحاولة مرة أخرى",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _connectToAndroidDevice(String macAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? macAddressPrinter = prefs.getString('mac_address_printer');
    if (!mounted) return;
    
    try {
      // Check if already connected
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        print("✅ Already connected to printer");
        return;
      }

      print("🔍 Searching for bonded devices...");
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      
      print("📱 Found ${devices.length} bonded devices");

      BluetoothDevice? targetDevice = devices.firstWhere(
        (d) => d.address == macAddress,
        orElse: () => BluetoothDevice("Printer", macAddressPrinter ?? macAddress),
      );

      if (targetDevice != null) {
        print("✅ Found printer: ${targetDevice.name} (${targetDevice.address})");
        print("🔌 Connecting to printer...");
        
        await bluetooth.connect(targetDevice).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
              'Connection timeout - printer may be off or out of range'),
        );
        
        // Give it a moment to establish connection
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify the connection was successful
        bool? connectedCheck = await bluetooth.isConnected;
        if (connectedCheck != true) {
          throw Exception("Connection established but verification failed");
        }

        print("✅ Connected to printer");
      } else {
        print("❌ No device with MAC address $macAddress");
        Fluttertoast.showToast(
            msg: "أنت لا تمتلك طابعة zebra",
            backgroundColor: Colors.green,
            fontSize: 18);
        throw Exception("Printer device not found");
      }
    } catch (e) {
      print("❌ Error connecting to device: $e");
      if (mounted) {
        Fluttertoast.showToast(
            msg: "خطأ في الاتصال بالطابعة: $e",
            backgroundColor: Colors.red,
            fontSize: 18);
      }
      rethrow;
    }
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
          licensedOperator: licensedOperator);

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
                          licensedOperator: licensedOperator);
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
      print("1.11");
      if (connectedIOSDevice == null) {
        print("1.12");
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
            licensedOperator: licensedOperator);
      }
      print("1.13");

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
          licensedOperator: licensedOperator);
    }
  }

  Future<void> _disconnectFromAndroidDevice() async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        print("🔌 Disconnecting from printer...");
        await bluetooth.disconnect();
        // Add delay to ensure disconnection completes
        await Future.delayed(const Duration(milliseconds: 300));
        print("✅ Disconnected from printer");
      }
    } catch (e) {
      print("⚠️ Error disconnecting from device: $e");
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
    try {
      await _connectToAndroidDevice(macAddress);

      // Verify connection before printing
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to connect to printer")),
          );
        }
        return;
      }

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

      print("📄 Generated ZPL length: ${invoiceZPL.length} characters");
      print("📤 Writing ZPL to printer...");

      bool writeSuccess = await bluetooth.write(invoiceZPL);
      
      print("✍️ Write result: $writeSuccess");
      
      if (!writeSuccess) {
        throw Exception("Failed to write data to printer");
      }

      // Wait for printer to process the data
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice printed successfully!")),
        );
      }
    } catch (e) {
      print("❌ Printing error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error printing invoice: $e")),
        );
      }
    } finally {
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
    final int baseHeight = 510; // Starting height of the items
    final int rowHeight = 30; // Height for each row
    final int footerHeight = 160; // Space for footer
    int punusCount = 0;
    for (int i = 0; i < items.length; i++) {
      if (int.parse(items[i].bonus.toString()) != 0) {
        punusCount++;
      }
    }
    final int itemSectionHeight = (items.length + punusCount) * rowHeight;
    final int paperHeight = baseHeight + itemSectionHeight + footerHeight;

    final StringBuffer zpl = StringBuffer();

    // Header with Company Name, Invoice Details, and Shop Name
    zpl.write("""
^XA
^CI28
^CW1,E:TT0003M_.FNT
^LL${paperHeight} // Dynamically replace paper height
^PA0,1,1,1
$invoiceHeader
^FO1,218^GB569,0,8^FS

// Invoice Details

^FO20,310^A1N,30,30^FDالتاريخ: $date^FS
^FO20,350^A1N,30,30^FDالوقت: $time^FS
^FO160,390^A1N,30,30^FD${customerName.toString()}^FS
  """);

    if (userType == "quds" ||
        licensedOperator == "999999999" ||
        licensedOperator.isEmpty) {
      zpl.write("""
^FO160,230^A1N,30,30^FD رقم: $invoiceNumber^FS
  """);
    } else {
      zpl.write("""
^FO160,230^A1N,30,30^FDفاتورة ضريبية رقم: $invoiceNumber^FS
^FO20,270^A1N,30,30^FDOriginal^FS
^FO360,270^A1N,30,30^FDمشغل مرخص^FS
^FO360,310^A1N,30,30^FD$licensedOperator^FS
  """);
    }

    // Table Header
    zpl.write("""
^FO5,445^GB500,3,3^FS
^FO5,445^A1N,27,27^FDالاسم               الكمية       السعر   المجموع^FS
^FO5,475^GB500,3,3^FS
  """);

    // Dynamic Vertical Lines for Columns
    int tableStartY = 480;
    zpl.write("""
^FO200,${tableStartY}^GB3,${itemSectionHeight},3^FS // Vertical line for 'الكمية'
^FO100,${tableStartY}^GB3,${itemSectionHeight},3^FS // Vertical line for 'السعر'

^FO310,${tableStartY}^GB3,${itemSectionHeight},3^FS // Vertical line for 'الاسم'
  """);

    // Items Rows
    int yPosition = tableStartY;
    for (var item in items) {
      String name = item.name.length > 30
          ? item.name.substring(0, 30)
          : item.name.padLeft(20);
      String quantity = item.quantity.toStringAsFixed(1);
      String price = item.price.toStringAsFixed(2);
      String total = item.total.toStringAsFixed(2);

      zpl.write("""
^FO330,$yPosition^A1N,21,21^FD$name^FS   // Aligned under 'الاسم'
^FO210,$yPosition^A1N,28,28^FD$quantity^FS // Aligned under 'الكمية'
^FO110,$yPosition^A1N,28,28^FD$price^FS   // Aligned under 'السعر'
^FO10,$yPosition^A1N,28,28^FD$total^FS    // Aligned under 'المجموع'
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

    // Footer with Total, Discount, and Final Total
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

  Future<Null> sat_start(BuildContext context) async {
    TimeOfDay? picked1 = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        initialEntryMode: TimePickerEntryMode.dial,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!);
        });

    if (picked1 != null)
      setState(() {
        selectedTime = picked1;
        _hour = selectedTime.hour.toString();
        _minute = selectedTime.minute.toString();
        _time = _hour + ' : ' + _minute;
        Controller.text = _time;
        Controller.text = formatDate(
            DateTime(2019, 08, 1, selectedTime.hour, selectedTime.minute),
            [HH, ':', nn, ":", "00"]).toString();
      });
  }

  TextEditingController dateinput = TextEditingController();
  _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        dateinput.text = formattedDate;
      });
    } else {
      // print("Date is not selected");
    }
  }

  TextEditingController DiscountController = TextEditingController();
  TextEditingController discountPercentageController = TextEditingController();
  TextEditingController valueController = TextEditingController();
  TextEditingController valueafterController = TextEditingController();
  TextEditingController deliveryDateController = TextEditingController();
  TextEditingController NotesController = TextEditingController();
  String platformMessage = "";
  Future<bool> hasPendingLocalOrders() async {
    final db = CartDatabaseHelper();

    // Fetch pending orders from both quds and vansale
    final qudsOrders = await db.getPendingOrders();
    final vansaleOrders = await db.getPendingOrdersVansale();

    // Return true if any of them has at least one local order
    return qudsOrders.isNotEmpty || vansaleOrders.isNotEmpty;
  }

  send(pdf) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var now = DateTime.now();
    String actualDate = DateFormat('yyyy-MM-dd').format(now);
    String actualTime = DateFormat('HH:mm:ss').format(now);

    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? customerPhone = prefs.getString('phone');
    String? macAddressPrinter = prefs.getString('mac_address_printer');
    String? invoiceHeader = prefs.getString('invoice_header');
    String? shopNo = prefs.getString('shop_no');
    String? type = prefs.getString('type');
    String? senderName = prefs.getString('sender_name');
    String? store_id_order = prefs.getString('store_id') ?? "1";
    String? _deviceId = prefs.getString('device_id') ?? "";
    String? _userID = prefs.getString('user_id') ?? "0";
    String? _apiCompanyID = prefs.getString('api_company_id') ?? "0";

    if (isOnline) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      List<Map<String, dynamic>> productsArray =
          cartProvider.getProductsArray();
      List<InvoiceItem> fatoraItems = [];

      List ProductsIDarray = [];
      List ProductsNamearray = [];
      List qtyArray = [];
      List priceArray = [];
      List productBarcodeArray = [];
      List ponus1Array = [];
      List ponus2Array = [];
      List discountArray = [];
      List notesArray = [];
      List colorArray = [];

      for (int i = 0; i < productsArray.length; i++) {
        var product = productsArray[i];
        ProductsIDarray.add(product["product_id"]);
        ProductsNamearray.add(product["name"]);
        priceArray.add(product["price"]);
        colorArray.add(product["color"].toString());
        qtyArray.add(product["quantity"]);
        productBarcodeArray.add(product["productBarcode"]);
        ponus1Array.add(product["ponus1"]);
        ponus2Array.add(0);
        discountArray.add(product["discount"]);
        notesArray.add(product["notes"]);

        fatoraItems.add(InvoiceItem(
          name: product["name"],
          bonus: product["ponus1"].toString(),
          quantity: product["quantity"],
          discount: double.parse(product["discount"].toString()),
          price: product["price"],
          total: product["quantity"] * product["price"],
        ));
      }

      LocationData? currentLocation;
      if (type == "vansale") {
        try {
          currentLocation = await Location().getLocation();
        } catch (_) {
          currentLocation = null;
        }
      }

      var body = {
        "f_date": actualDate,
        "f_time": actualTime,
        "f_code": "1",
        "f_value": valueafterController.text == ""
            ? valueController.text
            : valueafterController.text,
        "f_discount":
            DiscountController.text == "" ? "0" : DiscountController.text,
        "note": NotesController.text,
        "delivery_date": deliveryDateController.text == ""
            ? ""
            : deliveryDateController.text,
        "customer_id": widget.id.toString(),
        "company_id": company_id.toString(),
        "salesman_id": salesman_id.toString(),
        "store_id": store_id_order,
        "device_id": _deviceId.toString(),
        "user_id": _userID.toString(),
        "cash": orders.toString() == "true" ? "true" : "false",
        "lattiude": type == "vansale"
            ? currentLocation?.latitude.toString() ?? "0.0"
            : "0.0",
        "longitude": type == "vansale"
            ? currentLocation?.longitude.toString() ?? "0.0"
            : "0.0",
        "logestice_id": _apiCompanyID,
        "logestic_company_id": _apiCompanyID,
        "product_id": ProductsIDarray,
        "color_name": colorArray,
        "product_name": ProductsNamearray,
        "p_price": priceArray,
        "p_quantity": qtyArray,
        "product_barcode": productBarcodeArray,
        "bonus1": ponus1Array,
        "bonus2": ponus2Array,
        "discount": discountArray,
        "notes": notesArray,
        "isUploaded": "1",
      };

      String url =
          type == "quds" ? AppLink.addOrderQuds : AppLink.addOrderVansale;

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        Map valueMap = jsonDecode(response.body);

        if (valueMap['status'].toString() == 'true') {
          // 1) capture the server order number first
          final String onlineOrderNumber =
              (valueMap['fatora']?['id']?.toString() ??
                  valueMap['fatora']?['fatora_no']?.toString() ??
                  '');

          // 2) open the waybill form *now* if requested
          await _maybeOpenWaybillAfterSave(onlineOrderNumber);

          // 3) proceed with the rest of your success handling
          Fluttertoast.showToast(
            msg: type == "quds"
                ? "تم اضافة الطلبية بنجاح"
                : "تم اضافة الفاتورة بنجاح",
            backgroundColor: Colors.green,
            fontSize: 18,
          );
          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);
          cartProvider.clearCart();
          pdf;

          // pop 4 times as you had
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);

          if (senderName?.isNotEmpty == true) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: const Text('هل تريد ارسال رسالة SMS ؟'),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            sendSMS(
                              message:
                                  "شكرا لشرائك بمبلغ ${valueafterController.text == "" ? valueController.text : valueafterController.text}",
                              phoneNumber: customerPhone.toString(),
                              senderName: senderName.toString(),
                            );
                          },
                          child: Container(
                            width: 100,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Main_Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
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
                          },
                          child: Container(
                            width: 100,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Main_Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
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
                    )
                  ],
                );
              },
            );
          }

          if (pdf.toString() == "nothing") {
            if (Platform.isIOS) {
              _showDeviceSelectionPopup(
                userType: type.toString(),
                macAddress: macAddressPrinter.toString(),
                items: fatoraItems,
                customerName: widget.customer_name.toString(),
                date: actualDate.toString(),
                time: actualTime.toString(),
                invoiceHeader: invoiceHeader.toString(),
                discount: DiscountController.text == ""
                    ? "0"
                    : DiscountController.text,
                finalTotal: valueafterController.text == ""
                    ? valueController.text
                    : valueafterController.text,
                invoiceNumber: type.toString() == "quds"
                    ? valueMap["fatora"]["id"].toString()
                    : valueMap["fatora"]["fatora_no"].toString(),
                salesManNumber: salesman_id.toString(),
                licensedOperator: shopNo.toString(),
              );
            } else {
              await _printInvoice(
                userType: type.toString(),
                macAddress: macAddressPrinter.toString(),
                items: fatoraItems,
                customerName: widget.customer_name.toString(),
                date: actualDate,
                time: actualTime,
                invoiceHeader: invoiceHeader.toString(),
                discount: DiscountController.text == ""
                    ? "0"
                    : DiscountController.text,
                finalTotal: valueafterController.text == ""
                    ? valueController.text
                    : valueafterController.text,
                invoiceNumber: type.toString() == "quds"
                    ? valueMap["fatora"]["id"].toString()
                    : valueMap["fatora"]["fatora_no"].toString(),
                salesManNumber: salesman_id.toString(),
                licensedOperator: shopNo.toString(),
              );
            }

            if (type != "quds") {
              updatePrintedValue(valueMap["fatora"]["id"].toString(), "1");
            }
          }

          addHistory(widget.id, "1");
        } else {
          Fluttertoast.showToast(
            msg: "فشل في إضافة الفاتورة: تحقق من الحقول",
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        print("Exception occurred: $e");
        Fluttertoast.showToast(
          msg: "حدث خطأ أثناء إرسال الطلب",
          backgroundColor: Colors.red,
        );
      }
    } else {
      // -------------- OFFLINE BRANCH --------------
      final dbHelper = CartDatabaseHelper();
      String? maxFatora = await dbHelper.getMaxFatoraNumber();

      if (maxFatora != null) {
        print("Current Max Fatora Number: $maxFatora");
      } else {
        print("No max fatora number found yet.");
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      List<CartItem> cartItems = cartProvider.cartItems;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String storeId = prefs.getString('store_id') ?? "1";
      String? _userID = prefs.getString('user_id') ?? "0";
      var now = DateTime.now();
      String orderDate = DateFormat('yyyy-MM-dd').format(now);
      String orderTime = DateFormat('HH:mm:ss').format(now);

      if (type == "quds") {
        OrderModel order = OrderModel(
          customerName: widget.customer_name.toString(),
          fatora_number: maxFatora.toString(),
          deliveryDate: deliveryDateController.text,
          customerId: widget.id.toString(),
          user_id: _userID.toString(),
          storeId: storeId,
          totalAmount: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          discount: double.parse(
              DiscountController.text == "" ? "0" : DiscountController.text),
          cashPaid: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          orderDate: orderDate,
          orderTime: orderTime,
          isUploaded: "0",
          status: "pending",
        );
        int orderId = await dbHelper.insertOrder(order);

        List<OrderItemModel> orderItems = cartItems.map((cartItem) {
          return OrderItemModel(
            isUploaded: "0",
            bonus1: cartItem.ponus1.toString(),
            bonus2: cartItem.ponus2.toString(),
            orderId: int.parse(maxFatora.toString()),
            productId: cartItem.productId.toString(),
            productName: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            discount: cartItem.discount,
            total: cartItem.quantity * cartItem.price,
            color: cartItem.color.toString(),
            barcode: cartItem.productBarcode.toString(),
          );
        }).toList();
        await dbHelper.insertOrderItems(orderId, orderItems);

        OrderArchiveModel orderArchive = OrderArchiveModel(
          deliveryDate: deliveryDateController.text,
          customerId: widget.id.toString(),
          user_id: _userID.toString(),
          storeId: storeId,
          totalAmount: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          discount: double.parse(
              DiscountController.text == "" ? "0" : DiscountController.text),
          cashPaid: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          orderDate: orderDate,
          orderTime: orderTime,
          status: "pending",
        );
        int orderIdArchive = await dbHelper.insertOrderArchive(orderArchive);

        List<OrderItemArchiveModel> orderItemsArchive =
            cartItems.map((cartItem) {
          return OrderItemArchiveModel(
            orderId: orderId,
            bonus1: cartItem.ponus1.toString(),
            bonus2: cartItem.ponus2.toString(),
            productId: cartItem.productId.toString(),
            productName: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            discount: cartItem.discount,
            total: cartItem.quantity * cartItem.price,
            color: cartItem.color.toString(),
            barcode: cartItem.productBarcode.toString(),
          );
        }).toList();
        await dbHelper.insertOrderItemsArchive(
            orderIdArchive, orderItemsArchive);
        print("Done");
      } else {
        LocationData? currentLocation;
        var location = Location();
        try {
          currentLocation = await location.getLocation();
        } on Exception {
          currentLocation = null;
        }

        OrderVansaleModel order = OrderVansaleModel(
          deliveryDate: deliveryDateController.text,
          isUploaded: "0",
          fatora_number: maxFatora.toString(),
          cash: orders.toString() == "true" ? "true" : "false",
          latitude: currentLocation!.latitude.toString(),
          user_id: _userID.toString(),
          longitude: currentLocation.longitude.toString(),
          customerId: widget.id.toString(),
          customerName: widget.customer_name.toString(),
          storeId: storeId,
          totalAmount: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          discount: double.parse(
              DiscountController.text == "" ? "0" : DiscountController.text),
          cashPaid: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          orderDate: orderDate,
          orderTime: orderTime,
          printed: "0",
          status: "pending",
        );
        int orderId = await dbHelper.insertOrderVansale(order);

        List<OrderItemVansaleModel> orderItems = cartItems.map((cartItem) {
          return OrderItemVansaleModel(
            orderId: int.parse(maxFatora.toString()),
            bonus1: cartItem.ponus1.toString(),
            bonus2: cartItem.ponus2.toString(),
            productId: cartItem.productId.toString(),
            productName: cartItem.name,
            isUploaded: "0",
            quantity: cartItem.quantity,
            price: cartItem.price,
            discount: cartItem.discount,
            total: cartItem.quantity * cartItem.price,
            color: cartItem.color.toString(),
            barcode: cartItem.productBarcode.toString(),
          );
        }).toList();
        await dbHelper.insertOrderItemsVansale(
            int.parse(maxFatora.toString()), orderItems);

        OrderVansaleArchiveModel orderVansaleArchive = OrderVansaleArchiveModel(
          deliveryDate: deliveryDateController.text,
          fatora_number: maxFatora.toString(),
          latitude: currentLocation!.latitude.toString(),
          user_id: _userID.toString(),
          longitude: currentLocation.longitude.toString(),
          customerId: widget.id.toString(),
          storeId: storeId,
          totalAmount: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          discount: double.parse(
              DiscountController.text == "" ? "0" : DiscountController.text),
          cashPaid: double.parse(valueafterController.text == ""
              ? valueController.text
              : valueafterController.text),
          orderDate: orderDate,
          orderTime: orderTime,
          status: "pending",
        );
        int orderIdVansaleArchive =
            await dbHelper.insertOrderVansaleArchive(orderVansaleArchive);

        List<OrderItemVansaleArchiveModel> orderItemsVansaleArchive =
            cartItems.map((cartItem) {
          return OrderItemVansaleArchiveModel(
            orderId: int.parse(maxFatora.toString()),
            bonus1: cartItem.ponus1.toString(),
            bonus2: cartItem.ponus2.toString(),
            productId: cartItem.productId.toString(),
            productName: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            discount: cartItem.discount,
            total: cartItem.quantity * cartItem.price,
            color: cartItem.color.toString(),
            barcode: cartItem.productBarcode.toString(),
          );
        }).toList();
        await dbHelper.insertOrderItemsVansaleArchive(
            int.parse(maxFatora.toString()), orderItemsVansaleArchive);

        for (var cartItem in cartItems) {
          double currentStock = await dbHelper
              .getProductStock(int.parse(cartItem.productId.toString()));
          double newStock = currentStock -
              (cartItem.quantity +
                  double.parse(cartItem.ponus1.toString()) +
                  double.parse(cartItem.ponus2.toString()));
          await dbHelper.updateProductStock(
              int.parse(cartItem.productId.toString()), newStock);
        }

        if (pdf.toString() == "nothing") {
          await _printInvoice(
            userType: type.toString(),
            macAddress: macAddressPrinter.toString(),
            items: [],
            customerName: widget.customer_name.toString(),
            date: actualDate,
            time: actualTime,
            invoiceHeader: invoiceHeader.toString(),
            discount:
                DiscountController.text == "" ? "0" : DiscountController.text,
            finalTotal: valueafterController.text == ""
                ? valueController.text
                : valueafterController.text,
            invoiceNumber: maxFatora.toString(),
            salesManNumber: salesman_id.toString(),
            licensedOperator: shopNo.toString(),
          );
          if (type != "quds") {
            await CartDatabaseHelper()
                .updatePrintedStatusForOrderVansale(orderId, '1');
          }
        }
      }

      // >>> OFFLINE: open the waybill form with maxFatora BEFORE incrementing number/popping
      await _maybeOpenWaybillAfterSave(maxFatora?.toString() ?? '');

      int newFatoraNumber = int.parse(maxFatora.toString()) + 1;
      await dbHelper.updateMaxFatoraNumber(newFatoraNumber.toString());

      final formatter = DateFormat('dd-MM-yyyy hh:mm a', 'en');
      HistoryModel newhistoryRecord = HistoryModel(
        created_at: formatter.format(now),
        customer_id: widget.id,
        h_code: "1",
        lattitude: "",
        longitude: "",
      );

      await CartDatabaseHelper().insertHistory(newhistoryRecord);

      print("✅ maxFatoraNumber updated successfully!");

      Navigator.of(context, rootNavigator: true).pop();
      type.toString() == "quds"
          ? Fluttertoast.showToast(
              msg: "تم اضافة الطلبية بنجاح",
              backgroundColor: Colors.green,
              fontSize: 18)
          : Fluttertoast.showToast(
              msg: "تم اضافة الفاتورة بنجاح",
              backgroundColor: Colors.green,
              fontSize: 18);

      final cartProvider2 = Provider.of<CartProvider>(context, listen: false);
      cartProvider2.clearCart();
      pdf;

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  Future<void> _persistLogesticsIdOnServer({
    required String orderId, // fatora id
    required String logesticeId, // shipment.id from LogesTechs
  }) async {
    final uri = Uri.parse(
        'https://yaghm.com/admin/api/fawater/$orderId/set-logestics-id');
    final body = {'logestice_id': logesticeId};

    try {
      final r = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );
      if (r.statusCode != 200) {
        print('set-logestics-id failed: ${r.statusCode} -> ${r.body}');
      }
    } catch (e) {
      print('set-logestics-id exception: $e');
    }
  }

  final DataDownloader dataDownloader = DataDownloader();

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            alignment: Alignment.center,
            height: 100.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text(
                  "Loading...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  nothing() {}

  pdfFatoraA4(var cartItems) async {
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

    // Title Section
    final title = pw.Column(
      children: [
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("تسعيرة", style: pw.TextStyle(fontSize: 20)),
          ),
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(), style: pw.TextStyle(fontSize: 17)),
            pw.SizedBox(width: 5),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("التاريخ : ", style: pw.TextStyle(fontSize: 17)),
            ),
          ]),
        ]),
        pw.SizedBox(height: 5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(widget.customer_name.toString(),
                style: pw.TextStyle(fontSize: 17)),
          ),
          pw.SizedBox(width: 5),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("اسم الزبون : ", style: pw.TextStyle(fontSize: 17)),
          ),
        ]),
        if (deliveryDate)
          pw.Column(
            children: [
              pw.SizedBox(height: 5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text(deliveryDateController.text,
                      style: pw.TextStyle(fontSize: 17)),
                ),
                pw.SizedBox(width: 5),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text("تاريخ الاستلام : ",
                      style: pw.TextStyle(fontSize: 17)),
                ),
              ]),
            ],
          )
      ],
    );
    widgets.add(title);

    // Header Row (added image column)
    final firstrow = pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("المبلغ", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          if (discountSetting)
            pw.Expanded(
              flex: 1,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                    child: pw.Text("الخصم", style: pw.TextStyle(fontSize: 17))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("السعر", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          if (ponus1)
            pw.Expanded(
              flex: 1,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                    child: pw.Text("بونص", style: pw.TextStyle(fontSize: 17))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("الكمية", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("الصنف", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
        ],
      ),
    );
    widgets.add(firstrow);

    // ListView with image in each row
    final listview = pw.ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        var item = cartItems[index];

        double total = item.discount == 0.0
            ? item.price * item.quantity
            : item.quantity * item.price * (1 - item.discount / 100);

        // Word wrap name
        List<String> nameLines = [];
        String name = item.name;
        int maxChars = 15;
        List<String> words = name.split(' ');
        String line = '';
        for (String word in words) {
          if ((line + ' ' + word).trim().length <= maxChars) {
            line += (line.isEmpty ? '' : ' ') + word;
          } else {
            nameLines.add(line);
            line = word;
          }
        }
        if (line.isNotEmpty) nameLines.add(line);

        double rowHeight = 25.0 + (nameLines.length * 25.0);

        return pw.Container(
          height: rowHeight,
          decoration:
              pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${total.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              if (discountSetting)
                pw.Expanded(
                  flex: 1,
                  child: pw.Center(
                      child: pw.Text("${item.discount}",
                          style: pw.TextStyle(fontSize: 17))),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${item.price.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              if (ponus1)
                pw.Expanded(
                  flex: 1,
                  child: pw.Center(
                      child: pw.Text("${item.ponus1}",
                          style: pw.TextStyle(fontSize: 17))),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${item.quantity.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: nameLines
                          .map((line) =>
                              pw.Text(line, style: pw.TextStyle(fontSize: 14)))
                          .toList(),
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

    final total =
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      if (NotesController.text != "")
        pw.Column(children: [
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(NotesController.text,
                  style: pw.TextStyle(fontSize: 17)),
            ),
            pw.SizedBox(width: 5),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child:
                    pw.Text("الملاحظات : ", style: pw.TextStyle(fontSize: 17))),
          ]),
        ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(widget.total.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع قبل الخصم : ",
                style: pw.TextStyle(fontSize: 17))),
      ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(DiscountController.text == "" ? "0" : DiscountController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(" الخصم : ", style: pw.TextStyle(fontSize: 17))),
      ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(
            valueafterController.text == ""
                ? widget.total.toString()
                : valueafterController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع النهائي : ",
                style: pw.TextStyle(fontSize: 17))),
      ]),
    ]);
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

  pdfFatoraA4WithImage(var cartItems) async {
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

    // Title Section
    final title = pw.Column(
      children: [
        pw.Center(
          child: pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("تسعيرة", style: pw.TextStyle(fontSize: 20)),
          ),
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(), style: pw.TextStyle(fontSize: 17)),
            pw.SizedBox(width: 5),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text("التاريخ : ", style: pw.TextStyle(fontSize: 17)),
            ),
          ]),
        ]),
        pw.SizedBox(height: 5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(widget.customer_name.toString(),
                style: pw.TextStyle(fontSize: 17)),
          ),
          pw.SizedBox(width: 5),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("اسم الزبون : ", style: pw.TextStyle(fontSize: 17)),
          ),
        ]),
        if (deliveryDate)
          pw.Column(
            children: [
              pw.SizedBox(height: 5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text(deliveryDateController.text,
                      style: pw.TextStyle(fontSize: 17)),
                ),
                pw.SizedBox(width: 5),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text("تاريخ الاستلام : ",
                      style: pw.TextStyle(fontSize: 17)),
                ),
              ]),
            ],
          )
      ],
    );
    widgets.add(title);

    // Header Row (added image column)
    final firstrow = pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("الصورة", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("المبلغ", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          if (discountSetting)
            pw.Expanded(
              flex: 1,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                    child: pw.Text("الخصم", style: pw.TextStyle(fontSize: 17))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("السعر", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          if (ponus1)
            pw.Expanded(
              flex: 1,
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                    child: pw.Text("بونص", style: pw.TextStyle(fontSize: 17))),
              ),
            ),
          pw.Expanded(
            flex: 1,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("الكمية", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                  child: pw.Text("الصنف", style: pw.TextStyle(fontSize: 17))),
            ),
          ),
        ],
      ),
    );
    widgets.add(firstrow);

    // ListView with image in each row
    final listview = pw.ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        var item = cartItems[index];

        double total = item.discount == 0.0
            ? item.price * item.quantity
            : item.quantity * item.price * (1 - item.discount / 100);

        // Word wrap name
        List<String> nameLines = [];
        String name = item.name;
        int maxChars = 15;
        List<String> words = name.split(' ');
        String line = '';
        for (String word in words) {
          if ((line + ' ' + word).trim().length <= maxChars) {
            line += (line.isEmpty ? '' : ' ') + word;
          } else {
            nameLines.add(line);
            line = word;
          }
        }
        if (line.isNotEmpty) nameLines.add(line);

        double rowHeight = 25.0 + (nameLines.length * 25.0);

        // Image
        pw.Widget? imageWidget;
        if (item.image != null && File(item.image).existsSync()) {
          final bytes = File(item.image).readAsBytesSync();
          imageWidget = pw.Image(pw.MemoryImage(bytes),
              width: 40, height: 40, fit: pw.BoxFit.cover);
        } else {
          imageWidget = pw.Text("—");
        }

        return pw.Container(
          height: rowHeight,
          decoration:
              pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 1, child: pw.Center(child: imageWidget)),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${total.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              if (discountSetting)
                pw.Expanded(
                  flex: 1,
                  child: pw.Center(
                      child: pw.Text("${item.discount}",
                          style: pw.TextStyle(fontSize: 17))),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${item.price.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              if (ponus1)
                pw.Expanded(
                  flex: 1,
                  child: pw.Center(
                      child: pw.Text("${item.ponus1}",
                          style: pw.TextStyle(fontSize: 17))),
                ),
              pw.Expanded(
                flex: 1,
                child: pw.Center(
                    child: pw.Text("${item.quantity.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 17))),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: nameLines
                          .map((line) =>
                              pw.Text(line, style: pw.TextStyle(fontSize: 14)))
                          .toList(),
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

    final total =
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      if (NotesController.text != "")
        pw.Column(children: [
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(NotesController.text,
                  style: pw.TextStyle(fontSize: 17)),
            ),
            pw.SizedBox(width: 5),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child:
                    pw.Text("الملاحظات : ", style: pw.TextStyle(fontSize: 17))),
          ]),
        ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(widget.total.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع قبل الخصم : ",
                style: pw.TextStyle(fontSize: 17))),
      ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(DiscountController.text == "" ? "0" : DiscountController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(" الخصم : ", style: pw.TextStyle(fontSize: 17))),
      ]),
      pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(
            valueafterController.text == ""
                ? widget.total.toString()
                : valueafterController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع النهائي : ",
                style: pw.TextStyle(fontSize: 17))),
      ]),
    ]);
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

  pdfFatora8CM(var cartItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? shop_no = prefs.getString('shop_no');
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    // var imagelogo = pw.MemoryImage(
    //   (await rootBundle.load('assets/quds_logo.jpeg')).buffer.asUint8List(),
    // );
    List<pw.Widget> widgets = [];
    final title = pw.Column(
      children: [
        // pw.Container(
        //     height: 70,
        //     width: double.infinity,
        //     child: pw.Image(imagelogo, fit: pw.BoxFit.cover)),
        // pw.SizedBox(
        //   height: 5,
        // ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(),
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.SizedBox(width: 5),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("التاريخ : ", style: pw.TextStyle(fontSize: 9))),
          ]),
        ]),
        pw.SizedBox(height: 2),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(widget.customer_name.toString(),
                style: pw.TextStyle(fontSize: 8)),
          ),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child:
                  pw.Text("أسم الزبون : ", style: pw.TextStyle(fontSize: 9))),
        ]),
        pw.SizedBox(
          height: 5,
        ),
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
                // decoration: pw.BoxDecoration(
                //   border: pw.Border.all(color: PdfColors.grey400),
                // ),
                child: pw.Center(
                  child: pw.Text(
                    "المبلغ",
                    style: pw.TextStyle(fontSize: 8),
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
                    "السعر",
                    style: pw.TextStyle(fontSize: 8),
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
                    "الكمية",
                    style: pw.TextStyle(fontSize: 8),
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
                    "الصنف",
                    style: pw.TextStyle(fontSize: 8),
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
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        CartItem item = cartItems[index];
        double total = item.price * item.quantity;
        return pw.Container(
          height: 30,
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
                          "${total.toString()}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
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
                          "${item.price}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
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
                          "${item.quantity}",
                          style: pw.TextStyle(
                            fontSize: 8,
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
                    flex: 2,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          "${item.name}",
                          style: pw.TextStyle(
                            fontSize: 8,
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
    final total =
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(widget.total.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجوع قبل الخصم : ",
                style: pw.TextStyle(fontSize: 9))),
      ]),
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(DiscountController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(" الخصم : ", style: pw.TextStyle(fontSize: 9))),
      ]),
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(valueController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.SizedBox(width: 5),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع النهائي : ",
                style: pw.TextStyle(fontSize: 9))),
      ]),
    ]);
    widgets.add(total);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
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

  pdfFatora5CM(var cartItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? shop_no = prefs.getString('shop_no');
    var now = DateTime.now();
    var formatterDate = DateFormat('yyyy-MM-dd');
    var formatterTime = DateFormat('kk:mm:ss');
    String actualDate = formatterDate.format(now);
    String actualTime = formatterTime.format(now);
    var arabicFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Hacen_Tunisia.ttf"));
    // var imagelogo = pw.MemoryImage(
    //   (await rootBundle.load('assets/quds_logo.jpeg')).buffer.asUint8List(),
    // );
    List<pw.Widget> widgets = [];
    final title = pw.Column(
      children: [
        // pw.Container(
        //     height: 70,
        //     width: double.infinity,
        //     child: pw.Image(imagelogo, fit: pw.BoxFit.cover)),
        pw.SizedBox(
          height: 5,
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Row(children: [
            pw.Text(actualDate.toString(),
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
            pw.SizedBox(width: 2),
            pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text("التاريخ : ", style: pw.TextStyle(fontSize: 6))),
          ]),
        ]),
        pw.SizedBox(height: 2),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(widget.customer_name.toString(),
                style: pw.TextStyle(fontSize: 6)),
          ),
          pw.SizedBox(width: 5),
          pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child:
                  pw.Text("أسم الزبون : ", style: pw.TextStyle(fontSize: 6))),
        ]),
        pw.SizedBox(
          height: 5,
        ),
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
                // decoration: pw.BoxDecoration(
                //   border: pw.Border.all(color: PdfColors.grey400),
                // ),
                child: pw.Center(
                  child: pw.Text(
                    "المبلغ",
                    style: pw.TextStyle(fontSize: 6),
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
                    "السعر",
                    style: pw.TextStyle(fontSize: 6),
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
                    "الكمية",
                    style: pw.TextStyle(fontSize: 6),
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
                    "الصنف",
                    style: pw.TextStyle(fontSize: 6),
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
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        CartItem item = cartItems[index];
        double total = item.price * item.quantity;
        return pw.Container(
          height: 40,
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
                          "${total.toString()}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 6,
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
                          "${item.price}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 6,
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
                          "${item.quantity}",
                          style: pw.TextStyle(
                            fontSize: 6,
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
                    flex: 2,
                    child: pw.Container(
                      child: pw.Center(
                        child: pw.Text(
                          "${item.name}",
                          style: pw.TextStyle(
                            fontSize: 6,
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
    final total =
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(widget.total.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
        pw.SizedBox(width: 2),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجوع قبل الخصم : ",
                style: pw.TextStyle(fontSize: 6))),
      ]),
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(DiscountController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
        pw.SizedBox(width: 2),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(" الخصم : ", style: pw.TextStyle(fontSize: 6))),
      ]),
      pw.SizedBox(height: 5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
        pw.Text(valueController.text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
        pw.SizedBox(width: 2),
        pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text("المجموع النهائي : ",
                style: pw.TextStyle(fontSize: 6))),
      ]),
    ]);
    widgets.add(total);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
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
}

class _Debouncer {
  _Debouncer({this.ms = 350});
  final int ms;
  Timer? _t;
  void run(void Function() fn) {
    _t?.cancel();
    _t = Timer(Duration(milliseconds: ms), fn);
  }

  void dispose() => _t?.cancel();
}

class DeliveryFormResult {
  final String email;
  final String password;
  final String orderNumber;
  final String customerName;
  final String phone;
  final String? phone2;
  final String address;
  final String description;
  final int cityId;
  final int qty;
  final String? notes;
  final double? cod;
  final double? weight;

  DeliveryFormResult({
    required this.email,
    required this.password,
    required this.orderNumber,
    required this.customerName,
    required this.phone,
    required this.description,
    this.phone2,
    required this.address,
    required this.cityId,
    required this.qty,
    this.notes,
    this.cod,
    this.weight,
  });
}
