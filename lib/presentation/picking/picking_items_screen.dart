import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../providers/picking_provider.dart';
import '../../l10n/strings_en.dart';

class PickingItemsScreen extends StatefulWidget {
  final String pickNo;
  final int tenantId;
  final String company;

  const PickingItemsScreen({
    Key? key,
    required this.pickNo,
    required this.tenantId,
    this.company = '',
  }) : super(key: key);

  @override
  State<PickingItemsScreen> createState() => _PickingItemsScreenState();
}

class _PickingItemsScreenState extends State<PickingItemsScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<PickingProvider>();
    try {
      await provider.selectPickingList(widget.pickNo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading picking items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final provider = context.read<PickingProvider>();
    final lines = provider.currentPickingLines;
    if (index >= lines.length) return;

    final line = lines[index];

    // Navigate to details
    if (mounted) {
      context.push(
        RouteNames.pickingDetail,
        extra: {
          'pickNo': widget.pickNo,
          'pickingLine': line,
          'currentIndex': index,
          'tenantId': widget.tenantId,
          'company': widget.company,
        },
      );
    }
  }

  String _getStatusLabel(double actualQty, double pickQty) {
    if (actualQty == 0) {
      return '未対応';
    } else if (actualQty < pickQty) {
      return '一部対応';
    } else {
      return '完了';
    }
  }

  Color _getStatusColor(double actualQty, double pickQty) {
    if (actualQty == 0) {
      return AppColors.black;
    } else if (actualQty < pickQty) {
      return AppColors.text_warning;
    } else {
      return AppColors.greenDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ピッキング明細${widget.company.isNotEmpty ? ' (${widget.company})' : ''}'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<PickingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_1.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            );
          }

          final lines = provider.currentPickingLines;
          if (lines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No picking items found',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isSelected = _selectedIndex == index;
              final statusLabel = _getStatusLabel(
                line.actualQty ?? 0.0,
                line.pickQty,
              );
              final statusColor = _getStatusColor(
                line.actualQty ?? 0.0,
                line.pickQty,
              );

              return InkWell(
                onTap: () => _handleItemTap(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.headerColor
                        : Colors.white,
                    border: Border.all(
                      color: AppColors.borderTable,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bin
                        Row(
                          children: [
                            const Text(
                              '棚: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'MSPGothic',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line.bin ?? '(No bin)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'MSPGothic',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Product
                        Row(
                          children: [
                            const Text(
                              '商品： ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'MSPGothic',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line.productName ?? line.productCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'MSPGothic',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quantity
                        Row(
                          children: [
                            const Text(
                              '数量: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'MSPGothic',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${line.actualQty ?? 0} / ${line.pickQty}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'MSPGothic',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Status
                        Row(
                          children: [
                            const Text(
                              '状態: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'MSPGothic',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'MSPGothic',
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

