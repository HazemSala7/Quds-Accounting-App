import 'dart:convert';
// import 'package:blue_print_pos/blue_print_pos.dart';
// import 'package:blue_print_pos/models/models.dart';
// import 'package:blue_print_pos/receipt/receipt.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:quds_yaghmour/Screens/total_sales/total_sales_card/total_sales_card.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class TotalSales extends StatefulWidget {
  const TotalSales({Key? key}) : super(key: key);

  @override
  State<TotalSales> createState() => _TotalSalesState();
}

class _TotalSalesState extends State<TotalSales> {
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
              title: "اجمالي المبيعات",
            ),
            preferredSize: Size.fromHeight(50)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Container(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Main_Color,
                                border: Border.all(color: Colors.white)),
                            child: Center(
                              child: Text(
                                "اجمالي المبيعات",
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
                                border: Border.all(color: Color(0xffD6D3D3))),
                            child: Center(
                              child: Text(
                                "نقدا",
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
                                border: Border.all(color: Color(0xffD6D3D3))),
                            child: Center(
                              child: Text(
                                "الذمم",
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
                                border: Border.all(color: Colors.white)),
                            child: Center(
                              child: Text(
                                "الخصم",
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
              TotalSalesCard(
                total: total,
                rece: rece,
                discount: discount,
                cash: cash,
              ),
            ],
          ),
        ),
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

  var total, discount, rece, cash;
  setTotalSales() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    int? company_id = prefs.getInt('company_id');
    int? salesman_id = prefs.getInt('salesman_id');
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    // print(formattedDate);
    var headers = {
      'Authorization': 'Bearer $token',
      'ContentType': 'application/json'
    };
    var url =
        '${AppLink.totalSales}/${company_id.toString()}/${salesman_id.toString()}/${formattedDate}';

    var response = await http.get(Uri.parse(url), headers: headers);
    var res = jsonDecode(response.body);
    setState(() {
      total = res["total"] ?? 0;
      rece = res["rece"] ?? 0;
      discount = res["discount"] ?? 0;
      cash = res["cash"] ?? 0;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setTotalSales();
  }
}
