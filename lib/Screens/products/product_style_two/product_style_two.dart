import 'package:flutter/material.dart';

class ProductStyleTwo extends StatefulWidget {
  final String name;
  final String image;
  final double price;
  final int qty;
  final int bonus;

  const ProductStyleTwo({
    Key? key,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
    required this.bonus,
  }) : super(key: key);

  @override
  State<ProductStyleTwo> createState() => _ProductStyleTwoState();
}

class _ProductStyleTwoState extends State<ProductStyleTwo> {
  late TextEditingController priceController;
  late TextEditingController qtyController;
  late TextEditingController bonusController;

  double total = 0;

  @override
  void initState() {
    super.initState();
    priceController =
        TextEditingController(text: widget.price.toStringAsFixed(1));
    qtyController = TextEditingController(text: widget.qty.toString());
    bonusController = TextEditingController(text: widget.bonus.toString());
    calculateTotal();
  }

  void calculateTotal() {
    double price = double.tryParse(priceController.text) ?? 0;
    int qty = int.tryParse(qtyController.text) ?? 0;
    int bonus = int.tryParse(bonusController.text) ?? 0;

    setState(() {
      total = (price * qty) + bonus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Text("الاسم", textAlign: TextAlign.center),
                Text("السعر", textAlign: TextAlign.center),
                Text("الكمية", textAlign: TextAlign.center),
                Text("البونص", textAlign: TextAlign.center),
                Text("المجموع", textAlign: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(widget.name, textAlign: TextAlign.center),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  onChanged: (_) => calculateTotal(),
                ),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => calculateTotal(),
                ),
                TextField(
                  controller: bonusController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) => calculateTotal(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(total.toStringAsFixed(1),
                      textAlign: TextAlign.center),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
