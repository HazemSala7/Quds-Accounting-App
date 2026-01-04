import 'package:flutter/material.dart';

class DrawerCard extends StatefulWidget {
  Function navi;
  Icon myicon;
  final name;
  DrawerCard({
    Key? key,
    required this.navi,
    required this.name,
    required this.myicon,
  }) : super(key: key);

  @override
  State<DrawerCard> createState() => _DrawerCardState();
}

class _DrawerCardState extends State<DrawerCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.navi();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 13),
        child: Row(
          children: [
            SizedBox(width: 20),
            widget.myicon,
            SizedBox(
              width: 20,
            ),
            Text(
              widget.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
