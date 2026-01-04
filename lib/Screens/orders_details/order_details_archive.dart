import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  OrderDetailsPage({required this.orderId});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Database? db;
  List<Map<String, dynamic>> orderItems = [];

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
  }

  Future<void> fetchOrderItems() async {
    final data = await db?.query(
          'order_items_archive',
          where: 'order_id = ?',
          whereArgs: [widget.orderId],
        ) ??
        [];
    setState(() {
      orderItems = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order #${widget.orderId} Details")),
      body: ListView.builder(
        itemCount: orderItems.length,
        itemBuilder: (context, index) {
          final item = orderItems[index];
          return ListTile(
            title: Text("${item['product_name']}",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Qty: ${item['quantity']} x ${item['price']}"),
            trailing: Text("Total: ${item['total']}",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
