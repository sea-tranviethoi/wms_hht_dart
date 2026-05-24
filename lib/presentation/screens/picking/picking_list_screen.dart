import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/injection.dart';
import '../../blocs/picking/picking_bloc.dart';
import '../../../routes/route_names.dart';
import '../../widgets/app_empty.dart';
import '../../widgets/app_error.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/back_to_menu_button.dart';
import '../../widgets/module_list_tile.dart';

/// Port từ screens/Picking/PickingList.js — minimal modern layout.
///
/// Hiển thị danh sách picking orders của tenant.
/// scanStatus:
///   0 = 未開始
///   1 = 進行中 (đang scan bởi thiết bị này)
///   2 = ロック (đang xử lý bởi thiết bị khác)
class PickingListScreen extends StatelessWidget {
  final int tenantId;
  final String company;

  const PickingListScreen({
    super.key,
    required this.tenantId,
    this.company = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PickingBloc(remote: sl())
        ..add(FetchPickingLists(tenantId: tenantId)),
      child: _PickingListView(tenantId: tenantId, company: company),
    );
  }
}

class _PickingListView extends StatefulWidget {
  final int tenantId;
  final String company;

  const _PickingListView({required this.tenantId, required this.company});

  @override
  State<_PickingListView> createState() => _PickingListViewState();
}

class _PickingListViewState extends State<_PickingListView> {
  final _searchCtrl = TextEditingController();
  int? _selectedIndex;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _backToTenantSelection() =>
      context.go('${RouteNames.tenantSelection}?funcNumber=3');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
          onPressed: _backToTenantSelection,
        ),
        title: Text('ピッキング一覧${widget.company.isNotEmpty ? ' (${widget.company})' : ''}', style: AppTextStyles.appBarTitle),
        actions: [
          BlocBuilder<PickingBloc, PickingState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
              onPressed: state is PickingLoading
                  ? null
                  : () {
                      _searchCtrl.clear();
                      context.read<PickingBloc>().add(
                            FetchPickingLists(tenantId: widget.tenantId),
                          );
                    },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'フィルターする内容を入力してください。',
              onChanged: (v) =>
                  context.read<PickingBloc>().add(SearchPickingLists(v)),
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(child: _buildBody()),

          // ── Back button — module color (Picking = Orange) ────
          BackToMenuButton(
            color: AppColors.settingsColor3,
            onPressed: _backToTenantSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<PickingBloc, PickingState>(
      builder: (context, state) {
        if (state is PickingLoading) {
          return AppLoading.centered(message: '読み込み中...');
        }
        if (state is PickingError) {
          return AppError.generic(
            message: state.message,
            onRetry: () => context
                .read<PickingBloc>()
                .add(FetchPickingLists(tenantId: widget.tenantId)),
          );
        }
        if (state is PickingListsLoaded) {
          if (state.rows.isEmpty) {
            return AppEmpty.list(message: 'ピッキングリストがありません');
          }
          return Container(
            color: AppColors.white,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: state.rows.length,
              separatorBuilder: (_, __) => const ModuleListDivider(),
              itemBuilder: (context, index) {
                final row = state.rows[index];
                final isSelected = _selectedIndex == index;

                final (Color statusColor, String statusLabel) =
                    switch (row.scanStatus) {
                  1 => (AppColors.textWarning,    '進行中'),
                  2 => (AppColors.gray,           'ロック'),
                  _ => (AppColors.settingsColor3, '未開始'),
                };

                return ModuleListTile(
                  title: row.pickNo,
                  subtitle: null,
                  trailingText: '${row.binCount} 棚',
                  statusColor: statusColor,
                  statusLabel: statusLabel,
                  isSelected: isSelected,
                  onTap: () => _handleRowTap(context, index, row),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _handleRowTap(BuildContext context, int index, PickingRow row) {
    if (row.scanStatus == 2) {
      // Handled by other device → show notification dialog
      final other = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知',
              style: TextStyle(fontFamily: AppTextStyles.font)),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.pickNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: AppTextStyles.font),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.settingsColor3),
              child: const Text('閉じる',
                  style: TextStyle(fontFamily: AppTextStyles.font)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _selectedIndex = index);

    context.push(
      RouteNames.pickingItems,
      extra: {
        'pickNo': row.pickNo,
        'tenantId': widget.tenantId,
        'company': widget.company,
      },
    );
  }
}
