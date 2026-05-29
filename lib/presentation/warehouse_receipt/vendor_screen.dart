import 'package:flutter/material.dart';

import '../../core/constants/app_styles.dart';

class VendorScreen extends StatelessWidget {
  const VendorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Download', style: AppStyles.appBarTitle)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, 1),
          child: const Text('Download (Stub)'),
        ),
      ),
    );
  }
}
