import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/storage/cache_storage.dart';
import '../../data/datasources/remote/wr_remote_datasource.dart';
import '../../routes/route_names.dart';
import '../blocs/wr/wr_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/module_list_tile.dart';
import '../widgets/module_tinted_button.dart';

class WRListScreen extends StatelessWidget {
  final int tenantId;
  final String company;

  const WRListScreen({super.key, this.tenantId = 0, this.company = ''});

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
  final _searchCtrl = TextEditingController();
  int? _selectedIndex;
  Map<String, dynamic>? _filters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  void _backToMenu() => context.go(RouteNames.mainMenu);

  void _handleRowTap(BuildContext context, int index, WRRow row) {
    if (row.scanStatus == 3) {
      final other = row.hhtInfoOther?.split('-').first ?? '他のユーザー';
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知', style: TextStyle(fontFamily: 'MSPGothic')),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.receiptNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: 'MSPGothic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.settingsColor1),
              child: const Text('閉じる', style: TextStyle(fontFamily: 'MSPGothic')),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    context.push(RouteNames.warehouseReceiptDetail, extra: {
      'receiptNo': row.receiptNo,
      'supplierName': row.supplierName,
      'tenantId': widget.tenantId,
    });
  }

  Future<void> _openFilter() async {
    final result = await context.push<Map<String, dynamic>>(
      RouteNames.warehouseReceiptFilter,
      extra: {'tenantId': widget.tenantId, 'company': widget.company},
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _backToMenu,
        ),
        title: Text(
          '入荷一覧${widget.company.isNotEmpty ? " (${widget.company})" : ""}',
          style: const TextStyle(fontFamily: 'MSPGothic', color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.white), onPressed: _loadData),
        ],
      ),
      body: BlocListener<WRBloc, WRState>(
        listener: (context, state) {
          if (state is WRError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.btnRed),
            );
          }
          if (state is WRResetDone) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('リセットが完了しました'), backgroundColor: AppColors.btnGreen),
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText: 'フィルターする内容を入力してください。',
                onChanged: (v) => context.read<WRBloc>().add(SearchWRLists(v)),
              ),
            ),
            Expanded(child: _buildBody()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<WRBloc, WRState>(
      builder: (context, state) {
        if (state is WRLoading || state is WRResetting) {
          return AppLoading.centered(message: '読み込み中...');
        }
        if (state is WRError) {
          return AppError.generic(message: state.message, onRetry: _loadData);
        }
        final rows = state is WRListsLoaded ? state.rows : <WRRow>[];
        if (rows.isEmpty && state is WRListsLoaded) {
          return AppEmpty.list(message: '入荷データがありません');
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
            final row = rows[index];
            final (Color statusColor, String statusLabel) = switch (row.scanStatus) {
              2 => (AppColors.textWarning,    '進行中'),
              3 => (AppColors.gray,           'ロック'),
              _ => (AppColors.settingsColor1, '未開始'),
            };
            final firstProduct = (row.productNames ?? '')
                .split(',')
                .map((n) => n.trim())
                .firstWhere((n) => n.isNotEmpty, orElse: () => '');
            final subtitle = firstProduct.length > 30
                ? '${firstProduct.substring(0, 30)}…'
                : firstProduct;
            final supplier = (row.supplierName ?? '').trim();
            final trailing = supplier.length > 14
                ? '${supplier.substring(0, 14)}…'
                : (supplier.isEmpty ? '' : supplier);
            return ModuleListTile(
              title: row.receiptNo,
              subtitle: subtitle.isEmpty ? null : subtitle,
              trailingText: trailing,
              statusColor: statusColor,
              statusLabel: statusLabel,
              isSelected: _selectedIndex == index,
              onTap: () => _handleRowTap(context, index, row),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.light)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Material(
                color: AppColors.settingsColor1,
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                child: InkWell(
                  onTap: _backToMenu,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                        SizedBox(width: 8),
                        Text('戻る', style: TextStyle(fontFamily: 'MSPGothic', color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ModuleTintedButton(
                label: '絞り込み',
                icon: Icons.filter_list,
                color: AppColors.settingsColor1,
                onPressed: _openFilter,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
