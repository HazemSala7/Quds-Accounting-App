import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quds_yaghmour/LocalDB/Provider/refresh-provider.dart';
import 'package:quds_yaghmour/Screens/catches/catches.dart';
import 'package:quds_yaghmour/Screens/change_password/change_password.dart';
import 'package:quds_yaghmour/Screens/login_screen/login_page.dart';
import 'package:quds_yaghmour/Screens/orders/orders_archive.dart';
import 'package:quds_yaghmour/Screens/sarf/sarf.dart';
import 'package:quds_yaghmour/Screens/total_sales/total_sales.dart';
import 'package:quds_yaghmour/Server/server.dart' as globals;
import 'package:quds_yaghmour/Services/Drawer/card_drawer/card_drawer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../Screens/customers/customers.dart';
import '../../Screens/money_movements/money_movements.dart';
import '../../Screens/orders/orders.dart';
import '../../Screens/rest_products/rest_products.dart';
import '../../Screens/settings/settings.dart';
import '../../Screens/total_receivables/total_receivables.dart';

bool mylang = false;

class DrawerMain extends StatefulWidget {
  const DrawerMain({Key? key}) : super(key: key);

  @override
  _DrawerMainState createState() => _DrawerMainState();
}

class _DrawerMainState extends State<DrawerMain> {
  @override
  bool moreComanies = false;
  bool showMoneyMovments = false;
  var roleID;
  String type = "";
  String userName = "";
  String userPassword = "";
  String showTotalSales = "true";
  setConrollers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _roleID = prefs.getString('role_id');
    String? _showTotalSales = prefs.getString('showTotalSales');
    String? _type = prefs.getString('type');
    String? _userName = prefs.getString('user_name');
    String? _password = prefs.getString('password');
    List<String>? _companies =
        await prefs.getStringList("companiesList") ?? [""];
    int? salesmanID = await prefs.getInt("salesman_id");
    if (salesmanID.toString() == "999") {
      showMoneyMovments = true;
    } else {
      showMoneyMovments = false;
    }
    if (_companies!.length == 1) {
      moreComanies = false;
    } else {
      moreComanies = true;
    }
    type = _type.toString();
    userPassword = _password.toString();
    userName = _userName.toString();
    roleID = _roleID.toString();
    showTotalSales = _showTotalSales.toString();

    setState(() {});
  }

  @override
  void initState() {
    setConrollers();
    super.initState();
  }

  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Stack(
            alignment: Alignment.topLeft,
            children: [
              DrawerHeader(
                padding: EdgeInsets.all(0),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ],
          ),
          Visibility(
            visible: type.toString() == "quds" ? false : true,
            child: Column(
              children: [
                Visibility(
                  visible: globals.JUST,
                  child: Column(
                    children: [
                      DrawerCard(
                          navi: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RestProducts()));
                          },
                          name: "البضاعة المتبقية",
                          myicon: Icon(Icons.production_quantity_limits)),
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 35, left: 35, top: 10),
                        child: Container(
                            width: double.infinity,
                            height: 2,
                            color: Color(0xffC6C5C5)),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: globals.JUST && showTotalSales == "true",
                  child: DrawerCard(
                      navi: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TotalSales()));
                      },
                      name: "اجمالي المبيعات",
                      myicon: Icon(Icons.sell_rounded)),
                ),
                Visibility(
                  visible: globals.JUST && showTotalSales == "true",
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 35, left: 35, top: 10),
                    child: Container(
                        width: double.infinity,
                        height: 2,
                        color: Color(0xffC6C5C5)),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: roleID.toString() == "4" ? false : true,
            child: DrawerCard(
                navi: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TotalReceivables()));
                },
                name: "مجمل الذمم",
                myicon: Icon(Icons.money)),
          ),
          Visibility(
            visible: roleID.toString() == "4" ? false : true,
            child: Padding(
              padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
              child: Container(
                  width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
            ),
          ),
          Visibility(
            visible: roleID.toString() == "4" ? false : showMoneyMovments,
            child: Column(
              children: [
                DrawerCard(
                    navi: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MoneyMovement()));
                    },
                    name: "مجمل الحركات",
                    myicon: Icon(Icons.move_up)),
                Padding(
                  padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
                  child: Container(
                      width: double.infinity,
                      height: 2,
                      color: Color(0xffC6C5C5)),
                ),
              ],
            ),
          ),
          Visibility(
            visible: roleID.toString() == "3" || roleID.toString() == "4"
                ? false
                : true,
            child: DrawerCard(
                navi: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Catches()));
                },
                name: "سندات القبض",
                myicon: Icon(Icons.receipt)),
          ),
          Visibility(
            visible: roleID.toString() == "3" || roleID.toString() == "4"
                ? false
                : true,
            child: Padding(
              padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
              child: Container(
                  width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
            ),
          ),
          Visibility(
            visible: roleID.toString() == "3" || roleID.toString() == "4"
                ? false
                : true,
            child: DrawerCard(
                navi: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Sarf()));
                },
                name: "سندات الصرف",
                myicon: Icon(Icons.receipt)),
          ),
          Visibility(
            visible: roleID.toString() == "3" || roleID.toString() == "4"
                ? false
                : true,
            child: Padding(
              padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
              child: Container(
                  width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
            ),
          ),
          Visibility(
            visible: roleID.toString() == "3" ? false : true,
            child: DrawerCard(
                navi: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Orders()));
                },
                name: type.toString() == "quds" ? "الطلبيات" : "الفواتير",
                myicon: Icon(Icons.request_quote_sharp)),
          ),
          Visibility(
            visible: roleID.toString() == "3" ? false : true,
            child: Padding(
              padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
              child: Container(
                  width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
            ),
          ),
          Visibility(
            visible:
                userName.toString() == "53" && userPassword.toString() == "53",
            child: Column(
              children: [
                DrawerCard(
                    navi: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OrdersArchivePage()));
                    },
                    name: type.toString() == "quds"
                        ? "الطلبيات المأرشفة"
                        : "الفواتير المأرشفة",
                    myicon: Icon(Icons.request_quote_sharp)),
                Padding(
                  padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
                  child: Container(
                      width: double.infinity,
                      height: 2,
                      color: Color(0xffC6C5C5)),
                ),
              ],
            ),
          ),
          DrawerCard(
            navi: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );

              // After coming back from Settings, reload preferences to reflect updated globals
              SharedPreferences prefs = await SharedPreferences.getInstance();
              globals.isOnline = prefs.getBool('isOnline') ?? true;
              globals.productImage = prefs.getBool('productImage') ?? true;
              globals.ponus1 = prefs.getBool('ponus1') ?? false;
              globals.ponus2 = prefs.getBool('ponus2') ?? false;
              globals.discountSetting = prefs.getBool('discount') ?? false;
              globals.notes = prefs.getBool('notes') ?? false;
              globals.existed_qty = prefs.getBool('existed_qty') ?? false;
              globals.deliveryDate = prefs.getBool('deliveryDate') ?? false;
              globals.order_kashf_from_new_to_old =
                  prefs.getBool('order_kashf_from_new_to_old') ?? false;
              globals.desc = prefs.getBool('desc') ?? false;
              globals.store_id = prefs.getString('store_id') ?? "1";

              setState(() {}); // refresh UI
            },
            name: "تعريفات أولية",
            myicon: Icon(Icons.perm_device_information),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
            child: Container(
                width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
          ),
          DrawerCard(
              navi: () async {
                final _url =
                    Uri.parse("https://yaghm.com/yaghco/contact_us.php");
                if (!await launchUrl(_url,
                    mode: LaunchMode.externalApplication)) {
                  Fluttertoast.showToast(
                      msg:
                          "لم يتم التمكن من الدخول الرابط , الرجاء المحاولة فيما بعد");
                }
              },
              name: "تواصل معنا",
              myicon: Icon(Icons.contact_phone)),
          Padding(
            padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
            child: Container(
                width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
          ),
          DrawerCard(
              navi: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen()));
              },
              name: "تغيير كلمة المرور",
              myicon: Icon(Icons.perm_device_information)),
          Padding(
            padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
            child: Container(
                width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
          ),
          Visibility(
            visible: moreComanies,
            child: Column(
              children: [
                DrawerCard(
                  navi: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();

                    List<String>? _companies =
                        await prefs.getStringList("companiesList");
                    int? salesman_id1 = await prefs.getInt("salesman_id1");
                    int? salesman_id2 = await prefs.getInt("salesman_id2");
                    int? salesman_id3 = await prefs.getInt("salesman_id3");
                    String? storeName1 =
                        await prefs.getString("store_name_1") ?? "-";
                    String? storeName2 =
                        await prefs.getString("store_name_2") ?? "-";
                    String? storeName3 =
                        await prefs.getString("store_name_3") ?? "-";

                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 200,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "الرجاء اختر رقم الشركة",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 35, left: 35),
                                child: ListView.builder(
                                  itemCount: _companies!.length,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    // Dynamically get the store name based on index
                                    String storeName = index == 0
                                        ? storeName1
                                        : index == 1
                                            ? storeName2
                                            : index == 2
                                                ? storeName3
                                                : "";

                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: SizedBox(
                                                  height: 100,
                                                  width: 100,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          await Future.delayed(
                                              Duration(milliseconds: 300));
                                          await prefs.setInt('company_id',
                                              int.parse(_companies[index]));
                                          await prefs.setStringList(
                                              'companiesList', _companies);
                                          await prefs.setInt(
                                            'salesman_id',
                                            int.parse(index == 0
                                                ? salesman_id1.toString()
                                                : index == 1
                                                    ? salesman_id2.toString()
                                                    : salesman_id3.toString()),
                                          );

                                          var headers = {
                                            'ContentType': 'application/json'
                                          };
                                          var url =
                                              'https://yaghm.com/admin/api/customers/${_companies[index]}/${index == 0 ? salesman_id1 : index == 1 ? salesman_id2 : salesman_id3}';
                                          var response = await http.get(
                                              Uri.parse(url),
                                              headers: headers);
                                          var res = jsonDecode(
                                              response.body)['customers'];

                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  Customers(
                                                CustomersArray: res,
                                                companiesArray: _companies,
                                              ),
                                            ),
                                            (route) => false,
                                          );
                                          Fluttertoast.showToast(
                                              msg: 'تم تسجيل الدخول بنجاح');
                                        },
                                        child: Container(
                                          width: 150,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color.fromRGBO(83, 89, 219, 1),
                                                Color.fromRGBO(
                                                    32, 39, 160, 0.6),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${_companies[index]} - $storeName',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  name: "اختيار الشركة",
                  myicon: Icon(Icons.store),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 35, left: 35, top: 10),
                  child: Container(
                    width: double.infinity,
                    height: 2,
                    color: Color(0xffC6C5C5),
                  ),
                ),
              ],
            ),
          ),
          DrawerCard(
              navi: () async {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (BuildContext context) => LoginScreen()),
                    (Route<dynamic> route) => false);
                Fluttertoast.showToast(msg: "تم تسجيل الخروج بنجاح");
              },
              name: "تسجيل خروج",
              myicon: Icon(Icons.logout)),
          Padding(
            padding:
                const EdgeInsets.only(right: 35, left: 35, top: 10, bottom: 50),
            child: Container(
                width: double.infinity, height: 2, color: Color(0xffC6C5C5)),
          ),
        ],
      ),
    );
  }
}
