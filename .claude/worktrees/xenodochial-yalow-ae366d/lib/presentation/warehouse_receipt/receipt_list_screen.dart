import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import '../widgets/custom_button.dart';
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
      backgroundColor: AppColors.lighter,
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
                CustomButton(
                  text: 'Main',
                  type: ButtonType.danger,
                  size: ButtonSize.small,
                  onPressed: () => context.go(RouteNames.mainMenu),
                ),
                CustomButton(
                  text: 'F5',
                  type: ButtonType.secondary,
                  size: ButtonSize.small,
                  icon: Icons.refresh,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refresh (F5)')),
                    );
                  },
                ),
                CustomButton(
                  text: 'Sync',
                  type: ButtonType.secondary,
                  size: ButtonSize.small,
                  icon: Icons.sync,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sync')),
                    );
                  },
                ),
                CustomButton(
                  text: 'DL',
                  type: ButtonType.success,
                  size: ButtonSize.small,
                  icon: Icons.download,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorScreen()),
                    );
                    if (result == 1) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Reload after Vendor download')),
                      );
                    }
                  },
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
                  tileColor: selected ? AppColors.menuTileColors[0].withValues(alpha: 0.15) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
