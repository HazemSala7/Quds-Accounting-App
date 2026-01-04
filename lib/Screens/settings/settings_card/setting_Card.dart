import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:flutter_switch/flutter_switch.dart';

class SettingsCard extends StatefulWidget {
  bool status;
  final name;
  Function Status;
  SettingsCard(
      {Key? key, this.name, required this.status, required this.Status})
      : super(key: key);

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            // showOnOff: true,
            onToggle: (val) {
              widget.Status();
            },
          ),
        ],
      ),
    );
  }
}
