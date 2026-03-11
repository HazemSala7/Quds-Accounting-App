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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: () {
          widget.navi();
        },
        splashColor: Color(0xFF5359DB).withOpacity(0.15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? Color(0xFF5359DB).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF5359DB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: Color(0xFF5359DB),
                    size: 20,
                  ),
                  child: widget.myicon,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _hovering ? Color(0xFF5359DB) : Color(0xFF333333),
                    letterSpacing: -0.2,
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
