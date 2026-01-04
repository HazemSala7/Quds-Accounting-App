import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'widgets.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (context, snapshot) {
          if (snapshot.data == BluetoothState.on) {
            return const FindDevicesScreen();
          }
          return BluetoothOffScreen(state: snapshot.data);
        },
      ),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Bluetooth is ${state.toString().split('.').last}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Devices')),
      body: StreamBuilder<List<ScanResult>>(
        stream: FlutterBlue.instance.scanResults,
        initialData: const [],
        builder: (c, snapshot) {
          return ListView(
            children: snapshot.data!
                .map(
                  (r) => ScanResultTile(
                    result: r,
                    onTap: () {
                      r.device.connect();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceScreen(device: r.device),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () =>
            FlutterBlue.instance.startScan(timeout: const Duration(seconds: 4)),
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  List<int> _randomBytes() {
    final r = Random();
    return List<int>.generate(4, (_) => r.nextInt(255));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: StreamBuilder<List<BluetoothService>>(
        stream: device.services,
        initialData: const [],
        builder: (c, snapshot) {
          return ListView(
            children: snapshot.data!
                .map(
                  (s) => ServiceTile(
                    service: s,
                    characteristicTiles: s.characteristics
                        .map(
                          (c) => CharacteristicTile(
                            characteristic: c,
                            descriptorTiles: c.descriptors
                                .map(
                                  (d) => DescriptorTile(
                                    descriptor: d,
                                    onReadPressed: d.read,
                                    onWritePressed: () =>
                                        d.write(_randomBytes()),
                                  ),
                                )
                                .toList(),
                            onReadPressed: c.read,
                            onWritePressed: () =>
                                c.write(_randomBytes(), withoutResponse: true),
                            onNotificationPressed: () =>
                                c.setNotifyValue(!c.isNotifying),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
