import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsCard extends StatefulWidget {
  bool status;
  final name;
  Function Status;
  final IconData? icon;
  SettingsCard(
      {Key? key, this.name, required this.status, required this.Status, this.icon})
      : super(key: key);

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (widget.icon != null)
                  Icon(widget.icon, color: Color(0xff34568B), size: 22),
                if (widget.icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FlutterSwitch(
            activeColor: Colors.green,
            width: 60.0,
            height: 30.0,
            valueFontSize: 25.0,
            toggleSize: 27.0,
            value: widget.status,
            borderRadius: 30.0,
            padding: 3.0,
            onToggle: (val) {
              widget.Status();
            },
          ),
        ],
      ),
    );
  }
}
