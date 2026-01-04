import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/total_receivables/total_card/total_card.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';

class TotalReceivables extends StatefulWidget {
  const TotalReceivables({Key? key}) : super(key: key);

  @override
  State<TotalReceivables> createState() => _TotalReceivablesState();
}

class _TotalReceivablesState extends State<TotalReceivables> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
          child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerMain(),
        appBar: PreferredSize(
            child: AppBarBack(
              title: "مجمل الذمم",
            ),
            preferredSize: Size.fromHeight(50)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15, top: 35),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 50,
                        child: TextField(
                          onChanged: (_) {
                            if (searchController.text == "") {
                              setState(() {
                                fun = false;
                              });
                            } else {
                              setState(() {
                                fun = true;
                              });
                            }
                          },
                          controller: searchController,
                          textAlign: TextAlign.center,
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: 'بحث عن رقم الزبون',
                            hintStyle: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 14),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Main_Color, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 50,
                        child: TextField(
                          onChanged: (_) {
                            if (searchControllerByName.text == "" &&
                                searchController.text == "") {
                              setState(() {
                                fun = false;
                              });
                            } else {
                              setState(() {
                                fun = true;
                              });
                            }
                          },
                          controller: searchControllerByName,
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.center,
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: 'بحث عن أسم الزبون',
                            hintStyle: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 14),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Main_Color, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2.0, color: Color(0xffD6D3D3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder(
                future: searchController.text != ""
                    ? searchCustomersByID()
                    : searchControllerByName.text != ""
                        ? searchCustomersByName()
                        : getCustomers(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SpinKitPulse(
                        color: Main_Color,
                        size: 60,
                      ),
                    );
                  } else {
                    if (snapshot.data != null) {
                      var Customers = snapshot.data["customers"];
                      var SUM = snapshot.data["sum"] ?? 0.0;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 15, right: 15, top: 20),
                            child: Row(
                              children: [
                                Text(
                                  "مجموع الرصيد : ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  SUM.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 15, left: 15, top: 10),
                            child: Container(
                              height: 40,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Main_Color,
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Center(
                                        child: Text(
                                          "الرقم",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Main_Color,
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Center(
                                        child: Text(
                                          "الرصيد",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Main_Color,
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Center(
                                        child: Text(
                                          "أسم الزبون",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Main_Color,
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Center(
                                        child: Text(
                                          "رقم الهاتف",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Main_Color,
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: Center(
                                        child: Text(
                                          "واتس اب",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ListView.builder(
                            itemCount: Customers.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return TotalCard(
                                index: index,
                                lattitude: 0.0,
                                longitude: 0.0,
                                id: Customers[index]['id'] ?? "0",
                                balance: Customers[index]['c_balance'] ?? "",
                                name: Customers[index]['c_name'] ?? "",
                                phone: Customers[index]['phone1'] ?? " - ",
                              );
                            },
                          ),
                        ],
                      );
                    } else {
                      return Center(
                          child: SizedBox(
                              height: 40,
                              width: 40,
                              child: CircularProgressIndicator()));
                    }
                  }
                },
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      )),
    );
  }

  bool fun = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController searchControllerByName = TextEditingController();

  getCustomers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');

    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };

    var url =
        'https://yaghm.com/admin/api/customers/${company_id.toString()}/${salesman_id.toString()}';
    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);

    return res;
  }

  searchCustomersByID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        'http://yaghm.com/admin/api/customers/${company_id.toString()}/${salesman_id.toString()}/search?id=${searchController.text}';
    print("url1");
    print(url);

    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);
    return res;
  }

  searchCustomersByName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        'http://yaghm.com/admin/api/customers/${company_id.toString()}/${salesman_id.toString()}/${searchControllerByName.text}';
    print("url2");
    print(url);
    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);
    return res;
  }
}
