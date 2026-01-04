import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';

import '../../customer_details/customer_details.dart';

class InvoiceDetailsCard extends StatefulWidget {
  final total, name, ponus, price, discount;
  InvoiceDetailsCard(
      {Key? key, this.total, this.name, this.ponus, this.price, this.discount})
      : super(key: key);

  @override
  State<InvoiceDetailsCard> createState() => _InvoiceDetailsCardState();
}

class _InvoiceDetailsCardState extends State<InvoiceDetailsCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 15),
      child: Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      widget.total,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      widget.name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      widget.ponus,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      widget.discount,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: InkWell(
                      onTap: () {},
                      child: Text(
                        widget.price,
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
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: double.infinity,
                height: 2,
                color: Color(0xffD6D3D3),
              ),
            )
          ],
        ),
      ),
    );
  }
}
