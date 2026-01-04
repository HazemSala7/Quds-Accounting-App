import 'package:date_format/date_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-vansale-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/check-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/check-vansale-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Services/AppBar/appbar_back.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Server/server.dart';
import '../../Services/Drawer/drawer.dart';

class AddSarf extends StatefulWidget {
  final id, name;
  const AddSarf({Key? key, this.id, this.name}) : super(key: key);

  @override
  State<AddSarf> createState() => _AddSarfState();
}

class _AddSarfState extends State<AddSarf> {
  @override
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  initval() {
    print(widget.name.toString());
    setState(() {
      nameController.text = widget.name.toString();
    });
  }

  @override
  void initState() {
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
                title: "اضافة سند صرف",
              ),
              preferredSize: Size.fromHeight(50)),
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, right: 15, left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "أسم الزبون",
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
                        controller: nameController,
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
                          hintText: "أسم الزبون",
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
                        keyboardType: TextInputType.numberWithOptions(
                            signed: true, decimal: true),
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
                        keyboardType: TextInputType.numberWithOptions(
                            signed: true, decimal: true),
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
                  // Padding(
                  //   padding:
                  //       const EdgeInsets.only(top: 20, right: 15, left: 15),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         "مجموع الشيكات",
                  //         style: TextStyle(
                  //             fontSize: 16, fontWeight: FontWeight.bold),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         flex: 4,
                  //         child: Container(
                  //           height: 50,
                  //           child: TextField(
                  //             controller: TOTAL,
                  //             readOnly: true,
                  //             onChanged: (hazem) {
                  //               setState(() {
                  //                 var init_value = double.parse(
                  //                         DiscountController.text == ""
                  //                             ? "0"
                  //                             : DiscountController.text) +
                  //                     double.parse(CashController.text == ""
                  //                         ? "0"
                  //                         : CashController.text) +
                  //                     double.parse(
                  //                         TOTAL.text == "" ? "0" : TOTAL.text);

                  //                 MAINTOTAL.text = init_value.toString();
                  //               });
                  //             },
                  //             obscureText: false,
                  //             decoration: InputDecoration(
                  //               focusedBorder: OutlineInputBorder(
                  //                 borderSide: BorderSide(
                  //                     color: Color(0xff34568B), width: 2.0),
                  //               ),
                  //               enabledBorder: OutlineInputBorder(
                  //                 borderSide: BorderSide(
                  //                     width: 2.0, color: Color(0xffD6D3D3)),
                  //               ),
                  //               hintText: "مجموع الشيكات",
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //       Expanded(
                  //           flex: 1,
                  //           child: InkWell(
                  //             onTap: () {
                  //               showDialog(
                  //                 context: context,
                  //                 builder: (BuildContext context) {
                  //                   return AlertDialog(
                  //                     actions: <Widget>[
                  //                       Column(
                  //                         mainAxisAlignment:
                  //                             MainAxisAlignment.center,
                  //                         children: [
                  //                           Padding(
                  //                             padding: const EdgeInsets.only(
                  //                                 top: 10, right: 15, left: 15),
                  //                             child: Row(
                  //                               mainAxisAlignment:
                  //                                   MainAxisAlignment.start,
                  //                               children: [
                  //                                 Text(
                  //                                   "قيمه الشيك",
                  //                                   style: TextStyle(
                  //                                       fontSize: 16,
                  //                                       fontWeight:
                  //                                           FontWeight.bold),
                  //                                 ),
                  //                               ],
                  //                             ),
                  //                           ),
                  //                           Padding(
                  //                             padding: const EdgeInsets.only(
                  //                                 right: 5, left: 5, top: 5),
                  //                             child: Container(
                  //                               height: 50,
                  //                               width: double.infinity,
                  //                               child: TextField(
                  //                                 keyboardType: TextInputType
                  //                                     .numberWithOptions(
                  //                                         signed: true,
                  //                                         decimal: true),
                  //                                 controller: valueController,
                  //                                 obscureText: false,
                  //                                 decoration: InputDecoration(
                  //                                   focusedBorder:
                  //                                       OutlineInputBorder(
                  //                                     borderSide: BorderSide(
                  //                                         color:
                  //                                             Color(0xff34568B),
                  //                                         width: 2.0),
                  //                                   ),
                  //                                   enabledBorder:
                  //                                       OutlineInputBorder(
                  //                                     borderSide: BorderSide(
                  //                                         width: 2.0,
                  //                                         color: Color(
                  //                                             0xffD6D3D3)),
                  //                                   ),
                  //                                   hintText: "قيمه الشيك",
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                           ),
                  //                           Padding(
                  //                             padding: const EdgeInsets.only(
                  //                                 top: 10, right: 15, left: 15),
                  //                             child: Row(
                  //                               mainAxisAlignment:
                  //                                   MainAxisAlignment.start,
                  //                               children: [
                  //                                 Text(
                  //                                   "تاريخ الاستحقاق",
                  //                                   style: TextStyle(
                  //                                       fontSize: 16,
                  //                                       fontWeight:
                  //                                           FontWeight.bold),
                  //                                 ),
                  //                               ],
                  //                             ),
                  //                           ),
                  //                           Padding(
                  //                             padding: const EdgeInsets.only(
                  //                                 right: 5, left: 5, top: 5),
                  //                             child: Container(
                  //                               height: 50,
                  //                               width: double.infinity,
                  //                               child: TextField(
                  //                                 onTap: _pickDate,
                  //                                 controller:
                  //                                     datechekController,
                  //                                 obscureText: false,
                  //                                 decoration: InputDecoration(
                  //                                   focusedBorder:
                  //                                       OutlineInputBorder(
                  //                                     borderSide: BorderSide(
                  //                                         color:
                  //                                             Color(0xff34568B),
                  //                                         width: 2.0),
                  //                                   ),
                  //                                   enabledBorder:
                  //                                       OutlineInputBorder(
                  //                                     borderSide: BorderSide(
                  //                                         width: 2.0,
                  //                                         color: Color(
                  //                                             0xffD6D3D3)),
                  //                                   ),
                  //                                   hintText: "تاريخ الاستحقاق",
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                           ),
                  //                           Padding(
                  //                             padding: const EdgeInsets.only(
                  //                                 right: 25, left: 25, top: 25),
                  //                             child: MaterialButton(
                  //                               shape: RoundedRectangleBorder(
                  //                                   borderRadius:
                  //                                       BorderRadius.all(
                  //                                           Radius.circular(
                  //                                               10))),
                  //                               height: 50,
                  //                               minWidth: double.infinity,
                  //                               color: Color(0xff34568B),
                  //                               textColor: Colors.white,
                  //                               child: Text(
                  //                                 "اضافة شيك",
                  //                                 style: TextStyle(
                  //                                     fontSize: 22,
                  //                                     fontWeight:
                  //                                         FontWeight.bold),
                  //                               ),
                  //                               onPressed: () {
                  //                                 if (valueController.text ==
                  //                                         "" ||
                  //                                     datechekController.text ==
                  //                                         "") {
                  //                                   showDialog(
                  //                                     context: context,
                  //                                     builder: (BuildContext
                  //                                         context) {
                  //                                       return AlertDialog(
                  //                                         content: Text(
                  //                                             'الرجاء تعبئه جميع الفراغات'),
                  //                                         actions: <Widget>[
                  //                                           InkWell(
                  //                                             onTap: () {
                  //                                               Navigator.of(
                  //                                                       context)
                  //                                                   .pop();
                  //                                             },
                  //                                             child: Text(
                  //                                               'حسنا',
                  //                                               style: TextStyle(
                  //                                                   color: Color(
                  //                                                       0xff34568B)),
                  //                                             ),
                  //                                           ),
                  //                                         ],
                  //                                       );
                  //                                     },
                  //                                   );
                  //                                 } else {
                  //                                   cheks_array.add(
                  //                                       valueController.text);
                  //                                   setState(() {
                  //                                     chk_no_array.add(1);
                  //                                     value_array.add(
                  //                                         valueController.text);
                  //                                     date_array.add(
                  //                                         datechekController
                  //                                             .text);
                  //                                     account_num_array.add(1);
                  //                                     bank_num_array.add(1);

                  //                                     check_total +=
                  //                                         double.parse(
                  //                                             valueController
                  //                                                 .text);
                  //                                     TOTAL.text = check_total
                  //                                         .toString();

                  //                                     var init_value = double.parse(
                  //                                             DiscountController
                  //                                                         .text ==
                  //                                                     ""
                  //                                                 ? "0"
                  //                                                 : DiscountController
                  //                                                     .text) +
                  //                                         double.parse(
                  //                                             CashController
                  //                                                         .text ==
                  //                                                     ""
                  //                                                 ? "0"
                  //                                                 : CashController
                  //                                                     .text) +
                  //                                         double.parse(
                  //                                             TOTAL.text == ""
                  //                                                 ? "0"
                  //                                                 : TOTAL.text);

                  //                                     MAINTOTAL.text =
                  //                                         init_value.toString();
                  //                                   });
                  //                                   Navigator.pop(context);
                  //                                   setState(() {
                  //                                     cheknumController.text =
                  //                                         "";
                  //                                     valueController.text = "";
                  //                                     datechekController.text =
                  //                                         "";
                  //                                     accountnumController
                  //                                         .text = "";
                  //                                     bank_numController.text =
                  //                                         "";
                  //                                   });
                  //                                 }
                  //                               },
                  //                             ),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     ],
                  //                   );
                  //                 },
                  //               );
                  //             },
                  //             child: Container(
                  //               decoration: BoxDecoration(
                  //                   shape: BoxShape.circle, color: Main_Color),
                  //               height: 50,
                  //               width: 50,
                  //               child: Center(
                  //                   child: Image.asset("assets/plus.jpeg")),
                  //             ),
                  //           ))
                  //     ],
                  //   ),
                  // ),
                  // Visibility(
                  //   visible: cheks_array.length > 0 ? true : false,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(top: 15),
                  //     child: Container(
                  //       height: 80,
                  //       width: double.infinity,
                  //       child: ListView.builder(
                  //           itemCount: cheks_array.length,
                  //           scrollDirection: Axis.horizontal,
                  //           itemBuilder: (context, int index) {
                  //             return Padding(
                  //               padding:
                  //                   const EdgeInsets.only(right: 15, left: 15),
                  //               child: Stack(
                  //                 alignment: Alignment.topLeft,
                  //                 children: [
                  //                   Container(
                  //                     height: 60,
                  //                     width: 100,
                  //                     child: Center(
                  //                       child: Text(
                  //                         "${cheks_array[index]}",
                  //                         style: TextStyle(
                  //                             fontWeight: FontWeight.bold,
                  //                             fontSize: 16,
                  //                             color: Colors.white),
                  //                       ),
                  //                     ),
                  //                     decoration: BoxDecoration(
                  //                         borderRadius:
                  //                             BorderRadius.circular(10),
                  //                         color: Main_Color),
                  //                   ),
                  //                   IconButton(
                  //                       padding: EdgeInsets.all(2),
                  //                       onPressed: () {
                  //                         check_total = check_total -
                  //                             int.parse(cheks_array[index]
                  //                                 .toString());
                  //                         TOTAL.text = check_total.toString();
                  //                         cheks_array.removeAt(index);

                  //                         var init_value = double.parse(
                  //                                 DiscountController.text == ""
                  //                                     ? "0"
                  //                                     : DiscountController
                  //                                         .text) +
                  //                             double.parse(
                  //                                 CashController.text == ""
                  //                                     ? "0"
                  //                                     : CashController.text) +
                  //                             double.parse(TOTAL.text == ""
                  //                                 ? "0"
                  //                                 : TOTAL.text);

                  //                         MAINTOTAL.text =
                  //                             init_value.toString();

                  //                         setState(() {});
                  //                       },
                  //                       icon: Icon(
                  //                         Icons.delete,
                  //                         size: 20,
                  //                         color: Colors.white,
                  //                       ))
                  //                 ],
                  //               ),
                  //             );
                  //           }),
                  //     ),
                  //   ),
                  // ),
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
                        "اضافة سند صرف",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Center(
                                      child: CircularProgressIndicator())),
                            );
                          },
                        );
                        send();
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
  TextEditingController CashController = TextEditingController();
  TextEditingController DiscountController = TextEditingController();
  TextEditingController ChksController = TextEditingController();
  TextEditingController NotesController = TextEditingController();
  send() async {
    if (MAINTOTAL.text == '') {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('الرجء اضافة المجموع النقدي او شيك'),
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
      String actualDate = formatterDate.format(now);
      String actualTime = formatterTime.format(now);
      int? company_id = prefs.getInt('company_id');
      int? salesman_id = prefs.getInt('salesman_id');
      String? store_id_order = prefs.getString('store_id');
      String? type = prefs.getString('type');
      if (isOnline) {
        if (cheks_array.length == 0) {
          setState(() {
            chk_no_array.add(1);
            value_array.add(0);
            date_array.add("2022-02-22");
            account_num_array.add(1);
            bank_num_array.add(1);
          });
        }

        var url = type.toString() == "quds"
            ? AppLink.addCatchReceiptQuds
            : AppLink.vansaleAddCatchReceipt;
        var request = new http.MultipartRequest("POST", Uri.parse(url));
        request.fields['downloaded'] = "1";
        request.fields['store_id'] = store_id_order.toString();
        request.fields['customer_id'] = widget.id.toString();
        request.fields['company_id'] = company_id.toString();
        request.fields['salesman_id'] = salesman_id.toString();
        request.fields['q_type'] = "sarf";
        request.fields['cash'] =
            CashController.text == "" ? "0" : CashController.text;
        request.fields['discount'] =
            DiscountController.text == "" ? "0" : DiscountController.text;
        request.fields['notes'] =
            NotesController.text == "" ? "-" : NotesController.text;
        request.fields['q_date'] = actualDate.toString();
        request.fields['q_time'] = actualTime.toString();
        for (int i = 0; i < chk_no_array.length; i++) {
          request.fields['chk_no[$i]'] = chk_no_array[i].toString();
        }
        for (int i = 0; i < value_array.length; i++) {
          request.fields['chk_value[$i]'] = value_array[i].toString();
        }
        for (int i = 0; i < date_array.length; i++) {
          request.fields['chk_date[$i]'] = date_array[i].toString();
        }
        for (int i = 0; i < bank_num_array.length; i++) {
          request.fields['bank_no[$i]'] = bank_num_array[i].toString();
        }
        for (int i = 0; i < bank_num_array.length; i++) {
          request.fields['bank_branch[$i]'] = bank_num_array[i].toString();
        }
        for (int i = 0; i < account_num_array.length; i++) {
          request.fields['account_no[$i]'] = account_num_array[i].toString();
        }
        var response = await request.send();
        response.stream.transform(utf8.decoder).listen((value) async {
          Map valueMap = json.decode(value);
          if (valueMap['message'].toString() ==
              'Catch Receipt created successfully') {
            Navigator.of(context, rootNavigator: true).pop();
            Fluttertoast.showToast(
              msg: "تم اضافة سند الصرف بنجاح",
            );
            Navigator.pop(context);
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
            qType: "sarf",
            isUploaded: 0,
            downloaded: 0,
            cashAmount: double.tryParse(CashController.text) ?? 0.0,
            discount: double.tryParse(DiscountController.text) ?? 0.0,
            totalChecks: double.tryParse(TOTAL.text) ?? 0.0,
            finalTotal: double.tryParse(MAINTOTAL.text) ?? 0.0,
            notes: NotesController.text,
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
            customerID: widget.id,
            customerName: widget.name,
            qType: "sarf",
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

        Navigator.of(context, rootNavigator: true).pop();
        Fluttertoast.showToast(
            msg: "تم حفظ سند الصرف محلياً وسيتم رفعه عند توفر الإنترنت");
        Navigator.pop(context);
      }
    }
  }
}
