import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/Screens/settings/settings_card/setting_Card.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart' as globals;
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/data_downloader/data_downloader.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Services/AppBar/appbar_back.dart';
import '../../Services/Drawer/drawer.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  TextEditingController idController = TextEditingController();
  DataDownloader dataDownloader = DataDownloader();
  TextEditingController companyNameController1 = TextEditingController();
  TextEditingController companyNameController2 = TextEditingController();
  TextEditingController companyNameController3 = TextEditingController();
  List<String>? companies = [];
  String systemType = "";
  @override
  void initState() {
    super.initState();
    setSettings();
  }

  setSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? store_id_order = prefs.getString('store_id');
    String? store_name = prefs.getString('store_name_1');
    String? store_name_2 = prefs.getString('store_name_2');
    String? store_name_3 = prefs.getString('store_name_3');
    String? type = prefs.getString('type');
    List<String>? _companies =
        await prefs.getStringList("companiesList") ?? [""];
    globals.isOnline = prefs.getBool('isOnline') ?? true;
    globals.productImage = prefs.getBool('productImage') ?? true;
    if (store_id_order.toString() == "null") {
      idController.text = "1";
      await prefs.setString('store_id', idController.text);
    } else {
      idController.text = store_id_order.toString();
    }
    if (store_name.toString() == "null") {
      companyNameController1.text = "";
      await prefs.setString('store_name_1', companyNameController1.text);
    } else {
      companyNameController1.text = store_name.toString();
    }
    if (store_name_2.toString() == "null") {
      companyNameController2.text = "";
      await prefs.setString('store_name_2', companyNameController2.text);
    } else {
      companyNameController2.text = store_name_2.toString();
    }
    if (store_name_3.toString() == "null") {
      companyNameController3.text = "";
      await prefs.setString('store_name_3', companyNameController3.text);
    } else {
      companyNameController3.text = store_name_3.toString();
    }
    systemType = type.toString();
    if (type.toString() == "quds") {
      productStyleTwo = false;
    }
    companies = _companies;
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
                title: "الاعدادات",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
              child: Column(
            children: [
              Visibility(
                visible: globals.JUST,
                child: Padding(
                  padding: const EdgeInsets.only(top: 25, right: 15, left: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "رقم المخزن",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: globals.JUST,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: TextField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        // يسمح بالأرقام فقط
                        FilteringTextInputFormatter.digitsOnly,
                        // حد أقصى رقمين
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (value) async {
                        // لو حاول إدخال أكثر من رقمين (حماية إضافية)
                        if (value.length > 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'لا يمكن إدخال أكثر من رقمين',
                                textAlign: TextAlign.right,
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // حفظ القيمة فقط إذا كانت صالحة
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('store_id', value);
                      },
                      decoration: InputDecoration(
                        hintText: "رقم المخزن",
                        counterText: "", // إخفاء عداد الأحرف
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xff34568B),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            width: 2.0,
                            color: Color(0xffD6D3D3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 25, right: 15, left: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "أسم الشركة",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    controller: companyNameController1,
                    obscureText: false,
                    onChanged: (_) async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString(
                          'store_name_1', companyNameController1.text);
                    },
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xff34568B), width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(width: 2.0, color: Color(0xffD6D3D3)),
                      ),
                      hintText: "أسم الشركة",
                    ),
                  ),
                ),
              ),

              Visibility(
                visible: globals.JUST,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                        "تحديث صور المنتجات",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        ValueNotifier<String> message = ValueNotifier<String>(
                            "📥 Fetching product images...");
                        ValueNotifier<double> progress =
                            ValueNotifier<double>(0.0);

                        showProgressDialog(context, message, progress);

                        try {
                          await dataDownloader.updateProductImagesFromApiOnly(
                              progress, message);
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "❌ Error updating product images: $e",
                            backgroundColor: Colors.red,
                          );
                        } finally {
                          if (Navigator.canPop(context)) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        }
                      }),
                ),
              ),
              Visibility(
                visible: companies!.length == 2 || companies!.length == 3
                    ? true
                    : false,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 25, right: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "أسم الشركة الثانية",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 15, left: 15, top: 5),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        child: TextField(
                          controller: companyNameController2,
                          obscureText: false,
                          onChanged: (_) async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString(
                                'store_name_2', companyNameController2.text);
                          },
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xff34568B), width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                            hintText: "أسم الشركة الثانية",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: companies!.length == 3 ? true : false,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 25, right: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "أسم الشركة الثالثة",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 15, left: 15, top: 5),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        child: TextField(
                          controller: companyNameController3,
                          obscureText: false,
                          onChanged: (_) async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setString(
                                'store_name_3', companyNameController3.text);
                          },
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xff34568B), width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                            hintText: "أسم الشركة الثالثة",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Visibility(
              //   visible: !isOnline,
              //   child: Padding(
              //     padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
              //     child: ButtonWidget(
              //         name: "تحديث البيانات",
              //         height: 50,
              //         width: double.infinity,
              //         BorderColor: Main_Color,
              //         FontSize: 18,
              //         OnClickFunction: () async {
              //           ValueNotifier<String> message =
              //               ValueNotifier<String>("Starting...");
              //           ValueNotifier<double> progress =
              //               ValueNotifier<double>(0.0);
              //           showProgressDialog(context, message, progress);
              //           try {
              //             await dataDownloader.downloadAndSaveData(
              //                 progress, message);
              //           } catch (e) {
              //             print("error");
              //             print(e);
              //             Fluttertoast.showToast(
              //                 msg: 'Failed to download data');
              //           } finally {
              //             if (Navigator.canPop(context)) {
              //               // ✅ Ensure there is an open dialog before closing
              //               Navigator.of(context, rootNavigator: true).pop();
              //             }
              //           }
              //         },
              //         BorderRaduis: 10,
              //         ButtonColor: Main_Color,
              //         NameColor: Colors.white),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 25, left: 25),
                child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 7,
                            blurRadius: 5,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white),
                    child: Column(
                      children: [
                        Visibility(
                          visible: globals.JUST,
                          child: Column(
                            children: [
                              SettingsCard(
                                status: globals.isOnline,
                                Status: () async {
                                  setState(() {
                                    globals.isOnline = !globals.isOnline;
                                  });
                                  // globals.isOnline = !globals.isOnline;
                                  if (globals.isOnline) {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'isOnline', globals.isOnline);
                                    final dbHelper = CartDatabaseHelper();
                                    List<CatchModel> receipts = await dbHelper
                                        .getUnuploadedCatchReceipts();
                                    List<CatchVansaleModel> receiptsVansale =
                                        await dbHelper
                                            .getUnuploadedCatchReceiptsVansale();

                                    List<Map<String, dynamic>> localOrders =
                                        await dbHelper.getPendingOrders();

                                    List<Map<String, dynamic>>
                                        localOrdersVansale = await dbHelper
                                            .getPendingOrdersVansale();

                                    if (receipts.isEmpty &&
                                        receiptsVansale.isEmpty &&
                                        localOrders.isEmpty &&
                                        localOrdersVansale.isEmpty) {
                                    } else {
                                      await syncData(context);
                                    }
                                  } else {
                                    print("0.1");
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'isOnline', globals.isOnline);
                                    ValueNotifier<String> message =
                                        ValueNotifier<String>("Starting...");
                                    ValueNotifier<double> progress =
                                        ValueNotifier<double>(0.0);
                                    showProgressDialog(
                                        context, message, progress);
                                    print("0.2");
                                    try {
                                      await dataDownloader.downloadAndSaveData(
                                          progress, message);
                                    } catch (e) {
                                      print("error");
                                      print(e);
                                      Fluttertoast.showToast(
                                          msg: 'Failed to download data');
                                    } finally {
                                      if (Navigator.canPop(context)) {
                                        // ✅ Ensure there is an open dialog before closing
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                      }
                                    }
                                  }
                                },
                                name: "العمل اونلاين",
                              ),
                              Visibility(
                                visible: systemType.toString() == "quds"
                                    ? false
                                    : true,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SettingsCard(
                                      status: globals.productStyleTwo,
                                      Status: () async {
                                        setState(() {
                                          globals.productStyleTwo =
                                              !globals.productStyleTwo;
                                        });
                                        SharedPreferences prefs =
                                            await SharedPreferences
                                                .getInstance();
                                        await prefs.setBool('productStyleTwo',
                                            globals.productStyleTwo);
                                      },
                                      name: "شكل فاتورة 2 ",
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.productImage,
                                Status: () async {
                                  setState(() {
                                    globals.productImage =
                                        !globals.productImage;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'productImage', globals.productImage);
                                },
                                name: "اظهار صورة المنتج",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.ponus1,
                                Status: () async {
                                  setState(() {
                                    globals.ponus1 = !globals.ponus1;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('ponus1', globals.ponus1);
                                },
                                name: "اظهار بونص 1",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.ponus2,
                                name: "اظهار بونص 2",
                                Status: () async {
                                  setState(() {
                                    globals.ponus2 = !globals.ponus2;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('ponus2', globals.ponus2);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.discountSetting,
                                Status: () async {
                                  setState(() {
                                    globals.discountSetting =
                                        !globals.discountSetting;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'discount', globals.discountSetting);
                                },
                                name: "اظهار الخصم",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.notes,
                                Status: () async {
                                  setState(() {
                                    globals.notes = !globals.notes;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('notes', globals.notes);
                                },
                                name: "اظهار الملاحظات",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.existed_qty,
                                Status: () async {
                                  setState(() {
                                    globals.existed_qty = !globals.existed_qty;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'existed_qty', globals.existed_qty);
                                },
                                name: "اظهار الكمية الموجودة",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.hideProductLessThan0,
                                Status: () async {
                                  setState(() {
                                    globals.hideProductLessThan0 =
                                        !globals.hideProductLessThan0;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('hideProductLessThan0',
                                      globals.hideProductLessThan0);
                                },
                                name: "اخفاء الأصناف الصفرية",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              SettingsCard(
                                status: globals.deliveryDate,
                                Status: () async {
                                  setState(() {
                                    globals.deliveryDate =
                                        !globals.deliveryDate;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'deliveryDate', globals.deliveryDate);
                                },
                                name: "اظهار تاريخ التسليم",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SettingsCard(
                          status: globals.order_kashf_from_new_to_old,
                          Status: () async {
                            setState(() {
                              globals.order_kashf_from_new_to_old =
                                  !globals.order_kashf_from_new_to_old;
                            });
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setBool('order_kashf_from_new_to_old',
                                globals.order_kashf_from_new_to_old);
                          },
                          name: "كشف الحساب من الأحدث الى الأقدم",
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.grey,
                          ),
                        ),
                        Visibility(
                          visible: globals.JUST,
                          child: Column(
                            children: [
                              SettingsCard(
                                status: globals.desc,
                                Status: () async {
                                  setState(() {
                                    globals.desc = !globals.desc;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('desc', globals.desc);
                                },
                                name: "اظهار الوصف",
                              ),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        )
                      ],
                    )),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
