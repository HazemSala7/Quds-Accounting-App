import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'testprint.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final TestPrint testPrint = TestPrint();

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> bondedDevices = [];

    try {
      bondedDevices = await bluetooth.getBondedDevices();
    } on PlatformException {}

    bluetooth.onStateChanged().listen((state) {
      if (!mounted) return;
      setState(() {
        connected = state == BlueThermalPrinter.CONNECTED;
      });
    });

    if (!mounted) return;
    setState(() {
      devices = bondedDevices;
      connected = isConnected ?? false;
    });
  }

  void connect() {
    if (selectedDevice == null) {
      showMessage('No device selected');
      return;
    }

    bluetooth.isConnected.then((isConnected) {
      if (isConnected != true) {
        bluetooth.connect(selectedDevice!).catchError((_) {
          setState(() => connected = false);
        });
      }
    });
  }

  void disconnect() {
    bluetooth.disconnect();
    setState(() => connected = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> getDeviceItems() {
    if (devices.isEmpty) {
      return [
        DropdownMenuItem(
          child: Text('No devices'),
        )
      ];
    }

    return devices.map((d) {
      return DropdownMenuItem(
        value: d,
        child: Text(d.name ?? d.address ?? ''),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Blue Thermal Printer'),
          backgroundColor: Colors.brown,
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('Select Printer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButton<BluetoothDevice>(
                isExpanded: true,
                items: getDeviceItems(),
                value: selectedDevice,
                onChanged: (v) => setState(() => selectedDevice = v),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: initBluetooth,
                    child: Text('Refresh'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: connected ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: connected ? disconnect : connect,
                    child: Text(connected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (!connected) {
                    showMessage('Printer not connected');
                    return;
                  }
                  testPrint.sample();
                },
                child: Text('PRINT TEST', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
