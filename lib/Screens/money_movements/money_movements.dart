import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quds_yaghmour/Screens/kashf_hesab/kashf_card/kashf_card.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'money_movement_card/money_movement_card.dart';

class MoneyMovement extends StatefulWidget {
  final customer_id;
  final name;
  const MoneyMovement({Key? key, this.customer_id, this.name})
      : super(key: key);

  @override
  State<MoneyMovement> createState() => _MoneyMovementState();
}

class _MoneyMovementState extends State<MoneyMovement> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  final customersBalances = [];

  getCustomerBalance(int index) {
    double sum = 0.0;
    for (var i = 0; i < index + 1; i++) {
      sum += double.parse(customersBalances[i]);
    }
    return sum;
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
      if (start_date.text != "") {
        _page = 1;
        filterStatments();
        getAllStatments();
        setState(() {});
      } else {
        _firstLoad();
        setState(() {});
      }
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

  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
          child: Scaffold(
        key: _scaffoldState,
        drawer: DrawerMain(),
        appBar: PreferredSize(
            child: AppBarBack(
              title: "مجمل الحركات",
            ),
            preferredSize: Size.fromHeight(50)),
        body: _isFirstLoadRunning
            ? Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: SpinKitPulse(
                  color: Main_Color,
                  size: 60,
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 25, left: 25, top: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            child: TextField(
                              onTap: setStart,
                              controller: start_date,
                              readOnly: true,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'من تاريخ',
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
                          width: 20,
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            child: TextField(
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              onTap: setEnd,
                              controller: end_date,
                              readOnly: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'الى تاريخ',
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              "مجموع الدائن :$total_mnh",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "مجموع المدين :$total_lah",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 10,
                          left: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "الرقم",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "الاسم",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "منه",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "له",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "البيان",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "التاريخ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color.fromRGBO(83, 89, 219, 1),
                                      Color.fromRGBO(32, 39, 160, 0.6),
                                    ]),
                                    border:
                                        Border.all(color: Color(0xffD6D3D3))),
                                child: Center(
                                  child: Text(
                                    "رقم السند",
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
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _controller,
                      itemCount: listPDF.length,
                      itemBuilder: (context, index) {
                        customersBalances.clear();
                        for (var customer in listPDF) {
                          customersBalances
                              .add(customer['money_amount'].toString());
                        }
                        return MoneyMovementCard(
                          actions: listPDF[index]['action'] ?? [],
                          action_id: listPDF[index]['action_id'] ?? "-",
                          id: listPDF[index]['customer_id'] ?? 0,
                          name: listPDF[index]['customer_name'] ?? "-",
                          bayan: listPDF[index]['action_type'] ?? "",
                          mnh: double.parse(listPDF[index]['money_amount']
                                      .toString()) >
                                  0
                              ? listPDF[index]['money_amount'].toString()
                              : "0",
                          lah: double.parse(listPDF[index]['money_amount']
                                      .toString()) <
                                  0
                              ? double.parse(listPDF[index]['money_amount']
                                      .toString()) *
                                  -1
                              : "0",
                          date: listPDF[index]['action_date'] ?? "",
                        );
                      },
                    ),
                  ),
                  // when the _loadMore function is running
                  if (_isLoadMoreRunning == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
      )),
    );
  }

  var listPDFAll = [];
  var listPDF = [];
  List array_mnh = [];
  List action_type = [];
  double total_mnh = 0.0;

  List array_lah = [];
  double total_lah = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setControllers();
    _firstLoad();
    getAllStatments();
    _controller = ScrollController()..addListener(_loadMore);
  }

  // At the beginning, we fetch the first 20 posts
  int _page = 1;
  // you can change this value to fetch more or less posts per page (10, 15, 5, etc)
  final int _limit = 20;

  // There is next page or not
  bool _hasNextPage = true;

  // Used to display loading indicators when _firstLoad function is running
  bool _isFirstLoadRunning = false;

  // Used to display loading indicators when _loadMore function is running
  bool _isLoadMoreRunning = false;

  filterStatments() async {
    setState(() {
      _isFirstLoadRunning = true;
      listPDF = [];
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        'https://yaghm.com/admin/api/filter_statments_all_customers/$company_id/$salesman_id/${start_date.text}/${end_date.text}?page=$_page';
    var response = await http.get(Uri.parse(url), headers: headers);
    setState(() {
      listPDF = json.decode(response.body)["statments"]["data"];
      _isFirstLoadRunning = false;
    });
  }

  var LastBalanceValue;

  // This function will be called when the app launches (see the initState function)
  void _firstLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      var url =
          "https://yaghm.com/admin/api/statments_all_customers/${company_id.toString()}?page=$_page";
      final res = await http.get(Uri.parse(url));
      setState(() {
        listPDF = json.decode(res.body)["statements"]["data"];
      });
    } catch (err) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  // This function will be triggered whenver the user scroll
  // to near the bottom of the list view
  void _loadMore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller!.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      _page += 1; // Increase _page by 1

      try {
        var url = start_date.text == ""
            ? "https://yaghm.com/admin/api/statments_all_customers/${company_id.toString()}?page=$_page"
            : "https://yaghm.com/admin/api/filter_statments_all_customers/$company_id/$salesman_id/${start_date.text}/${end_date.text}?page=$_page";

        final res = await http.get(Uri.parse(url));

        final List fetchedPosts = start_date.text == ""
            ? json.decode(res.body)["statements"]["data"]
            : json.decode(res.body)["statments"]["data"];
        if (fetchedPosts.isNotEmpty) {
          // Filter out duplicates based on unique identifiers
          final uniqueFetchedPosts = fetchedPosts
              .where((newPost) => !listPDF
                  .any((existingPost) => newPost['id'] == existingPost['id']))
              .toList();

          setState(() {
            listPDF.addAll(uniqueFetchedPosts);
          });
        } else {
          Fluttertoast.showToast(msg: "نهاية الحركات");
          Timer(Duration(milliseconds: 300), () {
            Fluttertoast.cancel();
          });
        }
      } catch (err) {
        if (kDebugMode) {
          print('Something went wrong!');
        }
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  getAllStatments() async {
    setState(() {
      total_lah = 0.0;
      total_mnh = 0.0;
      listPDFAll.clear();
      array_mnh.clear();
      array_lah.clear();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    String? code_price = prefs.getString('price_code');
    try {
      if (start_date.text == "" || end_date.text == "") {
        var url =
            "https://yaghm.com/admin/api/all_statments_with_all_customers/${company_id.toString()}";

        final res = await http.get(Uri.parse(url));
        setState(() {
          listPDFAll = json.decode(res.body)["statements"];
          for (int i = 0; i < listPDFAll.length; i++) {
            if (double.parse(listPDFAll[i]['money_amount'].toString()) > 0) {
              var money = listPDFAll[i]['money_amount'].toString();

              array_mnh.add(money);
            } else {
              var money =
                  double.parse(listPDFAll[i]['money_amount'].toString()) * -1;

              array_lah.add(money);
            }
          }
          for (int i = 0; i < array_mnh.length; i++) {
            total_mnh = total_mnh + double.parse(array_mnh[i].toString());
          }
          for (int i = 0; i < array_lah.length; i++) {
            total_lah = total_lah + double.parse(array_lah[i].toString());
          }
          var lastBalance =
              listPDFAll.isNotEmpty ? listPDFAll.last['balance'] : null;

          LastBalanceValue = lastBalance;
        });
      } else {
        var url =
            "https://yaghm.com/admin/api/get_all_filter_statments_all_customers/$company_id/${start_date.text}/${end_date.text}";
        final res = await http.get(Uri.parse(url));
        setState(() {
          listPDFAll = json.decode(res.body)["statments"];
          for (int i = 0; i < listPDFAll.length; i++) {
            if (double.parse(listPDFAll[i]['money_amount'].toString()) > 0) {
              var money = listPDFAll[i]['money_amount'].toString();

              array_mnh.add(money);
            } else {
              var money =
                  double.parse(listPDFAll[i]['money_amount'].toString()) * -1;

              array_lah.add(money);
            }
          }
          for (int i = 0; i < array_mnh.length; i++) {
            total_mnh = total_mnh + double.parse(array_mnh[i].toString());
          }
          for (int i = 0; i < array_lah.length; i++) {
            total_lah = total_lah + double.parse(array_lah[i].toString());
          }
          var lastBalance =
              listPDFAll.isNotEmpty ? listPDFAll.last['balance'] : null;

          LastBalanceValue = lastBalance;
        });
      }
    } catch (err) {
      if (kDebugMode) {
        Navigator.of(context, rootNavigator: true).pop();
        print('Something went wrong , $err');
      }
    }
  }

  // The controller for the ListView
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.removeListener(_loadMore);
    super.dispose();
  }
}
