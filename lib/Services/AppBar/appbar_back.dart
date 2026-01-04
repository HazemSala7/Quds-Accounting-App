import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/main.dart';

class AppBarBack extends StatefulWidget {
  final title;
  const AppBarBack({Key? key, required this.title}) : super(key: key);

  @override
  State<AppBarBack> createState() => _AppBarBackState();
}

class _AppBarBackState extends State<AppBarBack> {
  @override
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
        widget.title,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
      ),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context, true); // true means the page should refresh
        },
        icon: Icon(Icons.arrow_back),
        iconSize: 25,
      ),
    );
  }
}
