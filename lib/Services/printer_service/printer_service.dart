import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';

class BluetoothPrinterService {
  final FlutterBlue flutterBlueInstance = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> discoveredDevices = [];

  Future<void> checkBluetoothStatusAndScan({
    required BuildContext context,
    required String macAddress,
    required String Function() generateZPL, // Function to generate custom ZPL
  }) async {
    print("1.1");
    bool isProcessing = true;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      print("1.2");
      bool isBluetoothOn = await flutterBlueInstance.isOn;
      if (!isBluetoothOn) {
        print("1.3");
        Fluttertoast.showToast(msg: "Please enable Bluetooth.");
        isProcessing = false;
        return;
      }
      print("1.4");
    } else {
      print("1.5");
      BluetoothState state = await flutterBlueInstance.state.first;
      if (state != BluetoothState.on) {
        print("1.6");
        Fluttertoast.showToast(msg: "Please enable Bluetooth.");
        isProcessing = false;
        return;
      }
    }
    print("1.7");

    // Scan for devices and show the selection popup
    await _scanForDevices(
        context: context, macAddress: macAddress, generateZPL: generateZPL);
    print("1.8");
  }

  Future<void> _scanForDevices({
    required BuildContext context,
    required String macAddress,
    required String Function() generateZPL,
  }) async {
    print("1.9");
    discoveredDevices.clear();
    flutterBlueInstance.startScan(timeout: const Duration(seconds: 5));
    print("1.10");
    await for (var result in flutterBlueInstance.scanResults) {
      for (var device in result) {
        // if (!discoveredDevices.any((d) => d.id.id == device.device.id.id)) {
        discoveredDevices.add(device.device);
        // }
      }
    }
    print("1.11");
    flutterBlueInstance.stopScan();
    print("1.12");
    print("discoveredDevices");
    print(discoveredDevices);
    if (discoveredDevices.isNotEmpty) {
      _showDeviceSelectionPopup(
        context: context,
        macAddress: macAddress,
        generateZPL: generateZPL,
      );
    } else {
      Fluttertoast.showToast(msg: "No devices found.");
    }
  }

  void _showDeviceSelectionPopup({
    required BuildContext context,
    required String macAddress,
    required String Function() generateZPL,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select a Device"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = discoveredDevices[index];
                return ListTile(
                  title: Text(
                      device.name.isEmpty ? "Unnamed Device" : device.name),
                  subtitle: Text(device.id.id),
                  onTap: () {
                    Navigator.of(context).pop();
                    _connectToDevice(device: device, generateZPL: generateZPL);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice({
    required BluetoothDevice device,
    required String Function() generateZPL,
  }) async {
    try {
      await device.connect();
      connectedDevice = device;
      await _printZPL(generateZPL());
    } catch (e) {
      Fluttertoast.showToast(msg: "Error connecting to device: $e");
    } finally {
      await device.disconnect();
      connectedDevice = null;
    }
  }

  Future<void> _printZPL(String zpl) async {
    if (connectedDevice == null) return;

    try {
      List<BluetoothService> services =
          await connectedDevice!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            for (String chunk in _chunkZPL(zpl, 200)) {
              await characteristic
                  .write(Uint8List.fromList(utf8.encode(chunk)));
              await Future.delayed(const Duration(milliseconds: 200));
            }
            Fluttertoast.showToast(msg: "Invoice printed successfully!");
            return;
          }
        }
      }
      Fluttertoast.showToast(msg: "No writable characteristic found.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error printing invoice: $e");
    }
  }

  List<String> _chunkZPL(String zpl, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < zpl.length; i += chunkSize) {
      chunks.add(zpl.substring(
          i, i + chunkSize > zpl.length ? zpl.length : i + chunkSize));
    }
    return chunks;
  }
}
