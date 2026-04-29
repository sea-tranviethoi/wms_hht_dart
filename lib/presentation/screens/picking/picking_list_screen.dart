import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../blocs/picking/picking_bloc.dart';
import '../../../routes/route_names.dart';

/// Port từ screens/Picking/PickingList.js
///
/// Hiển thị danh sách picking orders của tenant.
/// scanStatus màu sắc:
///   0 = bình thường (đen)
///   1 = đang scan bởi thiết bị này (cam)
///   2 = đang xử lý bởi thiết bị khác (xám)
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      appBar: AppBar(
        backgroundColor: AppColors.themeBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () =>
              context.go('${RouteNames.tenantSelection}?funcNumber=3'),
        ),
        title: Text(
          'ピッキング一覧${widget.company.isNotEmpty ? ' (${widget.company})' : ''}',
          style: const TextStyle(
            fontFamily: 'MSPGothic',
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          BlocBuilder<PickingBloc, PickingState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
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
          _buildSearchBar(context),
          _buildTableHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontFamily: 'MSPGothic'),
        decoration: InputDecoration(
          hintText: 'フィルターする内容を入力してください。',
          hintStyle: const TextStyle(fontFamily: 'MSPGothic', color: AppColors.gray),
          prefixIcon: const Icon(Icons.search, color: AppColors.gray),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<PickingBloc>().add(SearchPickingLists(''));
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: AppColors.ghostWhiteColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) =>
            context.read<PickingBloc>().add(SearchPickingLists(v)),
      ),
    );
  }

  // ─── Table header ─────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderTable),
                  right: BorderSide(color: AppColors.borderTable),
                ),
              ),
              child: const Text(
                'ピッキング番号',
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderTable)),
              ),
              child: const Text(
                '棚数',
                style: TextStyle(
                  fontFamily: 'MSPGothic',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────

  Widget _buildBody() {
    return BlocBuilder<PickingBloc, PickingState>(
      builder: (context, state) {
        if (state is PickingLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.themeBackground),
          );
        }
        if (state is PickingError) {
          return _buildError(context, state.message);
        }
        if (state is PickingListsLoaded) {
          if (state.rows.isEmpty) {
            return const Center(
              child: Text(
                'ピッキングリストがありません',
                style: TextStyle(fontFamily: 'MSPGothic', color: AppColors.gray),
              ),
            );
          }
          return ListView.builder(
            itemCount: state.rows.length,
            itemBuilder: (context, index) => _PickingRowTile(
              row: state.rows[index],
              onTap: () => _handleRowTap(context, state.rows[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.textError, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  fontFamily: 'MSPGothic', color: AppColors.textError),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context
                .read<PickingBloc>()
                .add(FetchPickingLists(tenantId: widget.tenantId)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeBackground,
                foregroundColor: Colors.white),
            child: const Text('再試行', style: TextStyle(fontFamily: 'MSPGothic')),
          ),
        ],
      ),
    );
  }

  // ─── Row tap ──────────────────────────────────────────────────

  void _handleRowTap(BuildContext context, PickingRow row) {
    if (row.scanStatus == 2) {
      // Handled by other device
      final other = row.hhtInfoOther.split('-').first;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('通知', style: TextStyle(fontFamily: 'MSPGothic')),
          content: Text(
            'ユーザー「$other」は別デバイスで ${row.pickNo} を対応してます。ご確認ください。',
            style: const TextStyle(fontFamily: 'MSPGothic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる', style: TextStyle(fontFamily: 'MSPGothic')),
            ),
          ],
        ),
      );
      return;
    }

    context.push(
      RouteNames.pickingItems,
      extra: {
        'pickNo': row.pickNo,
        'tenantId': widget.tenantId,
        'company': widget.company,
      },
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  context.go('${RouteNames.tenantSelection}?funcNumber=3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.settingsColor4,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '戻る',
                style: TextStyle(
                    fontFamily: 'MSPGothic',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Row tile ─────────────────────────────────────────────────────────────────

class _PickingRowTile extends StatelessWidget {
  final PickingRow row;
  final VoidCallback onTap;

  const _PickingRowTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Widget? leadingWidget;

    switch (row.scanStatus) {
      case 1:
        textColor = AppColors.textWarning;
        leadingWidget = const Icon(Icons.refresh, size: 28, color: AppColors.blackTextColor);
        break;
      case 2:
        textColor = AppColors.grayTextColor;
        leadingWidget = const Icon(Icons.construction, size: 28, color: AppColors.blackTextColor);
        break;
      default:
        textColor = AppColors.blackTextColor;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.borderTable)),
        ),
        child: Row(
          children: [
            // PickNo column
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.borderTable)),
                ),
                child: Row(
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget,
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        row.pickNo,
                        style: TextStyle(
                          fontFamily: 'MSPGothic',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // BinCount column
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  '${row.binCount}',
                  style: TextStyle(
                    fontFamily: 'MSPGothic',
                    fontSize: 14,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
