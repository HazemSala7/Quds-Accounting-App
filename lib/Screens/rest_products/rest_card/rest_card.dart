import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';

import '../../customer_details/customer_details.dart';

class RestCard extends StatefulWidget {
  final name;
  var sold_qty, rest_qty, id;
  RestCard({
    Key? key,
    required this.id,
    this.name,
    this.rest_qty,
    this.sold_qty,
  }) : super(key: key);

  @override
  State<RestCard> createState() => _RestCardState();
}

class _RestCardState extends State<RestCard> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.sold_qty == 0 && widget.rest_qty == 0 ? false : true,
      child: Container(
        height: 40,
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
                flex: 3,
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
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      "${widget.rest_qty}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => CustomerDetails()));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xffDFDFDF),
                        border: Border.all(color: Color(0xffD6D3D3))),
                    child: Center(
                      child: Text(
                        "${widget.sold_qty}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Main_Color),
                      ),
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
