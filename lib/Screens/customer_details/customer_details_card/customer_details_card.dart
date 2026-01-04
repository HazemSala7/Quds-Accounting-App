import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';

class CustomerDetailsCard extends StatefulWidget {
  final name;
  IconData my_icon;
  Function navi;
  CustomerDetailsCard({
    Key? key,
    required this.navi,
    required this.my_icon,
    required this.name,
  }) : super(key: key);

  @override
  State<CustomerDetailsCard> createState() => CcustomerDetailsCardState();
}

class CcustomerDetailsCardState extends State<CustomerDetailsCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.navi();
      },
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 7,
                blurRadius: 5,
              ),
            ],
            gradient: LinearGradient(colors: [
              Color.fromRGBO(83, 89, 219, 1),
              Color.fromRGBO(32, 39, 160, 0.6),
            ]),
            borderRadius: BorderRadius.circular(10)),
        height: 100,
        width: 170,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                widget.my_icon,
                color: Colors.white,
                size: 30,
              ),
              Text(
                widget.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
