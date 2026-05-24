import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/bin_audit_repository.dart';
import '../../routes/route_names.dart';
import '../blocs/bin_audit/bin_audit_bloc.dart';
import '../widgets/app_empty.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/back_to_menu_button.dart';
import '../widgets/module_list_tile.dart';

class BinAuditListScreen extends StatelessWidget {
  const BinAuditListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BinAuditBloc(repository: sl<BinAuditRepository>())
        ..add(FetchBinAuditList()),
      child: const _BinAuditListView(),
    );
  }
}

class _BinAuditListView extends StatefulWidget {
  const _BinAuditListView();
  @override
  State<_BinAuditListView> createState() => _BinAuditListViewState();
}

class _BinAuditListViewState extends State<_BinAuditListView> {
  final _searchCtrl = TextEditingController();
  int? _selectedIndex;
  static final _dateFormat = DateFormat('yyyy/MM/dd');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData() => context.read<BinAuditBloc>().add(FetchBinAuditList());
  void _backToMenu() => context.go(RouteNames.mainMenu);

  void _handleRowTap(int index, BinAuditRow row) {
    setState(() => _selectedIndex = index);
    context.push(RouteNames.binAuditDetail, extra: {
      'id': row.id,
      'stockTakeNo': row.stockTakeNo,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.settingsColor6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
          onPressed: _backToMenu,
        ),
        title: const Text('棚卸一覧', style: AppTextStyles.appBarTitle),
        actions: [
          BlocBuilder<BinAuditBloc, BinAuditState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white, size: AppTextStyles.sizeAppBarIcon),
              onPressed: state is BinAuditLoading ? null : _loadData,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'フィルターする内容を入力してください。',
              onChanged: (v) => context.read<BinAuditBloc>().add(SearchBinAuditList(v)),
            ),
          ),
          Expanded(child: _buildBody()),
          BackToMenuButton(color: AppColors.settingsColor6, onPressed: _backToMenu),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<BinAuditBloc, BinAuditState>(
      builder: (context, state) {
        if (state is BinAuditLoading) return AppLoading.centered(message: '読み込み中...');
        if (state is BinAuditError) return AppError.generic(message: state.message, onRetry: _loadData);
        final rows = state is BinAuditListLoaded ? state.rows : <BinAuditRow>[];
        if (rows.isEmpty && state is BinAuditListLoaded) return AppEmpty.list(message: '棚卸データがありません');
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          separatorBuilder: (_, __) => const ModuleListDivider(),
          itemBuilder: (context, index) {
            final row = rows[index];
            final (Color statusColor, String statusLabel) = row.isDone
                ? (AppColors.wageningenGreen, '完了')
                : row.isPending
                    ? (AppColors.textWarning, '進行中')
                    : (AppColors.settingsColor6, '未開始');
            final dateStr = row.transactionDate != null
                ? _dateFormat.format(row.transactionDate!)
                : '';
            final trailing = row.recordNo != null ? '#${row.recordNo}' : null;
            return ModuleListTile(
              title: row.stockTakeNo,
              subtitle: dateStr.isNotEmpty ? dateStr : null,
              trailingText: trailing,
              statusColor: statusColor,
              statusLabel: statusLabel,
              isSelected: _selectedIndex == index,
              onTap: () => _handleRowTap(index, row),
            );
          },
        );
      },
    );
  }
}
