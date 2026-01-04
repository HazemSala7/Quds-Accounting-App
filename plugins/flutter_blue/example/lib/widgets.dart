// Copyright 2017, Paul DeMarco.
// BSD-style license.

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({
    Key? key,
    required this.result,
    this.onTap,
  }) : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(result.device.name, overflow: TextOverflow.ellipsis),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _hex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: ElevatedButton(
        onPressed: result.advertisementData.connectable ? onTap : null,
        child: const Text('CONNECT'),
      ),
      children: <Widget>[
        _buildAdvRow(context, 'Local Name', result.advertisementData.localName),
        _buildAdvRow(
          context,
          'TX Power',
          result.advertisementData.txPowerLevel?.toString() ?? 'N/A',
        ),
        _buildAdvRow(
          context,
          'Manufacturer',
          result.advertisementData.manufacturerData.entries
              .map((e) => '${e.key}: ${_hex(e.value)}')
              .join(', '),
        ),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    Key? key,
    required this.service,
    required this.characteristicTiles,
  }) : super(key: key);

  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Service ${service.uuid.toString().substring(4, 8)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: characteristicTiles,
    );
  }
}

class CharacteristicTile extends StatelessWidget {
  const CharacteristicTile({
    Key? key,
    required this.characteristic,
    required this.descriptorTiles,
    this.onReadPressed,
    this.onWritePressed,
    this.onNotificationPressed,
  }) : super(key: key);

  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Characteristic ${characteristic.uuid.toString().substring(4, 8)}',
      ),
      subtitle: Text(characteristic.value.toString()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
              icon: const Icon(Icons.download), onPressed: onReadPressed),
          IconButton(icon: const Icon(Icons.upload), onPressed: onWritePressed),
          IconButton(
            icon: Icon(
              characteristic.isNotifying ? Icons.sync_disabled : Icons.sync,
            ),
            onPressed: onNotificationPressed,
          ),
        ],
      ),
      children: descriptorTiles,
    );
  }
}

class DescriptorTile extends StatelessWidget {
  const DescriptorTile({
    Key? key,
    required this.descriptor,
    this.onReadPressed,
    this.onWritePressed,
  }) : super(key: key);

  final BluetoothDescriptor descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Descriptor ${descriptor.uuid.toString().substring(4, 8)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
              icon: const Icon(Icons.download), onPressed: onReadPressed),
          IconButton(icon: const Icon(Icons.upload), onPressed: onWritePressed),
        ],
      ),
    );
  }
}
