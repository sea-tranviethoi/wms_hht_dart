import 'package:flutter/material.dart';

class VendorScreen extends StatelessWidget {
  const VendorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Download')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, 1),
          child: const Text('Download (Stub)'),
        ),
      ),
    );
  }
}
