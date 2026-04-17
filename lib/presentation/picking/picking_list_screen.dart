import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../routes/route_names.dart';
import '../providers/picking_provider.dart';
import '../../l10n/app_strings.dart';
import '../widgets/loading_indicator.dart';

class PickingListScreen extends StatefulWidget {
  final int tenantId;
  final String company;

  const PickingListScreen({
    Key? key,
    required this.tenantId,
    this.company = '',
  }) : super(key: key);

  @override
  State<PickingListScreen> createState() => _PickingListScreenState();
}

class _PickingListScreenState extends State<PickingListScreen> {
  final TextEditingController _searchController = TextEditingController();
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
      await provider.initialize();
      await provider.fetchPickingData(widget.tenantId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading picking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSearch(String keyword) async {
    final provider = context.read<PickingProvider>();
    await provider.searchPickingLists(keyword);
  }

  void _handleRowTap(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    final provider = context.read<PickingProvider>();
    final tableData = provider.tableData;
    if (index >= tableData.length) return;

    final rowData = tableData[index];
    final pickNo = rowData[0].toString();

    // Check if handled by other device
    final isHandledByOther = await provider.checkPickingListStatus(pickNo);
    if (isHandledByOther) {
      final hhtInfo = rowData[3].toString();
      final otherUser = hhtInfo.split('-').first;
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: Text(
              '他のデバイスは{$pickNo}を対応してます。ご確認ください。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Navigate to items
    await provider.selectPickingList(pickNo);
    if (mounted) {
      context.push(
        RouteNames.pickingItems,
        extra: {'pickNo': pickNo, 'tenantId': widget.tenantId, 'company': widget.company},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ピッキング一覧${widget.company.isNotEmpty ? ' (${widget.company})' : ''}'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('${RouteNames.tenantSelection}?funcNumber=3'),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'フィルターする内容を入力してください。',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.lighter, width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.lighter, width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryLight,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: _handleSearch,
              onChanged: (value) {
                setState(() {}); // Update to show/hide clear button
              },
            ),
          ),

          // Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.borderTable, width: 1),
                top: BorderSide(color: AppColors.borderTable, width: 1),
                left: BorderSide(color: AppColors.borderTable, width: 1),
                right: BorderSide(color: AppColors.borderTable, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: AppColors.borderTable,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'ピッキング番号',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'MSPGothic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      '棚数',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'MSPGothic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Picking list
          Expanded(
            child: Consumer<PickingProvider>(
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

                if (provider.tableData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No picking lists found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (provider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Error: ${provider.errorMessage}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
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
                  itemCount: provider.tableData.length,
                  itemBuilder: (context, index) {
                    final rowData = provider.tableData[index];
                    final isSelected = _selectedIndex == index;
                    final scanStatus = rowData[2] as int;
                    final pickNo = rowData[0].toString();
                    final binCount = rowData[1] as int;

                    Color textColor = AppColors.black;
                    Widget? leadingIcon;

                    if (scanStatus == 1) {
                      // Scanned - Orange
                      textColor = AppColors.text_warning;
                      leadingIcon = IconButton(
                        icon: const Icon(Icons.refresh),
                        color: AppColors.blackText,
                        iconSize: 35,
                        onPressed: () {
                          // TODO: Implement reset
                        },
                      );
                    } else if (scanStatus == 2) {
                      // Handled by other - Grey
                      textColor = AppColors.text_placeholder;
                      leadingIcon = IconButton(
                        icon: const Icon(Icons.construction),
                        color: AppColors.blackText,
                        iconSize: 35,
                        onPressed: () {
                          final hhtInfo = rowData[3].toString();
                          final otherUser = hhtInfo.split('-').first;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Notification'),
                              content: Text(
                                'ユーザー「$otherUser」は別デバイスで $pickNo を対応してます。ご確認ください。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return InkWell(
                      onTap: () => _handleRowTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.headerColor
                              : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.borderTable,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Picking Number
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: scanStatus != 0 ? 0 : 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: AppColors.borderTable,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (scanStatus != 0)
                                      Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.only(
                                          right: 0,
                                          top: 8,
                                        ),
                                        child: leadingIcon ?? const SizedBox(),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          pickNo,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'MSPGothic',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bin Count
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: 8,
                                  right: 4,
                                ),
                                child: Text(
                                  binCount.toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontFamily: 'MSPGothic',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(top: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('${RouteNames.tenantSelection}?funcNumber=3'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btn_red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Builder(
                      builder: (context) {
                        final strings = AppStrings.of(context);
                        return Text(
                          strings.back,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

