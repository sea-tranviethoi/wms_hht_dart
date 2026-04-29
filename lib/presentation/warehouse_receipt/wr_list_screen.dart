import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme_config.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/wr/wr_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 入荷一覧 — BLoC version (Phase 4)
class WRListScreen extends StatelessWidget {
  final int tenantId;
  final String company;

  const WRListScreen({
    super.key,
    this.tenantId = 0,
    this.company = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WRBloc(remote: sl<WRRemoteDataSource>()),
      child: _WRListView(tenantId: tenantId, company: company),
    );
  }
}

class _WRListView extends StatefulWidget {
  final int tenantId;
  final String company;

  const _WRListView({required this.tenantId, required this.company});

  @override
  State<_WRListView> createState() => _WRListViewState();
}

class _WRListViewState extends State<_WRListView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedIndex;
  Map<String, dynamic>? _filters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _loadData() {
    final hhtInfo = sl<CacheStorage>().getString('hhtInfo') ?? '';
    context.read<WRBloc>().add(FetchWRLists(
          hhtInfo: hhtInfo,
          tenantId: widget.tenantId,
          vendorId: _filters?['vendorId']?.toString(),
          productCode: _filters?['productCode']?.toString(),
          productName: _filters?['productName']?.toString(),
          janCode: _filters?['janCode']?.toString(),
          arrivalNumber: _filters?['arrivalNumber']?.toString(),
        ));
  }

  void _handleSearch(String keyword) {
    context.read<WRBloc>().add(SearchWRLists(keyword));
  }

  void _handleRowTap(BuildContext context, int index, WRRow row) {
    if (row.scanStatus == 3) {
      final otherUser = row.hhtInfoOther?.split('-').first ?? '他のユーザー';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notification'),
          content: Text(
            'ユーザー「$otherUser」は別デバイスで ${row.receiptNo} を対応してます。ご確認ください。',
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
      return;
    }

    setState(() => _selectedIndex = index);

    context.push(
      RouteNames.warehouseReceiptDetail,
      extra: {
        'receiptNo': row.receiptNo,
        'supplierName': row.supplierName,
        'tenantId': widget.tenantId,
      },
    );
  }

  Future<void> _handleReset(WRRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認'),
        content: Text('入荷番号: ${row.receiptNo}\nスキャンデータをリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('はい'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<WRBloc>().add(ResetWRStatus(row));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('入荷一覧'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.mainMenu),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: BlocListener<WRBloc, WRState>(
        listener: (context, state) {
          if (state is WRError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is WRResetDone) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('リセットが完了しました'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'フィルターする内容を入力してください。',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (_, value, __) => value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.lighter, width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.lighter, width: 2),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.primaryLight, width: 2),
                  ),
                ),
                onChanged: _handleSearch,
              ),
            ),

            // Table header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderTable),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppColors.borderTable),
                        ),
                      ),
                      child: Text(
                        '入荷番号',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
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
                      child: Text(
                        '仕入先名',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          fontFamily: 'MSPGothic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Receipt list
            Expanded(
              child: BlocBuilder<WRBloc, WRState>(
                builder: (context, state) {
                  if (state is WRLoading || state is WRResetting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is WRError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    );
                  }

                  final rows = state is WRListsLoaded
                      ? state.rows
                      : <WRRow>[];

                  if (rows.isEmpty && state is WRListsLoaded) {
                    return const Center(
                      child: Text(
                        '入荷データがありません',
                        style: TextStyle(fontFamily: 'MSPGothic'),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) => _WRRowTile(
                      row: rows[index],
                      isSelected: _selectedIndex == index,
                      onTap: () => _handleRowTap(context, index, rows[index]),
                      onReset: () => _handleReset(rows[index]),
                    ),
                  );
                },
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(top: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Row(
                children: [
                  // 戻る
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go(RouteNames.mainMenu),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.btn_red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('戻る',
                          style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 絞り込み (Filter)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result =
                            await context.push<Map<String, dynamic>>(
                          RouteNames.warehouseReceiptFilter,
                          extra: {
                            'tenantId': widget.tenantId,
                            'company': widget.company,
                          },
                        );
                        if (result != null && mounted) {
                          setState(() => _filters = result);
                          _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('絞り込み',
                          style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Row tile ──────────────────────────────────────────────────────────────────

class _WRRowTile extends StatelessWidget {
  final WRRow row;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _WRRowTile({
    required this.row,
    required this.isSelected,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final scanStatus = row.scanStatus;

    Color textColor = AppColors.black;
    Widget? leadingIcon;

    if (scanStatus == 2) {
      textColor = AppColors.text_warning;
      leadingIcon = IconButton(
        icon: const Icon(Icons.refresh),
        color: AppColors.blackText,
        iconSize: 35,
        onPressed: onReset,
      );
    } else if (scanStatus == 3) {
      textColor = AppColors.text_placeholder;
      leadingIcon = IconButton(
        icon: const Icon(Icons.construction),
        color: AppColors.blackText,
        iconSize: 35,
        onPressed: onTap,
      );
    }

    Color statusCircleColor() {
      if (scanStatus == 2) return AppColors.text_warning;
      if (scanStatus == 3) return AppColors.text_placeholder;
      return AppColors.black;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.headerColor : Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.borderTable),
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Receipt No + Product Names
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: (scanStatus == 2 || scanStatus == 3) ? 0 : 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.borderTable),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (scanStatus == 2 || scanStatus == 3)
                          SizedBox(
                            width: 50,
                            child: leadingIcon ?? const SizedBox(),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.receiptNo,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  fontFamily: 'MSPGothic',
                                ),
                              ),
                              if (row.productNames != null &&
                                  row.productNames!.isNotEmpty)
                                ...row.productNames!
                                    .split(',')
                                    .where((n) => n.trim().isNotEmpty)
                                    .map(
                                      (n) => Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Text(
                                          n.trim().length > 25
                                              ? '${n.trim().substring(0, 25)}...'
                                              : n.trim(),
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: textColor,
                                            fontFamily: 'MSPGothic',
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Supplier Name
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    child: Text(
                      row.supplierName ?? '',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.sp,
                        fontFamily: 'MSPGothic',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            // Status circle indicator (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: statusCircleColor(),
                    width: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
