import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quds_yaghmour/LocalDB/DataBase/DataBase.dart';
import 'package:quds_yaghmour/LocalDB/Models/catch-model.dart';
import 'package:quds_yaghmour/LocalDB/Models/maxFatoraNumber-model.dart';
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/Services/data_downloader/data_downloader.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBarMain extends StatefulWidget {
  const AppBarMain({Key? key}) : super(key: key);

  @override
  State<AppBarMain> createState() => _AppBarMainState();
}

class _AppBarMainState extends State<AppBarMain> {
  @override
  String type = "";
  initiatePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _type = prefs.getString('type') ?? "quds";

    setState(() {
      type = _type;
    });
  }

  @override
  void initState() {
    initiatePrefs();
    super.initState();
  }

  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Color.fromRGBO(83, 89, 219, 1),
          Color.fromRGBO(32, 39, 160, 0.6),
        ])),
      ),
      title: Text(
        type.toString() == "quds" ? "القدس موبايل" : "القدس موبايل Vansale",
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
      ),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: Icon(Icons.menu),
        iconSize: 25,
      ),
    );
  }
}
