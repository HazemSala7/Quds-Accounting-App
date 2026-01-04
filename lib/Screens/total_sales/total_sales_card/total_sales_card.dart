import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import '../../customer_details/customer_details.dart';

class TotalSalesCard extends StatefulWidget {
  var cash, rece, discount, total;
  TotalSalesCard({Key? key, this.cash, this.discount, this.rece, this.total})
      : super(key: key);

  @override
  State<TotalSalesCard> createState() => _TotalSalesCardState();
}

class _TotalSalesCardState extends State<TotalSalesCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, left: 15),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "₪${widget.total}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0xffDFDFDF),
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "₪${widget.cash}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "₪${widget.rece}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0xffDFDFDF),
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "${widget.discount}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Main_Color),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
