import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/history-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../customer_details/customer_details.dart';

class CustomerCard extends StatefulWidget {
  final name, phone, price_code, id, balance, cash, lattitude, longitude, area;
  int index;
  CustomerCard(
      {Key? key,
      required this.id,
      required this.index,
      required this.lattitude,
      required this.longitude,
      required this.cash,
      required this.balance,
      required this.area,
      this.name,
      this.price_code,
      this.phone})
      : super(key: key);

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('price_code', widget.price_code.toString());
        await prefs.setString('cash', widget.cash.toString());
        await prefs.setString('phone', widget.phone.toString());
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CustomerDetails(
                      lattitude: widget.lattitude,
                      longitude: widget.longitude,
                      edit:
                          widget.name.toString() == "زبون جديد" ? true : false,
                      balance: widget.balance,
                      id: widget.id,
                      name: widget.name,
                    )));
        if (isOnline) {
          print("here");
          addHistory(widget.id, "0");
        } else {
          final now = DateTime.now();
          final formatter = DateFormat('dd-MM-yyyy hh:mm a', 'en');
          HistoryModel newhistoryRecord = HistoryModel(
            created_at: formatter.format(now),
            customer_id: widget.id,
            h_code: "0",
            lattitude: "",
            longitude: "",
          );

          await CartDatabaseHelper().insertHistory(newhistoryRecord);
        }
      },
      child: Container(
        height: 40,
        color: widget.index % 2 == 0 ? Colors.white : Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(right: 15, left: 15),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      "${widget.id}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffDFDFDF),
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      widget.name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      widget.phone,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Main_Color),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      widget.area,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Main_Color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
