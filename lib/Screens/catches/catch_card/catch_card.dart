import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutterBlue;
import 'package:quds_yaghmour/LocalDB/Models/invoice-model.dart';
import 'package:quds_yaghmour/Screens/catch_receipt/catch_receipt.dart';
import 'package:quds_yaghmour/Server/functions/functions.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../customer_details/customer_details.dart';

class CatchCard extends StatefulWidget {
  final name,
      phone,
      chaks,
      discount,
      cash,
      id,
      notes,
      balance,
      printed,
      uniqueID,
      qType,
      lattitude,
      longitude;
  var discoveredDevices;

  CatchCard(
      {Key? key,
      required this.id,
      required this.uniqueID,
      required this.discoveredDevices,
      this.name,
      this.notes,
      this.phone,
      required this.printed,
      required this.qType,
      required this.lattitude,
      required this.longitude,
      required this.balance,
      required this.chaks,
      required this.discount,
      required this.cash})
      : super(key: key);

  @override
  State<CatchCard> createState() => _CatchCardState();
}

class _CatchCardState extends State<CatchCard> {
  @override
  String platform = Platform.isIOS ? "iOS" : "Android";
  double parseValue(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 0.0; // Default to 0.0 if value is null or empty
    }
    try {
      return double.parse(value.toString());
    } catch (e) {
      print('Error parsing value: $value');
      return 0.0; // Default to 0.0 on parse failure
    }
  }

  void _showDeviceSelectionPopup({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) {
    print("1.1");
    if (connectedIOSDevice != null && connectedIOSDevice!.id.id == macAddress) {
      print("1.2");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Already connected to ${connectedIOSDevice!.name}")),
      );
      print("1.3");

      _printInvoice(
          printed: "0",
          macAddress: connectedIOSDevice!.id.id,
          invoiceHeader: invoiceHeader.toString(),
          cashTotal: cashTotal.toString() == "" ? "0" : cashTotal.toString(),
          customerName: widget.name.toString(),
          date: date.toString(),
          time: time.toString(),
          discount: discount.toString() == "" ? "0" : discount.toString(),
          finalTotal: finalTotal.toString(),
          invoiceNumber: invoiceNumber.toString(),
          salesManNumber: salesManNumber.toString(),
          shaksTotal: shaksTotal.toString(),
          licensedOperator: licensedOperator.toString());

      return;
    } else {
      // BEFORE: print("2.1"); print(widget.discoveredDevices); showDialog(...);

// 1) If a spinner or another dialog might be open, close it safely
      Navigator.of(context, rootNavigator: true).maybePop();

// 2) Schedule on the next frame + use the root navigator
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: true,
          builder: (ctx) {
            final devices = widget.discoveredDevices; // or use your state list
            if (devices.isEmpty) {
              return const AlertDialog(
                content: Text("لم يتم العثور على أي طابعة"),
              );
            }
            return AlertDialog(
              title: const Text("Select a Device"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final d = devices[index];
                    final displayName =
                        (d.name.isEmpty) ? "Unnamed Device" : d.name;
                    return ListTile(
                      title: Text(displayName),
                      subtitle: Text(d.id.id),
                      onTap: () {
                        Navigator.of(ctx, rootNavigator: true)
                            .pop(); // close picker

                        _connectToIOSDevice(
                          printed: "0",
                          macAddress: d.id.id, // ✅ use the UUID we tapped
                          invoiceHeader: invoiceHeader,
                          cashTotal: (cashTotal?.toString().isEmpty ?? true)
                              ? "0"
                              : cashTotal.toString(),
                          customerName: widget.name.toString(),
                          date: date.toString(),
                          time: time.toString(),
                          discount: (discount?.toString().isEmpty ?? true)
                              ? "0"
                              : discount.toString(),
                          finalTotal: finalTotal.toString(),
                          invoiceNumber: invoiceNumber.toString(),
                          salesManNumber: salesManNumber.toString(),
                          shaksTotal: shaksTotal.toString(),
                          licensedOperator: licensedOperator.toString(),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      });
    }
  }

  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? macAddressPrinter = prefs.getString('mac_address_printer');
        String? invoiceHeader = prefs.getString('invoice_header');
        int? company_id = prefs.getInt('company_id');
        int? salesman_id = prefs.getInt('salesman_id');
        String? shopNo = prefs.getString('shop_no') ?? "0";
        String? type = prefs.getString('type');
        String? vansaleCanPrint = prefs.getString('vansale_can_print');
        if (vansaleCanPrint.toString() == "true") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('تأكيد', textAlign: TextAlign.right),
                content: Text(
                  'هل تريد طباعة سند القبض؟',
                  textAlign: TextAlign.right,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Action for "No"
                      Navigator.of(context).pop();
                    },
                    child: Text('لا'),
                  ),
                  TextButton(
                    onPressed: () async {
                      var now = DateTime.now();
                      var formatterDate = DateFormat('yy-MM-dd');
                      var formatterTime = DateFormat('kk:mm:ss');
                      String? senderName = prefs.getString('sender_name');
                      String? customerPhone = prefs.getString('phone');
                      String actualDate = formatterDate.format(now);
                      String actualTime = formatterTime.format(now);
                      var totalValue = parseValue(widget.discount) +
                          parseValue(widget.chaks) +
                          parseValue(widget.cash);

                      if (Platform.isIOS) {
                        print("ios");
                        _showDeviceSelectionPopup(
                            printed: "0",
                            macAddress: macAddressPrinter.toString(),
                            invoiceHeader: invoiceHeader.toString(),
                            cashTotal: widget.cash.toString(),
                            customerName: widget.name.toString(),
                            date: actualDate.toString(),
                            time: actualTime.toString(),
                            discount: widget.discount.toString(),
                            finalTotal: totalValue.toString(),
                            invoiceNumber: widget.uniqueID.toString(),
                            salesManNumber: salesman_id.toString(),
                            shaksTotal: widget.chaks.toString(),
                            licensedOperator: shopNo.toString());
                      } else {
                        _printInvoice(
                            macAddress: macAddressPrinter.toString(),
                            invoiceHeader: invoiceHeader.toString(),
                            time: actualTime.toString(),
                            cashTotal: widget.cash.toString(),
                            customerName: widget.name.toString(),
                            date: widget.phone.toString(),
                            discount: widget.discount.toString(),
                            finalTotal: totalValue.toString(),
                            invoiceNumber: widget.uniqueID.toString(),
                            salesManNumber: salesman_id.toString(),
                            shaksTotal: widget.chaks.toString(),
                            licensedOperator: shopNo.toString(),
                            printed: '0');
                      }

                      if (type != "quds") {
                        updateCatchReceiptPrintedValue(widget.uniqueID, "1");
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('نعم'),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Container(
        height: 40,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "${widget.id}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0xffDFDFDF),
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    widget.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.qType.toString() == "qabd" ? true : false,
              child: Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      "${widget.chaks}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "${widget.cash}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    "${widget.discount}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomerDetails(
                                lattitude: widget.lattitude,
                                longitude: widget.longitude,
                                edit: false,
                                balance: widget.balance,
                              )));
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffDFDFDF),
                      border: Border.all(color: Color(0xffD6D3D3))),
                  child: Center(
                    child: Text(
                      widget.phone,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Main_Color),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD6D3D3))),
                child: Center(
                  child: Text(
                    widget.notes,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isProcessing = false;

  // iOS Variables
  flutterBlue.FlutterBlue flutterBlueInstance =
      flutterBlue.FlutterBlue.instance;
  flutterBlue.BluetoothDevice? connectedIOSDevice;

  // Android Variables
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  TextEditingController macController = TextEditingController();

  Future<void> _printInvoice({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String invoiceHeader,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    if (Platform.isIOS) {
      print("1.11");
      if (connectedIOSDevice == null) {
        print("1.12");
        await _connectToIOSDevice(
            macAddress: macAddress,
            cashTotal: cashTotal,
            printed: printed,
            customerName: customerName,
            date: date,
            time: time,
            invoiceHeader: invoiceHeader,
            discount: discount,
            finalTotal: finalTotal,
            invoiceNumber: invoiceNumber,
            salesManNumber: salesManNumber,
            shaksTotal: shaksTotal,
            licensedOperator: licensedOperator);
      }
      print("1.13");

      final invoiceZPL = generateInvoiceZPL(
          cashTotal: cashTotal,
          printed: printed,
          customerName: customerName,
          date: date,
          time: time,
          invoiceHeader: invoiceHeader,
          discount: discount,
          finalTotal: finalTotal,
          invoiceNumber: invoiceNumber,
          salesManNumber: salesManNumber,
          shaksTotal: shaksTotal,
          licensedOperator: licensedOperator);

      try {
        if (connectedIOSDevice != null) {
          List<flutterBlue.BluetoothService> services =
              await connectedIOSDevice!.discoverServices();

          for (var service in services) {
            for (var characteristic in service.characteristics) {
              if (characteristic.properties.write) {
                for (String chunk in _chunkZPL(invoiceZPL, 200)) {
                  await characteristic
                      .write(Uint8List.fromList(utf8.encode(chunk)));
                  await Future.delayed(Duration(milliseconds: 200));
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invoice printed successfully!")),
                  );
                }

                // ✅ Disconnect only after successful printing
                try {
                  await connectedIOSDevice!.disconnect();
                  connectedIOSDevice = null;
                  print("🔌 iOS printer disconnected.");
                } catch (e) {
                  print("❗ Failed to disconnect iOS printer: $e");
                }

                return;
              }
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No writable characteristic found")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No connected iOS printer found")),
            );
          }
        }
      } catch (e) {
        print("e");
        print(e);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error printing invoice: $e")),
          );
        }
      }
    } else {
      await _printInvoiceAndroid(
          macAddress: macAddress,
          cashTotal: cashTotal,
          printed: printed,
          customerName: customerName,
          date: date,
          time: time,
          invoiceHeader: invoiceHeader,
          discount: discount,
          finalTotal: finalTotal,
          invoiceNumber: invoiceNumber,
          salesManNumber: salesManNumber,
          shaksTotal: shaksTotal,
          licensedOperator: licensedOperator);
    }
  }

  // Fetch iOS Devices and Connect
  Future<void> _connectToIOSDevice({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String invoiceHeader,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    if (mounted) {
      setState(() {
        isProcessing = true;
      });
    }

    try {
      // Find the device
      final deviceToConnect = widget.discoveredDevices.firstWhere(
        (device) => device.id.id == macAddress,
        // orElse: () => null, // Prevents exception if device is not found
      );

      if (deviceToConnect == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device not found")),
        );
        return;
      }

      // If the device is already connected, disconnect it first
      if (connectedIOSDevice?.id.id == deviceToConnect.id.id) {
        await connectedIOSDevice?.disconnect();
        connectedIOSDevice = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device disconnected.")),
        );
        return;
      }

      await deviceToConnect.connect();

      connectedIOSDevice = deviceToConnect;

      // Print invoice after successful connection
      _printInvoice(
          printed: "0",
          macAddress: macAddress.toString(),
          invoiceHeader: invoiceHeader.toString(),
          cashTotal: cashTotal.toString() == "" ? "0" : cashTotal.toString(),
          customerName: widget.name.toString(),
          date: date.toString(),
          time: time.toString(),
          discount: discount.toString() == "" ? "0" : discount.toString(),
          finalTotal: finalTotal.toString(),
          invoiceNumber: invoiceNumber.toString(),
          salesManNumber: salesManNumber.toString(),
          shaksTotal: shaksTotal.toString(),
          licensedOperator: licensedOperator.toString());
    } catch (e) {
      print("error");
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to device: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _connectToAndroidDevice(String macAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? macAddressPrinter = prefs.getString('mac_address_printer');

    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      isProcessing = true;
    });

    try {
      // If permissions are granted, proceed to get the bonded devices
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      // Look for the device with the matching MAC address
      BluetoothDevice? targetDevice = devices.firstWhere(
        (d) => d.address == macAddress,
        orElse: () => BluetoothDevice("hazem", macAddressPrinter),
      );
      if (targetDevice != null) {
        print("1");
        await bluetooth.connect(targetDevice);
        if (!mounted) return; // Ensure the widget is still in the tree
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Connected to ${targetDevice.name}")),
        // );
      } else {
        if (!mounted) return; // Ensure the widget is still in the tree
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("No device with MAC address $macAddress")),
        // );
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Error connecting to device: $e")),
        // );
      }
    } finally {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _disconnectFromAndroidDevice() async {
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      isProcessing = true;
    });

    try {
      // Explicitly check if the device is connected
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected!) {
        await bluetooth.disconnect();
        if (!mounted) return; // Ensure the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device disconnected successfully")),
        );
      } else {
        if (!mounted) return; // Ensure the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No device is currently connected")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error disconnecting from device: $e")),
        );
      }
    } finally {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _printInvoiceAndroid({
    required String macAddress,
    required String invoiceNumber,
    required String licensedOperator,
    required String date,
    required String time,
    required String printed,
    required String customerName,
    required String invoiceHeader,
    required String salesManNumber,
    required String discount,
    required String shaksTotal,
    required String cashTotal,
    required String finalTotal,
  }) async {
    await _connectToAndroidDevice(macAddress);

    final invoiceZPL = generateInvoiceZPL(
      invoiceNumber: invoiceNumber,
      printed: printed,
      licensedOperator: licensedOperator,
      invoiceHeader: invoiceHeader,
      date: date,
      time: time,
      customerName: customerName,
      cashTotal: cashTotal,
      salesManNumber: salesManNumber,
      shaksTotal: shaksTotal,
      discount: discount,
      finalTotal: finalTotal,
    );

    try {
      bluetooth.write(invoiceZPL); // Pass the string directly
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Invoice printed successfully!")),
      // );
      await _disconnectFromAndroidDevice();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error printing invoice: $e")),
      );
      await _disconnectFromAndroidDevice();
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
