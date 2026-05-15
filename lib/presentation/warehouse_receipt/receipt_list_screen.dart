import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import 'vendor_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  int? _selectedIndex;
  final List<Map<String, String>> _wrList = [
    {'wr': 'WR001', 'vendor': 'Vendor A'},
    {'wr': 'WR002', 'vendor': 'Vendor B'},
    {'wr': 'WR003', 'vendor': 'Vendor C'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Warehouse Receipt List'),
        backgroundColor: AppColors.headerColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => context.go(RouteNames.mainMenu),
                  child: const Text('Main'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // F5/Refresh logic placeholder
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refresh (F5)')));
                  },
                  child: const Text('F5'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Sync logic placeholder
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync')));
                  },
                  child: const Text('Sync'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorScreen()),
                    );
                    if (result == 1) {
                      // Reload data if Vendor download returns 1
                      messenger.showSnackBar(const SnackBar(content: Text('Reload after Vendor download')));
                    }
                  },
                  child: const Text('DL'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _wrList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final wr = _wrList[index];
                final selected = _selectedIndex == index;
                return ListTile(
                  title: Text('WR: ${wr['wr']}'),
                  subtitle: Text('Vendor: ${wr['vendor']}'),
                  selected: selected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                  tileColor: selected ? AppColors.menuColors[0].withValues(alpha: 0.15) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
